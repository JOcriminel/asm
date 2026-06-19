package com.asm.dux.web;

import com.asm.dux.domain.model.ChecklistResponse;
import com.asm.dux.domain.model.ChecklistTask;
import com.asm.dux.infrastructure.db.repository.ChecklistResponseRepository;
import com.asm.dux.infrastructure.db.repository.ChecklistTaskRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/dux/checklists/responses")
public class ChecklistResponseController {

    private final ChecklistResponseRepository responseRepository;
    private final ChecklistTaskRepository taskRepository;

    public ChecklistResponseController(ChecklistResponseRepository responseRepository, ChecklistTaskRepository taskRepository) {
        this.responseRepository = responseRepository;
        this.taskRepository = taskRepository;
    }

    @GetMapping("/{idLigneDocument}")
    public List<ChecklistResponse> getResponses(@PathVariable String idLigneDocument) {
        return responseRepository.findByIdLigneDocument(idLigneDocument);
    }

    @PostMapping("/{idLigneDocument}")
    public ChecklistResponse toggleResponse(@PathVariable String idLigneDocument, 
                                            @RequestParam Long taskId, 
                                            @RequestParam Boolean isChecked) {
        Optional<ChecklistResponse> existing = responseRepository.findByIdLigneDocumentAndTaskId(idLigneDocument, taskId);
        ChecklistResponse response;
        if (existing.isPresent()) {
            response = existing.get();
            response.setIsChecked(isChecked);
            response.setDateChecked(LocalDateTime.now());
        } else {
            response = new ChecklistResponse();
            response.setIdLigneDocument(idLigneDocument);
            ChecklistTask task = taskRepository.findById(taskId).orElseThrow();
            response.setTask(task);
            response.setIsChecked(isChecked);
            response.setDateChecked(LocalDateTime.now());
        }
        
        try {
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();
            if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                org.springframework.security.oauth2.jwt.Jwt jwt = ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                String preferredUsername = jwt.getClaimAsString("preferred_username");
                if (preferredUsername != null && !preferredUsername.isEmpty()) {
                    username = preferredUsername;
                }
            }
            response.setCheckedBy(username);
        } catch (Exception e) {
            // fallback if SecurityContext is not populated (e.g. testing)
            response.setCheckedBy("system");
        }
        
        return responseRepository.save(response);
    }

    @PutMapping("/{idLigneDocument}/note")
    public ChecklistResponse updateNote(@PathVariable String idLigneDocument,
                                        @RequestParam Long taskId,
                                        @RequestParam(required = false) String note) {
        Optional<ChecklistResponse> existing = responseRepository.findByIdLigneDocumentAndTaskId(idLigneDocument, taskId);
        ChecklistResponse response;
        if (existing.isPresent()) {
            response = existing.get();
        } else {
            response = new ChecklistResponse();
            response.setIdLigneDocument(idLigneDocument);
            ChecklistTask task = taskRepository.findById(taskId).orElseThrow();
            response.setTask(task);
            response.setIsChecked(false);
            response.setDateChecked(LocalDateTime.now());
        }

        if (note == null || note.trim().isEmpty()) {
            response.setNote(null);
            response.setDateNote(null);
        } else {
            response.setNote(note.trim());
            response.setDateNote(LocalDateTime.now());
        }

        try {
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            String username = auth.getName();
            if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                org.springframework.security.oauth2.jwt.Jwt jwt = ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                String preferredUsername = jwt.getClaimAsString("preferred_username");
                if (preferredUsername != null && !preferredUsername.isEmpty()) {
                    username = preferredUsername;
                }
            }
            response.setCheckedBy(username);
        } catch (Exception e) {
            response.setCheckedBy("system");
        }

        return responseRepository.save(response);
    }
}
