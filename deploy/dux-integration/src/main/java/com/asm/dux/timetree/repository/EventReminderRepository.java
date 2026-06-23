package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.EventReminder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository("timetreeEventReminderRepository")
public interface EventReminderRepository extends JpaRepository<EventReminder, Long> {
    List<EventReminder> findAllByEventId(Long eventId);

    @Query("SELECT r FROM EventReminder r JOIN FETCH r.event e WHERE r.isTriggered = false AND r.reminderTime <= :now AND e.deleted = false")
    List<EventReminder> findPendingReminders(@Param("now") LocalDateTime now);
}
