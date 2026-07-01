package com.asm.dux.infrastructure.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "document_validation_proof")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DocumentValidationProof {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "document_id", nullable = false)
    private String documentId;

    @Column(name = "document_type", nullable = false)
    private String documentType;

    @Column(name = "signature_path", length = 500)
    private String signaturePath;

    @Column(name = "photo_path", length = 500)
    private String photoPath;

    @Column(name = "validated_by", length = 100)
    private String validatedBy;

    @Column(name = "validated_at", nullable = false)
    private LocalDateTime validatedAt;
}
