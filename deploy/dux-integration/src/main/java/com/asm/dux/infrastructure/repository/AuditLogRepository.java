package com.asm.dux.infrastructure.repository;

import com.asm.dux.infrastructure.entity.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    long countByActionAndTimestampBetween(String action, LocalDateTime start, LocalDateTime end);

    @Query("SELECT FUNCTION('PARSEDATETIME', FUNCTION('FORMATDATETIME', a.timestamp, 'yyyy-MM-dd'), 'yyyy-MM-dd') as date, COUNT(a) as count " +
           "FROM AuditLog a " +
           "WHERE a.action = :action AND a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY FUNCTION('PARSEDATETIME', FUNCTION('FORMATDATETIME', a.timestamp, 'yyyy-MM-dd'), 'yyyy-MM-dd') " +
           "ORDER BY date ASC")
    List<Map<String, Object>> countByActionGroupedByDay(
            @Param("action") String action,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT EXTRACT(HOUR FROM a.timestamp) as hour, COUNT(a) as count " +
           "FROM AuditLog a " +
           "WHERE a.action = :action AND a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY EXTRACT(HOUR FROM a.timestamp) " +
           "ORDER BY hour ASC")
    List<Map<String, Object>> countByActionGroupedByHour(
            @Param("action") String action,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    org.springframework.data.domain.Page<AuditLog> findAllByOrderByTimestampDesc(org.springframework.data.domain.Pageable pageable);
}
