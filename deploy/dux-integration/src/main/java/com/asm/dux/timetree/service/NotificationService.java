package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.domain.NotificationPreference;
import com.asm.dux.timetree.domain.TimetreeNotification;
import com.asm.dux.timetree.repository.NotificationPreferenceRepository;
import com.asm.dux.timetree.repository.NotificationRepository;
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

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final NotificationPreferenceRepository notificationPreferenceRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final SimpMessagingTemplate messagingTemplate;

    // Helper to send/publish notifications
    public void triggerNotification(Member recipient, String title, String content, 
                                     String type, String entityType, Long entityId, String actionType) {
        log.info("Triggering notification event to recipient: {} - Type: {}", recipient.getUsername(), type);
        NotificationEvent event = new NotificationEvent(
            this, recipient, title, content, type, entityType, entityId, actionType
        );
        eventPublisher.publishEvent(event);
    }

    // Listener to persist and push notifications
    @EventListener
    @Transactional(value = "timertreeTransactionManager")
    public void handleNotificationEvent(NotificationEvent event) {
        log.info("Handling notification event for: {} - Title: {}", event.getRecipient().getUsername(), event.getTitle());
        
        NotificationPreference pref = getPreferencesForUser(event.getRecipient().getId(), event.getRecipient());

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

        TimetreeNotification notification = TimetreeNotification.builder()
                .recipient(event.getRecipient())
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

        // Push real-time over WebSocket if Push is generally enabled for user
        if (Boolean.TRUE.equals(pref.getPushEnabled())) {
            log.info("Pushing notification real-time via WebSocket to: {}", event.getRecipient().getUsername());
            messagingTemplate.convertAndSendToUser(
                    event.getRecipient().getUsername(),
                    "/queue/notifications",
                    mapToNotificationMap(saved)
            );
            pushUnreadCount(event.getRecipient().getUsername(), event.getRecipient().getId());
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
}
