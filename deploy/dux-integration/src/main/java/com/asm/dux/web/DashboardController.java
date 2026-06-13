package com.asm.dux.web;

import com.asm.dux.infrastructure.repository.AuditLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * REST controller for Performance Dashboard statistics and live feed.
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
    public ResponseEntity<Map<String, Object>> getStats(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        log.info("GET /api/dux/dashboard/stats");

        LocalDateTime start = startDate != null ? startDate.atStartOfDay() : LocalDate.now().atStartOfDay();
        LocalDateTime end = endDate != null ? endDate.atTime(LocalTime.MAX) : LocalDate.now().atTime(LocalTime.MAX);
        LocalDateTime historyStart = startDate != null ? start : start.minusDays(7);

        long scansToday = auditLogRepository.countByActionAndTimestampBetween("SCAN", start, end);
        long deletionsToday = auditLogRepository.countByActionAndTimestampBetween("DELETE", start, end);
        
        List<Map<String, Object>> scansLast7Days = auditLogRepository.countByActionGroupedByDay("SCAN", historyStart, end);
        List<Map<String, Object>> scansByHour = auditLogRepository.countByActionGroupedByHour("SCAN", start, end);

        Map<String, Object> stats = new HashMap<>();
        stats.put("scansToday", scansToday);
        stats.put("deletionsToday", deletionsToday);
        stats.put("scansLast7Days", scansLast7Days);
        stats.put("scansByHour", scansByHour);

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/feed")
    public ResponseEntity<Page<com.asm.dux.infrastructure.entity.AuditLog>> getFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        log.info("GET /api/dux/dashboard/feed?page={}&size={}", page, size);
        Page<com.asm.dux.infrastructure.entity.AuditLog> feed = auditLogRepository.findAllByOrderByTimestampDesc(PageRequest.of(page, size));
        return ResponseEntity.ok(feed);
    }
}
