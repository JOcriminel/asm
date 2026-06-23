package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.CustomField;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeCustomFieldRepository")
public interface CustomFieldRepository extends JpaRepository<CustomField, Long> {
    List<CustomField> findAllByOrderBySortOrderAsc();
    List<CustomField> findAllByScopeTypeAndScopeIdOrderBySortOrderAsc(String scopeType, String scopeId);
    List<CustomField> findAllByScopeTypeOrderBySortOrderAsc(String scopeType);
}
