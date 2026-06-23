package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Event;
import com.asm.dux.timetree.domain.EventReminder;
import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.repository.EventReminderRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReminderScheduler {

    private final EventReminderRepository eventReminderRepository;
    private final MemberRepository memberRepository;
    private final NotificationService notificationService;

    @Scheduled(fixedDelay = 60000)
    @Transactional
    public void processReminders() {
        LocalDateTime now = LocalDateTime.now();
        List<EventReminder> pending = eventReminderRepository.findPendingReminders(now);
        if (pending.isEmpty()) {
            return;
        }

        log.info("Processing {} pending event reminders...", pending.size());

        for (EventReminder reminder : pending) {
            reminder.setIsTriggered(true);
            eventReminderRepository.save(reminder);

            Event event = reminder.getEvent();
            List<Member> recipients = new ArrayList<>();
            if (event.getParticipants() != null && !event.getParticipants().isEmpty()) {
                recipients.addAll(event.getParticipants());
            } else {
                if (event.getCreatedBy() != null) {
                    memberRepository.findByUsername(event.getCreatedBy()).ifPresent(recipients::add);
                }
            }

            for (Member m : recipients) {
                notificationService.triggerNotification(
                        m,
                        "Rappel d'événement",
                        "L'événement '" + event.getTitle() + "' commence le " + event.getStartDate().toString(),
                        "REMINDER",
                        "EVENT",
                        event.getId(),
                        "REMINDER"
                );
            }
        }
    }
}
