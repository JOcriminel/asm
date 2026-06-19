package com.asm.dux.infrastructure.db.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Column;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "num_serie_records")
public class NumSerieRecord {

    @Id
    @jakarta.persistence.GeneratedValue(strategy = jakarta.persistence.GenerationType.IDENTITY)
    private Long id;

    @Column(name = "num_serie", length = 255)
    private String numSerie;

    @Column(name = "document_id", nullable = false)
    private String documentId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public NumSerieRecord() {
    }

    public NumSerieRecord(String numSerie, String documentId) {
        this.numSerie = numSerie;
        this.documentId = documentId;
        this.createdAt = LocalDateTime.now();
    }

    public String getNumSerie() {
        return numSerie;
    }

    public void setNumSerie(String numSerie) {
        this.numSerie = numSerie;
    }

    public String getDocumentId() {
        return documentId;
    }

    public void setDocumentId(String documentId) {
        this.documentId = documentId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
