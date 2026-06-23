package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Calendar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository("timetreeCalendarRepository")
public interface CalendarRepository extends JpaRepository<Calendar, Long> {
}
