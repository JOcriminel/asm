package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_NOTIFICATION", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetreeNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "RECIPIENT_ID", nullable = false)
    private Member recipient;

    @Column(name = "TITLE", nullable = false, length = 150)
    private String title;

    @Column(name = "CONTENT", nullable = false, length = 1000)
    private String content;

    @Column(name = "TYPE", nullable = false, length = 50)
    private String type; // e.g. NEW_MESSAGE, NEW_ATTACHMENT, etc.

    @Column(name = "ENTITY_TYPE", nullable = false, length = 50)
    private String entityType; // e.g. EVENT, ATTACHMENT, MESSAGE

    @Column(name = "ENTITY_ID", nullable = false)
    private Long entityId;

    @Column(name = "ACTION_TYPE", nullable = false, length = 50)
    private String actionType; // e.g. CREATED, UPDATED, DELETED, NEW, ASSIGNED

    @Column(name = "IS_READ", nullable = false)
    @Builder.Default
    private boolean read = false;

    @Column(name = "CREATED_AT", nullable = false)
    private LocalDateTime createdAt;
}
