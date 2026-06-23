package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.TimetreeAuditLog;
import com.asm.dux.timetree.repository.TimetreeAuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditService {

    private final TimetreeAuditLogRepository auditLogRepository;

    public void logAction(String username, String action, String entityType, Long entityId, String result, String details) {
        String ipAddress = "0.0.0.0";
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                HttpServletRequest request = attributes.getRequest();
                ipAddress = request.getRemoteAddr();
            }
        } catch (Exception e) {
            log.warn("Failed to retrieve request IP address", e);
        }

        TimetreeAuditLog logEntry = TimetreeAuditLog.builder()
                .username(username)
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .result(result)
                .ipAddress(ipAddress)
                .actionDate(LocalDateTime.now())
                .details(details)
                .build();
        auditLogRepository.save(logEntry);
        log.info("Audit log saved: action={} user={} entityType={} entityId={} result={}", action, username, entityType, entityId, result);
    }
}
