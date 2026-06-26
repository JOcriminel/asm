package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.CustomFieldCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeCustomFieldCategoryRepository")
public interface CustomFieldCategoryRepository extends JpaRepository<CustomFieldCategory, Long> {
    List<CustomFieldCategory> findAllByOrderByDisplayOrderAsc();
}
