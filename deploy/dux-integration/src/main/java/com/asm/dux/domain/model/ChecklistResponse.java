package com.asm.dux.domain.model;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDateTime;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "preparation_ChecklistResponse")
public class ChecklistResponse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String idLigneDocument;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private ChecklistTask task;

    @Column(nullable = false)
    private Boolean isChecked;

    @Column(nullable = false)
    private LocalDateTime dateChecked;

    @Column(nullable = true, length = 1000)
    private String note;

    @Column(nullable = true)
    private LocalDateTime dateNote;

    @Column(nullable = true)
    private String checkedBy;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getIdLigneDocument() { return idLigneDocument; }
    public void setIdLigneDocument(String idLigneDocument) { this.idLigneDocument = idLigneDocument; }

    public ChecklistTask getTask() { return task; }
    public void setTask(ChecklistTask task) { this.task = task; }

    public Boolean getIsChecked() { return isChecked; }
    public void setIsChecked(Boolean isChecked) { this.isChecked = isChecked; }

    public LocalDateTime getDateChecked() { return dateChecked; }
    public void setDateChecked(LocalDateTime dateChecked) { this.dateChecked = dateChecked; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public LocalDateTime getDateNote() { return dateNote; }
    public void setDateNote(LocalDateTime dateNote) { this.dateNote = dateNote; }

    public String getCheckedBy() { return checkedBy; }
    public void setCheckedBy(String checkedBy) { this.checkedBy = checkedBy; }
}
