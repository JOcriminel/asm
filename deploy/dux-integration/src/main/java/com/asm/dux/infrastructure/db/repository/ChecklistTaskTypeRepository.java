package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ChecklistTaskType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ChecklistTaskTypeRepository extends JpaRepository<ChecklistTaskType, Long> {
}
