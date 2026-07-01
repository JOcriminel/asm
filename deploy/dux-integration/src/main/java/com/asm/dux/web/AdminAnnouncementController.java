package com.asm.dux.web;

import com.asm.dux.timetree.service.NotificationService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Slf4j
@RestController
@RequestMapping({
    "/api/dux/timetree/admin/announcements",
    "/api/timetree/admin/announcements",
    "/api/dux/api/timetree/admin/announcements",
    "/api/dux/api/dux/timetree/admin/announcements"
})
@RequiredArgsConstructor
public class AdminAnnouncementController {

    private final NotificationService notificationService;

    @PostMapping
    public ResponseEntity<Void> sendAnnouncement(@RequestBody AnnouncementRequest request) {
        log.info("Admin sending announcement: '{}' targeting calendars: {}", request.getTitle(), request.getCalendarIds());
        notificationService.triggerAnnouncement(
            request.getTitle(),
            request.getContent(),
            request.getCalendarIds()
        );
        return ResponseEntity.ok().build();
    }

    @Data
    public static class AnnouncementRequest {
        private String title;
        private String content;
        private List<Long> calendarIds;
    }
}
