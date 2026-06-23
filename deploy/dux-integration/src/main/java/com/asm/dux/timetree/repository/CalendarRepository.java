package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Calendar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository("timetreeCalendarRepository")
public interface CalendarRepository extends JpaRepository<Calendar, Long> {
    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT c.id FROM Group g JOIN g.calendars c WHERE g.chef.id = :memberId OR :memberId IN (SELECT m.id FROM g.members m)")
    java.util.List<Long> findAllowedCalendarIdsByMemberId(@org.springframework.data.repository.query.Param("memberId") Long memberId);
}
