package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.TimetreeNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

@Repository("timetreeNotificationRepository")
public interface NotificationRepository extends JpaRepository<TimetreeNotification, Long> {
    List<TimetreeNotification> findAllByRecipientIdOrderByCreatedAtDesc(Long recipientId);
    Page<TimetreeNotification> findAllByRecipientIdOrderByCreatedAtDesc(Long recipientId, Pageable pageable);
    List<TimetreeNotification> findAllByRecipientIdAndReadFalse(Long recipientId);
    long countByRecipientIdAndReadFalse(Long recipientId);
}
