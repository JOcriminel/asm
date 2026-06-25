package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Calendar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository("timetreeCalendarRepository")
public interface CalendarRepository extends JpaRepository<Calendar, Long> {
    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT c.id FROM Member m JOIN m.calendars c WHERE m.id = :memberId")
    java.util.List<Long> findAllowedCalendarIdsByMemberId(@org.springframework.data.repository.query.Param("memberId") Long memberId);
}
