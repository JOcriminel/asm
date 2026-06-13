package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetDocumentByIdUseCase;
import com.asm.dux.domain.usecase.EditLigneUseCase;
import com.asm.dux.infrastructure.entity.AuditLog;
import com.asm.dux.infrastructure.repository.AuditLogRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

/**
 * REST controller for single-document retrieval and editing.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class DocumentController {

    private final GetDocumentByIdUseCase getDocumentByIdUseCase;
    private final EditLigneUseCase editLigneUseCase;
    private final AuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;

    public DocumentController(GetDocumentByIdUseCase getDocumentByIdUseCase, 
                              EditLigneUseCase editLigneUseCase,
                              AuditLogRepository auditLogRepository) {
        this.getDocumentByIdUseCase = getDocumentByIdUseCase;
        this.editLigneUseCase = editLigneUseCase;
        this.auditLogRepository = auditLogRepository;
        this.objectMapper = new ObjectMapper();
    }

    @GetMapping("/document/{id}")
    public ResponseEntity<String> getDocument(@PathVariable String id) {
        log.info("GET /document/{}", id);
        String result = getDocumentByIdUseCase.execute(id);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/Document/editLigne")
    public ResponseEntity<String> editLigne(@RequestBody String body) {
        log.info("POST /Document/editLigne");
        String result = editLigneUseCase.execute(body);

        // Audit Trail Extraction
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String userId = auth != null ? auth.getName() : "system";

            JsonNode root = objectMapper.readTree(body);
            JsonNode data = root.path("data");
            if (!data.isMissingNode()) {
                String documentId = data.path("iddocument").asText(null);
                String lineId = data.path("id").asText(null);
                JsonNode listNumSerie = data.path("listNumSerie");
                if (listNumSerie.isArray()) {
                    for (JsonNode snNode : listNumSerie) {
                        String serialNumber = snNode.path("NumSerie").asText(null);
                        if (serialNumber != null && !serialNumber.isEmpty()) {
                            AuditLog audit = AuditLog.builder()
                                    .action("SCAN")
                                    .documentId(documentId)
                                    .lineId(lineId)
                                    .serialNumber(serialNumber)
                                    .timestamp(LocalDateTime.now())
                                    .userId(userId)
                                    .build();
                            auditLogRepository.save(audit);
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to write audit log for SCAN", e);
        }

        return ResponseEntity.ok(result);
    }
}
