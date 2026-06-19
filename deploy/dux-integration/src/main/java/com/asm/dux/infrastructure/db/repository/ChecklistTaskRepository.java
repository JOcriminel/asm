package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ChecklistTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

import org.springframework.data.repository.query.Param;

@Repository
public interface ChecklistTaskRepository extends JpaRepository<ChecklistTask, Long> {
    List<ChecklistTask> findByGroupId(Long groupId);
    List<ChecklistTask> findByTypeId(Long typeId);
    List<ChecklistTask> findByGroupIdAndTypeId(Long groupId, Long typeId);

    @Query("SELECT t FROM ChecklistTask t WHERE t.codeFamille = :codeFamille OR (t.group IS NOT NULL AND t.group.id IN (SELECT m.group.id FROM ChecklistFamilyMapping m WHERE m.codeFamille = :codeFamille))")
    List<ChecklistTask> findTasksByCodeFamille(@Param("codeFamille") String codeFamille);
}
