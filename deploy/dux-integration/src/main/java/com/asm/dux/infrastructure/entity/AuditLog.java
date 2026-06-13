package com.asm.dux.infrastructure.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "audit_log")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String action; // SCAN, DELETE

    @Column(name = "document_id")
    private String documentId;

    @Column(name = "line_id")
    private String lineId;

    @Column(name = "serial_number", nullable = false)
    private String serialNumber;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(name = "user_id")
    private String userId;
}
