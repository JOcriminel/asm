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

    @Query("SELECT CAST(a.timestamp AS date) as date, COUNT(a) as count " +
           "FROM AuditLog a " +
           "WHERE a.action = :action AND a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY CAST(a.timestamp AS date) " +
           "ORDER BY date ASC")
    List<Map<String, Object>> countByActionGroupedByDay(
            @Param("action") String action,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT HOUR(a.timestamp) as hour, COUNT(a) as count " +
           "FROM AuditLog a " +
           "WHERE a.action = :action AND a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY HOUR(a.timestamp) " +
           "ORDER BY hour ASC")
    List<Map<String, Object>> countByActionGroupedByHour(
            @Param("action") String action,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT YEAR(a.timestamp) as year, MONTH(a.timestamp) as month, COUNT(a) as count " +
           "FROM AuditLog a " +
           "WHERE a.action = :action AND a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY YEAR(a.timestamp), MONTH(a.timestamp) " +
           "ORDER BY year ASC, month ASC")
    List<Map<String, Object>> countByActionGroupedByMonth(
            @Param("action") String action,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT a.userId as userId, " +
           "SUM(CASE WHEN a.action = 'SCAN' THEN 1 ELSE 0 END) as scans, " +
           "SUM(CASE WHEN a.action = 'DELETE' THEN 1 ELSE 0 END) as deletions " +
           "FROM AuditLog a " +
           "WHERE a.timestamp BETWEEN :startDate AND :endDate " +
           "GROUP BY a.userId")
    List<Map<String, Object>> getOperatorPerformance(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    org.springframework.data.domain.Page<AuditLog> findAllByOrderByTimestampDesc(org.springframework.data.domain.Pageable pageable);
}
