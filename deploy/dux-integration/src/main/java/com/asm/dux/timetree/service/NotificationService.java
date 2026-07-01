package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.domain.NotificationPreference;
import com.asm.dux.timetree.domain.TimetreeNotification;
import com.asm.dux.timetree.domain.UserDevice;
import com.asm.dux.timetree.repository.NotificationPreferenceRepository;
import com.asm.dux.timetree.repository.NotificationRepository;
import com.asm.dux.timetree.repository.UserDeviceRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import com.asm.dux.timetree.repository.CalendarRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import com.asm.dux.timetree.repository.EventReminderRepository;
import com.asm.dux.timetree.repository.EventMessageRepository;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationPreferenceRepository notificationPreferenceRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final SimpMessagingTemplate messagingTemplate;
    private final FcmService fcmService;
    private final UserDeviceRepository userDeviceRepository;
    private final MemberRepository memberRepository;
    private final CalendarRepository calendarRepository;
    private final EventReminderRepository eventReminderRepository;
    private final EventMessageRepository eventMessageRepository;

    // Helper to send/publish notifications
    public void triggerNotification(Member recipient, Member sender, String title, String content, 
                                     String type, String entityType, Long entityId, String actionType) {
        log.info("Triggering notification event to recipient: {} - Sender: {} - Type: {}", recipient.getUsername(), sender != null ? sender.getUsername() : "null", type);
        NotificationEvent event = new NotificationEvent(
            this, recipient, sender, title, content, type, entityType, entityId, actionType
        );
        eventPublisher.publishEvent(event);
    }

    public void triggerNotification(Member recipient, String title, String content, 
                                     String type, String entityType, Long entityId, String actionType) {
        triggerNotification(recipient, null, title, content, type, entityType, entityId, actionType);
    }

    // Listener to persist and push notifications
    @EventListener
    @Transactional(value = "timertreeTransactionManager")
    public void handleNotificationEvent(NotificationEvent event) {
        log.info("Handling notification event for: {} - Title: {}", event.getRecipient().getUsername(), event.getTitle());
        
        NotificationPreference pref = getPreferencesForUser(event.getRecipient().getId(), event.getRecipient());

        // 1. Check if notifications are currently snoozed/muted (DND mode)
        if (pref.getSnoozeUntil() != null && pref.getSnoozeUntil().isAfter(LocalDateTime.now())) {
            log.info("Notifications for user {} are currently muted/snoozed", event.getRecipient().getUsername());
            return;
        }

        // 1.5. Check if it is the recipient's own action
        if (event.getSender() != null && event.getRecipient().getId().equals(event.getSender().getId())) {
            if (Boolean.TRUE.equals(pref.getMuteAllExceptSpecific())) {
                log.info("Filtering out own action notification for user {} because muteAllExceptSpecific is enabled", event.getRecipient().getUsername());
                return;
            }
            if (!Boolean.TRUE.equals(pref.getNotifyOwnActions())) {
                log.info("Filtering out own action notification for user {}", event.getRecipient().getUsername());
                return;
            }
        }

        // Check if this type of notification is muted by user preference
        boolean allowed = true;
        String type = event.getType() != null ? event.getType().toUpperCase() : "";
        if (type.equals("MENTION")) {
            allowed = Boolean.TRUE.equals(pref.getMentionsEnabled());
        } else if (type.equals("REMINDER")) {
            allowed = Boolean.TRUE.equals(pref.getRemindersEnabled());
        } else if (type.equals("NEW_MESSAGE") || type.equals("CHAT")) {
            allowed = Boolean.TRUE.equals(pref.getChatEnabled());
        } else {
            allowed = Boolean.TRUE.equals(pref.getPushEnabled());
        }

        if (!allowed) {
            log.info("Notification of type {} for user {} is muted by preference", type, event.getRecipient().getUsername());
            return;
        }

        // If the type check allowed it, but the user has "mute all except specific" enabled:
        if (allowed && Boolean.TRUE.equals(pref.getMuteAllExceptSpecific())) {
            // Reminders themselves are always allowed (the user explicitly scheduled them)
            if (!type.equals("REMINDER")) {
                // For other types, only allow if the target event has reminders configured
                Long eventId = null;
                if ("EVENT".equals(event.getEntityType())) {
                    eventId = event.getEntityId();
                } else if ("MESSAGE".equals(event.getEntityType()) && event.getEntityId() != null) {
                    final Long msgId = event.getEntityId();
                    eventId = eventMessageRepository.findById(msgId)
                            .map(msg -> msg.getEvent() != null ? msg.getEvent().getId() : null)
                            .orElse(null);
                }
                
                if (eventId != null) {
                    boolean eventHasReminders = !eventReminderRepository.findAllByEventId(eventId).isEmpty();
                    if (!eventHasReminders) {
                        allowed = false;
                        log.info("Muting notification of type {} because event {} does not have any active reminders", type, eventId);
                    }
                } else {
                    // Mute if not associated with an event
                    allowed = false;
                    log.info("Muting notification of type {} because it is not associated with a specific event", type);
                }
            }
        }

        if (!allowed) {
            return;
        }

        TimetreeNotification notification = TimetreeNotification.builder()
                .recipient(event.getRecipient())
                .sender(event.getSender())
                .title(event.getTitle())
                .content(event.getContent())
                .type(event.getType())
                .entityType(event.getEntityType())
                .entityId(event.getEntityId())
                .actionType(event.getActionType())
                .createdAt(LocalDateTime.now())
                .read(false)
                .build();
        
        TimetreeNotification saved = notificationRepository.save(notification);

        // Push real-time over WebSocket and FCM if Push is enabled for user
        if (Boolean.TRUE.equals(pref.getPushEnabled())) {
            log.info("Pushing notification real-time via WebSocket to: {}", event.getRecipient().getUsername());
            messagingTemplate.convertAndSendToUser(
                    event.getRecipient().getUsername(),
                    "/queue/notifications",
                    mapToNotificationMap(saved)
            );
            pushUnreadCount(event.getRecipient().getUsername(), event.getRecipient().getId());

            // Send external mobile push notification via FCM
            try {
                List<UserDevice> devices = userDeviceRepository.findByMemberId(event.getRecipient().getId());
                for (UserDevice device : devices) {
                    java.util.Map<String, String> dataPayload = new java.util.HashMap<>();
                    dataPayload.put("entityType", event.getEntityType() != null ? event.getEntityType() : "");
                    dataPayload.put("entityId", event.getEntityId() != null ? String.valueOf(event.getEntityId()) : "");
                    dataPayload.put("actionType", event.getActionType() != null ? event.getActionType() : "");

                    fcmService.sendPushNotification(
                            device.getDeviceToken(),
                            event.getTitle(),
                            event.getContent(),
                            dataPayload
                    );
                }
            } catch (Exception e) {
                log.error("Failed to send push notification via FCM for user {}", event.getRecipient().getUsername(), e);
            }
        }
    }

    private void pushUnreadCount(String username, Long memberId) {
        long unreadCount = notificationRepository.countByRecipientIdAndReadFalse(memberId);
        java.util.Map<String, Object> payload = new java.util.HashMap<>();
        payload.put("type", "UNREAD_COUNT");
        payload.put("count", unreadCount);

        log.info("Pushing unread count update via WebSocket to: {} count={}", username, unreadCount);
        messagingTemplate.convertAndSendToUser(
                username,
                "/queue/notifications",
                payload
        );
    }

    public List<TimetreeNotification> getNotificationsForUser(Long memberId) {
        return notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(memberId);
    }

    public Page<TimetreeNotification> getNotificationsForUser(Long memberId, Pageable pageable) {
        return notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(memberId, pageable);
    }

    @Transactional(value = "timertreeTransactionManager")
    public boolean markAsRead(Long id, Long memberId) {
        Optional<TimetreeNotification> notOpt = notificationRepository.findById(id);
        if (notOpt.isPresent()) {
            TimetreeNotification notif = notOpt.get();
            if (notif.getRecipient().getId().equals(memberId)) {
                notif.setRead(true);
                notificationRepository.save(notif);
                pushUnreadCount(notif.getRecipient().getUsername(), memberId);
                return true;
            }
        }
        return false;
    }

    @Transactional(value = "timertreeTransactionManager")
    public void markAllAsRead(Long memberId, String username) {
        List<TimetreeNotification> unread = notificationRepository.findAllByRecipientIdAndReadFalse(memberId);
        for (TimetreeNotification notif : unread) {
            notif.setRead(true);
        }
        notificationRepository.saveAll(unread);
        pushUnreadCount(username, memberId);
    }

    @Transactional(value = "timertreeTransactionManager")
    public boolean deleteNotification(Long id, Long memberId) {
        Optional<TimetreeNotification> notOpt = notificationRepository.findById(id);
        if (notOpt.isPresent()) {
            TimetreeNotification notif = notOpt.get();
            if (notif.getRecipient().getId().equals(memberId)) {
                notificationRepository.delete(notif);
                pushUnreadCount(notif.getRecipient().getUsername(), memberId);
                return true;
            }
        }
        return false;
    }

    // Preference Helpers
    public NotificationPreference getPreferencesForUser(Long memberId, Member member) {
        return notificationPreferenceRepository.findByMemberId(memberId)
                .orElseGet(() -> {
                    NotificationPreference defaultPref = NotificationPreference.builder()
                            .member(member)
                            .emailEnabled(false)
                            .pushEnabled(true)
                            .mentionsEnabled(true)
                            .remindersEnabled(true)
                            .chatEnabled(true)
                            .soundEnabled(true)
                            .vibrationEnabled(true)
                            .snoozeUntil(null)
                            .muteAllExceptSpecific(false)
                            .notifyOwnActions(false)
                            .build();
                    return notificationPreferenceRepository.save(defaultPref);
                });
    }

    @Transactional(value = "timertreeTransactionManager")
    public NotificationPreference updatePreferences(Long memberId, NotificationPreference newPref, Member member) {
        NotificationPreference current = getPreferencesForUser(memberId, member);
        current.setEmailEnabled(newPref.getEmailEnabled());
        current.setPushEnabled(newPref.getPushEnabled());
        current.setMentionsEnabled(newPref.getMentionsEnabled());
        current.setRemindersEnabled(newPref.getRemindersEnabled());
        current.setChatEnabled(newPref.getChatEnabled());
        current.setSoundEnabled(newPref.getSoundEnabled());
        current.setVibrationEnabled(newPref.getVibrationEnabled());
        current.setSnoozeUntil(newPref.getSnoozeUntil());
        current.setMuteAllExceptSpecific(newPref.getMuteAllExceptSpecific());
        current.setNotifyOwnActions(newPref.getNotifyOwnActions());
        return notificationPreferenceRepository.save(current);
    }

    private java.util.Map<String, Object> mapToNotificationMap(TimetreeNotification n) {
        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("id", n.getId().toString());
        map.put("recipientId", n.getRecipient().getId().toString());
        map.put("title", n.getTitle());
        map.put("content", n.getContent());
        map.put("type", n.getType());
        map.put("entityType", n.getEntityType());
        map.put("entityId", n.getEntityId().toString());
        map.put("actionType", n.getActionType());
        map.put("isRead", n.isRead());
        map.put("createdAt", n.getCreatedAt().toString());
        return map;
    }

    @Transactional(value = "timertreeTransactionManager")
    public void triggerAnnouncement(String title, String content, List<Long> calendarIds) {
        log.info("Triggering announcement: '{}' for calendarIds: {}", title, calendarIds);
        java.util.Set<Member> targetRecipients = new java.util.HashSet<>();

        if (calendarIds == null || calendarIds.isEmpty()) {
            // Global Broadcast to all members
            targetRecipients.addAll(memberRepository.findAll());
        } else {
            // Targeted Calendar members
            for (Long calendarId : calendarIds) {
                calendarRepository.findById(calendarId).ifPresent(calendar -> {
                    if (calendar.getMembers() != null) {
                        targetRecipients.addAll(calendar.getMembers());
                    }
                });
            }
        }

        // Trigger notification for each unique member in target scope
        for (Member recipient : targetRecipients) {
            triggerNotification(
                    recipient,
                    title,
                    content,
                    "ANNOUNCEMENT",
                    "SYSTEM",
                    0L,
                    "BROADCAST"
            );
        }
    }
}
