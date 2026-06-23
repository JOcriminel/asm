package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/timetree/search", "/api/dux/api/timetree/search"})
@RequiredArgsConstructor
public class SearchController {

    private final EventRepository eventRepository;
    private final CalendarRepository calendarRepository;
    private final EventAttachmentRepository eventAttachmentRepository;
    private final EventMessageRepository eventMessageRepository;
    private final MemberRepository memberRepository;
    private final TimetreeSecurityService securityService;

    @GetMapping
    public ResponseEntity<?> search(@RequestParam(required = false) String query) {
        log.info("GET /api/timetree/search query={}", query);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        if (query == null || query.trim().length() < 2) {
            Map<String, Object> emptyMap = new LinkedHashMap<>();
            emptyMap.put("events", Collections.emptyList());
            emptyMap.put("calendars", Collections.emptyList());
            emptyMap.put("attachments", Collections.emptyList());
            emptyMap.put("messages", Collections.emptyList());
            emptyMap.put("members", Collections.emptyList());
            return ResponseEntity.ok(emptyMap);
        }

        String searchLower = query.trim().toLowerCase();

        // 1. Search Members
        List<Map<String, Object>> membersResult = memberRepository.findAll().stream()
                .filter(m -> (m.getFullName() != null && m.getFullName().toLowerCase().contains(searchLower))
                        || (m.getUsername() != null && m.getUsername().toLowerCase().contains(searchLower))
                        || (m.getEmail() != null && m.getEmail().toLowerCase().contains(searchLower)))
                .map(m -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", m.getId().toString());
                    map.put("username", m.getUsername());
                    map.put("fullName", m.getFullName());
                    map.put("email", m.getEmail());
                    map.put("role", m.getRole());
                    return map;
                })
                .collect(Collectors.toList());

        // 2. Search Calendars (Only those current member can read)
        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        List<Map<String, Object>> calendarsResult = calendarRepository.findAll().stream()
                .filter(c -> !Boolean.TRUE.equals(c.getDeleted()))
                .filter(c -> allowedCalendarIds.contains(c.getId()))
                .filter(c -> (c.getName() != null && c.getName().toLowerCase().contains(searchLower))
                        || (c.getDescription() != null && c.getDescription().toLowerCase().contains(searchLower)))
                .map(c -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", c.getId().toString());
                    map.put("name", c.getName());
                    map.put("description", c.getDescription());
                    map.put("color", c.getColor());
                    return map;
                })
                .collect(Collectors.toList());

        // 3. Search Events (Only allowed events, soft-delete aware, private events hidden from non-participants)
        List<Map<String, Object>> eventsResult = eventRepository.findAll().stream()
                .filter(e -> !Boolean.TRUE.equals(e.getDeleted()))
                .filter(e -> securityService.canReadEvent(current, e))
                .filter(e -> (e.getTitle() != null && e.getTitle().toLowerCase().contains(searchLower))
                        || (e.getDescription() != null && e.getDescription().toLowerCase().contains(searchLower)))
                .map(e -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", e.getId().toString());
                    map.put("title", e.getTitle());
                    map.put("description", e.getDescription());
                    map.put("startDate", e.getStartDate().toString());
                    map.put("endDate", e.getEndDate().toString());
                    map.put("color", e.getColor());
                    map.put("status", e.getStatus().name());
                    map.put("priority", e.getPriority().name());
                    return map;
                })
                .collect(Collectors.toList());

        // 4. Search Attachments (Only from readable events, soft-delete aware)
        List<Map<String, Object>> attachmentsResult = eventAttachmentRepository.findAll().stream()
                .filter(a -> !Boolean.TRUE.equals(a.getDeleted()))
                .filter(a -> !Boolean.TRUE.equals(a.getEvent().getDeleted()))
                .filter(a -> securityService.canReadEvent(current, a.getEvent()))
                .filter(a -> a.getFileName() != null && a.getFileName().toLowerCase().contains(searchLower))
                .map(a -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", a.getId().toString());
                    map.put("eventId", a.getEvent().getId().toString());
                    map.put("eventTitle", a.getEvent().getTitle());
                    map.put("fileName", a.getFileName());
                    map.put("fileType", a.getFileType());
                    map.put("fileSize", a.getFileSize());
                    map.put("uploadedBy", a.getUploadedBy());
                    map.put("uploadedAt", a.getUploadedAt().toString());
                    return map;
                })
                .collect(Collectors.toList());

        // 5. Search Messages (Only from readable events)
        List<Map<String, Object>> messagesResult = eventMessageRepository.findAll().stream()
                .filter(m -> !Boolean.TRUE.equals(m.getEvent().getDeleted()))
                .filter(m -> securityService.canReadEvent(current, m.getEvent()))
                .filter(m -> m.getMessage() != null && m.getMessage().toLowerCase().contains(searchLower))
                .map(m -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", m.getId().toString());
                    map.put("eventId", m.getEvent().getId().toString());
                    map.put("eventTitle", m.getEvent().getTitle());
                    map.put("memberName", m.getMember() != null ? m.getMember().getFullName() : "System");
                    map.put("message", m.getMessage());
                    map.put("sentAt", m.getSentAt().toString());
                    return map;
                })
                .collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("events", eventsResult);
        response.put("calendars", calendarsResult);
        response.put("attachments", attachmentsResult);
        response.put("messages", messagesResult);
        response.put("members", membersResult);

        return ResponseEntity.ok(response);
    }
}
