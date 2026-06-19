package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ChecklistFamilyMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChecklistFamilyMappingRepository extends JpaRepository<ChecklistFamilyMapping, Long> {
    List<ChecklistFamilyMapping> findByGroupId(Long groupId);
    List<ChecklistFamilyMapping> findByCodeFamille(String codeFamille);
    void deleteByGroupId(Long groupId);
}
