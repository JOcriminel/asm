package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/notifications", "/api/timetree/notifications"})
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final TimetreeSecurityService securityService;

    // Get list of notifications for the user
    @GetMapping
    public ResponseEntity<?> getNotifications() {
        log.info("GET notifications list");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        List<TimetreeNotification> list = notificationService.getNotificationsForUser(current.getId());
        List<Map<String, Object>> response = list.stream().map(this::mapToNotificationMap).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    // Mark single notification as read
    @PostMapping("/{id}/read")
    public ResponseEntity<?> markRead(@PathVariable Long id) {
        log.info("POST mark notification as read id={}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        boolean success = notificationService.markAsRead(id, current.getId());
        if (success) {
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification introuvable ou accès refusé");
    }

    // Mark all notifications as read
    @PostMapping("/read-all")
    public ResponseEntity<?> markAllRead() {
        log.info("POST mark all notifications as read");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        notificationService.markAllAsRead(current.getId());
        return ResponseEntity.ok().build();
    }

    private Map<String, Object> mapToNotificationMap(TimetreeNotification n) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", n.getId().toString());
        map.put("recipientId", n.getRecipient().getId().toString());
        map.put("title", n.getTitle());
        map.put("content", n.getContent());
        map.put("type", n.getType());
        map.put("entityType", n.getEntityType());
        map.put("entityId", n.getEntityId().toString());
        map.put("actionType", n.getActionType());
        map.put("isRead", n.isRead());
        map.put("createdAt", n.getCreatedAt().toString());
        return map;
    }
}
