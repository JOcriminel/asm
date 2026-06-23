package com.asm.dux.timetree;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.web.socket.WebSocketHttpHeaders;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;
import org.springframework.web.socket.sockjs.client.SockJsClient;
import org.springframework.web.socket.sockjs.client.Transport;
import org.springframework.web.socket.sockjs.client.WebSocketTransport;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.RabbitMQContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import com.asm.dux.timetree.repository.MemberRepository;
import com.asm.dux.timetree.domain.Member;


import java.lang.reflect.Type;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Broker relay integration test using Testcontainers RabbitMQ with STOMP plugin.
 *
 * Verifies that STOMP pub/sub works through the RabbitMQ relay (not simple in-memory broker).
 * Two STOMP clients connect, one sends a message, the other receives it via RabbitMQ.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class TimetreeBrokerRelayTests {

    @Container
    static RabbitMQContainer rabbitmq = new RabbitMQContainer(
            DockerImageName.parse("rabbitmq:3.12-management"))
            .withPluginsEnabled("rabbitmq_stomp")
            .withExposedPorts(5672, 15672, 61613);

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void configureContainers(DynamicPropertyRegistry registry) {
        // Redis
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
        // RabbitMQ STOMP broker relay
        registry.add("spring.websocket.broker.type", () -> "relay");
        registry.add("spring.rabbitmq.host", rabbitmq::getHost);
        registry.add("spring.rabbitmq.username", rabbitmq::getAdminUsername);
        registry.add("spring.rabbitmq.password", rabbitmq::getAdminPassword);
        registry.add("timetree.websocket.relay.stomp-port",
                () -> rabbitmq.getMappedPort(61613));
    }


    @MockBean
    private JwtDecoder jwtDecoder;

    @Autowired
    private MemberRepository memberRepository;

    @LocalServerPort
    private int port;

    @Test
    void testStompMessageDeliveryThroughRabbitMQRelay() throws Exception {
        // Mock JWT for test user
        Jwt jwt = Jwt.withTokenValue("relay-test-token")
                .header("alg", "RS256")
                .subject("relay-user")
                .issuer("http://localhost:8080/auth/realms/DuxWeb")
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);

        // Save user in db to allow CONNECT
        memberRepository.findByUsername("relay-user").orElseGet(() ->
                memberRepository.save(Member.builder()
                        .username("relay-user").fullName("Relay User")
                        .role("MEMBER").build()));

        // Build STOMP client
        List<Transport> transports = List.of(new WebSocketTransport(new StandardWebSocketClient()));
        WebSocketStompClient stompClient = new WebSocketStompClient(new SockJsClient(transports));
        stompClient.setMessageConverter(new MappingJackson2MessageConverter());

        String wsUrl = "http://localhost:" + port + "/ws-timetree";
        StompHeaders connectHeaders = new StompHeaders();
        connectHeaders.add("Authorization", "Bearer relay-test-token");

        CompletableFuture<Map<?, ?>> received = new CompletableFuture<>();
        CountDownLatch sessionReady = new CountDownLatch(1);

        StompSession session = stompClient.connectAsync(wsUrl,
                new WebSocketHttpHeaders(), connectHeaders,
                new StompSessionHandlerAdapter() {
                    @Override
                    public void afterConnected(StompSession s, StompHeaders h) {
                        // Subscribe to a test topic
                        s.subscribe("/topic/relay-test", new StompFrameHandler() {
                            @Override
                            public Type getPayloadType(StompHeaders headers) {
                                return Map.class;
                            }
                            @Override
                            public void handleFrame(StompHeaders headers, Object payload) {
                                received.complete((Map<?, ?>) payload);
                            }
                        });
                        sessionReady.countDown();
                    }
                }).get(10, TimeUnit.SECONDS);

        // Wait for subscription to be ready
        assertThat(sessionReady.await(5, TimeUnit.SECONDS)).isTrue();

        // Send a message through the relay
        Map<String, String> payload = Map.of("text", "Hello via RabbitMQ relay!", "source", "broker-relay-test");
        session.send("/topic/relay-test", payload);

        // Wait for delivery
        Map<?, ?> result = received.get(8, TimeUnit.SECONDS);
        assertThat(result).isNotNull();
        assertThat(result.get("text")).isEqualTo("Hello via RabbitMQ relay!");
        assertThat(result.get("source")).isEqualTo("broker-relay-test");

        session.disconnect();
        stompClient.stop();
    }

    @Test
    void testRabbitMQContainerIsRunning() {
        assertThat(rabbitmq.isRunning()).isTrue();
        assertThat(rabbitmq.getMappedPort(5672)).isGreaterThan(0);
        assertThat(rabbitmq.getMappedPort(61613)).isGreaterThan(0);
    }
}
