package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.AuditService;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import com.asm.dux.timetree.service.WebSocketMetricsService;
import com.asm.dux.web.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TimetreeControllerTests {

    @Mock private EventRepository eventRepository;
    @Mock private CalendarRepository calendarRepository;
    @Mock private EventAttachmentRepository eventAttachmentRepository;
    @Mock private EventMessageRepository eventMessageRepository;
    @Mock private MemberRepository memberRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private PageRepository pageRepository;
    @Mock private GroupRepository groupRepository;
    @Mock private TimetreeAuditLogRepository auditLogRepository;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private TimetreeSecurityService securityService;
    @Mock private AuditService auditService;
    @Mock private WebSocketMetricsService webSocketMetricsService;

    private SearchController searchController;
    private ExportController exportController;
    private RestoreController restoreController;
    private TimetreeController timetreeController;

    private Member mockMember;
    private com.asm.dux.timetree.domain.Calendar mockCalendar;
    private Event mockEvent;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        searchController = new SearchController(eventRepository, calendarRepository, eventAttachmentRepository, eventMessageRepository, memberRepository, securityService);
        exportController = new ExportController(eventRepository, securityService);
        restoreController = new RestoreController(jdbcTemplate, securityService, auditService);
        timetreeController = new TimetreeController(categoryRepository, pageRepository, groupRepository, auditLogRepository, memberRepository, calendarRepository, eventRepository, auditService, securityService, webSocketMetricsService);

        mockMember = Member.builder().id(10L).username("testuser").fullName("Test User").role("MEMBER").build();
        mockCalendar = com.asm.dux.timetree.domain.Calendar.builder().id(100L).name("Mock Calendar").deleted(false).build();
        Tag mockTag = Tag.builder().id(1L).name("Finance").color("#FF0000").build();
        mockEvent = Event.builder()
                .id(200L)
                .title("Mock Event")
                .description("Mock Event Description")
                .deleted(false)
                .isPrivate(false)
                .calendar(mockCalendar)
                .status(EventStatus.IN_PROGRESS)
                .priority(EventPriority.HIGH)
                .startDate(LocalDateTime.of(2026, 6, 23, 20, 0))
                .endDate(LocalDateTime.of(2026, 6, 23, 21, 0))
                .createdBy("admin")
                .tags(new HashSet<>(Collections.singletonList(mockTag)))
                .build();
    }

    @Test
    void testSearchAccessDeniedUnauthenticated() {
        when(securityService.getCurrentMember()).thenReturn(null);
        ResponseEntity<?> response = searchController.search("query");
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void testSearchSuccessEnforcesFilters() {
        when(securityService.getCurrentMember()).thenReturn(mockMember);
        when(securityService.getAllowedCalendarIds(mockMember)).thenReturn(Collections.singletonList(100L));
        when(securityService.canReadEvent(eq(mockMember), any(Event.class))).thenReturn(true);

        when(memberRepository.findAll()).thenReturn(Collections.singletonList(mockMember));
        when(calendarRepository.findAll()).thenReturn(Collections.singletonList(mockCalendar));
        when(eventRepository.findAll()).thenReturn(Collections.singletonList(mockEvent));
        when(eventAttachmentRepository.findAll()).thenReturn(Collections.emptyList());
        when(eventMessageRepository.findAll()).thenReturn(Collections.emptyList());

        ResponseEntity<?> response = searchController.search("Mock");
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertNotNull(body);
        List<?> events = (List<?>) body.get("events");
        List<?> calendars = (List<?>) body.get("calendars");
        assertEquals(1, events.size());
        assertEquals(1, calendars.size());
    }

    @Test
    void testExportAccessDeniedUnauthenticated() {
        ResponseEntity<?> response = exportController.exportEvents("csv", null, null, null);
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void testExportFormatsSuccess() {
        when(securityService.getCurrentMember()).thenReturn(mockMember);
        when(securityService.getAllowedCalendarIds(mockMember)).thenReturn(Collections.singletonList(100L));
        when(securityService.canReadEvent(eq(mockMember), any(Event.class))).thenReturn(true);
        when(eventRepository.findActiveEventsInCalendars(anyList(), any(LocalDateTime.class), any(LocalDateTime.class)))
                .thenReturn(Collections.singletonList(mockEvent));

        ResponseEntity<?> responseCsv = exportController.exportEvents("csv", null, null, null);
        assertEquals(HttpStatus.OK, responseCsv.getStatusCode());

        ResponseEntity<?> responseIcs = exportController.exportEvents("ics", null, null, null);
        assertEquals(HttpStatus.OK, responseIcs.getStatusCode());

        ResponseEntity<?> responseXls = exportController.exportEvents("xlsx", null, null, null);
        assertEquals(HttpStatus.OK, responseXls.getStatusCode());

        ResponseEntity<?> responsePdf = exportController.exportEvents("pdf", null, null, null);
        assertEquals(HttpStatus.OK, responsePdf.getStatusCode());

        try {
            java.io.File dir = new java.io.File("C:/Users/ACHRAF/.gemini/antigravity/brain/7d14387a-76e9-41a3-92e3-8a3acc509b71");
            if (dir.exists()) {
                java.nio.file.Files.write(java.nio.file.Paths.get("C:/Users/ACHRAF/.gemini/antigravity/brain/7d14387a-76e9-41a3-92e3-8a3acc509b71/sample_export.csv"), (byte[]) responseCsv.getBody());
                java.nio.file.Files.write(java.nio.file.Paths.get("C:/Users/ACHRAF/.gemini/antigravity/brain/7d14387a-76e9-41a3-92e3-8a3acc509b71/sample_export.ics"), (byte[]) responseIcs.getBody());
                java.nio.file.Files.write(java.nio.file.Paths.get("C:/Users/ACHRAF/.gemini/antigravity/brain/7d14387a-76e9-41a3-92e3-8a3acc509b71/sample_export.xlsx"), (byte[]) responseXls.getBody());
                java.nio.file.Files.write(java.nio.file.Paths.get("C:/Users/ACHRAF/.gemini/antigravity/brain/7d14387a-76e9-41a3-92e3-8a3acc509b71/sample_export.pdf"), (byte[]) responsePdf.getBody());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    void testRestoreAccessDeniedForMembers() {
        when(securityService.getCurrentMember()).thenReturn(mockMember);
        ResponseEntity<?> response = restoreController.restoreEntity("EVENT", 200L);
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());
    }

    @Test
    void testRestoreSuccessForAdmin() {
        Member admin = Member.builder().id(1L).username("admin").role("ADMIN").build();
        when(securityService.getCurrentMember()).thenReturn(admin);
        when(jdbcTemplate.update(anyString(), eq(200L))).thenReturn(1);

        ResponseEntity<?> response = restoreController.restoreEntity("EVENT", 200L);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(auditService, times(1)).logAction(eq("admin"), eq("RESTORE"), eq("EVENT"), eq(200L), eq("SUCCESS"), anyString());
    }

    @Test
    void testDashboardMetricsCalculation() {
        when(securityService.getCurrentMember()).thenReturn(mockMember);
        when(securityService.canReadEvent(eq(mockMember), any(Event.class))).thenReturn(true);
        when(categoryRepository.count()).thenReturn(3L);
        when(pageRepository.count()).thenReturn(7L);
        when(groupRepository.count()).thenReturn(2L);
        when(eventRepository.findAll()).thenReturn(Collections.singletonList(mockEvent));

        ResponseEntity<Map<String, Object>> response = timetreeController.getDashboard();
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Map<String, Object> body = response.getBody();
        assertNotNull(body);
        Map<String, Object> summary = (Map<String, Object>) body.get("summary");
        assertEquals(3, summary.get("categoriesCount"));
        assertEquals(7, summary.get("pagesCount"));
        assertEquals(2, summary.get("groupsCount"));

        Map<String, Long> statusMap = (Map<String, Long>) body.get("eventsByStatus");
        assertEquals(1L, statusMap.get("IN_PROGRESS"));

        Map<String, Long> priorityMap = (Map<String, Long>) body.get("eventsByPriority");
        assertEquals(1L, priorityMap.get("HIGH"));
    }
}
