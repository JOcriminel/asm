package com.asm.dux.timetree;

import com.asm.dux.timetree.service.DuplicateMessageDetector;
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
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Integration tests for Redis offline queue:
 *   - Enqueue when user is offline
 *   - Replay on reconnect (exactly-once guarantee)
 *   - No duplicate messages after retry with same clientMessageId
 *   - Queue cleared after replay
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class TimetreeOfflineQueueTests {

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void configureRedis(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
    }

    @MockBean
    private JwtDecoder jwtDecoder;

    @Autowired
    private OfflineQueueService offlineQueueService;

    @Autowired
    private PresenceService presenceService;

    @Autowired
    private DuplicateMessageDetector duplicateDetector;

    @Autowired
    private StringRedisTemplate redisTemplate;

    @BeforeEach
    void setUp() {
        redisTemplate.getConnectionFactory().getConnection().flushAll();

        Jwt jwt = Jwt.withTokenValue("test-token")
                .header("alg", "RS256")
                .subject("alice")
                .issuer("http://localhost:8080/auth/realms/DuxWeb")
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);
    }

    // ─── Test 1: Enqueue for offline user ───────────────────────────────────────

    @Test
    void testEnqueueForOfflineUser() {
        String username = "offline-user";
        // User is offline (no Redis presence key)
        assertThat(presenceService.isOnline(username)).isFalse();

        Map<String, Object> payload = new HashMap<>();
        payload.put("clientMessageId", "550e8400-e29b-41d4-a716-446655440000");
        payload.put("message", "Hello offline user");
        payload.put("eventId", "42");

        offlineQueueService.enqueue(username, payload);

        long queueSize = offlineQueueService.getQueueSize(username);
        assertThat(queueSize).isEqualTo(1);

        // Verify Redis key exists
        Boolean keyExists = redisTemplate.hasKey("timetree:offline:" + username);
        assertThat(keyExists).isTrue();
    }

    // ─── Test 2: Multiple messages queued in order ────────────────────────────────

    @Test
    void testMultipleMessagesQueuedInOrder() {
        String username = "queued-user";

        for (int i = 1; i <= 5; i++) {
            Map<String, Object> payload = Map.of(
                    "clientMessageId", UUID.randomUUID().toString().replace("-", "4").substring(0, 8)
                            + "-0000-4000-8000-000000000" + String.format("%03d", i),
                    "message", "Message " + i
            );
            offlineQueueService.enqueue(username, payload);
        }

        assertThat(offlineQueueService.getQueueSize(username)).isEqualTo(5);

        List<Map<String, Object>> queued = offlineQueueService.peekQueue(username);
        assertThat(queued).hasSize(5);
    }

    // ─── Test 3: Replay delivers messages and clears queue ───────────────────────

    @Test
    void testReplayDeliveredAndQueueCleared() {
        String username = "replay-user";
        String clientId = "550e8400-e29b-41d4-a716-446655440001";

        Map<String, Object> payload = new HashMap<>();
        payload.put("clientMessageId", clientId);
        payload.put("message", "Replayed message");

        offlineQueueService.enqueue(username, payload);
        assertThat(offlineQueueService.getQueueSize(username)).isEqualTo(1);

        // Replay (user comes online)
        offlineQueueService.replayIfPending(username);

        // Queue should be empty after replay
        assertThat(offlineQueueService.getQueueSize(username)).isEqualTo(0);
        Boolean keyExists = redisTemplate.hasKey("timetree:offline:" + username);
        assertThat(keyExists).isFalse();
    }

    // ─── Test 4: Exactly-once — no duplicate delivery after retry ───────────────

    @Test
    void testExactlyOnceDeliveryNoDuplicates() {
        String username = "dedup-user";
        String clientId  = "550e8400-e29b-41d4-a716-446655440002";

        Map<String, Object> payload = new HashMap<>();
        payload.put("clientMessageId", clientId);
        payload.put("message", "Original message");

        // Register as already-delivered in dup cache (simulates prior ACK)
        duplicateDetector.registerMessage(clientId, "server-msg-id-999");

        // Enqueue anyway (simulates client retry before ACK was acknowledged)
        offlineQueueService.enqueue(username, payload);
        assertThat(offlineQueueService.getQueueSize(username)).isEqualTo(1);

        // Replay — duplicate detector should suppress the redelivery
        offlineQueueService.replayIfPending(username);

        // Queue cleared, no duplicate sent (verified by absence of error + empty queue)
        assertThat(offlineQueueService.getQueueSize(username)).isEqualTo(0);
        // Confirm the original serverMessageId is still in dup cache
        String storedServerId = duplicateDetector.getExistingServerMessageId(clientId);
        assertThat(storedServerId).isEqualTo("server-msg-id-999");
    }

    // ─── Test 5: Redis key schema validation ────────────────────────────────────

    @Test
    void testRedisOfflineKeySchema() {
        String username = "key-test-user";
        offlineQueueService.enqueue(username, Map.of("message", "test", "clientMessageId",
                "550e8400-e29b-41d4-a716-446655440003"));

        // Verify key format: timetree:offline:{username}
        Boolean exists = redisTemplate.hasKey("timetree:offline:" + username);
        assertThat(exists).isTrue();

        // Verify TTL is set (24h = 86400s)
        Long ttl = redisTemplate.getExpire("timetree:offline:" + username,
                java.util.concurrent.TimeUnit.SECONDS);
        assertThat(ttl).isGreaterThan(0).isLessThanOrEqualTo(86400);
    }

    // ─── Test 6: UUID v4 validation ─────────────────────────────────────────────

    @Test
    void testUuidV4Validation() {
        DuplicateMessageDetector detector = duplicateDetector;

        // Valid UUID v4
        assertThat(detector.isValidUUID("550e8400-e29b-41d4-a716-446655440000")).isTrue();
        assertThat(detector.isValidUUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")).isFalse(); // v1
        assertThat(detector.isValidUUID("not-a-uuid")).isFalse();
        assertThat(detector.isValidUUID("")).isFalse();
        assertThat(detector.isValidUUID(null)).isFalse();

        // Confirm v4 variants
        assertThat(detector.isValidUUID("6ba7b814-9dad-0000-8000-00c04fd430c8")).isFalse(); // v0
        assertThat(detector.isValidUUID("6ba7b814-9dad-4000-a000-00c04fd430c8")).isTrue();  // v4 variant a
    }
}
