package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetNumSerieByBonSortUseCase;
import com.asm.dux.domain.usecase.DeleteNumSerieUseCase;
import com.asm.dux.infrastructure.entity.AuditLog;
import com.asm.dux.infrastructure.repository.AuditLogRepository;
import com.asm.dux.infrastructure.db.entity.NumSerieRecord;
import com.asm.dux.infrastructure.db.repository.NumSerieRecordRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

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
    private final NumSerieRecordRepository numSerieRecordRepository;

    public NumSerieController(
            GetNumSerieByBonSortUseCase getNumSerieByBonSortUseCase,
            DeleteNumSerieUseCase deleteNumSerieUseCase,
            AuditLogRepository auditLogRepository,
            NumSerieRecordRepository numSerieRecordRepository) {
        this.getNumSerieByBonSortUseCase = getNumSerieByBonSortUseCase;
        this.deleteNumSerieUseCase = deleteNumSerieUseCase;
        this.auditLogRepository = auditLogRepository;
        this.numSerieRecordRepository = numSerieRecordRepository;
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

    @GetMapping("/numSerie/check/{sn}")
    public ResponseEntity<String> checkNumSerie(@PathVariable String sn) {
        log.info("GET /numSerie/check/{}", sn);
        List<NumSerieRecord> records = numSerieRecordRepository.findByNumSerieIgnoreCase(sn);
        if (!records.isEmpty()) {
            return ResponseEntity.ok("{\"exists\": true, \"documentId\": \"" + records.get(0).getDocumentId() + "\"}");
        } else {
            return ResponseEntity.ok("{\"exists\": false}");
        }
    }

    @PostMapping("/numSerie/track")
    public ResponseEntity<String> trackNumSerie(@RequestParam String sn, @RequestParam String documentId) {
        log.info("POST /numSerie/track sn={} documentId={}", sn, documentId);
        numSerieRecordRepository.save(new NumSerieRecord(sn.trim().toLowerCase(), documentId));
        return ResponseEntity.ok("{\"success\": true}");
    }

    @DeleteMapping("/numSerie/untrack/{sn}")
    public ResponseEntity<String> untrackNumSerie(@PathVariable String sn) {
        log.info("DELETE /numSerie/untrack/{}", sn);
        List<NumSerieRecord> records = numSerieRecordRepository.findByNumSerieIgnoreCase(sn);
        numSerieRecordRepository.deleteAll(records);
        return ResponseEntity.ok("{\"success\": true}");
    }
}
