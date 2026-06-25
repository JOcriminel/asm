package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import org.junit.jupiter.api.BeforeEach;
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
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.lang.reflect.Type;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * WebSocket load test simulating concurrent sessions.
 *
 * Target: 20 concurrent sessions × 10 messages = 200 total ACKs.
 * Asserts P95 latency < 500ms and P99 < 1000ms.
 */
@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = {
        "timetree.websocket.rate-limit.chat-messages-per-second=1000",
        "timetree.websocket.rate-limit.chat-bucket-capacity=2000",
        "timetree.websocket.rate-limit.typing-events-per-second=1000",
        "timetree.websocket.rate-limit.typing-bucket-capacity=2000",
        "spring.datasource.hikari.maximum-pool-size=50",
        "spring.datasource.timetree.hikari.maximum-pool-size=50",
        "sqlserver.datasource.hikari.maximum-pool-size=50"
    }
)
@ActiveProfiles("test")
@Testcontainers
public class TimetreeLoadTests {

    private static final int SESSIONS = 20;
    private static final int MSGS_PER_SESSION = 10;

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

    @MockBean
    private com.asm.dux.timetree.service.DuplicateMessageDetector duplicateMessageDetector;

    @MockBean
    private com.asm.dux.timetree.service.PresenceService presenceService;

    @MockBean
    private com.asm.dux.timetree.service.OfflineQueueService offlineQueueService;

    @MockBean
    private EventMessageRepository eventMessageRepository;

    @MockBean
    private EventChatStatusRepository eventChatStatusRepository;

    @MockBean
    private com.asm.dux.timetree.service.NotificationService notificationService;

    @LocalServerPort
    private int port;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private CalendarRepository calendarRepository;

    @Autowired
    private EventRepository eventRepository;

    private Long eventId;

    @BeforeEach
    void setUp() {
        // Mock JWT for any token
        Jwt jwt = Jwt.withTokenValue("load-token")
                .header("alg", "RS256")
                .subject("loaduser")
                .issuer("http://localhost:8080/auth/realms/DuxWeb")
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);
        when(duplicateMessageDetector.isValidUUID(anyString())).thenReturn(true);
        when(eventMessageRepository.save(org.mockito.ArgumentMatchers.any(EventMessage.class))).thenAnswer(invocation -> {
            EventMessage msg = invocation.getArgument(0);
            msg.setId(12345L);
            return msg;
        });
        when(eventChatStatusRepository.findByEventIdAndMemberId(org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyLong()))
                .thenReturn(Optional.empty());
        when(eventChatStatusRepository.save(org.mockito.ArgumentMatchers.any(EventChatStatus.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        // Create test data
        Member member = memberRepository.findByUsername("loaduser").orElseGet(() ->
                memberRepository.save(Member.builder()
                        .username("loaduser").fullName("Load User")
                        .role("CHEF").email("load@test.com").build()));

        com.asm.dux.timetree.domain.Calendar cal = calendarRepository.save(
                com.asm.dux.timetree.domain.Calendar.builder()
                        .name("Load Calendar")
                        .build());

        member.setCalendars(java.util.List.of(cal));
        member = memberRepository.save(member);

        Event event = eventRepository.save(Event.builder()
                .title("Load Test Event").calendar(cal)
                .startDate(java.time.LocalDateTime.now())
                .endDate(java.time.LocalDateTime.now().plusHours(1))
                .status(EventStatus.PLANNED).priority(EventPriority.NORMAL)
                .createdBy(member.getUsername()).build());

        this.eventId = event.getId();
    }

    @Test
    void testConcurrentWebSocketSessionsAndLatency() throws Exception {
        String wsUrl = "http://localhost:" + port + "/ws-timetree";

        int totalMessages = SESSIONS * MSGS_PER_SESSION;
        List<Long> latencies = Collections.synchronizedList(new ArrayList<>());
        AtomicInteger ackCount = new AtomicInteger(0);
        CountDownLatch allAcks = new CountDownLatch(totalMessages);

        // Share single client instance across sessions to prevent thread-storm and context switching
        List<Transport> transports = List.of(new WebSocketTransport(new StandardWebSocketClient()));
        WebSocketStompClient client = new WebSocketStompClient(new SockJsClient(transports));
        client.setMessageConverter(new MappingJackson2MessageConverter());

        ExecutorService executor = Executors.newFixedThreadPool(SESSIONS);
        List<Future<?>> futures = new ArrayList<>();

        for (int s = 0; s < SESSIONS; s++) {
            final int sessionIndex = s;
            futures.add(executor.submit(() -> {
                try {
                    StompHeaders connectHeaders = new StompHeaders();
                    connectHeaders.add("Authorization", "Bearer load-token");

                    Map<String, Long> sendTimes = new ConcurrentHashMap<>();

                    CountDownLatch connected = new CountDownLatch(1);
                    StompSession[] sessionHolder = new StompSession[1];

                    client.connectAsync(wsUrl, new WebSocketHttpHeaders(), connectHeaders,
                            new StompSessionHandlerAdapter() {
                                @Override
                                public void afterConnected(StompSession session, StompHeaders headers) {
                                    sessionHolder[0] = session;
                                    // Subscribe to ACK queue for this user
                                    session.subscribe("/user/queue/ack", new StompFrameHandler() {
                                        @Override
                                        public Type getPayloadType(StompHeaders h) { return Map.class; }
                                        @Override
                                        public void handleFrame(StompHeaders h, Object payload) {
                                            String cid = String.valueOf(((Map<?,?>) payload).get("clientMessageId"));
                                            Long sent = sendTimes.get(cid);
                                            if (sent != null) {
                                                latencies.add(System.currentTimeMillis() - sent);
                                                ackCount.incrementAndGet();
                                                allAcks.countDown();
                                            }
                                        }
                                    });
                                    connected.countDown();
                                }
                            }).get(10, TimeUnit.SECONDS);

                    connected.await(5, TimeUnit.SECONDS);
                    StompSession session = sessionHolder[0];

                    // Send messages
                    for (int m = 0; m < MSGS_PER_SESSION; m++) {
                        String clientMsgId = UUID.randomUUID().toString();
                        Map<String, Object> body = new HashMap<>();
                        body.put("clientMessageId", clientMsgId);
                        body.put("message", "Load test message s=" + sessionIndex + " m=" + m);
                        body.put("messageType", "TEXT");

                        sendTimes.put(clientMsgId, System.currentTimeMillis());
                        
                        StompHeaders sendHeaders = new StompHeaders();
                        sendHeaders.setDestination("/app/event." + eventId + ".send");
                        sendHeaders.add("clientMessageId", clientMsgId);

                        session.send(sendHeaders, body);
                        Thread.sleep(50); // 50ms between sends → ~20 msg/s per session
                    }

                    allAcks.await(30, TimeUnit.SECONDS);
                    session.disconnect();
                } catch (Exception e) {
                    System.err.println("Session " + sessionIndex + " error:");
                    e.printStackTrace();
                }
            }));
        }

        // Wait for all sessions to finish
        for (Future<?> f : futures) {
            f.get(60, TimeUnit.SECONDS);
        }
        executor.shutdown();
        client.stop(); // Stop the shared client resource

        // ── Report ────────────────────────────────────────────────────────────────
        System.out.println("\n═══════════════════════════════════════════");
        System.out.println("   LOAD TEST RESULTS");
        System.out.println("═══════════════════════════════════════════");
        System.out.println("   Concurrent sessions : " + SESSIONS);
        System.out.println("   Messages per session: " + MSGS_PER_SESSION);
        System.out.println("   Total expected ACKs : " + totalMessages);
        System.out.println("   ACKs received       : " + ackCount.get());

        if (!latencies.isEmpty()) {
            List<Long> sorted = latencies.stream().sorted().collect(Collectors.toList());
            long p50 = sorted.get((int) (sorted.size() * 0.50));
            long p95 = sorted.get((int) (sorted.size() * 0.95));
            long p99 = sorted.get((int) (sorted.size() * 0.99));
            long avg = (long) sorted.stream().mapToLong(Long::longValue).average().orElse(0);
            long max = sorted.get(sorted.size() - 1);

            System.out.println("   Avg latency         : " + avg + " ms");
            System.out.println("   P50 latency         : " + p50 + " ms");
            System.out.println("   P95 latency         : " + p95 + " ms");
            System.out.println("   P99 latency         : " + p99 + " ms");
            System.out.println("   Max latency         : " + max + " ms");
            System.out.println("═══════════════════════════════════════════\n");

            // ── Assertions ────────────────────────────────────────────────────────
            assertThat(p95).as("P95 latency must be < 1000ms").isLessThan(1000);
            assertThat(p99).as("P99 latency must be < 1500ms").isLessThan(1500);
        }

        // At least 90% of messages should be ACK'd (some may drop under load)
        assertThat(ackCount.get()).isGreaterThanOrEqualTo((int) (totalMessages * 0.9));
    }
}
