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
import com.asm.dux.infrastructure.repository.DocumentValidationProofRepository;

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
    private final DocumentValidationProofRepository documentValidationProofRepository;

    public DocumentController(GetDocumentByIdUseCase getDocumentByIdUseCase,
                              EditLigneUseCase editLigneUseCase,
                              EditDocumentUseCase editDocumentUseCase,
                              ChangeDocumentStatusUseCase changeDocumentStatusUseCase,
                              AuditLogRepository auditLogRepository,
                              JdbcTemplate jdbcTemplate,
                              DocumentValidationProofRepository documentValidationProofRepository) {
        this.getDocumentByIdUseCase = getDocumentByIdUseCase;
        this.editLigneUseCase = editLigneUseCase;
        this.editDocumentUseCase = editDocumentUseCase;
        this.changeDocumentStatusUseCase = changeDocumentStatusUseCase;
        this.auditLogRepository = auditLogRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.documentValidationProofRepository = documentValidationProofRepository;
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
            @PathVariable String statusId,
            @RequestBody(required = false) java.util.Map<String, Object> body) {
        log.info("POST /document/changeStatus/{}/{} with body: {}", id, statusId, body != null ? "present" : "absent");
        
        if (body != null) {
            try {
                String signatureBase64 = (String) body.get("signatureBase64");
                String photoBase64 = (String) body.get("photoBase64");
                String docType = (String) body.getOrDefault("docType", "BP");
                
                String signaturePath = null;
                String photoPath = null;
                
                if (signatureBase64 != null && !signatureBase64.isEmpty()) {
                    signaturePath = saveBase64File(signatureBase64, "validation", "signature_" + id, ".png");
                }
                if (photoBase64 != null && !photoBase64.isEmpty()) {
                    photoPath = saveBase64File(photoBase64, "validation", "photo_" + id, ".jpg");
                }
                
                if (signaturePath != null || photoPath != null) {
                    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
                    String userId = "system";
                    if (auth != null) {
                        userId = auth.getName();
                        if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                            org.springframework.security.oauth2.jwt.Jwt jwt = ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                            String preferredUsername = jwt.getClaimAsString("preferred_username");
                            if (preferredUsername != null && !preferredUsername.isEmpty()) {
                                userId = preferredUsername;
                            }
                        }
                    }
                    
                    com.asm.dux.infrastructure.entity.DocumentValidationProof proof = com.asm.dux.infrastructure.entity.DocumentValidationProof.builder()
                            .documentId(id)
                            .documentType(docType)
                            .signaturePath(signaturePath)
                            .photoPath(photoPath)
                            .validatedBy(userId)
                            .validatedAt(LocalDateTime.now())
                            .build();
                    
                    documentValidationProofRepository.save(proof);
                    log.info("Saved validation proof for document id={}, type={}", id, docType);
                }
            } catch (Exception e) {
                log.error("Failed to save validation proof", e);
            }
        }
        
        String result = changeDocumentStatusUseCase.execute(id, statusId);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/document/{id}/validation-proof")
    public ResponseEntity<?> getValidationProof(@PathVariable String id) {
        log.info("GET /document/{}/validation-proof", id);
        java.util.List<com.asm.dux.infrastructure.entity.DocumentValidationProof> proofs = 
                documentValidationProofRepository.findAllByDocumentIdOrderByValidatedAtDesc(id);
        if (proofs.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        com.asm.dux.infrastructure.entity.DocumentValidationProof proof = proofs.get(0);
        
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("id", proof.getId());
        map.put("documentId", proof.getDocumentId());
        map.put("documentType", proof.getDocumentType());
        map.put("validatedBy", proof.getValidatedBy());
        map.put("validatedAt", proof.getValidatedAt().toString());
        
        String baseUrl = getBaseUrl();
        if (proof.getSignaturePath() != null) {
            map.put("signatureUrl", baseUrl + "/api/timetree/local-download?key=" + proof.getSignaturePath());
        }
        if (proof.getPhotoPath() != null) {
            map.put("photoUrl", baseUrl + "/api/timetree/local-download?key=" + proof.getPhotoPath());
        }
        
        return ResponseEntity.ok(map);
    }

    private String saveBase64File(String base64Str, String subFolder, String fileNamePrefix, String extension) throws java.io.IOException {
        if (base64Str == null || base64Str.isEmpty()) {
            return null;
        }
        if (base64Str.contains(",")) {
            base64Str = base64Str.substring(base64Str.indexOf(",") + 1);
        }
        byte[] bytes = java.util.Base64.getDecoder().decode(base64Str);
        
        String fileName = fileNamePrefix + "_" + java.util.UUID.randomUUID().toString() + extension;
        java.nio.file.Path targetDir = java.nio.file.Paths.get("uploads/attachments").resolve(subFolder).toAbsolutePath().normalize();
        java.nio.file.Files.createDirectories(targetDir);
        java.nio.file.Path targetFile = targetDir.resolve(fileName);
        java.nio.file.Files.write(targetFile, bytes);
        
        return subFolder + "/" + fileName;
    }

    private String getBaseUrl() {
        try {
            org.springframework.web.context.request.RequestAttributes attributes = 
                org.springframework.web.context.request.RequestContextHolder.getRequestAttributes();
            if (attributes instanceof org.springframework.web.context.request.ServletRequestAttributes) {
                jakarta.servlet.http.HttpServletRequest request = 
                    ((org.springframework.web.context.request.ServletRequestAttributes) attributes).getRequest();
                
                String host = request.getHeader("Host");
                if (host == null || host.isBlank()) {
                    host = request.getServerName() + ":" + request.getServerPort();
                }
                
                String forwardedHost = request.getHeader("X-Forwarded-Host");
                if (forwardedHost != null && !forwardedHost.isBlank()) {
                    host = forwardedHost;
                }
                
                String scheme = request.getScheme();
                String forwardedProto = request.getHeader("X-Forwarded-Proto");
                if (forwardedProto != null && !forwardedProto.isBlank()) {
                    scheme = forwardedProto;
                }
                
                String requestUri = request.getRequestURI();
                String contextPrefix = "";
                if (requestUri != null && requestUri.startsWith("/api/dux")) {
                    contextPrefix = "/api/dux";
                }
                
                return scheme + "://" + host + contextPrefix + request.getContextPath();
            }
        } catch (Exception e) {
            log.error("Failed to determine base URL", e);
        }
        return "http://localhost:9090";
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

