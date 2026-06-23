package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.domain.TimetreeNotification;
import com.asm.dux.timetree.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final ApplicationEventPublisher eventPublisher;

    // Helper to send/publish notifications
    public void triggerNotification(Member recipient, String title, String content, 
                                    String type, String entityType, Long entityId, String actionType) {
        log.info("Triggering notification event to recipient: {} - Type: {}", recipient.getUsername(), type);
        NotificationEvent event = new NotificationEvent(
            this, recipient, title, content, type, entityType, entityId, actionType
        );
        eventPublisher.publishEvent(event);
    }

    // Listener to persist notifications
    @EventListener
    @Transactional
    public void handleNotificationEvent(NotificationEvent event) {
        log.info("Handling notification event for: {} - Title: {}", event.getRecipient().getUsername(), event.getTitle());
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
        
        notificationRepository.save(notification);
    }

    public List<TimetreeNotification> getNotificationsForUser(Long memberId) {
        return notificationRepository.findAllByRecipientIdOrderByCreatedAtDesc(memberId);
    }

    @Transactional
    public boolean markAsRead(Long id, Long memberId) {
        Optional<TimetreeNotification> notOpt = notificationRepository.findById(id);
        if (notOpt.isPresent()) {
            TimetreeNotification notif = notOpt.get();
            if (notif.getRecipient().getId().equals(memberId)) {
                notif.setRead(true);
                notificationRepository.save(notif);
                return true;
            }
        }
        return false;
    }

    @Transactional
    public void markAllAsRead(Long memberId) {
        List<TimetreeNotification> unread = notificationRepository.findAllByRecipientIdAndReadFalse(memberId);
        for (TimetreeNotification notif : unread) {
            notif.setRead(true);
        }
        notificationRepository.saveAll(unread);
    }
}
