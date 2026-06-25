package com.asm.dux.web;

import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import com.asm.dux.timetree.service.AuditService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping({"/api/timetree/admin/restore", "/api/dux/api/timetree/admin/restore"})
@RequiredArgsConstructor
public class RestoreController {

    private final JdbcTemplate jdbcTemplate;
    private final TimetreeSecurityService securityService;
    private final AuditService auditService;

    @PostMapping("/{entityType}/{id}")
    public ResponseEntity<?> restoreEntity(@PathVariable String entityType, @PathVariable Long id) {
        Member current = securityService.getCurrentMember();
        if (current == null || !("ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Accès réservé aux administrateurs");
        }

        String tableName;
        switch (entityType.toUpperCase()) {
            case "EVENT":
                tableName = "TT_EVENT";
                break;
            case "CALENDAR":
                tableName = "TT_CALENDAR";
                break;
            case "ATTACHMENT":
                tableName = "TT_EVENT_ATTACHMENT";
                break;
            case "CUSTOM_FIELD":
                tableName = "CF_DEFINITION";
                break;
            case "GROUP":
                tableName = "TT_GROUP";
                break;
            default:
                return ResponseEntity.badRequest().body("Type d'entité inconnu: " + entityType);
        }

        try {
            int updated = jdbcTemplate.update("UPDATE dbo." + tableName + " SET deleted = 0 WHERE id = ?", id);
            if (updated > 0) {
                auditService.logAction(
                        current.getUsername(),
                        "RESTORE",
                        entityType.toUpperCase(),
                        id,
                        "SUCCESS",
                        "Administrateur a restauré " + entityType + " id=" + id
                );
                return ResponseEntity.ok("Restauré avec succès");
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("Failed to restore entity", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }
}
