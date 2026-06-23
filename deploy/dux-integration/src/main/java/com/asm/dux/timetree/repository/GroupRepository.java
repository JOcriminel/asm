package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Group;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeGroupRepository")
public interface GroupRepository extends JpaRepository<Group, Long> {
    List<Group> findAllByOrderByCreatedAtDesc();
    List<Group> findAllByActiveTrue();

    @org.springframework.data.jpa.repository.Query("SELECT g FROM Group g WHERE g.chef.id = :memberId OR :memberId IN (SELECT m.id FROM g.members m)")
    List<Group> findGroupsByMemberId(@org.springframework.data.repository.query.Param("memberId") Long memberId);

    @org.springframework.data.jpa.repository.Query("SELECT m FROM Group g JOIN g.members m WHERE g.id = :groupId")
    List<com.asm.dux.timetree.domain.Member> findMembersByGroupId(@org.springframework.data.repository.query.Param("groupId") Long groupId);
}
