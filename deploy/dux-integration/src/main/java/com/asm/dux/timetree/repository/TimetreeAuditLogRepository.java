package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.TimetreeAuditLog;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeAuditLogRepository")
public interface TimetreeAuditLogRepository extends JpaRepository<TimetreeAuditLog, Long> {
    @Query("SELECT t FROM TimetreeAuditLog t ORDER BY t.actionDate DESC")
    List<TimetreeAuditLog> findRecentLogs(Pageable pageable);
}
