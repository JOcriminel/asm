package com.asm.dux.infrastructure.repository;

import com.asm.dux.infrastructure.entity.DocumentValidationProof;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DocumentValidationProofRepository extends JpaRepository<DocumentValidationProof, Long> {
    List<DocumentValidationProof> findAllByDocumentIdOrderByValidatedAtDesc(String documentId);
}
