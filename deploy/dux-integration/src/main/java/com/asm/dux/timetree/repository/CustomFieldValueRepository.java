package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.CustomFieldValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository("timetreeCustomFieldValueRepository")
public interface CustomFieldValueRepository extends JpaRepository<CustomFieldValue, Long> {
    List<CustomFieldValue> findAllByEntityTypeAndEntityId(String entityType, String entityId);
    Optional<CustomFieldValue> findByFieldIdAndEntityTypeAndEntityId(Long fieldId, String entityType, String entityId);
    void deleteAllByEntityTypeAndEntityId(String entityType, String entityId);
}
