package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetNumSerieByBonSortUseCase;
import com.asm.dux.domain.usecase.DeleteNumSerieUseCase;
import com.asm.dux.infrastructure.entity.AuditLog;
import com.asm.dux.infrastructure.repository.AuditLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

/**
 * REST controller for DUX ERP serial number queries and actions.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class NumSerieController {

    private final GetNumSerieByBonSortUseCase getNumSerieByBonSortUseCase;
    private final DeleteNumSerieUseCase deleteNumSerieUseCase;
    private final AuditLogRepository auditLogRepository;

    public NumSerieController(
            GetNumSerieByBonSortUseCase getNumSerieByBonSortUseCase,
            DeleteNumSerieUseCase deleteNumSerieUseCase,
            AuditLogRepository auditLogRepository) {
        this.getNumSerieByBonSortUseCase = getNumSerieByBonSortUseCase;
        this.deleteNumSerieUseCase = deleteNumSerieUseCase;
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/numSerie/getByNumBonSort/{idlignedocument}")
    public ResponseEntity<String> getByNumBonSort(@PathVariable String idlignedocument) {
        log.info("GET /numSerie/getByNumBonSort/{}", idlignedocument);
        String result = getNumSerieByBonSortUseCase.execute(idlignedocument);
        return ResponseEntity.ok(result);
    }

    @DeleteMapping("/numSerie/delete/{id}")
    public ResponseEntity<String> deleteNumSerie(@PathVariable String id) {
        log.info("DELETE /numSerie/delete/{}", id);
        String result = deleteNumSerieUseCase.execute(id);

        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth != null ? auth.getName() : "system";

            AuditLog audit = AuditLog.builder()
                    .action("DELETE")
                    .serialNumber("ID=" + id) // We might only have the ID here
                    .timestamp(LocalDateTime.now())
                    .userId(userId)
                    .build();
            auditLogRepository.save(audit);
        } catch (Exception e) {
            log.error("Failed to write audit log for DELETE", e);
        }

        return ResponseEntity.ok(result);
    }
}
