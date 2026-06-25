package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequiredArgsConstructor
public class AttachmentController {

    private final EventRepository eventRepository;
    private final EventMessageRepository eventMessageRepository;
    private final EventAttachmentRepository eventAttachmentRepository;
    private final S3StorageService s3StorageService;
    private final TimetreeSecurityService securityService;
    private final NotificationService notificationService;
    private final com.asm.dux.timetree.service.AuditService auditService;
    private final AttachmentMetricsService metricsService;

    @Value("${timetree.upload.max-file-size:52428800}")
    private long maxFileSize;

    @Value("${timetree.upload.allowed-mime-types:application/pdf,image/png,image/jpeg,image/gif,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/plain,application/zip}")
    private String allowedMimeTypesString;

    private Set<String> getAllowedMimeTypes() {
        if (allowedMimeTypesString == null || allowedMimeTypesString.isBlank()) {
            return Collections.emptySet();
        }
        return Arrays.stream(allowedMimeTypesString.split(","))
                .map(String::trim)
                .map(String::toLowerCase)
                .collect(Collectors.toSet());
    }

    // 1. Get Pre-signed PUT URL for uploading
    @PostMapping({"/api/timetree/events/{id}/attachments/presigned-upload", "/api/dux/api/timetree/events/{id}/attachments/presigned-upload"})
    public ResponseEntity<?> getPresignedUploadUrl(
            @PathVariable Long id,
            @RequestBody PresignedUploadRequest request) {
        log.info("POST presigned upload URL for event id={}, fileName={}", id, request.getFileName());

        Member current = securityService.getCurrentMember();
        if (current == null) {
            metricsService.recordUploadAttempt("unauthorized", request.getContentType());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            metricsService.recordUploadAttempt("not_found", request.getContentType());
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            metricsService.recordUploadAttempt("forbidden", request.getContentType());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        // Validation: File size
        if (request.getFileSize() == null || request.getFileSize() <= 0) {
            metricsService.recordUploadAttempt("invalid_size", request.getContentType());
            return ResponseEntity.badRequest().body("Taille de fichier invalide");
        }
        if (request.getFileSize() > maxFileSize) {
            metricsService.recordUploadAttempt("size_limit_exceeded", request.getContentType());
            return ResponseEntity.badRequest().body("Le fichier dépasse la limite autorisée");
        }

        // Validation: MIME type
        String contentType = request.getContentType() != null ? request.getContentType() : "application/octet-stream";
        Set<String> allowedTypes = getAllowedMimeTypes();
        if (!allowedTypes.contains(contentType.toLowerCase())) {
            metricsService.recordUploadAttempt("invalid_mime", contentType);
            return ResponseEntity.badRequest().body("Type de fichier non autorisé: " + contentType);
        }

        try {
            // Generate S3 Key: events/{eventId}/{uuid}/{fileName}
            String uuid = UUID.randomUUID().toString();
            String cleanName = request.getFileName().replaceAll("[^a-zA-Z0-9.-]", "_");
            String s3Key = "events/" + id + "/" + uuid + "/" + cleanName;

            // Generate Pre-signed URL (valid for 15 minutes)
            String uploadUrl = s3StorageService.generatePresignedUploadUrl(s3Key, contentType, 15);

            PresignedUploadResponse response = PresignedUploadResponse.builder()
                    .uploadUrl(uploadUrl)
                    .s3Key(s3Key)
                    .fileName(request.getFileName())
                    .fileSize(request.getFileSize())
                    .contentType(contentType)
                    .build();

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to generate presigned upload URL", e);
            metricsService.recordUploadAttempt("error", contentType);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    // 2. Confirm Upload after direct upload to S3
    @PostMapping({"/api/timetree/events/{id}/attachments/confirm", "/api/dux/api/timetree/events/{id}/attachments/confirm"})
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> confirmUpload(
            @PathVariable Long id,
            @RequestBody ConfirmUploadRequest request) {
        log.info("POST confirm upload for event id={}, key={}", id, request.getS3Key());

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        // Security Validation: S3 key matches pattern events/{eventId}/...
        if (request.getS3Key() == null || !request.getS3Key().startsWith("events/" + id + "/")) {
            metricsService.recordUploadAttempt("invalid_s3_key", request.getContentType());
            return ResponseEntity.badRequest().body("Clé S3 invalide pour cet événement");
        }

        // Verify object existence and size in S3
        if (!s3StorageService.verifyObjectExists(request.getS3Key())) {
            metricsService.recordUploadAttempt("s3_object_not_found", request.getContentType());
            return ResponseEntity.badRequest().body("Le fichier n'a pas été trouvé dans le stockage objet");
        }

        long actualSize = s3StorageService.getObjectSize(request.getS3Key());
        if (request.getFileSize() != null && request.getFileSize() != actualSize) {
            log.warn("Reported size {} does not match S3 actual size {}", request.getFileSize(), actualSize);
        }

        try {
            // Save metadata to database
            EventAttachment attachment = EventAttachment.builder()
                    .event(event)
                    .fileName(request.getFileName())
                    .filePath(request.getS3Key()) // filePath stores the S3 key
                    .fileType(request.getContentType())
                    .uploadedBy(current.getUsername())
                    .uploadedAt(LocalDateTime.now())
                    .build();

            attachment.setOriginalFilename(request.getFileName());
            String storedFilename = request.getS3Key().substring(request.getS3Key().lastIndexOf('/') + 1);
            attachment.setStoredFilename(storedFilename);
            attachment.setFileSize(actualSize);

            EventAttachment saved = eventAttachmentRepository.save(attachment);

            auditService.logAction(current.getUsername(), "UPLOAD_ATTACHMENT", "EventAttachment", saved.getId(), "SUCCESS", "Uploaded S3 file: " + saved.getFileName() + " to event: " + event.getTitle());

            // Generate System Message
            EventMessage systemMsg = EventMessage.builder()
                    .event(event)
                    .member(current)
                    .message("A ajouté la pièce jointe: " + request.getFileName())
                    .messageType(EventMessage.MessageType.SYSTEM)
                    .metadata("ATTACHMENT_UPLOADED:" + saved.getId())
                    .sentAt(LocalDateTime.now())
                    .build();
            eventMessageRepository.save(systemMsg);

            // Trigger Notifications
            if (event.getCalendar() != null && event.getCalendar().getMembers() != null) {
                for (Member m : event.getCalendar().getMembers()) {
                    if (!m.getId().equals(current.getId())) {
                        notificationService.triggerNotification(
                                m,
                                "Nouvelle pièce jointe dans " + event.getTitle(),
                                current.getFullName() + " a partagé un fichier: " + request.getFileName(),
                                "NEW_ATTACHMENT",
                                "ATTACHMENT",
                                saved.getId(),
                                "CREATED"
                        );
                    }
                }
            }

            metricsService.recordUploadAttempt("success", request.getContentType());
            metricsService.recordUploadSize(actualSize);

            return ResponseEntity.status(HttpStatus.CREATED).body(mapToAttachmentMap(saved));

        } catch (Exception e) {
            log.error("Failed to confirm attachment upload", e);
            metricsService.recordUploadAttempt("error", request.getContentType());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    // 3. Get Pre-signed GET URL for downloading
    @GetMapping({"/api/timetree/events/attachments/presigned-download/{id}", "/api/dux/api/timetree/events/attachments/presigned-download/{id}"})
    public ResponseEntity<?> getPresignedDownloadUrl(@PathVariable Long id) {
        log.info("GET presigned download URL for attachment id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            metricsService.recordDownloadAttempt("unauthorized");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<EventAttachment> attOpt = eventAttachmentRepository.findById(id);
        if (!attOpt.isPresent()) {
            metricsService.recordDownloadAttempt("not_found");
            return ResponseEntity.notFound().build();
        }
        EventAttachment attachment = attOpt.get();

        if (!securityService.canReadEvent(current, attachment.getEvent())) {
            metricsService.recordDownloadAttempt("forbidden");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        try {
            // Generate download URL valid for 15 minutes
            String downloadUrl = s3StorageService.generatePresignedDownloadUrl(attachment.getFilePath(), 15);
            metricsService.recordDownloadAttempt("success");
            return ResponseEntity.ok(new PresignedDownloadResponse(downloadUrl));
        } catch (Exception e) {
            log.error("Failed to generate presigned download URL", e);
            metricsService.recordDownloadAttempt("error");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors de la génération du lien");
        }
    }

    // 4. List attachments for an event
    @GetMapping({"/api/timetree/events/{id}/attachments", "/api/dux/api/timetree/events/{id}/attachments"})
    public ResponseEntity<?> getAttachments(@PathVariable Long id) {
        log.info("GET attachments list for event id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<Event> eventOpt = eventRepository.findById(id);
        if (!eventOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Event event = eventOpt.get();

        if (!securityService.canReadEvent(current, event)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        List<EventAttachment> list = eventAttachmentRepository.findAllByEventId(id);
        List<Map<String, Object>> response = list.stream().map(this::mapToAttachmentMap).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    // 5. Legacy download endpoint (HTTP 302 Redirect to pre-signed GET URL)
    @GetMapping({"/api/timetree/events/attachments/download/{id}", "/api/dux/api/timetree/events/attachments/download/{id}"})
    public ResponseEntity<?> downloadAttachment(@PathVariable Long id) {
        log.info("GET legacy download redirect for attachment id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            metricsService.recordDownloadAttempt("unauthorized");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<EventAttachment> attOpt = eventAttachmentRepository.findById(id);
        if (!attOpt.isPresent()) {
            metricsService.recordDownloadAttempt("not_found");
            return ResponseEntity.notFound().build();
        }
        EventAttachment attachment = attOpt.get();

        if (!securityService.canReadEvent(current, attachment.getEvent())) {
            metricsService.recordDownloadAttempt("forbidden");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        try {
            String downloadUrl = s3StorageService.generatePresignedDownloadUrl(attachment.getFilePath(), 15);
            metricsService.recordDownloadAttempt("success");
            return ResponseEntity.status(HttpStatus.FOUND)
                    .header(HttpHeaders.LOCATION, downloadUrl)
                    .build();
        } catch (Exception e) {
            log.error("Failed to redirect legacy download to presigned URL", e);
            metricsService.recordDownloadAttempt("error");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors de la redirection");
        }
    }

    // 6. Delete attachment from S3 and Database (soft-delete)
    @DeleteMapping({"/api/timetree/events/attachments/{id}", "/api/dux/api/timetree/events/attachments/{id}"})
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> deleteAttachment(@PathVariable Long id) {
        log.info("DELETE attachment id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            metricsService.recordDeleteAttempt("unauthorized");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<EventAttachment> attOpt = eventAttachmentRepository.findById(id);
        if (!attOpt.isPresent()) {
            metricsService.recordDeleteAttempt("not_found");
            return ResponseEntity.notFound().build();
        }
        EventAttachment attachment = attOpt.get();
        Event event = attachment.getEvent();

        if (!securityService.canWriteEvent(current, event.getCalendar().getId())) {
            metricsService.recordDeleteAttempt("forbidden");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission insuffisante");
        }

        try {
            // Delete object from S3
            s3StorageService.deleteObject(attachment.getFilePath());

            // Generate System Message
            EventMessage systemMsg = EventMessage.builder()
                    .event(event)
                    .member(current)
                    .message("A supprimé la pièce jointe: " + attachment.getFileName())
                    .messageType(EventMessage.MessageType.SYSTEM)
                    .metadata("ATTACHMENT_DELETED:" + attachment.getFileName())
                    .sentAt(LocalDateTime.now())
                    .build();
            eventMessageRepository.save(systemMsg);

            // Delete record (Soft deletes via SQL delete config on entity)
            eventAttachmentRepository.delete(attachment);

            auditService.logAction(current.getUsername(), "DELETE_ATTACHMENT", "EventAttachment", attachment.getId(), "SUCCESS", "Deleted file: " + attachment.getFileName() + " from event: " + event.getTitle());

            // Trigger Notifications
            if (event.getCalendar() != null && event.getCalendar().getMembers() != null) {
                for (Member m : event.getCalendar().getMembers()) {
                    if (!m.getId().equals(current.getId())) {
                        notificationService.triggerNotification(
                                m,
                                "Pièce jointe supprimée",
                                current.getFullName() + " a supprimé le fichier: " + attachment.getFileName(),
                                "EVENT_UPDATE",
                                "ATTACHMENT",
                                event.getId(),
                                "DELETED"
                        );
                    }
                }
            }

            metricsService.recordDeleteAttempt("success");
            return ResponseEntity.noContent().build();

        } catch (Exception e) {
            log.error("Failed to delete attachment", e);
            metricsService.recordDeleteAttempt("error");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    private Map<String, Object> mapToAttachmentMap(EventAttachment a) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", a.getId().toString());
        map.put("eventId", a.getEvent().getId().toString());
        map.put("fileName", a.getFileName());
        map.put("filePath", a.getFilePath());
        map.put("fileType", a.getFileType());
        map.put("uploadedBy", a.getUploadedBy());
        map.put("uploadedAt", a.getUploadedAt().toString());

        map.put("originalFilename", a.getOriginalFilename() != null ? a.getOriginalFilename() : a.getFileName());
        map.put("storedFilename", a.getStoredFilename() != null ? a.getStoredFilename() : a.getFilePath());
        map.put("fileSize", a.getFileSize() != null ? a.getFileSize() : 0L);

        return map;
    }

    // --- DTOs ---

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresignedUploadRequest {
        private String fileName;
        private Long fileSize;
        private String contentType;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PresignedUploadResponse {
        private String uploadUrl;
        private String s3Key;
        private String fileName;
        private Long fileSize;
        private String contentType;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConfirmUploadRequest {
        private String fileName;
        private String s3Key;
        private Long fileSize;
        private String contentType;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresignedDownloadResponse {
        private String downloadUrl;
    }
}
