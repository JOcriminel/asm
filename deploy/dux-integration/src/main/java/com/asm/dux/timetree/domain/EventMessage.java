package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_EVENT_MESSAGE", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "EVENT_ID", nullable = false)
    private Event event;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MEMBER_ID", nullable = false)
    private Member member;

    @Column(name = "MESSAGE", nullable = false, length = 1000)
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(name = "MESSAGE_TYPE", nullable = false, length = 50)
    @Builder.Default
    private MessageType messageType = MessageType.TEXT;

    @Column(name = "METADATA", length = 500)
    private String metadata;

    @Column(name = "SENT_AT", nullable = false)
    private LocalDateTime sentAt;

    public enum MessageType {
        TEXT, IMAGE, FILE, SYSTEM
    }
}
