package com.asm.dux.web;

import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.domain.TimetreeAuditLog;
import com.asm.dux.timetree.repository.TimetreeAuditLogRepository;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.StringWriter;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/timetree/admin/audit-logs", "/api/dux/api/timetree/admin/audit-logs"})
@RequiredArgsConstructor
public class AuditController {

    private final TimetreeAuditLogRepository auditLogRepository;
    private final TimetreeSecurityService securityService;

    @GetMapping
    public ResponseEntity<?> getAuditLogs(
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) Long entityId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(required = false) String search) {

        Member current = securityService.getCurrentMember();
        if (current == null || !("ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès réservé aux administrateurs");
        }

        List<TimetreeAuditLog> allLogs = auditLogRepository.findAll();
        List<TimetreeAuditLog> filtered = allLogs.stream()
                .filter(log -> username == null || username.trim().isEmpty() || log.getUsername().equalsIgnoreCase(username.trim()))
                .filter(log -> action == null || action.trim().isEmpty() || log.getAction().equalsIgnoreCase(action.trim()))
                .filter(log -> entityType == null || entityType.trim().isEmpty() || log.getEntityType().equalsIgnoreCase(entityType.trim()))
                .filter(log -> entityId == null || log.getEntityId().equals(entityId))
                .filter(log -> startDate == null || log.getActionDate().isAfter(startDate) || log.getActionDate().isEqual(startDate))
                .filter(log -> endDate == null || log.getActionDate().isBefore(endDate) || log.getActionDate().isEqual(endDate))
                .filter(log -> {
                    if (search == null || search.trim().isEmpty()) return true;
                    String s = search.toLowerCase();
                    return (log.getUsername() != null && log.getUsername().toLowerCase().contains(s))
                            || (log.getAction() != null && log.getAction().toLowerCase().contains(s))
                            || (log.getEntityType() != null && log.getEntityType().toLowerCase().contains(s))
                            || (log.getDetails() != null && log.getDetails().toLowerCase().contains(s));
                })
                .sorted((a, b) -> b.getActionDate().compareTo(a.getActionDate()))
                .collect(Collectors.toList());

        return ResponseEntity.ok(filtered);
    }

    @GetMapping("/export")
    public ResponseEntity<?> exportAuditLogsCsv(
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) Long entityId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(required = false) String search) {

        Member current = securityService.getCurrentMember();
        if (current == null || !("ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès réservé aux administrateurs");
        }

        @SuppressWarnings("unchecked")
        List<TimetreeAuditLog> filtered = (List<TimetreeAuditLog>) getAuditLogs(
                username, action, entityType, entityId, startDate, endDate, search).getBody();

        if (filtered == null) {
            filtered = new ArrayList<>();
        }

        StringWriter sw = new StringWriter();
        sw.write("ID,ActionDate,Username,Action,EntityType,EntityID,Result,IPAddress,Details\n");
        for (TimetreeAuditLog log : filtered) {
            sw.write(String.format("%d,%s,%s,%s,%s,%s,%s,%s,%s\n",
                    log.getId(),
                    log.getActionDate().toString(),
                    escapeCsv(log.getUsername()),
                    escapeCsv(log.getAction()),
                    escapeCsv(log.getEntityType()),
                    log.getEntityId() != null ? log.getEntityId().toString() : "",
                    escapeCsv(log.getResult()),
                    escapeCsv(log.getIpAddress()),
                    escapeCsv(log.getDetails())
            ));
        }

        byte[] bytes = sw.toString().getBytes();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.setContentDispositionFormData("attachment", "audit_logs.csv");
        headers.setContentLength(bytes.length);

        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }
}
