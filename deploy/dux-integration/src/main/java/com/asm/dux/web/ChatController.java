package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/events", "/api/timetree/events"})
@RequiredArgsConstructor
public class ChatController {

    private final EventRepository eventRepository;
    private final EventMessageRepository eventMessageRepository;
    private final EventChatStatusRepository eventChatStatusRepository;
    private final TimetreeSecurityService securityService;
    private final NotificationService notificationService;

    // Get paginated chat messages for an event
    @GetMapping("/{id}/messages")
    public ResponseEntity<?> getMessages(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("GET messages for event id={} page={} size={}", id, page, size);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé à cette discussion");
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by("sentAt").descending());
        org.springframework.data.domain.Page<EventMessage> messagesPage = eventMessageRepository.findAllByEventId(id, pageable);

        List<Map<String, Object>> content = messagesPage.getContent().stream()
                .map(this::mapToMessageMap)
                .collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("messages", content);
        response.put("hasMore", messagesPage.hasNext());
        response.put("page", page);
        response.put("size", size);

        return ResponseEntity.ok(response);
    }

    // Post a new message
    @PostMapping("/{id}/messages")
    @Transactional
    public ResponseEntity<?> sendMessage(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        log.info("POST message for event id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé à cette discussion");
        }

        String text = (String) body.get("message");
        if (text == null || text.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Le message ne peut pas être vide");
        }

        String typeStr = (String) body.getOrDefault("messageType", "TEXT");
        EventMessage.MessageType messageType = EventMessage.MessageType.valueOf(typeStr.toUpperCase());
        String metadata = (String) body.get("metadata");

        EventMessage msg = EventMessage.builder()
                .event(event)
                .member(current)
                .message(text)
                .messageType(messageType)
                .metadata(metadata)
                .sentAt(LocalDateTime.now())
                .build();

        EventMessage saved = eventMessageRepository.save(msg);

        // Update read marker for the sender
        updateReadMarker(event, current, saved.getId());

        // Notify other group members who have access to this event
        Group group = event.getGroup();
        if (group != null && group.getMembers() != null) {
            for (Member m : group.getMembers()) {
                if (!m.getId().equals(current.getId())) {
                    notificationService.triggerNotification(
                            m,
                            "Nouveau message dans " + event.getTitle(),
                            current.getFullName() + ": " + text,
                            "NEW_MESSAGE",
                            "MESSAGE",
                            saved.getId(),
                            "NEW"
                    );
                }
            }
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(mapToMessageMap(saved));
    }

    // Mark chat as read
    @PostMapping("/{id}/chat/read")
    @Transactional
    public ResponseEntity<?> markRead(@PathVariable Long id) {
        log.info("POST chat/read for event id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        // Find the latest message in this room
        Pageable limitOne = PageRequest.of(0, 1, Sort.by("id").descending());
        org.springframework.data.domain.Page<EventMessage> latestPage = eventMessageRepository.findAllByEventId(id, limitOne);
        
        if (!latestPage.isEmpty()) {
            Long latestId = latestPage.getContent().get(0).getId();
            updateReadMarker(event, current, latestId);
        }

        return ResponseEntity.ok().build();
    }

    // Get unread counts for all events allowed to the current member
    @GetMapping("/unread-counts")
    public ResponseEntity<?> getUnreadCounts() {
        log.info("GET unread counts");

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        if (allowedCalendarIds.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyMap());
        }

        // Fetch active events in allowed calendars
        LocalDateTime start = LocalDateTime.now().minusYears(1);
        LocalDateTime end = LocalDateTime.now().plusYears(1);
        List<Event> events = eventRepository.findActiveEventsInCalendars(allowedCalendarIds, start, end);

        Map<String, Long> unreadCounts = new HashMap<>();
        for (Event e : events) {
            Optional<EventChatStatus> statusOpt = eventChatStatusRepository.findByEventIdAndMemberId(e.getId(), current.getId());
            long count;
            if (statusOpt.isPresent()) {
                Long lastReadId = statusOpt.get().getLastReadMessageId();
                if (lastReadId == null) {
                    count = eventMessageRepository.countByEventId(e.getId());
                } else {
                    count = eventMessageRepository.countByEventIdAndIdGreaterThan(e.getId(), lastReadId);
                }
            } else {
                count = eventMessageRepository.countByEventId(e.getId());
            }
            if (count > 0) {
                unreadCounts.put(e.getId().toString(), count);
            }
        }

        return ResponseEntity.ok(unreadCounts);
    }

    private void updateReadMarker(Event event, Member member, Long messageId) {
        EventChatStatus status = eventChatStatusRepository.findByEventIdAndMemberId(event.getId(), member.getId())
                .orElseGet(() -> EventChatStatus.builder()
                        .event(event)
                        .member(member)
                        .build());
        status.setLastReadMessageId(messageId);
        status.setLastReadAt(LocalDateTime.now());
        eventChatStatusRepository.save(status);
    }

    private Map<String, Object> mapToMessageMap(EventMessage m) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", m.getId().toString());
        map.put("eventId", m.getEvent().getId().toString());
        map.put("message", m.getMessage());
        map.put("messageType", m.getMessageType().name());
        map.put("metadata", m.getMetadata());
        map.put("sentAt", m.getSentAt().toString());

        Map<String, Object> senderMap = new HashMap<>();
        senderMap.put("id", m.getMember().getId().toString());
        senderMap.put("username", m.getMember().getUsername());
        senderMap.put("fullName", m.getMember().getFullName());
        senderMap.put("role", m.getMember().getRole());
        map.put("sender", senderMap);

        return map;
    }
}
