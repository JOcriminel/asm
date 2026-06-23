package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreePageRepository")
public interface PageRepository extends JpaRepository<Page, Long> {
    List<Page> findAllByOrderByDisplayOrderAsc();
    List<Page> findAllByActiveTrueOrderByDisplayOrderAsc();
}
