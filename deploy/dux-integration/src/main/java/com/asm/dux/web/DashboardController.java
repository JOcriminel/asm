package com.asm.dux.web;

import com.asm.dux.domain.model.DocumentFilter;
import com.asm.dux.domain.usecase.GetCommandListUseCase;
import com.asm.dux.infrastructure.repository.AuditLogRepository;
import com.asm.dux.infrastructure.db.repository.ChecklistResponseRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * REST controller for the ultimate Performance Dashboard statistics and live feed.
 * Aggregates logs, checklists, and ERP documents directly.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux/dashboard")
public class DashboardController {

    private final AuditLogRepository auditLogRepository;
    private final ChecklistResponseRepository checklistResponseRepository;
    private final GetCommandListUseCase getCommandListUseCase;
    private final ObjectMapper objectMapper;

    public DashboardController(AuditLogRepository auditLogRepository,
                               ChecklistResponseRepository checklistResponseRepository,
                               GetCommandListUseCase getCommandListUseCase) {
        this.auditLogRepository = auditLogRepository;
        this.checklistResponseRepository = checklistResponseRepository;
        this.getCommandListUseCase = getCommandListUseCase;
        this.objectMapper = new ObjectMapper();
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        log.info("GET /api/dux/dashboard/stats startDate={} endDate={}", startDate, endDate);

        LocalDateTime start = startDate != null ? startDate.atStartOfDay() : LocalDate.now().atStartOfDay();
        LocalDateTime end = endDate != null ? endDate.atTime(LocalTime.MAX) : LocalDate.now().atTime(LocalTime.MAX);

        // 1. Basic Counts
        long scansToday = auditLogRepository.countByActionAndTimestampBetween("SCAN", start, end);
        long deletionsToday = auditLogRepository.countByActionAndTimestampBetween("DELETE", start, end);
        long checklistResponsesToday = checklistResponseRepository.countByIsCheckedTrueAndDateCheckedBetween(start, end);

        // 2. Determine Timeline Grouping Resolution
        long daysBetween = ChronoUnit.DAYS.between(start.toLocalDate(), end.toLocalDate());
        final String groupBy;
        if (daysBetween <= 1) {
            groupBy = "HOUR";
        } else if (daysBetween > 45) {
            groupBy = "MONTH";
        } else {
            groupBy = "DAY";
        }

        // 3. Query Scans, Deletions, and Checklists Grouped by Resolution
        List<Map<String, Object>> scansGrouped;
        List<Map<String, Object>> deletionsGrouped;
        List<Map<String, Object>> checklistsGrouped;

        if ("HOUR".equals(groupBy)) {
            scansGrouped = auditLogRepository.countByActionGroupedByHour("SCAN", start, end);
            deletionsGrouped = auditLogRepository.countByActionGroupedByHour("DELETE", start, end);
            checklistsGrouped = checklistResponseRepository.countChecklistsGroupedByHour(start, end);
        } else if ("MONTH".equals(groupBy)) {
            scansGrouped = auditLogRepository.countByActionGroupedByMonth("SCAN", start, end);
            deletionsGrouped = auditLogRepository.countByActionGroupedByMonth("DELETE", start, end);
            checklistsGrouped = checklistResponseRepository.countChecklistsGroupedByMonth(start, end);
        } else {
            scansGrouped = auditLogRepository.countByActionGroupedByDay("SCAN", start, end);
            deletionsGrouped = auditLogRepository.countByActionGroupedByDay("DELETE", start, end);
            checklistsGrouped = checklistResponseRepository.countChecklistsGroupedByDay(start, end);
        }

        // 4. Fetch and Aggregate ERP Documents (BC, BP, BS) & Revenue
        long totalCommands = 0;
        double totalRevenue = 0.0;
        Map<String, Map<String, Object>> byType = new HashMap<>();
        Map<String, Map<String, Object>> byStatus = new HashMap<>();
        Map<String, Double> docRevenueTimeline = new HashMap<>();
        Map<String, Long> docCountTimeline = new HashMap<>();

        DateTimeFormatter erpDateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        DocumentFilter erpFilter = new DocumentFilter(
                start.format(erpDateFormatter),
                end.format(erpDateFormatter),
                "all", "all", "all", "all", "1", "1", "all", "0", null
        );

        try {
            String docsJson = getCommandListUseCase.execute(erpFilter, null);
            if (docsJson != null && !docsJson.isBlank()) {
                JsonNode root = objectMapper.readTree(docsJson);
                JsonNode array = null;
                if (root.isArray()) {
                    array = root;
                } else if (root.isObject()) {
                    for (String key : new String[]{"data", "content", "results", "documents"}) {
                        if (root.has(key) && root.get(key).isArray()) {
                            array = root.get(key);
                            break;
                        }
                    }
                }

                if (array != null && array.isArray()) {
                    totalCommands = array.size();
                    for (JsonNode item : array) {
                        double amount = 0.0;
                        if (item.has("mntTtc") && !item.get("mntTtc").isNull()) {
                            amount = item.get("mntTtc").asDouble();
                        } else if (item.has("mntNetht") && !item.get("mntNetht").isNull()) {
                            amount = item.get("mntNetht").asDouble();
                        }
                        totalRevenue += amount;

                        String docType = "BC";
                        if (item.has("codeClasseDocument") && !item.get("codeClasseDocument").isNull()) {
                            docType = item.get("codeClasseDocument").asText().trim();
                        } else if (item.has("libelleClasseDocument") && !item.get("libelleClasseDocument").isNull()) {
                            String lib = item.get("libelleClasseDocument").asText().toLowerCase();
                            if (lib.contains("commande")) docType = "BC";
                            else if (lib.contains("préparation") || lib.contains("preparation")) docType = "BP";
                            else if (lib.contains("sortie")) docType = "BS";
                        }

                        Map<String, Object> typeMap = byType.computeIfAbsent(docType, k -> {
                            Map<String, Object> m = new HashMap<>();
                            m.put("type", k);
                            m.put("count", 0L);
                            m.put("revenue", 0.0);
                            return m;
                        });
                        typeMap.put("count", (long) typeMap.get("count") + 1);
                        typeMap.put("revenue", (double) typeMap.get("revenue") + amount);

                        String status = "Inconnu";
                        if (item.has("libelleEtatDoc") && !item.get("libelleEtatDoc").isNull()) {
                            status = item.get("libelleEtatDoc").asText().trim();
                        }
                        Map<String, Object> statusMap = byStatus.computeIfAbsent(status, k -> {
                            Map<String, Object> m = new HashMap<>();
                            m.put("status", k);
                            m.put("count", 0L);
                            return m;
                        });
                        statusMap.put("count", (long) statusMap.get("count") + 1);

                        String docDateStr = null;
                        if (item.has("dateDocument") && !item.get("dateDocument").isNull()) {
                            docDateStr = item.get("dateDocument").asText();
                        } else if (item.has("dateCreation") && !item.get("dateCreation").isNull()) {
                            docDateStr = item.get("dateCreation").asText();
                        }

                        if (docDateStr != null && !docDateStr.isBlank()) {
                            try {
                                LocalDateTime docTime = LocalDateTime.parse(docDateStr.substring(0, 19));
                                String timelineKey = getTimelineKey(docTime, groupBy);
                                docRevenueTimeline.put(timelineKey, docRevenueTimeline.getOrDefault(timelineKey, 0.0) + amount);
                                docCountTimeline.put(timelineKey, docCountTimeline.getOrDefault(timelineKey, 0L) + 1);
                            } catch (Exception ex) {
                                // Ignore date parsing error for timeline
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch/parse ERP documents", e);
        }

        // 5. Build Consolidated Grouped Timeline Map
        Map<String, Map<String, Object>> timelineMap = new TreeMap<>();
        if ("HOUR".equals(groupBy)) {
            for (int i = 0; i < 24; i++) {
                String key = String.valueOf(i);
                timelineMap.put(key, createEmptyTimelineItem(formatLabel(key, groupBy)));
            }
        }

        for (Map<String, Object> map : scansGrouped) {
            String key = getGroupKey(map, groupBy);
            long count = ((Number) map.get("count")).longValue();
            Map<String, Object> item = timelineMap.computeIfAbsent(key, k -> createEmptyTimelineItem(formatLabel(k, groupBy)));
            item.put("scans", count);
        }

        for (Map<String, Object> map : deletionsGrouped) {
            String key = getGroupKey(map, groupBy);
            long count = ((Number) map.get("count")).longValue();
            Map<String, Object> item = timelineMap.computeIfAbsent(key, k -> createEmptyTimelineItem(formatLabel(k, groupBy)));
            item.put("deletions", count);
        }

        for (Map<String, Object> map : checklistsGrouped) {
            String key = getGroupKey(map, groupBy);
            long count = ((Number) map.get("count")).longValue();
            Map<String, Object> item = timelineMap.computeIfAbsent(key, k -> createEmptyTimelineItem(formatLabel(k, groupBy)));
            item.put("checklists", count);
        }

        for (Map.Entry<String, Double> entry : docRevenueTimeline.entrySet()) {
            String key = entry.getKey();
            double rev = entry.getValue();
            Map<String, Object> item = timelineMap.computeIfAbsent(key, k -> createEmptyTimelineItem(formatLabel(k, groupBy)));
            item.put("revenue", rev);
        }

        for (Map.Entry<String, Long> entry : docCountTimeline.entrySet()) {
            String key = entry.getKey();
            long cnt = entry.getValue();
            Map<String, Object> item = timelineMap.computeIfAbsent(key, k -> createEmptyTimelineItem(formatLabel(k, groupBy)));
            item.put("documents", cnt);
        }

        List<Map<String, Object>> timelineList = new ArrayList<>(timelineMap.values());
        if (!"HOUR".equals(groupBy)) {
            timelineList.sort((a, b) -> {
                String labelA = (String) a.get("label");
                String labelB = (String) b.get("label");
                return labelA.compareTo(labelB);
            });
        }

        // 6. Aggregate Operator Performance
        List<Map<String, Object>> opLogPerformance = auditLogRepository.getOperatorPerformance(start, end);
        List<Map<String, Object>> opChecklistsCount = checklistResponseRepository.getOperatorChecklistsCount(start, end);
        Map<String, Map<String, Object>> operatorsMap = new HashMap<>();

        for (Map<String, Object> map : opLogPerformance) {
            String userId = (String) map.get("userId");
            if (userId == null || userId.isBlank()) continue;

            long scans = ((Number) map.get("scans")).longValue();
            long deletions = ((Number) map.get("deletions")).longValue();

            Map<String, Object> opData = operatorsMap.computeIfAbsent(userId, k -> {
                Map<String, Object> m = new HashMap<>();
                m.put("userId", k);
                m.put("scans", 0L);
                m.put("deletions", 0L);
                m.put("checklists", 0L);
                m.put("accuracy", 100.0);
                return m;
            });
            opData.put("scans", scans);
            opData.put("deletions", deletions);

            double accuracy = 100.0;
            if (scans + deletions > 0) {
                accuracy = ((double) scans / (scans + deletions)) * 100.0;
            }
            opData.put("accuracy", Math.round(accuracy * 10.0) / 10.0);
        }

        for (Map<String, Object> map : opChecklistsCount) {
            String userId = (String) map.get("userId");
            if (userId == null || userId.isBlank()) continue;

            long checklists = ((Number) map.get("count")).longValue();

            Map<String, Object> opData = operatorsMap.computeIfAbsent(userId, k -> {
                Map<String, Object> m = new HashMap<>();
                m.put("userId", k);
                m.put("scans", 0L);
                m.put("deletions", 0L);
                m.put("checklists", 0L);
                m.put("accuracy", 100.0);
                return m;
            });
            opData.put("checklists", checklists);
        }

        List<Map<String, Object>> operatorPerformance = new ArrayList<>(operatorsMap.values());
        operatorPerformance.sort((a, b) -> {
            Long scansA = (Long) a.get("scans");
            Long scansB = (Long) b.get("scans");
            return scansB.compareTo(scansA);
        });

        // 7. Package Response
        Map<String, Object> summary = new HashMap<>();
        summary.put("scansCount", scansToday);
        summary.put("deletionsCount", deletionsToday);
        summary.put("checklistResponsesCount", checklistResponsesToday);
        summary.put("totalCommands", totalCommands);
        summary.put("totalRevenue", totalRevenue);

        double avgAccuracy = 100.0;
        if (scansToday + deletionsToday > 0) {
            avgAccuracy = ((double) scansToday / (scansToday + deletionsToday)) * 100.0;
        }
        summary.put("avgAccuracy", Math.round(avgAccuracy * 10.0) / 10.0);

        Map<String, Object> documentStats = new HashMap<>();
        documentStats.put("byType", new ArrayList<>(byType.values()));
        documentStats.put("byStatus", new ArrayList<>(byStatus.values()));

        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("summary", summary);
        responseMap.put("documentStats", documentStats);
        responseMap.put("timeline", timelineList);
        responseMap.put("operatorPerformance", operatorPerformance);

        return ResponseEntity.ok(responseMap);
    }

    @GetMapping("/feed")
    public ResponseEntity<org.springframework.data.domain.Page<com.asm.dux.infrastructure.entity.AuditLog>> getFeed(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        log.info("GET /api/dux/dashboard/feed?page={}&size={}", page, size);
        org.springframework.data.domain.Page<com.asm.dux.infrastructure.entity.AuditLog> feed =
                auditLogRepository.findAllByOrderByTimestampDesc(org.springframework.data.domain.PageRequest.of(page, size));
        return ResponseEntity.ok(feed);
    }

    // ─── Private Helper Methods ───────────────────────────────────────────────

    private String getTimelineKey(LocalDateTime dt, String groupBy) {
        if ("HOUR".equals(groupBy)) {
            return String.valueOf(dt.getHour());
        } else if ("MONTH".equals(groupBy)) {
            return String.format("%04d-%02d", dt.getYear(), dt.getMonthValue());
        } else {
            return dt.toLocalDate().toString();
        }
    }

    private String getGroupKey(Map<String, Object> map, String groupBy) {
        if ("HOUR".equals(groupBy)) {
            Object hour = map.get("hour");
            if (hour == null) hour = map.get("interval");
            return String.valueOf(hour);
        } else if ("MONTH".equals(groupBy)) {
            Number year = (Number) map.get("year");
            Number month = (Number) map.get("month");
            return String.format("%04d-%02d", year.intValue(), month.intValue());
        } else {
            Object dateObj = map.get("date");
            if (dateObj == null) dateObj = map.get("interval");
            return dateObj.toString();
        }
    }

    private Map<String, Object> createEmptyTimelineItem(String label) {
        Map<String, Object> map = new HashMap<>();
        map.put("label", label);
        map.put("scans", 0L);
        map.put("deletions", 0L);
        map.put("checklists", 0L);
        map.put("revenue", 0.0);
        map.put("documents", 0L);
        return map;
    }

    private String formatLabel(String key, String groupBy) {
        if ("HOUR".equals(groupBy)) {
            try {
                int hour = Integer.parseInt(key);
                return String.format("%02dh", hour);
            } catch (Exception e) {
                return key;
            }
        } else if ("MONTH".equals(groupBy)) {
            if (key.length() >= 7) {
                return key.substring(5, 7) + "/" + key.substring(2, 4);
            }
            return key;
        } else {
            if (key.length() >= 10) {
                return key.substring(8, 10) + "/" + key.substring(5, 7);
            }
            return key;
        }
    }
}
