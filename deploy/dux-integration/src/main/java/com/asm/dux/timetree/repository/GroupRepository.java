package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Group;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeGroupRepository")
public interface GroupRepository extends JpaRepository<Group, Long> {
    List<Group> findAllByOrderByCreatedAtDesc();
    List<Group> findAllByActiveTrue();
}
