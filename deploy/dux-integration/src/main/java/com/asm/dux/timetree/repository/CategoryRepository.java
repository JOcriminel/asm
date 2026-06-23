package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository("timetreeCategoryRepository")
public interface CategoryRepository extends JpaRepository<Category, Long> {
    List<Category> findAllByOrderByDisplayOrderAsc();
    List<Category> findAllByActiveTrueOrderByDisplayOrderAsc();
    Optional<Category> findByCode(String code);
}
