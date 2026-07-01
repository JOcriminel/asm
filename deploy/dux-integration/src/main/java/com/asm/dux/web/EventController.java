package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.domain.Calendar;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
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
public class EventController {

    private final EventRepository eventRepository;
    private final CalendarRepository calendarRepository;
    private final MemberRepository memberRepository;
    private final EventMessageRepository eventMessageRepository;
    private final EventAttachmentRepository eventAttachmentRepository;
    private final EventChatStatusRepository eventChatStatusRepository;
    private final NotificationRepository notificationRepository;
    private final NotificationService notificationService;
    private final FileStorageService fileStorageService;
    private final CustomFieldValueRepository customFieldValueRepository;
    
    private final TimetreeSecurityService securityService;
    private final AuditService auditService;
    private final TagRepository tagRepository;
    private final EventReminderRepository eventReminderRepository;
    private final TimetreeAuditLogRepository auditLogRepository;


    @GetMapping
    @Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<?> getEvents(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end,
            @RequestParam(required = false) List<Long> calendarIds,
            @RequestParam(required = false) List<String> tags) {
        log.info("GET /api/timetree/events start={} end={}", start, end);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
        List<Long> queryIds = new ArrayList<>();
        if (calendarIds != null && !calendarIds.isEmpty()) {
            for (Long cid : calendarIds) {
                if (allowedCalendarIds.contains(cid)) {
                    queryIds.add(cid);
                }
            }
        } else {
            queryIds.addAll(allowedCalendarIds);
        }

        if (queryIds.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }

        List<Event> events = eventRepository.findActiveEventsInCalendars(queryIds, start, end);
        
        // Filter by tags and permissions (including private events filter)
        List<Map<String, Object>> response = events.stream()
                .filter(e -> securityService.canReadEvent(current, e))
                .filter(e -> {
                    if (tags == null || tags.isEmpty()) return true;
                    if (e.getTags() == null) return false;
                    Set<String> eTagNames = e.getTags().stream().map(Tag::getName).collect(Collectors.toSet());
                    return tags.stream().anyMatch(eTagNames::contains);
                })
                .map(this::mapToEventMap)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<?> getEvent(@PathVariable Long id) {
        log.info("GET /api/timetree/events/{}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        return eventRepository.findById(id).map(event -> {
            if (!securityService.canReadEvent(current, event)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé à cet événement");
            }
            return ResponseEntity.ok(mapToEventMap(event));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> createEvent(@RequestBody Map<String, Object> body) {
        log.info("POST /api/timetree/events");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        try {
            String title = (String) body.get("title");
            String nomEvent = (String) body.get("nomEvent");
            Boolean titleModifiedDirectly = (Boolean) body.getOrDefault("titleModifiedDirectly", false);
            
            boolean isAdmin = "ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()) || "CHEF".equalsIgnoreCase(current.getRole());
            if (!isAdmin) {
                titleModifiedDirectly = false;
                nomEvent = nomEvent != null ? nomEvent : title;
                title = nomEvent;
            } else {
                if (Boolean.TRUE.equals(titleModifiedDirectly)) {
                    nomEvent = nomEvent != null ? nomEvent : title;
                } else {
                    nomEvent = nomEvent != null ? nomEvent : title;
                    title = nomEvent;
                }
            }

            String attachedDocumentId = (String) body.get("attachedDocumentId");
            String attachedDocumentType = (String) body.get("attachedDocumentType");
            String attachedDocumentCode = (String) body.get("attachedDocumentCode");
            String attachedClientName = (String) body.get("attachedClientName");

            if (attachedDocumentId != null && !attachedDocumentId.trim().isEmpty()) {
                String prefix = (attachedDocumentType != null && !attachedDocumentType.trim().isEmpty())
                        ? attachedDocumentType.trim() + " "
                        : "";
                nomEvent = prefix + attachedDocumentCode + " " + attachedClientName;
                title = nomEvent;
            }

            String description = (String) body.get("description");
            LocalDateTime startDate = parseDateTimeSafely((String) body.get("startDate"));
            LocalDateTime endDate = parseDateTimeSafely((String) body.get("endDate"));
            Boolean allDay = (Boolean) body.getOrDefault("allDay", false);
            String color = (String) body.get("color");
            Long calendarId = Long.valueOf(body.get("calendarId").toString());
            
            String recurrenceRule = (String) body.getOrDefault("recurrenceRule", "NONE");
            LocalDateTime recurrenceEndDate = null;
            if (body.get("recurrenceEndDate") != null && !body.get("recurrenceEndDate").toString().isEmpty()) {
                recurrenceEndDate = parseDateTimeSafely((String) body.get("recurrenceEndDate"));
            }

            // Access control check
            if (!securityService.canWriteEvent(current, calendarId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission insuffisante pour planifier sur ce calendrier");
            }

            Optional<Calendar> calOpt = calendarRepository.findById(calendarId);
            if (!calOpt.isPresent()) {
                return ResponseEntity.badRequest().body("Calendrier introuvable");
            }

            Boolean locked = (Boolean) body.getOrDefault("locked", false);
            Boolean isPrivate = (Boolean) body.getOrDefault("isPrivate", false);
            
            String statusStr = (String) body.getOrDefault("status", "PLANNED");
            EventStatus status = EventStatus.valueOf(statusStr.toUpperCase());
            
            String priorityStr = (String) body.getOrDefault("priority", "NORMAL");
            EventPriority priority = EventPriority.valueOf(priorityStr.toUpperCase());

            Event event = Event.builder()
                    .title(title)
                    .nomEvent(nomEvent)
                    .titleModifiedDirectly(titleModifiedDirectly)
                    .description(description)
                    .startDate(startDate)
                    .endDate(endDate)
                    .allDay(allDay)
                    .color(color)
                    .calendar(calOpt.get())
                    .recurrenceRule(recurrenceRule)
                    .recurrenceEndDate(recurrenceEndDate)
                    .createdAt(LocalDateTime.now())
                    .createdBy(current.getUsername())
                    .locked(locked)
                    .isPrivate(isPrivate)
                    .status(status)
                    .priority(priority)
                    .attachedDocumentId(attachedDocumentId)
                    .attachedDocumentType(attachedDocumentType)
                    .attachedDocumentCode(attachedDocumentCode)
                    .attachedClientName(attachedClientName)
                    .build();


            // Tags
            if (body.get("tags") instanceof List) {
                List<?> rawTags = (List<?>) body.get("tags");
                Set<Tag> tagsSet = new HashSet<>();
                for (Object tagObj : rawTags) {
                    if (tagObj instanceof Map) {
                        Map<?, ?> tMap = (Map<?, ?>) tagObj;
                        String name = (String) tMap.get("name");
                        String tColor = (String) tMap.get("color");
                        Tag tag = tagRepository.findByName(name).orElseGet(() -> 
                                tagRepository.save(Tag.builder().name(name).color(tColor).build())
                        );
                        tagsSet.add(tag);
                    }
                }
                event.setTags(tagsSet);
            }

            // Dependencies
            if (body.get("dependencyIds") instanceof List) {
                List<?> depIds = (List<?>) body.get("dependencyIds");
                Set<Event> depSet = new HashSet<>();
                for (Object dIdObj : depIds) {
                    Long dId = Long.valueOf(dIdObj.toString());
                    eventRepository.findById(dId).ifPresent(depSet::add);
                }
                
                // Validate dependency rule if marked COMPLETED
                if (status == EventStatus.COMPLETED) {
                    for (Event dep : depSet) {
                        if (dep.getStatus() != EventStatus.COMPLETED) {
                            return ResponseEntity.badRequest().body("Impossible de marquer cet événement comme terminé car l'événement dépendant '" + dep.getTitle() + "' n'est pas terminé.");
                        }
                    }
                }
                event.setDependencies(depSet);
            }

            // Participants resolution
            if (body.get("participantIds") instanceof List) {
                List<?> idsList = (List<?>) body.get("participantIds");
                List<Long> memberIds = idsList.stream().map(pId -> Long.valueOf(pId.toString())).collect(Collectors.toList());
                List<Member> participants = memberRepository.findAllById(memberIds);
                event.setParticipants(participants);
            }

            Event saved = eventRepository.save(event);

            // Reminders
            if (body.get("reminders") instanceof List) {
                List<?> rawReminders = (List<?>) body.get("reminders");
                List<EventReminder> reminders = new ArrayList<>();
                for (Object rObj : rawReminders) {
                    if (rObj instanceof String) {
                        LocalDateTime rTime = parseDateTimeSafely(rObj.toString());
                        reminders.add(EventReminder.builder().event(saved).reminderTime(rTime).build());
                    }
                }
                if (!reminders.isEmpty()) {
                    eventReminderRepository.saveAll(reminders);
                    saved.setReminders(reminders);
                }
            }

            // Audit Trail
            auditService.logAction(
                    current.getUsername(),
                    "CREATE",
                    "EVENT",
                    saved.getId(),
                    "SUCCESS",
                    String.format("Création de l'événement '%s' dans le calendrier ID=%d", saved.getTitle(), calendarId)
            );

            // Generate System Message
            EventMessage systemMsg = EventMessage.builder()
                    .event(saved)
                    .member(current)
                    .message("A créé l'événement: " + saved.getTitle())
                    .messageType(EventMessage.MessageType.SYSTEM)
                    .metadata("EVENT_CREATED")
                    .sentAt(LocalDateTime.now())
                    .build();
            eventMessageRepository.save(systemMsg);

            // Notify calendar members
            if (saved.getCalendar() != null && saved.getCalendar().getMembers() != null) {
                for (Member m : saved.getCalendar().getMembers()) {
                    notificationService.triggerNotification(
                            m,
                            current,
                            "Nouvel événement: " + saved.getTitle(),
                            current.getFullName() + " a planifié un nouvel événement.",
                            "EVENT_CREATED",
                            "EVENT",
                            saved.getId(),
                            "CREATED"
                    );
                }
            }

            return ResponseEntity.status(HttpStatus.CREATED).body(mapToEventMap(saved));

        } catch (Exception e) {
            log.error("Failed to create event", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    @PutMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> updateEvent(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        log.info("PUT /api/timetree/events/{}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        return eventRepository.findById(id).map(existing -> {
            try {
                // Enforce lock permission check
                if (!securityService.canModifyEvent(current, existing)) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Cet événement est verrouillé ou vos droits sont insuffisants pour le modifier");
                }

                Long calendarId = Long.valueOf(body.get("calendarId").toString());

                if (!securityService.canWriteEvent(current, calendarId)) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission insuffisante pour le calendrier cible");
                }

                String oldTitle = existing.getTitle();
                String oldStatus = existing.getStatus().name();
                String oldPriority = existing.getPriority().name();

                String title = (String) body.get("title");
                String nomEvent = (String) body.get("nomEvent");
                Boolean titleModifiedDirectly = (Boolean) body.getOrDefault("titleModifiedDirectly", false);

                String attachedDocumentId = (String) body.get("attachedDocumentId");
                String attachedDocumentType = (String) body.get("attachedDocumentType");
                String attachedDocumentCode = (String) body.get("attachedDocumentCode");
                String attachedClientName = (String) body.get("attachedClientName");

                existing.setAttachedDocumentId(attachedDocumentId);
                existing.setAttachedDocumentType(attachedDocumentType);
                existing.setAttachedDocumentCode(attachedDocumentCode);
                existing.setAttachedClientName(attachedClientName);

                if (attachedDocumentId != null && !attachedDocumentId.trim().isEmpty()) {
                    String prefix = (attachedDocumentType != null && !attachedDocumentType.trim().isEmpty())
                            ? attachedDocumentType.trim() + " "
                            : "";
                    nomEvent = prefix + attachedDocumentCode + " " + attachedClientName;
                    title = nomEvent;
                }

                boolean isAdmin = "ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()) || "CHEF".equalsIgnoreCase(current.getRole());
                if (!isAdmin) {
                    existing.setTitleModifiedDirectly(false);
                    existing.setNomEvent(nomEvent != null ? nomEvent : title);
                    EventTitleHelper.recalculateEventTitle(existing, customFieldValueRepository);
                } else {
                    existing.setTitleModifiedDirectly(titleModifiedDirectly);
                    existing.setNomEvent(nomEvent != null ? nomEvent : title);
                    if (Boolean.TRUE.equals(titleModifiedDirectly)) {
                        existing.setTitle(title);
                    } else {
                        EventTitleHelper.recalculateEventTitle(existing, customFieldValueRepository);
                    }
                }

                existing.setDescription((String) body.get("description"));

                existing.setStartDate(parseDateTimeSafely((String) body.get("startDate")));
                existing.setEndDate(parseDateTimeSafely((String) body.get("endDate")));
                existing.setAllDay((Boolean) body.getOrDefault("allDay", false));
                existing.setColor((String) body.get("color"));
                existing.setRecurrenceRule((String) body.getOrDefault("recurrenceRule", "NONE"));
                
                if (body.get("recurrenceEndDate") != null && !body.get("recurrenceEndDate").toString().isEmpty()) {
                    existing.setRecurrenceEndDate(parseDateTimeSafely((String) body.get("recurrenceEndDate")));
                } else {
                    existing.setRecurrenceEndDate(null);
                }

                Optional<Calendar> calOpt = calendarRepository.findById(calendarId);
                calOpt.ifPresent(existing::setCalendar);

                existing.setLocked((Boolean) body.getOrDefault("locked", false));
                existing.setIsPrivate((Boolean) body.getOrDefault("isPrivate", false));

                String statusStr = (String) body.getOrDefault("status", "PLANNED");
                EventStatus targetStatus = EventStatus.valueOf(statusStr.toUpperCase());
                
                String priorityStr = (String) body.getOrDefault("priority", "NORMAL");
                existing.setPriority(EventPriority.valueOf(priorityStr.toUpperCase()));

                // Update participants
                if (body.get("participantIds") instanceof List) {
                    List<?> idsList = (List<?>) body.get("participantIds");
                    List<Long> memberIds = idsList.stream().map(pId -> Long.valueOf(pId.toString())).collect(Collectors.toList());
                    List<Member> participants = memberRepository.findAllById(memberIds);
                    existing.setParticipants(participants);
                }

                // Update tags
                if (body.get("tags") instanceof List) {
                    List<?> rawTags = (List<?>) body.get("tags");
                    Set<Tag> tagsSet = new HashSet<>();
                    for (Object tagObj : rawTags) {
                        if (tagObj instanceof Map) {
                            Map<?, ?> tMap = (Map<?, ?>) tagObj;
                            String name = (String) tMap.get("name");
                            String tColor = (String) tMap.get("color");
                            Tag tag = tagRepository.findByName(name).orElseGet(() -> 
                                    tagRepository.save(Tag.builder().name(name).color(tColor).build())
                            );
                            tagsSet.add(tag);
                        }
                    }
                    existing.setTags(tagsSet);
                }

                // Update dependencies
                if (body.get("dependencyIds") instanceof List) {
                    List<?> depIds = (List<?>) body.get("dependencyIds");
                    Set<Event> depSet = new HashSet<>();
                    for (Object dIdObj : depIds) {
                        Long dId = Long.valueOf(dIdObj.toString());
                        eventRepository.findById(dId).ifPresent(depSet::add);
                    }
                    
                    // Enforce dependencies completed validation
                    if (targetStatus == EventStatus.COMPLETED) {
                        for (Event dep : depSet) {
                            if (dep.getStatus() != EventStatus.COMPLETED) {
                                return ResponseEntity.badRequest().body("Impossible de marquer cet événement comme terminé car l'événement dépendant '" + dep.getTitle() + "' n'est pas terminé.");
                            }
                        }
                    }
                    existing.setDependencies(depSet);
                }
                
                existing.setStatus(targetStatus);

                // Update reminders
                if (body.get("reminders") instanceof List) {
                    List<?> rawReminders = (List<?>) body.get("reminders");
                    List<EventReminder> existingReminders = eventReminderRepository.findAllByEventId(existing.getId());
                    eventReminderRepository.deleteAll(existingReminders);

                    List<EventReminder> reminders = new ArrayList<>();
                    for (Object rObj : rawReminders) {
                        if (rObj instanceof String) {
                            LocalDateTime rTime = parseDateTimeSafely(rObj.toString());
                            reminders.add(EventReminder.builder().event(existing).reminderTime(rTime).build());
                        }
                    }
                    if (!reminders.isEmpty()) {
                        eventReminderRepository.saveAll(reminders);
                        if (existing.getReminders() != null) {
                            existing.getReminders().clear();
                            existing.getReminders().addAll(reminders);
                        } else {
                            existing.setReminders(reminders);
                        }
                    } else {
                        if (existing.getReminders() != null) {
                            existing.getReminders().clear();
                        }
                    }
                }

                existing.setUpdatedAt(LocalDateTime.now());
                Event saved = eventRepository.save(existing);

                // Audit Trail
                auditService.logAction(
                        current.getUsername(),
                        "UPDATE",
                        "EVENT",
                        saved.getId(),
                        "SUCCESS",
                        String.format("Modification de l'événement '%s' (Statut: %s -> %s, Priorité: %s -> %s)",
                                saved.getTitle(), oldStatus, targetStatus.name(), oldPriority, saved.getPriority().name())
                );

                // Generate System Message
                EventMessage systemMsg = EventMessage.builder()
                        .event(saved)
                        .member(current)
                        .message("A mis à jour l'événement: " + saved.getTitle())
                        .messageType(EventMessage.MessageType.SYSTEM)
                        .metadata("EVENT_UPDATED")
                        .sentAt(LocalDateTime.now())
                        .build();
                eventMessageRepository.save(systemMsg);

                // Notify calendar members
                if (saved.getCalendar() != null && saved.getCalendar().getMembers() != null) {
                    for (Member m : saved.getCalendar().getMembers()) {
                        notificationService.triggerNotification(
                                m,
                                current,
                                "Événement mis à jour: " + saved.getTitle(),
                                current.getFullName() + " a modifié l'événement.",
                                "EVENT_UPDATED",
                                "EVENT",
                                saved.getId(),
                                "UPDATED"
                        );
                    }
                }

                return ResponseEntity.ok(mapToEventMap(saved));

            } catch (Exception e) {
                log.error("Failed to update event", e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
            }
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> deleteEvent(@PathVariable Long id) {
        log.info("DELETE /api/timetree/events/{}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        return eventRepository.findById(id).map(existing -> {
            if (!securityService.canModifyEvent(current, existing)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Cet événement est verrouillé ou vos droits sont insuffisants pour le supprimer");
            }

            // Soft delete event (sets deleted = 1 via SQLDelete)
            eventRepository.delete(existing);

            // Audit Trail
            auditService.logAction(
                    current.getUsername(),
                    "DELETE",
                    "EVENT",
                    id,
                    "SUCCESS",
                    "Suppression logique de l'événement: " + existing.getTitle()
            );

            // Trigger Notifications
            if (existing.getCalendar() != null && existing.getCalendar().getMembers() != null) {
                for (Member m : existing.getCalendar().getMembers()) {
                    notificationService.triggerNotification(
                            m,
                            current,
                            "Événement annulé",
                            current.getFullName() + " a supprimé l'événement: " + existing.getTitle(),
                            "EVENT_DELETED",
                            "EVENT",
                            existing.getId(),
                            "DELETED"
                    );
                }
            }

            // Soft delete attachments
            List<EventAttachment> attachments = eventAttachmentRepository.findAllByEventId(existing.getId());
            for (EventAttachment att : attachments) {
                try {
                    fileStorageService.deleteFile(att.getFilePath());
                } catch (Exception ex) {
                    log.error("Failed to delete attachment file: " + att.getFilePath(), ex);
                }
            }
            eventAttachmentRepository.deleteAll(attachments);

            // Delete chat messages
            List<EventMessage> messages = eventMessageRepository.findAllByEventIdOrderBySentAtAsc(existing.getId());
            eventMessageRepository.deleteAll(messages);

            // Delete chat status read-bookmarks
            List<EventChatStatus> statuses = eventChatStatusRepository.findAll().stream()
                    .filter(s -> s.getEvent().getId().equals(existing.getId()))
                    .collect(Collectors.toList());
            eventChatStatusRepository.deleteAll(statuses);

            // Delete event notifications from database
            List<TimetreeNotification> notifications = notificationRepository.findAll().stream()
                    .filter(n -> n.getEntityType().equalsIgnoreCase("EVENT") && n.getEntityId().equals(existing.getId()))
                    .collect(Collectors.toList());
            notificationRepository.deleteAll(notifications);

            // Delete custom field values associated with this event
            List<CustomFieldValue> values = customFieldValueRepository.findAllByEntityTypeAndEntityId("EVENT", existing.getId().toString());
            customFieldValueRepository.deleteAll(values);

            return ResponseEntity.noContent().build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // Dynamic endpoints for participants assignments
    @PostMapping("/{id}/participants")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> addParticipant(@PathVariable Long id, @RequestBody Map<String, String> request) {
        log.info("POST /api/timetree/events/{}/participants", id);
        Member current = securityService.getCurrentMember();
        if (current == null) return ResponseEntity.status(HttpStatus.FORBIDDEN).build();

        String memberIdStr = request.get("memberId");
        if (memberIdStr == null) return ResponseEntity.badRequest().body("memberId requis");
        Long memberId = Long.valueOf(memberIdStr);

        return eventRepository.findById(id).flatMap(event -> 
            memberRepository.findById(memberId).map(member -> {
                if (!securityService.canWriteEvent(current, event.getCalendar().getId())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
                }
                if (event.getParticipants() == null) {
                    event.setParticipants(new ArrayList<>());
                }
                if (!event.getParticipants().contains(member)) {
                    event.getParticipants().add(member);
                    eventRepository.save(event);
                }
                return ResponseEntity.ok(mapToEventMap(event));
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}/participants/{memberId}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> removeParticipant(@PathVariable Long id, @PathVariable Long memberId) {
        log.info("DELETE /api/timetree/events/{}/participants/{}", id, memberId);
        Member current = securityService.getCurrentMember();
        if (current == null) return ResponseEntity.status(HttpStatus.FORBIDDEN).build();

        return eventRepository.findById(id).flatMap(event -> 
            memberRepository.findById(memberId).map(member -> {
                if (!securityService.canWriteEvent(current, event.getCalendar().getId())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
                }
                if (event.getParticipants() != null && event.getParticipants().remove(member)) {
                    eventRepository.save(event);
                }
                return ResponseEntity.ok(mapToEventMap(event));
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/resolve-by-entity/{type}/{id}")
    public ResponseEntity<?> resolveEventByEntity(@PathVariable String type, @PathVariable Long id) {
        log.info("Resolving event ID for entity type={}, id={}", type, id);
        if ("EVENT".equalsIgnoreCase(type)) {
            return ResponseEntity.ok(Collections.singletonMap("eventId", id.toString()));
        } else if ("MESSAGE".equalsIgnoreCase(type)) {
            return eventMessageRepository.findById(id)
                    .map(msg -> ResponseEntity.ok(Collections.singletonMap("eventId", msg.getEvent().getId().toString())))
                    .orElse(ResponseEntity.notFound().build());
        } else if ("ATTACHMENT".equalsIgnoreCase(type)) {
            return eventAttachmentRepository.findById(id)
                    .map(att -> ResponseEntity.ok(Collections.singletonMap("eventId", att.getEvent().getId().toString())))
                    .orElse(ResponseEntity.notFound().build());
        }
        return ResponseEntity.badRequest().body("Entity type inconnu");
    }

    // Helper map serialization
    private Map<String, Object> mapToEventMap(Event e) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", e.getId().toString());
        map.put("title", e.getTitle());
        map.put("nomEvent", e.getNomEvent());
        map.put("titleModifiedDirectly", e.getTitleModifiedDirectly());
        map.put("description", e.getDescription());
        map.put("attachedDocumentId", e.getAttachedDocumentId());
        map.put("attachedDocumentType", e.getAttachedDocumentType());
        map.put("attachedDocumentCode", e.getAttachedDocumentCode());
        map.put("attachedClientName", e.getAttachedClientName());

        map.put("startDate", e.getStartDate().toString());
        map.put("endDate", e.getEndDate().toString());
        map.put("allDay", e.getAllDay());
        map.put("color", e.getColor());
        map.put("calendarId", e.getCalendar().getId().toString());
        map.put("calendarName", e.getCalendar().getName());
        map.put("recurrenceRule", e.getRecurrenceRule());
        map.put("recurrenceEndDate", e.getRecurrenceEndDate() != null ? e.getRecurrenceEndDate().toString() : null);
        map.put("locked", e.getLocked());
        map.put("isPrivate", e.getIsPrivate());
        map.put("status", e.getStatus().name());
        map.put("priority", e.getPriority().name());

        List<Map<String, Object>> tagsList = new ArrayList<>();
        if (e.getTags() != null) {
            for (Tag t : e.getTags()) {
                Map<String, Object> tMap = new HashMap<>();
                tMap.put("id", t.getId().toString());
                tMap.put("name", t.getName());
                tMap.put("color", t.getColor());
                tagsList.add(tMap);
            }
        }
        map.put("tags", tagsList);

        List<Map<String, Object>> depsList = new ArrayList<>();
        if (e.getDependencies() != null) {
            for (Event dep : e.getDependencies()) {
                Map<String, Object> dMap = new HashMap<>();
                dMap.put("id", dep.getId().toString());
                dMap.put("title", dep.getTitle());
                dMap.put("status", dep.getStatus().name());
                depsList.add(dMap);
            }
        }
        map.put("dependencies", depsList);

        List<String> remindersList = new ArrayList<>();
        if (e.getReminders() != null) {
            for (EventReminder r : e.getReminders()) {
                remindersList.add(r.getReminderTime().toString());
            }
        }
        map.put("reminders", remindersList);
        
        List<Map<String, Object>> participantsList = new ArrayList<>();
        if (e.getParticipants() != null) {
            for (Member m : e.getParticipants()) {
                Map<String, Object> mMap = new HashMap<>();
                mMap.put("id", m.getId().toString());
                mMap.put("username", m.getUsername());
                mMap.put("fullName", m.getFullName());
                mMap.put("email", m.getEmail());
                mMap.put("role", m.getRole());
                participantsList.add(mMap);
            }
        }
        map.put("participants", participantsList);

        List<CustomFieldValue> customFieldValuesList = customFieldValueRepository.findAllByEntityTypeAndEntityId("EVENT", e.getId().toString());
        Map<String, String> customFieldsMap = new HashMap<>();
        if (customFieldValuesList != null) {
            for (CustomFieldValue cfv : customFieldValuesList) {
                if (cfv.getField() != null && cfv.getValue() != null) {
                    customFieldsMap.put(cfv.getField().getId().toString(), cfv.getValue());
                }
            }
        }
        map.put("customFields", customFieldsMap);
        
        return map;
    }

    @GetMapping("/{id}/history")
    @Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<?> getEventHistory(@PathVariable Long id) {
        log.info("GET /api/timetree/events/{}/history", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        String role = current.getRole().toUpperCase();
        if (!("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role) || "CHEF".equals(role))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès réservé aux administrateurs et chefs d'agenda");
        }

        if (!("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role))) {
            List<Long> allowedCalendarIds = securityService.getAllowedCalendarIds(current);
            if (!allowedCalendarIds.contains(event.getCalendar().getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé à l'historique de cet événement");
            }
        }

        List<TimetreeAuditLog> logs = auditLogRepository.findByEntityTypeAndEntityIdOrderByActionDateDesc("EVENT", id);
        return ResponseEntity.ok(logs);
    }

    private LocalDateTime parseDateTimeSafely(String str) {
        if (str == null || str.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDateTime.parse(str);
        } catch (Exception e) {
            try {
                return java.time.OffsetDateTime.parse(str).toLocalDateTime();
            } catch (Exception ex) {
                try {
                    return java.time.Instant.parse(str).atZone(java.time.ZoneId.systemDefault()).toLocalDateTime();
                } catch (Exception exc) {
                    log.error("Failed to parse datetime safely: {}", str, exc);
                    throw new IllegalArgumentException("Format de date invalide: " + str);
                }
            }
        }
    }
}

