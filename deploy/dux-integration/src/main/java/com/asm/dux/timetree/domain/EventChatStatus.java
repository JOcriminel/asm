package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_EVENT_CHAT_STATUS", schema = "dbo")
@IdClass(EventChatStatusId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventChatStatus {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "EVENT_ID", nullable = false)
    private Event event;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MEMBER_ID", nullable = false)
    private Member member;

    @Column(name = "LAST_READ_MESSAGE_ID")
    private Long lastReadMessageId;

    @Column(name = "LAST_READ_AT", nullable = false)
    private LocalDateTime lastReadAt;
}
