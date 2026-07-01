package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.service.*;
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

import com.asm.dux.timetree.repository.UserDeviceRepository;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/notifications", "/api/timetree/notifications"})
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final TimetreeSecurityService securityService;
    private final UserDeviceRepository userDeviceRepository;

    // GET all notifications (paginated)
    @GetMapping
    public ResponseEntity<?> getNotifications(
            @RequestParam(required = false, defaultValue = "0") int page,
            @RequestParam(required = false, defaultValue = "20") int size) {
        log.info("GET notifications page={} size={}", page, size);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        Page<TimetreeNotification> notifPage =
                notificationService.getNotificationsForUser(current.getId(), PageRequest.of(page, size));

        List<Map<String, Object>> content = notifPage.getContent().stream()
                .map(this::mapToNotificationMap)
                .collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("notifications", content);
        response.put("totalElements", notifPage.getTotalElements());
        response.put("totalPages", notifPage.getTotalPages());
        response.put("page", page);
        response.put("size", size);
        response.put("hasMore", notifPage.hasNext());
        return ResponseEntity.ok(response);
    }

    // PUT mark single notification as read
    @PutMapping("/{id}/read")
    public ResponseEntity<?> markRead(@PathVariable Long id) {
        log.info("PUT mark notification as read id={}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        boolean success = notificationService.markAsRead(id, current.getId());
        if (success) return ResponseEntity.ok().build();
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification introuvable ou accès refusé");
    }

    // Legacy POST mark single as read (kept for backward compat)
    @PostMapping("/{id}/read")
    public ResponseEntity<?> markReadPost(@PathVariable Long id) {
        return markRead(id);
    }

    // PUT mark all notifications as read
    @PutMapping("/read-all")
    public ResponseEntity<?> markAllReadPut() {
        log.info("PUT mark all notifications as read");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }
        notificationService.markAllAsRead(current.getId(), current.getUsername());
        return ResponseEntity.ok().build();
    }

    // Legacy POST mark all read
    @PostMapping("/read-all")
    public ResponseEntity<?> markAllReadPost() {
        return markAllReadPut();
    }

    // DELETE a single notification (triggers unread count push)
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNotification(@PathVariable Long id) {
        log.info("DELETE notification id={}", id);
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }
        boolean success = notificationService.deleteNotification(id, current.getId());
        if (success) return ResponseEntity.ok().build();
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification introuvable ou accès refusé");
    }

    // GET user notification preferences
    @GetMapping("/preferences")
    public ResponseEntity<?> getPreferences() {
        log.info("GET notification preferences");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        NotificationPreference pref = notificationService.getPreferencesForUser(current.getId(), current);
        PreferenceDto dto = PreferenceDto.builder()
                .emailEnabled(Boolean.TRUE.equals(pref.getEmailEnabled()))
                .pushEnabled(Boolean.TRUE.equals(pref.getPushEnabled()))
                .mentionsEnabled(Boolean.TRUE.equals(pref.getMentionsEnabled()))
                .remindersEnabled(Boolean.TRUE.equals(pref.getRemindersEnabled()))
                .chatEnabled(Boolean.TRUE.equals(pref.getChatEnabled()))
                .soundEnabled(Boolean.TRUE.equals(pref.getSoundEnabled()))
                .vibrationEnabled(Boolean.TRUE.equals(pref.getVibrationEnabled()))
                .snoozeUntil(pref.getSnoozeUntil())
                .muteAllExceptSpecific(Boolean.TRUE.equals(pref.getMuteAllExceptSpecific()))
                .notifyOwnActions(Boolean.TRUE.equals(pref.getNotifyOwnActions()))
                .build();
        return ResponseEntity.ok(dto);
    }

    // PUT update user notification preferences
    @PutMapping("/preferences")
    public ResponseEntity<?> updatePreferences(@RequestBody PreferenceDto dto) {
        log.info("PUT notification preferences");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        NotificationPreference newPref = NotificationPreference.builder()
                .emailEnabled(dto.isEmailEnabled())
                .pushEnabled(dto.isPushEnabled())
                .mentionsEnabled(dto.isMentionsEnabled())
                .remindersEnabled(dto.isRemindersEnabled())
                .chatEnabled(dto.isChatEnabled())
                .soundEnabled(dto.isSoundEnabled())
                .vibrationEnabled(dto.isVibrationEnabled())
                .snoozeUntil(dto.getSnoozeUntil())
                .muteAllExceptSpecific(dto.isMuteAllExceptSpecific())
                .notifyOwnActions(dto.isNotifyOwnActions())
                .build();

        NotificationPreference saved = notificationService.updatePreferences(current.getId(), newPref, current);
        PreferenceDto responseDto = PreferenceDto.builder()
                .emailEnabled(Boolean.TRUE.equals(saved.getEmailEnabled()))
                .pushEnabled(Boolean.TRUE.equals(saved.getPushEnabled()))
                .mentionsEnabled(Boolean.TRUE.equals(saved.getMentionsEnabled()))
                .remindersEnabled(Boolean.TRUE.equals(saved.getRemindersEnabled()))
                .chatEnabled(Boolean.TRUE.equals(saved.getChatEnabled()))
                .soundEnabled(Boolean.TRUE.equals(saved.getSoundEnabled()))
                .vibrationEnabled(Boolean.TRUE.equals(saved.getVibrationEnabled()))
                .snoozeUntil(saved.getSnoozeUntil())
                .muteAllExceptSpecific(Boolean.TRUE.equals(saved.getMuteAllExceptSpecific()))
                .notifyOwnActions(Boolean.TRUE.equals(saved.getNotifyOwnActions()))
                .build();
        return ResponseEntity.ok(responseDto);
    }

    // POST register device token for push notifications
    @PostMapping("/devices/register")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> registerDevice(@RequestBody DeviceRegistrationRequest request) {
        log.info("POST register device token");
        Member current = securityService.getCurrentMember();
        if (current == null) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Utilisateur non authentifié");
        }

        if (request.getDeviceToken() == null || request.getDeviceToken().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Device token cannot be empty");
        }

        // Check if token already exists to prevent duplicate entries
        Optional<UserDevice> existing = userDeviceRepository.findByDeviceToken(request.getDeviceToken());
        if (existing.isPresent()) {
            UserDevice device = existing.get();
            device.setMember(current);
            device.setPlatform(request.getPlatform() != null ? request.getPlatform().toUpperCase() : "ANDROID");
            device.setLastActive(java.time.LocalDateTime.now());
            userDeviceRepository.save(device);
        } else {
            UserDevice newDevice = UserDevice.builder()
                    .member(current)
                    .deviceToken(request.getDeviceToken())
                    .platform(request.getPlatform() != null ? request.getPlatform().toUpperCase() : "ANDROID")
                    .lastActive(java.time.LocalDateTime.now())
                    .build();
            userDeviceRepository.save(newDevice);
        }

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

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PreferenceDto {
        private boolean emailEnabled;
        private boolean pushEnabled;
        private boolean mentionsEnabled;
        private boolean remindersEnabled;
        private boolean chatEnabled;
        private boolean soundEnabled;
        private boolean vibrationEnabled;
        private java.time.LocalDateTime snoozeUntil;
        private boolean muteAllExceptSpecific;
        private boolean notifyOwnActions;
    }

    @Data
    public static class DeviceRegistrationRequest {
        private String deviceToken;
        private String platform;
    }
}
