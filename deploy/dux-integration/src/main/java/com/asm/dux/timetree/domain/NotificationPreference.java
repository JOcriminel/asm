package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TT_NOTIFICATION_PREFERENCE", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MEMBER_ID", nullable = false, unique = true)
    private Member member;

    @Column(name = "EMAIL_ENABLED", nullable = false)
    @Builder.Default
    private Boolean emailEnabled = false;

    @Column(name = "PUSH_ENABLED", nullable = false)
    @Builder.Default
    private Boolean pushEnabled = true;

    @Column(name = "MENTIONS_ENABLED", nullable = false)
    @Builder.Default
    private Boolean mentionsEnabled = true;

    @Column(name = "REMINDERS_ENABLED", nullable = false)
    @Builder.Default
    private Boolean remindersEnabled = true;

    @Column(name = "CHAT_ENABLED", nullable = false)
    @Builder.Default
    private Boolean chatEnabled = true;

    @Column(name = "SOUND_ENABLED", nullable = false)
    @Builder.Default
    private Boolean soundEnabled = true;

    @Column(name = "VIBRATION_ENABLED", nullable = false)
    @Builder.Default
    private Boolean vibrationEnabled = true;

    @Column(name = "SNOOZE_UNTIL")
    private java.time.LocalDateTime snoozeUntil;

    @Column(name = "MUTE_ALL_EXCEPT_SPECIFIC", nullable = false)
    @Builder.Default
    private Boolean muteAllExceptSpecific = false;

    @Column(name = "NOTIFY_OWN_ACTIONS", nullable = false)
    @Builder.Default
    private Boolean notifyOwnActions = false;
}
