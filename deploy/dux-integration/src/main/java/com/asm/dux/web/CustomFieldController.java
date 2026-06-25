package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/custom-fields", "/api/timetree/custom-fields"})
@RequiredArgsConstructor
public class CustomFieldController {

    private final CustomFieldRepository customFieldRepository;
    private final CustomFieldValueRepository customFieldValueRepository;
    private final MemberRepository memberRepository;
    private final EventRepository eventRepository;
    private final EventMessageRepository eventMessageRepository;
    private final NotificationService notificationService;
    private final com.asm.dux.timetree.service.AuditService auditService;

    // Helper to get current authenticated member
    private Member getCurrentMember() {
        try {
            org.springframework.security.core.Authentication auth = 
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) return null;
            String username = auth.getName();
            if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                org.springframework.security.oauth2.jwt.Jwt jwt = 
                    ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                String preferredUsername = jwt.getClaimAsString("preferred_username");
                if (preferredUsername != null && !preferredUsername.isEmpty()) {
                    username = preferredUsername;
                }
            }
            return memberRepository.findByUsername(username).orElse(null);
        } catch (Exception e) {
            log.error("Failed to resolve current member", e);
            return null;
        }
    }

    // Helper to verify if user has permission to manage fields for a given scope
    private boolean hasPermission(String scopeType, String scopeId) {
        Member member = getCurrentMember();
        if (member == null) {
            log.warn("Permission check failed: User not found in database");
            return false;
        }
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role)) {
            return true;
        }
        if ("CHEF".equals(role)) {
            // Chef permissions are managed via direct calendar assignments
            return false;
        }
        return false;
    }

    // Get all custom fields, with optional filters
    @GetMapping
    public ResponseEntity<List<CustomField>> getCustomFields(
            @RequestParam(required = false) String scopeType,
            @RequestParam(required = false) String scopeId) {
        log.info("GET /api/timetree/custom-fields scopeType={}, scopeId={}", scopeType, scopeId);
        
        List<CustomField> fields;
        if (scopeType != null && scopeId != null) {
            fields = customFieldRepository.findAllByScopeTypeAndScopeIdOrderBySortOrderAsc(scopeType, scopeId);
        } else if (scopeType != null) {
            fields = customFieldRepository.findAllByScopeTypeOrderBySortOrderAsc(scopeType);
        } else {
            fields = customFieldRepository.findAllByOrderBySortOrderAsc();
        }
        return ResponseEntity.ok(fields);
    }

    // Get dynamic fields for an event, aggregating fields for its group and calendar
    @GetMapping("/event-fields")
    public ResponseEntity<List<CustomField>> getEventFields(
            @RequestParam(required = false) String groupId,
            @RequestParam(required = false) String calendarId,
            @RequestParam(required = false) String eventId) {
        log.info("GET /api/timetree/custom-fields/event-fields groupId={}, calendarId={}, eventId={}", groupId, calendarId, eventId);
        
        List<CustomField> result = new ArrayList<>();
        
        // Load group fields
        if (groupId != null && !groupId.isEmpty()) {
            result.addAll(customFieldRepository.findAllByScopeTypeAndScopeIdOrderBySortOrderAsc("GROUP", groupId));
        }
        
        // Load calendar fields
        if (calendarId != null && !calendarId.isEmpty()) {
            result.addAll(customFieldRepository.findAllByScopeTypeAndScopeIdOrderBySortOrderAsc("CALENDAR", calendarId));
        }
        
        // Load event fields
        if (eventId != null && !eventId.isEmpty()) {
            result.addAll(customFieldRepository.findAllByScopeTypeAndScopeIdOrderBySortOrderAsc("EVENT", eventId));
        }
        
        // Load global fields
        result.addAll(customFieldRepository.findAllByScopeTypeOrderBySortOrderAsc("GLOBAL"));
        
        // Sort the aggregated list by sortOrder, then active fields only
        List<CustomField> sortedActiveFields = result.stream()
                .filter(CustomField::getActive)
                .sorted(Comparator.comparingInt(CustomField::getSortOrder))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(sortedActiveFields);
    }

    // Get single custom field definition
    @GetMapping("/{id}")
    public ResponseEntity<CustomField> getCustomField(@PathVariable Long id) {
        log.info("GET /api/timetree/custom-fields/{}", id);
        return customFieldRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Create custom field definition
    @PostMapping
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> createCustomField(@RequestBody CustomField customField) {
        log.info("POST /api/timetree/custom-fields - name={}", customField.getName());
        
        if (!hasPermission(customField.getScopeType(), customField.getScopeId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission refusée pour créer ce champ.");
        }
        
        // Determine sort order
        if (customField.getSortOrder() == null) {
            List<CustomField> existing = customFieldRepository.findAllByOrderBySortOrderAsc();
            int maxOrder = existing.stream().mapToInt(CustomField::getSortOrder).max().orElse(0);
            customField.setSortOrder(maxOrder + 1);
        }
        
        CustomField saved = customFieldRepository.save(customField);
        
        Member current = getCurrentMember();
        String username = current != null ? current.getUsername() : "admin";
        auditService.logAction(username, "CREATE", "CustomField", saved.getId(), "SUCCESS", "Created custom field: " + saved.getName());
        
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // Update custom field definition
    @PutMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> updateCustomField(@PathVariable Long id, @RequestBody CustomField request) {
        log.info("PUT /api/timetree/custom-fields/{}", id);
        
        return customFieldRepository.findById(id).map(existing -> {
            if (!hasPermission(existing.getScopeType(), existing.getScopeId()) || 
                !hasPermission(request.getScopeType(), request.getScopeId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission refusée pour modifier ce champ.");
            }
            
            existing.setName(request.getName());
            existing.setLabel(request.getLabel());
            existing.setFieldType(request.getFieldType());
            existing.setRequired(request.getRequired());
            existing.setDefaultValue(request.getDefaultValue());
            existing.setOptions(request.getOptions());
            existing.setScopeType(request.getScopeType());
            existing.setScopeId(request.getScopeId());
            existing.setSortOrder(request.getSortOrder());
            existing.setActive(request.getActive());
            existing.setEmoji(request.getEmoji());
            existing.setEmojiOrder(request.getEmojiOrder());
            
            // Validation rules

            existing.setMinValue(request.getMinValue());
            existing.setMaxValue(request.getMaxValue());
            existing.setMinLength(request.getMinLength());
            existing.setMaxLength(request.getMaxLength());
            existing.setRegexPattern(request.getRegexPattern());
            
            // Display rules
            existing.setHidden(request.getHidden());
            existing.setReadOnly(request.getReadOnly());
            existing.setVisibilityRule(request.getVisibilityRule());
            
            CustomField saved = customFieldRepository.save(existing);
            
            Member current = getCurrentMember();
            String username = current != null ? current.getUsername() : "admin";
            auditService.logAction(username, "UPDATE", "CustomField", saved.getId(), "SUCCESS", "Updated custom field: " + saved.getName());
            
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    // Delete custom field definition
    @DeleteMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> deleteCustomField(@PathVariable Long id) {
        log.info("DELETE /api/timetree/custom-fields/{}", id);
        
        return customFieldRepository.findById(id).map(existing -> {
            if (!hasPermission(existing.getScopeType(), existing.getScopeId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Permission refusée pour supprimer ce champ.");
            }
            
            customFieldRepository.delete(existing);
            
            Member current = getCurrentMember();
            String username = current != null ? current.getUsername() : "admin";
            auditService.logAction(username, "DELETE", "CustomField", existing.getId(), "SUCCESS", "Deleted custom field: " + existing.getName());
            
            return ResponseEntity.noContent().build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // Reorder custom fields in bulk
    @PostMapping("/reorder")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> reorderCustomFields(@RequestBody List<Map<String, Object>> request) {
        log.info("POST /api/timetree/custom-fields/reorder");
        
        // Map list updates
        for (Map<String, Object> map : request) {
            Object idObj = map.get("id");
            Object orderObj = map.get("sortOrder");
            if (idObj != null && orderObj != null) {
                Long id = Long.valueOf(idObj.toString());
                int sortOrder = Integer.parseInt(orderObj.toString());
                customFieldRepository.findById(id).ifPresent(field -> {
                    if (hasPermission(field.getScopeType(), field.getScopeId())) {
                        field.setSortOrder(sortOrder);
                        customFieldRepository.save(field);
                    }
                });
            }
        }
        return ResponseEntity.ok().build();
    }

    // ─── VALUES ENDPOINTS ────────────────────────────────────────────────────
    
    // Get values for a specific entity
    @GetMapping("/values/{entityType}/{entityId}")
    public ResponseEntity<List<CustomFieldValue>> getValues(
            @PathVariable String entityType,
            @PathVariable String entityId) {
        log.info("GET /api/timetree/custom-fields/values/{}/{}", entityType, entityId);
        List<CustomFieldValue> values = customFieldValueRepository.findAllByEntityTypeAndEntityId(entityType, entityId);
        return ResponseEntity.ok(values);
    }

    // Save/update values for a specific entity
    @PostMapping("/values/{entityType}/{entityId}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> saveValues(
            @PathVariable String entityType,
            @PathVariable String entityId,
            @RequestBody Map<String, Object> valuesMap) {
        log.info("POST /api/timetree/custom-fields/values/{}/{}", entityType, entityId);
        
        List<CustomFieldValue> savedValues = new ArrayList<>();
        
        for (Map.Entry<String, Object> entry : valuesMap.entrySet()) {
            Long fieldId = Long.parseLong(entry.getKey());
            Optional<CustomField> fieldOpt = customFieldRepository.findById(fieldId);
            if (fieldOpt.isPresent()) {
                CustomField field = fieldOpt.get();
                
                String valueStr = null;
                Boolean showEmojiInTitle = false;
                
                if (entry.getValue() instanceof Map) {
                    Map<?, ?> mapVal = (Map<?, ?>) entry.getValue();
                    valueStr = mapVal.get("value") != null ? mapVal.get("value").toString() : null;
                    if (mapVal.get("showEmojiInTitle") != null) {
                        showEmojiInTitle = Boolean.valueOf(mapVal.get("showEmojiInTitle").toString());
                    }
                } else if (entry.getValue() != null) {
                    valueStr = entry.getValue().toString();
                }
                
                Optional<CustomFieldValue> valOpt = 
                    customFieldValueRepository.findByFieldIdAndEntityTypeAndEntityId(fieldId, entityType, entityId);
                
                CustomFieldValue val;
                if (valOpt.isPresent()) {
                    val = valOpt.get();
                    val.setValue(valueStr);
                    val.setShowEmojiInTitle(showEmojiInTitle);
                } else {
                    val = CustomFieldValue.builder()
                            .field(field)
                            .entityType(entityType)
                            .entityId(entityId)
                            .value(valueStr)
                            .showEmojiInTitle(showEmojiInTitle)
                            .build();
                }
                savedValues.add(customFieldValueRepository.save(val));
            }
        }

        if ("EVENT".equalsIgnoreCase(entityType)) {
            try {
                Long eventId = Long.parseLong(entityId);
                eventRepository.findById(eventId).ifPresent(event -> {
                    // Recalculate event title based on emojis and nomEvent
                    com.asm.dux.timetree.service.EventTitleHelper.recalculateEventTitle(event, customFieldValueRepository);
                    eventRepository.save(event);

                    // Save system message
                    EventMessage systemMsg = EventMessage.builder()
                            .event(event)
                            .member(getCurrentMember())
                            .message("A mis à jour les champs personnalisés")
                            .messageType(EventMessage.MessageType.SYSTEM)
                            .metadata("CUSTOM_FIELD_UPDATED")
                            .sentAt(LocalDateTime.now())
                            .build();
                    eventMessageRepository.save(systemMsg);

                    // Notify calendar members
                    if (event.getCalendar() != null && event.getCalendar().getMembers() != null) {
                        Member current = getCurrentMember();
                        for (Member m : event.getCalendar().getMembers()) {
                            if (current != null && !m.getId().equals(current.getId())) {
                                notificationService.triggerNotification(
                                        m,
                                        "Champs personnalisés mis à jour dans " + event.getTitle(),
                                        current.getFullName() + " a mis à jour les informations complémentaires.",
                                        "EVENT_UPDATE",
                                        "EVENT",
                                        event.getId(),
                                        "UPDATED"
                                );
                            }
                        }
                    }
                });
            } catch (Exception ex) {
                log.error("Failed to post custom field update system message", ex);
            }
        }


        try {
            Long eId = Long.parseLong(entityId);
            Member current = getCurrentMember();
            String username = current != null ? current.getUsername() : "admin";
            auditService.logAction(username, "UPDATE_VALUES", entityType.toUpperCase(), eId, "SUCCESS", "Saved custom fields values for " + entityType + " ID " + entityId);
        } catch (Exception e) {
            log.error("Failed to write custom field values audit log", e);
        }

        return ResponseEntity.ok(savedValues);
    }
}
