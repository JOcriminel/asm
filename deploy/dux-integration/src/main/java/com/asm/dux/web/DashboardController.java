package com.asm.dux.web;

import com.asm.dux.infrastructure.repository.AuditLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * REST controller for Performance Dashboard statistics.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux/dashboard")
public class DashboardController {

    private final AuditLogRepository auditLogRepository;

    public DashboardController(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        log.info("GET /api/dux/dashboard/stats");

        LocalDateTime startOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime endOfDay = LocalDateTime.of(LocalDate.now(), LocalTime.MAX);
        LocalDateTime sevenDaysAgo = startOfDay.minusDays(7);

        long scansToday = auditLogRepository.countByActionAndTimestampBetween("SCAN", startOfDay, endOfDay);
        long deletionsToday = auditLogRepository.countByActionAndTimestampBetween("DELETE", startOfDay, endOfDay);
        
        List<Map<String, Object>> scansLast7Days = auditLogRepository.countByActionGroupedByDay("SCAN", sevenDaysAgo);

        Map<String, Object> stats = new HashMap<>();
        stats.put("scansToday", scansToday);
        stats.put("deletionsToday", deletionsToday);
        stats.put("scansLast7Days", scansLast7Days);

        return ResponseEntity.ok(stats);
    }
}
