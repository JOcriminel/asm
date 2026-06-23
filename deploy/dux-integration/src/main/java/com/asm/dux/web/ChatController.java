package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
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
    
    private final MemberRepository memberRepository;
    private final GroupRepository groupRepository;
    private final SimpMessageSendingOperations messagingTemplate;
    private final DuplicateMessageDetector duplicateMessageDetector;
    private final WebSocketMetricsService metricsService;

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
        notifyGroupMembers(event, current, text, saved.getId());

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

        performMarkRead(event, current);
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

        Map<String, Long> unreadCounts = calculateUnreadCounts(current);
        return ResponseEntity.ok(unreadCounts);
    }

    // WebSocket STOMP: Real-time message delivery
    @MessageMapping("event.{id}.send")
    @Transactional
    public void handleStompMessage(@DestinationVariable Long id, Map<String, Object> body, Principal principal) {
        long startTime = System.currentTimeMillis();
        metricsService.incrementMessages();

        if (principal == null) {
            log.error("STOMP message received from unauthenticated principal");
            return;
        }

        String username = principal.getName();
        Member sender = memberRepository.findByUsername(username).orElse(null);
        if (sender == null) {
            log.error("Member not found for principal username={}", username);
            return;
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            log.error("Event not found with id={}", id);
            return;
        }
        Event event = eventOpt.get();

        // 1. Double-check duplicate message prevention
        String clientMessageId = (String) body.get("clientMessageId");
        if (duplicateMessageDetector.isDuplicate(clientMessageId)) {
            log.warn("Duplicate message detected for clientMessageId={}. Skipping persistence.", clientMessageId);
            sendStompAck(sender, clientMessageId, null);
            return;
        }

        String text = (String) body.get("message");
        if (text == null || text.trim().isEmpty()) {
            return;
        }

        String typeStr = (String) body.getOrDefault("messageType", "TEXT");
        EventMessage.MessageType messageType = EventMessage.MessageType.valueOf(typeStr.toUpperCase());
        String metadata = (String) body.get("metadata");

        EventMessage msg = EventMessage.builder()
                .event(event)
                .member(sender)
                .message(text)
                .messageType(messageType)
                .metadata(metadata)
                .sentAt(LocalDateTime.now())
                .build();

        EventMessage saved = eventMessageRepository.save(msg);
        duplicateMessageDetector.registerMessage(clientMessageId);

        // Update read marker for sender
        updateReadMarker(event, sender, saved.getId());

        // Broadcast message to all event subscribers
        Map<String, Object> messagePayload = mapToMessageMap(saved);
        if (clientMessageId != null) {
            messagePayload.put("clientMessageId", clientMessageId);
        }
        
        String destination = "/topic/event." + id + ".chat";
        messagingTemplate.convertAndSend(destination, messagePayload);

        // Notify other group members
        notifyGroupMembers(event, sender, text, saved.getId());

        // Send direct acknowledgement payload back to sender
        sendStompAck(sender, clientMessageId, saved.getId());

        // Latency logging
        metricsService.recordDeliveryLatency(System.currentTimeMillis() - startTime);
    }

    // WebSocket STOMP: Real-time typing indicators
    @MessageMapping("event.{id}.typing")
    public void handleStompTyping(@DestinationVariable Long id, Map<String, Object> body, Principal principal) {
        metricsService.incrementTyping();

        if (principal == null) return;
        String username = principal.getName();

        Boolean isTyping = (Boolean) body.get("isTyping");
        if (isTyping == null) isTyping = false;

        Map<String, Object> payload = new HashMap<>();
        payload.put("username", username);
        payload.put("isTyping", isTyping);

        String destination = "/topic/event." + id + ".typing";
        messagingTemplate.convertAndSend(destination, payload);
    }

    // WebSocket STOMP: Real-time read receipt updates
    @MessageMapping("event.{id}.read")
    @Transactional
    public void handleStompRead(@DestinationVariable Long id, Principal principal) {
        if (principal == null) return;
        String username = principal.getName();
        Member current = memberRepository.findByUsername(username).orElse(null);
        if (current == null) return;

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) return;
        Event event = eventOpt.get();

        performMarkRead(event, current);
    }

    private void performMarkRead(Event event, Member current) {
        Pageable limitOne = PageRequest.of(0, 1, Sort.by("id").descending());
        org.springframework.data.domain.Page<EventMessage> latestPage = eventMessageRepository.findAllByEventId(event.getId(), limitOne);
        
        if (!latestPage.isEmpty()) {
            Long latestId = latestPage.getContent().get(0).getId();
            updateReadMarker(event, current, latestId);
        }

        // Notify unread counter sync topic for the user
        Map<String, Long> unreadCounts = calculateUnreadCounts(current);
        String destination = "/topic/user." + current.getId() + ".unread";
        messagingTemplate.convertAndSend(destination, unreadCounts);
    }

    private Map<String, Long> calculateUnreadCounts(Member current) {
        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        if (allowedCalendarIds.isEmpty()) {
            return Collections.emptyMap();
        }

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
        return unreadCounts;
    }

    private void sendStompAck(Member sender, String clientMessageId, Long serverMessageId) {
        if (clientMessageId == null) return;
        Map<String, Object> ackPayload = new HashMap<>();
        ackPayload.put("clientMessageId", clientMessageId);
        ackPayload.put("serverMessageId", serverMessageId != null ? serverMessageId.toString() : null);
        ackPayload.put("timestamp", LocalDateTime.now().toString());

        messagingTemplate.convertAndSendToUser(sender.getUsername(), "/queue/ack", ackPayload);
    }

    private void notifyGroupMembers(Event event, Member current, String text, Long msgId) {
        Group group = event.getGroup();
        if (group != null) {
            List<Member> members = groupRepository.findMembersByGroupId(group.getId());
            for (Member m : members) {
                if (!m.getId().equals(current.getId())) {
                    notificationService.triggerNotification(
                            m,
                            "Nouveau message dans " + event.getTitle(),
                            current.getFullName() + ": " + text,
                            "NEW_MESSAGE",
                            "MESSAGE",
                            msgId,
                            "NEW"
                    );
                }
            }
        }
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
