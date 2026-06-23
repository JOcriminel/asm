package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_AUDIT_LOG", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetreeAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "USERNAME", length = 100)
    private String username;

    @Column(name = "ACTION", length = 100)
    private String action;

    @Column(name = "ENTITY_TYPE", length = 100)
    private String entityType;

    @Column(name = "ENTITY_ID")
    private Long entityId;

    @Column(name = "RESULT", length = 50)
    private String result;

    @Column(name = "IP_ADDRESS", length = 100)
    private String ipAddress;

    @Column(name = "ACTION_DATE")
    private LocalDateTime actionDate;

    @Lob
    @Column(name = "DETAILS", columnDefinition = "VARCHAR(MAX)")
    private String details;
}
