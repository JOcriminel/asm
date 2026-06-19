package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetDocumentByIdUseCase;
import com.asm.dux.domain.usecase.EditLigneUseCase;
import com.asm.dux.domain.usecase.EditDocumentUseCase;
import com.asm.dux.domain.usecase.ChangeDocumentStatusUseCase;
import com.asm.dux.infrastructure.entity.AuditLog;
import com.asm.dux.infrastructure.repository.AuditLogRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
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
    private final EditDocumentUseCase editDocumentUseCase;
    private final ChangeDocumentStatusUseCase changeDocumentStatusUseCase;
    private final AuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;
    private final JdbcTemplate jdbcTemplate;

    public DocumentController(GetDocumentByIdUseCase getDocumentByIdUseCase,
                              EditLigneUseCase editLigneUseCase,
                              EditDocumentUseCase editDocumentUseCase,
                              ChangeDocumentStatusUseCase changeDocumentStatusUseCase,
                              AuditLogRepository auditLogRepository,
                              JdbcTemplate jdbcTemplate) {
        this.getDocumentByIdUseCase = getDocumentByIdUseCase;
        this.editLigneUseCase = editLigneUseCase;
        this.editDocumentUseCase = editDocumentUseCase;
        this.changeDocumentStatusUseCase = changeDocumentStatusUseCase;
        this.auditLogRepository = auditLogRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = new ObjectMapper();
    }

    @GetMapping("/document/{id}")
    public ResponseEntity<String> getDocument(@PathVariable String id) {
        log.info("GET /document/{}", id);
        String result = getDocumentByIdUseCase.execute(id);
        
        try {
            JsonNode rootNode = objectMapper.readTree(result);
            JsonNode articlesNode = rootNode.path("listeArticles");
            if (articlesNode.isArray()) {
                for (JsonNode articleNode : articlesNode) {
                    if (articleNode instanceof ObjectNode) {
                        ObjectNode objNode = (ObjectNode) articleNode;
                        String idArticle = objNode.path("idArticle").asText(null);
                        java.util.Map<java.lang.String, java.lang.Object> familyData = null;
                        if (idArticle != null && !idArticle.isEmpty()) {
                            try {
                                familyData = jdbcTemplate.queryForMap(
                                    "SELECT codeFamille, libelleFamille FROM P_Article WHERE id = ?",
                                    idArticle
                                );
                            } catch (Exception e) {
                                String codeArticle = objNode.path("codeArticle").asText(null);
                                if (codeArticle != null && !codeArticle.isEmpty()) {
                                    try {
                                        familyData = jdbcTemplate.queryForMap(
                                            "SELECT codeFamille, libelleFamille FROM P_Article WHERE code = ?",
                                            codeArticle
                                        );
                                    } catch (Exception ex) {
                                        // Ignore
                                    }
                                }
                            }
                        }
                        if (familyData != null) {
                            java.lang.String codeFamille = (java.lang.String) familyData.get("codeFamille");
                            java.lang.String libelleFamille = (java.lang.String) familyData.get("libelleFamille");
                            if (codeFamille != null) {
                                objNode.put("codeFamille", codeFamille.trim());
                                objNode.put("idFamille", codeFamille.trim());
                            }
                            if (libelleFamille != null) {
                                objNode.put("libelleFamille", libelleFamille.trim());
                            }
                        }
                    }
                }
            }
            result = objectMapper.writeValueAsString(rootNode);
        } catch (Exception e) {
            log.error("Failed to enrich document with family codes", e);
        }
        
        log.info("DOCUMENT JSON: {}", result);
        return ResponseEntity.ok(result);
    }

    /**
     * Dedicated minimal endpoint to change document status.
     * The Java backend handles fetching the document and building
     * the correct FormData payload for the PHP backend.
     * Dart only needs to send: documentId + statusId.
     */
    @PostMapping("/document/changeStatus/{id}/{statusId}")
    public ResponseEntity<String> changeDocumentStatus(
            @PathVariable String id,
            @PathVariable String statusId) {
        log.info("POST /document/changeStatus/{}/{}", id, statusId);
        String result = changeDocumentStatusUseCase.execute(id, statusId);
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

    @PostMapping("/document/edit/{id}")
    public ResponseEntity<String> editDocument(@PathVariable String id, @RequestBody String body) {
        log.info("POST /document/edit/{}", id);
        String result = editDocumentUseCase.execute(id, body);
        return ResponseEntity.ok(result);
    }
}

