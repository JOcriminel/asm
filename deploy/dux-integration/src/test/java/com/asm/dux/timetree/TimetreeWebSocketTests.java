package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.DuplicateMessageDetector;
import com.asm.dux.timetree.service.PresenceService;
import com.asm.dux.timetree.service.WebSocketMetricsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
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
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.WebSocketHttpHeaders;
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
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class TimetreeWebSocketTests {

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void configureRedis(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
    }

    @LocalServerPort
    private int port;

    @MockBean
    private JwtDecoder jwtDecoder;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private CalendarRepository calendarRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private EventMessageRepository eventMessageRepository;

    @Autowired
    private DuplicateMessageDetector duplicateMessageDetector;

    @Autowired
    private WebSocketMetricsService metricsService;

    @Autowired
    private PresenceService presenceService;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    private String wsUrl;
    private WebSocketStompClient stompClient;

    private Member alice;
    private Member bob;
    private Event eventA;
    private Event eventB;

    @BeforeEach
    public void setup() {
        wsUrl = "ws://localhost:" + port + "/ws";

        // Setup SockJS client
        List<Transport> transports = List.of(new WebSocketTransport(new StandardWebSocketClient()));
        stompClient = new WebSocketStompClient(new SockJsClient(transports));
        stompClient.setMessageConverter(new MappingJackson2MessageConverter());

        // Clear and mock database state by disabling referential integrity
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT_MESSAGE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT");
        jdbcTemplate.execute("DELETE FROM dbo.TT_MEMBER_CALENDAR");
        jdbcTemplate.execute("DELETE FROM dbo.TT_CALENDAR");
        jdbcTemplate.execute("DELETE FROM dbo.TT_MEMBER");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");

        // Create Members
        alice = memberRepository.save(Member.builder().username("alice").fullName("Alice").role("MEMBER").build());
        bob = memberRepository.save(Member.builder().username("bob").fullName("Bob").role("MEMBER").build());

        // Create Calendars with direct member assignments
        com.asm.dux.timetree.domain.Calendar calA = calendarRepository.save(
                com.asm.dux.timetree.domain.Calendar.builder().name("Calendar A").build());
        com.asm.dux.timetree.domain.Calendar calB = calendarRepository.save(
                com.asm.dux.timetree.domain.Calendar.builder().name("Calendar B").build());

        alice.setCalendars(List.of(calA));
        bob.setCalendars(List.of(calB));
        alice = memberRepository.save(alice);
        bob = memberRepository.save(bob);

        // Create Events (Alice can read Event A, Bob can read Event B)
        eventA = eventRepository.save(Event.builder()
                .title("Event A")
                .calendar(calA)
                .startDate(LocalDateTime.now())
                .endDate(LocalDateTime.now().plusHours(1))
                .status(EventStatus.PLANNED)
                .priority(EventPriority.NORMAL)
                .build());

        eventB = eventRepository.save(Event.builder()
                .title("Event B")
                .calendar(calB)
                .startDate(LocalDateTime.now())
                .endDate(LocalDateTime.now().plusHours(1))
                .status(EventStatus.PLANNED)
                .priority(EventPriority.NORMAL)
                .build());
    }

    private void mockJwt(String username) {
        Jwt jwt = Mockito.mock(Jwt.class);
        when(jwt.getClaimAsString("preferred_username")).thenReturn(username);
        when(jwt.getSubject()).thenReturn(username);
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);
    }

    @Test
    public void testWebSocketConnectionSuccess() throws Exception {
        mockJwt("alice");
        
        StompHeaders headers = new StompHeaders();
        headers.add("passcode", "valid-token-alice");

        CompletableFuture<StompSession> future = new CompletableFuture<>();
        stompClient.connectAsync(wsUrl, new WebSocketHttpHeaders(), headers, new StompSessionHandlerAdapter() {
            @Override
            public void afterConnected(StompSession session, StompHeaders connectedHeaders) {
                future.complete(session);
            }
            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
            }
        });

        StompSession session = future.get(5, TimeUnit.SECONDS);
        assertThat(session.isConnected()).isTrue();
        session.disconnect();
    }

    @Test
    public void testWebSocketUnauthorizedSubscription() throws Exception {
        mockJwt("alice"); // Alice is connected
        
        StompHeaders headers = new StompHeaders();
        headers.add("passcode", "valid-token-alice");

        CompletableFuture<StompSession> sessionFuture = new CompletableFuture<>();
        stompClient.connectAsync(wsUrl, new WebSocketHttpHeaders(), headers, new StompSessionHandlerAdapter() {
            @Override
            public void afterConnected(StompSession session, StompHeaders connectedHeaders) {
                sessionFuture.complete(session);
            }
            @Override
            public void handleException(StompSession session, StompCommand command, StompHeaders headers, byte[] payload, Throwable exception) {
                exception.printStackTrace();
            }
            @Override
            public void handleTransportError(StompSession session, Throwable exception) {
                exception.printStackTrace();
            }
        });

        StompSession session = sessionFuture.get(5, TimeUnit.SECONDS);
        assertThat(session.isConnected()).isTrue();

        // Alice tries to subscribe to Event B (which she has no permission to read)
        CompletableFuture<Throwable> errorFuture = new CompletableFuture<>();
        session.subscribe("/topic/event." + eventB.getId() + ".chat", new StompFrameHandler() {
            @Override
            public Type getPayloadType(StompHeaders headers) {
                return Map.class;
            }
            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
            }
        });

        // Let's also assert that the session closes or returns error frame if unauthorized subscription occurs
        // Wait a brief moment to ensure subscription processing executes
        Thread.sleep(1000);
        
        // Assert that connection or subscription was rejected and session is closed
        assertThat(session.isConnected()).isFalse();
    }

    @Test
    public void testDuplicateMessagePreventionAndAck() throws Exception {
        mockJwt("alice");
        StompHeaders headers = new StompHeaders();
        headers.add("passcode", "valid-token-alice");

        CompletableFuture<StompSession> sessionFuture = new CompletableFuture<>();
        stompClient.connectAsync(wsUrl, new WebSocketHttpHeaders(), headers, new StompSessionHandlerAdapter() {
            @Override
            public void afterConnected(StompSession session, StompHeaders connectedHeaders) {
                sessionFuture.complete(session);
            }
            @Override
            public void handleException(StompSession session, StompCommand command, StompHeaders headers, byte[] payload, Throwable exception) {
                exception.printStackTrace();
            }
            @Override
            public void handleTransportError(StompSession session, Throwable exception) {
                exception.printStackTrace();
            }
        });
        StompSession session = sessionFuture.get(5, TimeUnit.SECONDS);

        // Listen for acknowledgements on user queue
        CompletableFuture<Map> ackFuture = new CompletableFuture<>();
        session.subscribe("/user/queue/ack", new StompFrameHandler() {
            @Override
            public Type getPayloadType(StompHeaders headers) {
                return Map.class;
            }
            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                ackFuture.complete((Map) payload);
            }
        });

        // Send a message with a specific clientMessageId
        Map<String, Object> messagePayload = new HashMap<>();
        String clientMsgId = "550e8400-e29b-41d4-a716-446655440101";
        messagePayload.put("clientMessageId", clientMsgId);
        messagePayload.put("message", "Hello Alice Event");

        StompHeaders sendHeaders = new StompHeaders();
        sendHeaders.setDestination("/app/event." + eventA.getId() + ".send");
        sendHeaders.add("clientMessageId", clientMsgId);

        session.send(sendHeaders, messagePayload);

        Map ack = ackFuture.get(5, TimeUnit.SECONDS);
        assertThat(ack).isNotNull();
        assertThat(ack.get("clientMessageId")).isEqualTo(clientMsgId);
        assertThat(ack.get("serverMessageId")).isNotNull();

        // Give the transaction time to commit completely before checking messageCountBefore
        Thread.sleep(1000);

        // Verify duplicate message is blocked
        int messageCountBefore = eventMessageRepository.findAll().size();
        session.send(sendHeaders, messagePayload);
        
        Thread.sleep(1000);
        int messageCountAfter = eventMessageRepository.findAll().size();
        assertThat(messageCountAfter).isEqualTo(messageCountBefore); // No new message should be saved

        session.disconnect();
    }
}
