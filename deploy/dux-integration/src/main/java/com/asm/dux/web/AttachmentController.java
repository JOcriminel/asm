package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
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
    private final FileStorageService fileStorageService;
    private final TimetreeSecurityService securityService;
    private final NotificationService notificationService;
    private final com.asm.dux.timetree.service.AuditService auditService;

    // Upload attachment
    @PostMapping({"/api/timetree/events/{id}/attachments", "/api/dux/api/timetree/events/{id}/attachments"})
    @Transactional
    public ResponseEntity<?> uploadAttachment(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) {
        log.info("POST upload attachment for event id={}, fileName={}", id, file.getOriginalFilename());

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

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("Le fichier est vide");
        }

        try {
            // Store file on disk
            String storedPath = fileStorageService.storeFile(file, "events/" + id);

            // Save metadata to database
            EventAttachment attachment = EventAttachment.builder()
                    .event(event)
                    .fileName(file.getOriginalFilename())
                    .filePath(storedPath)
                    .fileType(file.getContentType() != null ? file.getContentType() : "application/octet-stream")
                    .uploadedBy(current.getUsername())
                    .uploadedAt(LocalDateTime.now())
                    .build();

            // Populate additional custom metadata fields
            attachment.setOriginalFilename(file.getOriginalFilename());
            attachment.setStoredFilename(storedPath.substring(storedPath.lastIndexOf('/') + 1));
            attachment.setFileSize(file.getSize());

            EventAttachment saved = eventAttachmentRepository.save(attachment);

            auditService.logAction(current.getUsername(), "UPLOAD_ATTACHMENT", "EventAttachment", saved.getId(), "SUCCESS", "Uploaded file: " + saved.getFileName() + " to event: " + event.getTitle());

            // Generate System Message
            EventMessage systemMsg = EventMessage.builder()
                    .event(event)
                    .member(current)
                    .message("A ajouté la pièce jointe: " + file.getOriginalFilename())
                    .messageType(EventMessage.MessageType.SYSTEM)
                    .metadata("ATTACHMENT_UPLOADED:" + saved.getId())
                    .sentAt(LocalDateTime.now())
                    .build();
            eventMessageRepository.save(systemMsg);

            // Trigger Notifications
            Group group = event.getGroup();
            if (group != null && group.getMembers() != null) {
                for (Member m : group.getMembers()) {
                    if (!m.getId().equals(current.getId())) {
                        notificationService.triggerNotification(
                                m,
                                "Nouvelle pièce jointe dans " + event.getTitle(),
                                current.getFullName() + " a partagé un fichier: " + file.getOriginalFilename(),
                                "NEW_ATTACHMENT",
                                "ATTACHMENT",
                                saved.getId(),
                                "CREATED"
                        );
                    }
                }
            }

            return ResponseEntity.status(HttpStatus.CREATED).body(mapToAttachmentMap(saved));

        } catch (Exception e) {
            log.error("Failed to upload attachment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    // List attachments for an event
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

    // Download attachment (Permission-guarded, no public URLs)
    @GetMapping({"/api/timetree/events/attachments/download/{id}", "/api/dux/api/timetree/events/attachments/download/{id}"})
    public ResponseEntity<?> downloadAttachment(@PathVariable Long id) {
        log.info("GET download attachment id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<EventAttachment> attOpt = eventAttachmentRepository.findById(id);
        if (!attOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        EventAttachment attachment = attOpt.get();

        if (!securityService.canReadEvent(current, attachment.getEvent())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès refusé");
        }

        try {
            byte[] fileBytes = fileStorageService.loadFile(attachment.getFilePath());
            Resource resource = new ByteArrayResource(fileBytes);

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(attachment.getFileType()))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + attachment.getFileName() + "\"")
                    .body(resource);

        } catch (IOException e) {
            log.error("Failed to load attachment file", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Erreur lors de la lecture du fichier");
        }
    }

    // Delete attachment
    @DeleteMapping({"/api/timetree/events/attachments/{id}", "/api/dux/api/timetree/events/attachments/{id}"})
    @Transactional
    public ResponseEntity<?> deleteAttachment(@PathVariable Long id) {
        log.info("DELETE attachment id={}", id);

        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Optional<EventAttachment> attOpt = eventAttachmentRepository.findById(id);
        if (!attOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        EventAttachment attachment = attOpt.get();
        Event event = attachment.getEvent();

        if (!securityService.canWriteEvent(current, event.getCalendar().getId(), event.getGroup() != null ? event.getGroup().getId() : null)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission insuffisante");
        }

        try {
            // Delete file from disk
            fileStorageService.deleteFile(attachment.getFilePath());

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

            // Delete record
            eventAttachmentRepository.delete(attachment);

            auditService.logAction(current.getUsername(), "DELETE_ATTACHMENT", "EventAttachment", attachment.getId(), "SUCCESS", "Deleted file: " + attachment.getFileName() + " from event: " + event.getTitle());

            // Trigger Notifications
            Group group = event.getGroup();
            if (group != null && group.getMembers() != null) {
                for (Member m : group.getMembers()) {
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

            return ResponseEntity.noContent().build();

        } catch (Exception e) {
            log.error("Failed to delete attachment", e);
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
}
