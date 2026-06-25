package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.web.ChatController;
import com.asm.dux.web.NotificationController;
import com.asm.dux.web.TimelineController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class TimetreeNotificationTests {

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

    // Mock the messaging template so we can capture WebSocket dispatches
    @MockBean
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private NotificationController notificationController;

    @Autowired
    private ChatController chatController;

    @Autowired
    private TimelineController timelineController;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private CalendarRepository calendarRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private TimetreeAuditLogRepository auditLogRepository;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    private Member alice;
    private Member bob;
    private com.asm.dux.timetree.domain.Calendar calendar;
    private Event event;

    @BeforeEach
    public void setup() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_NOTIFICATION");
        jdbcTemplate.execute("DELETE FROM dbo.TT_NOTIFICATION_PREFERENCE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT_MESSAGE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT");
        jdbcTemplate.execute("DELETE FROM dbo.TT_MEMBER_CALENDAR");
        jdbcTemplate.execute("DELETE FROM dbo.TT_CALENDAR");
        jdbcTemplate.execute("DELETE FROM dbo.TT_MEMBER");
        jdbcTemplate.execute("DELETE FROM dbo.TT_AUDIT_LOG");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");

        alice = memberRepository.save(Member.builder().username("alice").fullName("Alice").role("MEMBER").build());
        bob   = memberRepository.save(Member.builder().username("bob").fullName("Bob").role("MEMBER").build());

        calendar = calendarRepository.save(com.asm.dux.timetree.domain.Calendar.builder()
                .name("Test Calendar")
                .build());

        alice.setCalendars(java.util.Arrays.asList(calendar));
        bob.setCalendars(java.util.Arrays.asList(calendar));
        alice = memberRepository.save(alice);
        bob = memberRepository.save(bob);

        event = eventRepository.save(Event.builder()
                .title("Test Event")
                .calendar(calendar)
                .startDate(LocalDateTime.now())
                .endDate(LocalDateTime.now().plusHours(1))
                .status(EventStatus.PLANNED)
                .priority(EventPriority.NORMAL)
                .build());

        mockJwt("alice");
        reset(messagingTemplate);
    }

    private void mockJwt(String username) {
        Jwt jwt = Mockito.mock(Jwt.class);
        when(jwt.getClaimAsString("preferred_username")).thenReturn(username);
        when(jwt.getSubject()).thenReturn(username);
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);

        JwtAuthenticationToken auth = new JwtAuthenticationToken(jwt, Collections.emptyList());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ─────────────────────────────────────────────
    //  Preferences: default values + update round-trip
    // ─────────────────────────────────────────────
    @Test
    public void testGetPreferences_DefaultAndCustomValues() {
        ResponseEntity<?> getResp = notificationController.getPreferences();
        assertEquals(HttpStatus.OK, getResp.getStatusCode());
        NotificationController.PreferenceDto defaultPref = (NotificationController.PreferenceDto) getResp.getBody();
        assertNotNull(defaultPref);
        assertFalse(defaultPref.isEmailEnabled(), "emailEnabled should default to false");
        assertTrue(defaultPref.isPushEnabled(), "pushEnabled should default to true");
        assertTrue(defaultPref.isMentionsEnabled(), "mentionsEnabled should default to true");

        NotificationController.PreferenceDto updateRequest = NotificationController.PreferenceDto.builder()
                .emailEnabled(true)
                .pushEnabled(false)
                .mentionsEnabled(false)
                .remindersEnabled(true)
                .chatEnabled(false)
                .build();

        ResponseEntity<?> putResp = notificationController.updatePreferences(updateRequest);
        assertEquals(HttpStatus.OK, putResp.getStatusCode());
        NotificationController.PreferenceDto updatedPref = (NotificationController.PreferenceDto) putResp.getBody();
        assertNotNull(updatedPref);
        assertTrue(updatedPref.isEmailEnabled());
        assertFalse(updatedPref.isPushEnabled());
        assertFalse(updatedPref.isMentionsEnabled());
    }

    // ─────────────────────────────────────────────
    //  Chat mention → MENTION notification persisted
    // ─────────────────────────────────────────────
    @Test
    public void testChatMentionsTriggerNotification() {
        mockJwt("alice");
        Map<String, Object> body = new HashMap<>();
        body.put("message", "Hello @bob, check this out!");
        body.put("messageType", "TEXT");

        ResponseEntity<?> chatResp = chatController.sendMessage(event.getId(), body);
        assertEquals(HttpStatus.CREATED, chatResp.getStatusCode());

        List<TimetreeNotification> bobNotifications =
                notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(bob.getId());
        assertEquals(1, bobNotifications.size());
        assertEquals("MENTION", bobNotifications.get(0).getType());
        assertThat(bobNotifications.get(0).getContent()).contains("Alice vous a mentionné");
    }

    // ─────────────────────────────────────────────
    //  Muted preference suppresses notification
    // ─────────────────────────────────────────────
    @Test
    public void testChatMentionsMutedByPreferences() {
        // Bob mutes mentions
        mockJwt("bob");
        notificationController.updatePreferences(NotificationController.PreferenceDto.builder()
                .pushEnabled(true)
                .mentionsEnabled(false)
                .build());

        // Alice mentions Bob
        mockJwt("alice");
        Map<String, Object> body = new HashMap<>();
        body.put("message", "Hello @bob!");
        chatController.sendMessage(event.getId(), body);

        List<TimetreeNotification> bobNotifications =
                notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(bob.getId());
        assertEquals(0, bobNotifications.size(), "Muted user should receive no notification");
    }

    // ─────────────────────────────────────────────
    //  Calendar activity timeline returns audit logs
    // ─────────────────────────────────────────────
    @Test
    public void testCalendarActivityTimeline() {
        auditLogRepository.save(TimetreeAuditLog.builder()
                .username("alice")
                .action("CREATE_EVENT")
                .entityType("EVENT")
                .entityId(event.getId())
                .result("SUCCESS")
                .actionDate(LocalDateTime.now())
                .details("Created event: " + event.getTitle())
                .build());

        ResponseEntity<?> response = timelineController.getCalendarActivity(calendar.getId(), 0, 20, null);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        @SuppressWarnings("unchecked")
        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertNotNull(body);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> activity = (List<Map<String, Object>>) body.get("activity");
        assertNotNull(activity);
        assertEquals(1, activity.size());
        assertEquals("CREATE_EVENT", activity.get(0).get("action"));
        assertEquals("alice", activity.get(0).get("username"));
    }

    // ─────────────────────────────────────────────
    //  Activity timeline filtered by action type
    // ─────────────────────────────────────────────
    @Test
    public void testCalendarActivityTimeline_FilteredByAction() {
        auditLogRepository.save(TimetreeAuditLog.builder()
                .username("alice").action("CREATE_EVENT").entityType("EVENT")
                .entityId(event.getId()).result("SUCCESS").actionDate(LocalDateTime.now())
                .details("Created event").build());
        auditLogRepository.save(TimetreeAuditLog.builder()
                .username("bob").action("UPDATE_EVENT").entityType("EVENT")
                .entityId(event.getId()).result("SUCCESS").actionDate(LocalDateTime.now())
                .details("Updated event").build());

        // Filter to only CREATE_EVENT
        ResponseEntity<?> response = timelineController.getCalendarActivity(calendar.getId(), 0, 20, "CREATE_EVENT");
        assertEquals(HttpStatus.OK, response.getStatusCode());

        @SuppressWarnings("unchecked")
        Map<String, Object> body = (Map<String, Object>) response.getBody();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> activity = (List<Map<String, Object>>) body.get("activity");
        assertEquals(1, activity.size(), "Should only return CREATE_EVENT logs");
        assertEquals("CREATE_EVENT", activity.get(0).get("action"));
    }

    // ─────────────────────────────────────────────
    //  Paginated notification history
    // ─────────────────────────────────────────────
    @Test
    public void testGetNotifications_Paginated() {
        mockJwt("alice");
        // Simulate 2 mentions from Bob to Alice
        Map<String, Object> msg1 = new HashMap<>();
        msg1.put("message", "Hey @alice, first mention!");
        Map<String, Object> msg2 = new HashMap<>();
        msg2.put("message", "Hey @alice, second mention!");

        // Switch to Bob to send messages
        mockJwt("bob");
        chatController.sendMessage(event.getId(), msg1);
        chatController.sendMessage(event.getId(), msg2);

        // Fetch Alice's paginated notifications
        mockJwt("alice");
        ResponseEntity<?> response = notificationController.getNotifications(0, 1);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        @SuppressWarnings("unchecked")
        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertNotNull(body);
        assertTrue((Boolean) body.get("hasMore"), "Page 0 with size=1 should have more pages");
        assertEquals(2L, body.get("totalElements"));
    }

    // ─────────────────────────────────────────────
    //  UNREAD_COUNT pushed to WebSocket on create, mark-read, mark-all-read
    // ─────────────────────────────────────────────
    @Test
    public void testUnreadCountPushedOnNotificationCreate() {
        mockJwt("alice");
        // Alice → Bob mention triggers notification + unread count push
        Map<String, Object> body = new HashMap<>();
        body.put("message", "Hi @bob !");
        chatController.sendMessage(event.getId(), body);

        // Verify WebSocket was called at least once with /queue/notifications for "bob"
        // The first call is the notification payload, the second is the UNREAD_COUNT
        verify(messagingTemplate, atLeast(2)).convertAndSendToUser(
                eq("bob"),
                eq("/queue/notifications"),
                any(Object.class)
        );
    }

    @Test
    public void testUnreadCountPushedOnMarkRead() {
        // Create a notification for Bob first
        mockJwt("alice");
        Map<String, Object> body = new HashMap<>();
        body.put("message", "Hey @bob check this!");
        chatController.sendMessage(event.getId(), body);

        reset(messagingTemplate);

        // Bob marks it read — should trigger an UNREAD_COUNT push
        mockJwt("bob");
        List<TimetreeNotification> bobNotifs =
                notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(bob.getId());
        assertFalse(bobNotifs.isEmpty());

        Long notifId = bobNotifs.get(0).getId();
        ResponseEntity<?> markReadResp = notificationController.markRead(notifId);
        assertEquals(HttpStatus.OK, markReadResp.getStatusCode());

        verify(messagingTemplate, times(1)).convertAndSendToUser(
                eq("bob"),
                eq("/queue/notifications"),
                argThat(arg -> {
                    if (arg instanceof Map) {
                        Object type = ((Map<?, ?>) arg).get("type");
                        return "UNREAD_COUNT".equals(type);
                    }
                    return false;
                })
        );
    }

    @Test
    public void testUnreadCountPushedOnMarkAllRead() {
        // Give Bob two notifications
        mockJwt("alice");
        chatController.sendMessage(event.getId(), Map.of("message", "Hey @bob one!"));
        chatController.sendMessage(event.getId(), Map.of("message", "Hey @bob two!"));

        reset(messagingTemplate);

        // Bob marks all read
        mockJwt("bob");
        ResponseEntity<?> resp = notificationController.markAllReadPut();
        assertEquals(HttpStatus.OK, resp.getStatusCode());

        verify(messagingTemplate, times(1)).convertAndSendToUser(
                eq("bob"),
                eq("/queue/notifications"),
                argThat(arg -> {
                    if (arg instanceof Map) {
                        Object type = ((Map<?, ?>) arg).get("type");
                        Object count = ((Map<?, ?>) arg).get("count");
                        return "UNREAD_COUNT".equals(type) && Long.valueOf(0L).equals(count);
                    }
                    return false;
                })
        );
    }
}
