package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.TimetreeAuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository("timetreeAuditLogRepository")
public interface TimetreeAuditLogRepository extends JpaRepository<TimetreeAuditLog, Long> {
    @Query("SELECT t FROM TimetreeAuditLog t ORDER BY t.actionDate DESC")
    List<TimetreeAuditLog> findRecentLogs(Pageable pageable);

    @Query("SELECT t FROM TimetreeAuditLog t WHERE " +
           "((t.entityType = 'CALENDAR' AND t.entityId = :calendarId) OR " +
           "(:hasEvents = true AND t.entityType = 'EVENT' AND t.entityId IN :eventIds) OR " +
           "(:hasAttachments = true AND (t.entityType = 'EVENTATTACHMENT' OR t.entityType = 'ATTACHMENT') AND t.entityId IN :attachmentIds)) " +
           "AND (:action IS NULL OR t.action = :action)")
    Page<TimetreeAuditLog> findCalendarLogs(
            @Param("calendarId") Long calendarId,
            @Param("hasEvents") boolean hasEvents,
            @Param("eventIds") Collection<Long> eventIds,
            @Param("hasAttachments") boolean hasAttachments,
            @Param("attachmentIds") Collection<Long> attachmentIds,
            @Param("action") String action,
            Pageable pageable);
}
