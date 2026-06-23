package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_EVENT_REMINDER", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventReminder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "EVENT_ID", nullable = false)
    private Event event;

    @Column(name = "REMINDER_TIME", nullable = false)
    private LocalDateTime reminderTime;

    @Column(name = "IS_TRIGGERED", nullable = false)
    @Builder.Default
    private Boolean isTriggered = false;
}
