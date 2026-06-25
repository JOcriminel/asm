package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/calendars", "/api/timetree/calendars"})
@RequiredArgsConstructor
public class TimelineController {

    private final CalendarRepository calendarRepository;
    private final EventRepository eventRepository;
    private final EventAttachmentRepository eventAttachmentRepository;
    private final TimetreeAuditLogRepository auditLogRepository;
    private final TimetreeSecurityService securityService;

    /**
     * GET /api/timetree/calendars/{id}/activity
     *
     * Returns a paginated, optionally filtered activity timeline for the calendar.
     *
     * Query params:
     *   page (default 0), size (default 20) — pagination
     *   action (optional) — filter by audit action type, e.g. CREATE_EVENT, UPLOAD_ATTACHMENT
     */
    @GetMapping("/{id}/activity")
    public ResponseEntity<?> getCalendarActivity(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String action) {
        log.info("GET activity timeline for calendar id={} page={} size={} action={}", id, page, size, action);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<com.asm.dux.timetree.domain.Calendar> calOpt = calendarRepository.findById(id);
        if (!calOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        // Security check: ensure user belongs to a group owning this calendar
        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        if (!allowedCalendarIds.contains(id)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé à l'historique de ce calendrier");
        }

        // Collect entity IDs scoped to this calendar
        List<Event> events = eventRepository.findAllByCalendarId(id);
        Set<Long> eventIds = events.stream().map(Event::getId).collect(Collectors.toSet());

        Set<Long> attachmentIds = eventAttachmentRepository.findAll().stream()
                .filter(att -> eventIds.contains(att.getEvent().getId()))
                .map(EventAttachment::getId)
                .collect(Collectors.toSet());

        boolean hasEvents = !eventIds.isEmpty();
        boolean hasAttachments = !attachmentIds.isEmpty();

        // Ensure empty sets don't cause JPQL IN () syntax errors
        if (!hasEvents) eventIds.add(-1L);
        if (!hasAttachments) attachmentIds.add(-1L);

        String actionFilter = (action != null && !action.isBlank()) ? action.trim().toUpperCase() : null;

        PageRequest pageable = PageRequest.of(page, size, Sort.by("actionDate").descending());
        Page<TimetreeAuditLog> logsPage = auditLogRepository.findCalendarLogs(
                id, hasEvents, eventIds, hasAttachments, attachmentIds, actionFilter, pageable);

        List<Map<String, Object>> content = logsPage.getContent().stream().map(logEntry -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("id", logEntry.getId().toString());
            map.put("username", logEntry.getUsername());
            map.put("action", logEntry.getAction());
            map.put("entityType", logEntry.getEntityType());
            map.put("entityId", logEntry.getEntityId() != null ? logEntry.getEntityId().toString() : null);
            map.put("result", logEntry.getResult());
            map.put("actionDate", logEntry.getActionDate() != null ? logEntry.getActionDate().toString() : null);
            map.put("details", logEntry.getDetails());
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("activity", content);
        response.put("totalElements", logsPage.getTotalElements());
        response.put("totalPages", logsPage.getTotalPages());
        response.put("page", page);
        response.put("size", size);
        response.put("hasMore", logsPage.hasNext());
        return ResponseEntity.ok(response);
    }
}
