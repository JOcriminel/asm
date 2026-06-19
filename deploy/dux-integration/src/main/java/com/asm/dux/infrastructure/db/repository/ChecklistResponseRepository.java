package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ChecklistResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChecklistResponseRepository extends JpaRepository<ChecklistResponse, Long> {
    List<ChecklistResponse> findByIdLigneDocument(String idLigneDocument);
    Optional<ChecklistResponse> findByIdLigneDocumentAndTaskId(String idLigneDocument, Long taskId);
    void deleteByIdLigneDocument(String idLigneDocument);
    long countByIsCheckedTrueAndDateCheckedBetween(java.time.LocalDateTime start, java.time.LocalDateTime end);
}
