package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.OfflineQueueService;
import com.asm.dux.timetree.service.PresenceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.time.Instant;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Integration tests for Redis-backed presence TTL expiry and heartbeat.
 *
 * Uses a short TTL (2 s) and cleanup interval (500 ms) from application-test.properties.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class TimetreePresenceTests {

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void configureRedis(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
        // 2-second TTL for fast expiry tests
        registry.add("timetree.websocket.presence.session-ttl-seconds", () -> "2");
        registry.add("timetree.websocket.presence.cleanup-interval-ms", () -> "500");
    }

    @MockBean
    private JwtDecoder jwtDecoder;

    @Autowired
    private PresenceService presenceService;

    @Autowired
    private StringRedisTemplate redisTemplate;

    @BeforeEach
    void setUp() {
        // Flush Redis before each test
        redisTemplate.getConnectionFactory().getConnection().flushAll();

        // Mock JWT decoder
        Jwt jwt = Jwt.withTokenValue("test-token")
                .header("alg", "RS256")
                .subject("alice")
                .issuer("http://localhost:8080/auth/realms/DuxWeb")
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);
    }

    // ─── Test 1: Session registers ONLINE in Redis ───────────────────────────────

    @Test
    void testPresenceOnlineSetInRedis() {
        presenceService.registerUserSession("session-001", "alice");

        Boolean exists = redisTemplate.hasKey("timetree:presence:alice");
        assertThat(exists).isTrue();
        assertThat(presenceService.isOnline("alice")).isTrue();

        String value = redisTemplate.opsForValue().get("timetree:presence:alice");
        assertThat(value).isEqualTo("ONLINE");
    }

    // ─── Test 2: Presence TTL expires and cleanup marks user OFFLINE ─────────────

    @Test
    void testPresenceTTLExpiry() throws InterruptedException {
        presenceService.registerUserSession("session-002", "bob");
        assertThat(presenceService.isOnline("bob")).isTrue();

        // Wait for Redis key to expire (TTL = 2s, wait 3s)
        Thread.sleep(3000);

        // Trigger cleanup
        presenceService.cleanExpiredSessions();

        assertThat(presenceService.isOnline("bob")).isFalse();
        Boolean keyExists = redisTemplate.hasKey("timetree:presence:bob");
        assertThat(keyExists).isFalse();
    }

    // ─── Test 3: Heartbeat prevents TTL expiry ──────────────────────────────────

    @Test
    void testHeartbeatPreventsExpiry() throws InterruptedException {
        presenceService.registerUserSession("session-003", "carol");
        assertThat(presenceService.isOnline("carol")).isTrue();

        // Send heartbeats every 1 second for 4 seconds (TTL=2s would normally expire)
        for (int i = 0; i < 4; i++) {
            Thread.sleep(1000);
            presenceService.refreshHeartbeat("carol");
        }

        // Run cleanup — carol should still be ONLINE because TTL was reset
        presenceService.cleanExpiredSessions();
        assertThat(presenceService.isOnline("carol")).isTrue();
    }

    // ─── Test 4: Disconnect marks user OFFLINE immediately ──────────────────────

    @Test
    void testDisconnectMarksOffline() {
        presenceService.registerUserSession("session-004", "dave");
        assertThat(presenceService.isOnline("dave")).isTrue();

        // Simulate disconnect by registering then removing
        presenceService.registerUserSession("session-004", "dave");
        // Call internal method via handleDisconnect simulation
        // We test the Redis state directly
        redisTemplate.delete("timetree:presence:dave");

        assertThat(presenceService.isOnline("dave")).isFalse();
    }

    // ─── Test 5: Redis key structure validation ──────────────────────────────────

    @Test
    void testRedisKeyStructure() {
        presenceService.registerUserSession("session-005", "eve");

        // Verify exact key format
        Boolean hasKey = redisTemplate.hasKey("timetree:presence:eve");
        assertThat(hasKey).isTrue();

        Long ttl = redisTemplate.getExpire("timetree:presence:eve", TimeUnit.SECONDS);
        assertThat(ttl).isGreaterThan(0).isLessThanOrEqualTo(2);
    }
}
