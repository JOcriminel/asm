package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository("timetreeEventRepository")
public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findAllByCalendarId(Long calendarId);
    @Query("SELECT e FROM Event e WHERE e.calendar.id IN :calendarIds AND " +
           "((e.startDate <= :end AND e.endDate >= :start) OR " +
           "(e.recurrenceRule <> 'NONE' AND (e.recurrenceEndDate IS NULL OR e.recurrenceEndDate >= :start) AND e.startDate <= :end))")
    List<Event> findActiveEventsInCalendars(
            @Param("calendarIds") List<Long> calendarIds,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end
    );
}
