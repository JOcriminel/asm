package com.asm.dux.web;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree", "/api/timetree"})
@RequiredArgsConstructor
public class TimetreeController {

    private final CategoryRepository categoryRepository;
    private final PageRepository pageRepository;
    private final TimetreeAuditLogRepository auditLogRepository;
    private final MemberRepository memberRepository;
    private final CalendarRepository calendarRepository;
    private final EventRepository eventRepository;
    private final com.asm.dux.timetree.service.AuditService auditService;
    private final com.asm.dux.timetree.service.TimetreeSecurityService securityService;
    private final com.asm.dux.timetree.service.WebSocketMetricsService webSocketMetricsService;
    private final com.asm.dux.infrastructure.dux.DuxHttpClient duxHttpClient;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    // Helper to write audit logs
    private void audit(String action, String entityType, Long entityId, String details) {
        try {
            String username = "admin";
            Member current = securityService.getCurrentMember();
            if (current != null) {
                username = current.getUsername();
            }
            auditService.logAction(username, action, entityType, entityId, "SUCCESS", details);
        } catch (Exception e) {
            log.error("Failed to write timetree audit log", e);
        }
    }

    // ─── MENU ────────────────────────────────────────────────────────────────
    @GetMapping("/menu")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<List<Map<String, Object>>> getMenu() {
        log.info("GET /api/timetree/menu");
        List<Category> categories = categoryRepository.findAllByActiveTrueOrderByDisplayOrderAsc();
        List<Map<String, Object>> menu = categories.stream().map(cat -> {
            Map<String, Object> catMap = new LinkedHashMap<>();
            catMap.put("id", cat.getId().toString());
            catMap.put("title", cat.getName());
            catMap.put("path", cat.getCode() != null ? cat.getCode() : "");
            catMap.put("displayOrder", cat.getDisplayOrder() != null ? cat.getDisplayOrder() : 0);
            catMap.put("allowedRoles", cat.getAllowedRoles());
            catMap.put("allowedUsers", cat.getAllowedUsers());

            List<Map<String, Object>> children = new ArrayList<>();
            if (cat.getPages() != null) {
                children = cat.getPages().stream()
                        .filter(p -> p.getActive() != null && p.getActive())
                        .sorted(Comparator.comparingInt(p -> p.getDisplayOrder() != null ? p.getDisplayOrder() : 0))
                        .map(p -> {
                            Map<String, Object> pMap = new LinkedHashMap<>();
                            pMap.put("id", p.getId().toString());
                            pMap.put("title", p.getName());
                            pMap.put("path", p.getRoute() != null ? p.getRoute() : "");
                            pMap.put("displayOrder", p.getDisplayOrder() != null ? p.getDisplayOrder() : 0);
                            pMap.put("allowedRoles", p.getAllowedRoles());
                            pMap.put("allowedUsers", p.getAllowedUsers());
                            pMap.put("children", Collections.emptyList());
                            return pMap;
                        }).collect(Collectors.toList());
            }
            catMap.put("children", children);
            return catMap;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(menu);
    }

    // ─── DASHBOARD ───────────────────────────────────────────────────────────
    @GetMapping("/dashboard")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<Map<String, Object>> getDashboard() {
        log.info("GET /api/timetree/dashboard");
        long catCount = categoryRepository.count();
        long pageCount = pageRepository.count();
        long memberCount = memberRepository.count();

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("categoriesCount", (int) catCount);
        summary.put("pagesCount", (int) pageCount);
        summary.put("membersCount", (int) memberCount);

        List<TimetreeAuditLog> logs = auditLogRepository.findRecentLogs(PageRequest.of(0, 10));
        List<Map<String, Object>> activities = logs.stream().map(l -> {
            Map<String, Object> lMap = new LinkedHashMap<>();
            lMap.put("id", l.getId().toString());
            lMap.put("type", l.getEntityType() != null ? l.getEntityType().toUpperCase() : "SYSTEM");
            lMap.put("title", l.getDetails() != null ? l.getDetails() : (l.getAction() + " " + l.getEntityType()));
            lMap.put("timestamp", l.getActionDate() != null ? l.getActionDate().toString() : LocalDateTime.now().toString());
            return lMap;
        }).collect(Collectors.toList());

        // Calculate Hardening Metrics
        Member current = securityService.getCurrentMember();
        List<Event> allEvents = eventRepository.findAll().stream()
                .filter(e -> !Boolean.TRUE.equals(e.getDeleted()))
                .filter(e -> current == null || securityService.canReadEvent(current, e))
                .collect(Collectors.toList());

        // Events by Status
        Map<String, Long> eventsByStatus = allEvents.stream()
                .collect(Collectors.groupingBy(e -> e.getStatus().name(), Collectors.counting()));

        // Events by Priority
        Map<String, Long> eventsByPriority = allEvents.stream()
                .collect(Collectors.groupingBy(e -> e.getPriority().name(), Collectors.counting()));

        // Upcoming Events (next 7 days)
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime sevenDaysLater = now.plusDays(7);
        List<Map<String, Object>> upcomingEvents = allEvents.stream()
                .filter(e -> e.getStartDate().isAfter(now) && e.getStartDate().isBefore(sevenDaysLater))
                .sorted(Comparator.comparing(Event::getStartDate))
                .map(e -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", e.getId().toString());
                    map.put("title", e.getTitle());
                    map.put("startDate", e.getStartDate().toString());
                    map.put("endDate", e.getEndDate().toString());
                    map.put("color", e.getColor());
                    return map;
                }).collect(Collectors.toList());

        // Most Active Calendars (by event count)
        Map<String, Long> calendarEventCounts = allEvents.stream()
                .filter(e -> e.getCalendar() != null)
                .collect(Collectors.groupingBy(e -> e.getCalendar().getName(), Collectors.counting()));
        List<Map<String, Object>> mostActiveCalendars = calendarEventCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(entry -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("calendarName", entry.getKey());
                    m.put("eventCount", entry.getValue());
                    return m;
                }).collect(Collectors.toList());

        // Most Active Members
        Map<String, Long> memberParticipantCounts = allEvents.stream()
                .filter(e -> e.getParticipants() != null)
                .flatMap(e -> e.getParticipants().stream())
                .collect(Collectors.groupingBy(Member::getFullName, Collectors.counting()));
        List<Map<String, Object>> mostActiveMembers = memberParticipantCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(entry -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("memberName", entry.getKey());
                    m.put("eventCount", entry.getValue());
                    return m;
                }).collect(Collectors.toList());

        // Calendar Utilization % (next 30 days occupied days)
        LocalDateTime startRange = LocalDateTime.now().with(java.time.LocalTime.MIN);
        LocalDateTime endRange = startRange.plusDays(30).with(java.time.LocalTime.MAX);
        Set<java.time.LocalDate> uniqueDaysWithEvents = allEvents.stream()
                .filter(e -> !e.getStartDate().isAfter(endRange) && !e.getEndDate().isBefore(startRange))
                .flatMap(e -> {
                    List<java.time.LocalDate> dates = new java.util.ArrayList<>();
                    java.time.LocalDate cur = e.getStartDate().toLocalDate();
                    java.time.LocalDate end = e.getEndDate().toLocalDate();
                    while (!cur.isAfter(end)) {
                        if (!cur.isBefore(startRange.toLocalDate()) && !cur.isAfter(endRange.toLocalDate())) {
                            dates.add(cur);
                        }
                        cur = cur.plusDays(1);
                    }
                    return dates.stream();
                })
                .collect(Collectors.toSet());
        double calendarUtilization = (uniqueDaysWithEvents.size() / 30.0) * 100.0;
        calendarUtilization = Math.round(calendarUtilization * 10.0) / 10.0;

        Map<String, Object> dashboard = new LinkedHashMap<>();
        dashboard.put("summary", summary);
        dashboard.put("recentActivities", activities);
        dashboard.put("eventsByStatus", eventsByStatus);
        dashboard.put("eventsByPriority", eventsByPriority);
        dashboard.put("upcomingEvents", upcomingEvents);
        dashboard.put("mostActiveCalendars", mostActiveCalendars);
        dashboard.put("mostActiveMembers", mostActiveMembers);
        dashboard.put("calendarUtilization", calendarUtilization);

        return ResponseEntity.ok(dashboard);
    }

    @GetMapping("/metrics/websocket")
    public ResponseEntity<?> getWebSocketMetrics() {
        log.info("GET /api/timetree/metrics/websocket");
        return ResponseEntity.ok(webSocketMetricsService.getMetricsReport());
    }

    // ─── CATEGORIES CRUD ─────────────────────────────────────────────────────
    private Map<String, Object> categoryToMap(Category c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.getId() != null ? c.getId().toString() : null);
        m.put("name", c.getName());
        m.put("code", c.getCode());
        m.put("icon", c.getIcon());
        m.put("color", c.getColor());
        m.put("displayOrder", c.getDisplayOrder() != null ? c.getDisplayOrder() : 0);
        m.put("active", c.getActive() != null ? c.getActive() : false);
        m.put("allowedRoles", c.getAllowedRoles());
        m.put("allowedUsers", c.getAllowedUsers());
        m.put("createdAt", c.getCreatedAt());
        m.put("updatedAt", c.getUpdatedAt());
        return m;
    }

    @GetMapping("/categories")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<List<Map<String, Object>>> getCategories() {
        log.info("GET /api/timetree/categories");
        List<Map<String, Object>> result = categoryRepository.findAllByOrderByDisplayOrderAsc()
                .stream().map(this::categoryToMap).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    @GetMapping("/categories/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<Map<String, Object>> getCategory(@PathVariable Long id) {
        log.info("GET /api/timetree/categories/{}", id);
        return categoryRepository.findById(id)
                .map(c -> ResponseEntity.ok(categoryToMap(c)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/categories")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Map<String, Object>> createCategory(@RequestBody Category category) {
        log.info("POST /api/timetree/categories - {}", category.getName());
        category.setCreatedAt(LocalDateTime.now());
        category.setCreatedBy("admin");
        Category saved = categoryRepository.save(category);
        audit("CREATE", "Category", saved.getId(), "Created category: " + saved.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(categoryToMap(saved));
    }

    @PutMapping("/categories/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Map<String, Object>> updateCategory(@PathVariable Long id, @RequestBody Map<String, Object> requestBody) {
        log.info("PUT /api/timetree/categories/{}", id);
        return categoryRepository.findById(id).map(existing -> {
            if (requestBody.containsKey("name")) {
                existing.setName((String) requestBody.get("name"));
            }
            if (requestBody.containsKey("code")) {
                existing.setCode((String) requestBody.get("code"));
            }
            if (requestBody.containsKey("icon")) {
                existing.setIcon((String) requestBody.get("icon"));
            }
            if (requestBody.containsKey("color")) {
                existing.setColor((String) requestBody.get("color"));
            }
            if (requestBody.containsKey("displayOrder")) {
                existing.setDisplayOrder(requestBody.get("displayOrder") != null ? Integer.valueOf(requestBody.get("displayOrder").toString()) : 0);
            }
            if (requestBody.containsKey("active")) {
                existing.setActive(requestBody.get("active") != null && Boolean.parseBoolean(requestBody.get("active").toString()));
            }
            if (requestBody.containsKey("allowedRoles")) {
                existing.setAllowedRoles((String) requestBody.get("allowedRoles"));
            }
            if (requestBody.containsKey("allowedUsers")) {
                existing.setAllowedUsers((String) requestBody.get("allowedUsers"));
            }
            existing.setUpdatedAt(LocalDateTime.now());
            existing.setUpdatedBy("admin");
            Category saved = categoryRepository.save(existing);
            audit("UPDATE", "Category", saved.getId(), "Updated category: " + saved.getName());
            return ResponseEntity.ok(categoryToMap(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/categories/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Void> deleteCategory(@PathVariable Long id) {
        log.info("DELETE /api/timetree/categories/{}", id);
        return categoryRepository.findById(id).map(existing -> {
            categoryRepository.delete(existing);
            audit("DELETE", "Category", id, "Deleted category: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/categories/{id}/activate")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Map<String, Object>> activateCategory(@PathVariable Long id) {
        log.info("PATCH /api/timetree/categories/{}/activate", id);
        return categoryRepository.findById(id).map(existing -> {
            existing.setActive(true);
            existing.setUpdatedAt(LocalDateTime.now());
            Category saved = categoryRepository.save(existing);
            audit("ACTIVATE", "Category", saved.getId(), "Activated category: " + saved.getName());
            return ResponseEntity.ok(categoryToMap(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/categories/{id}/deactivate")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Map<String, Object>> deactivateCategory(@PathVariable Long id) {
        log.info("PATCH /api/timetree/categories/{}/deactivate", id);
        return categoryRepository.findById(id).map(existing -> {
            existing.setActive(false);
            existing.setUpdatedAt(LocalDateTime.now());
            Category saved = categoryRepository.save(existing);
            audit("DEACTIVATE", "Category", saved.getId(), "Deactivated category: " + saved.getName());
            return ResponseEntity.ok(categoryToMap(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── PAGES CRUD ──────────────────────────────────────────────────────────
    private Map<String, Object> pageToMap(Page p) {
        Map<String, Object> pMap = new LinkedHashMap<>();
        pMap.put("id", p.getId() != null ? p.getId().toString() : null);
        pMap.put("name", p.getName());
        pMap.put("route", p.getRoute());
        pMap.put("icon", p.getIcon());
        pMap.put("componentName", p.getComponentName());
        pMap.put("displayOrder", p.getDisplayOrder());
        pMap.put("active", p.getActive());
        pMap.put("allowedRoles", p.getAllowedRoles());
        pMap.put("allowedUsers", p.getAllowedUsers());
        pMap.put("createdAt", p.getCreatedAt());
        pMap.put("updatedAt", p.getUpdatedAt());
        pMap.put("categoryId", p.getCategory() != null && p.getCategory().getId() != null ? p.getCategory().getId().toString() : null);
        pMap.put("categoryName", p.getCategory() != null ? p.getCategory().getName() : null);
        return pMap;
    }

    @GetMapping("/pages")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<List<Map<String, Object>>> getPages() {
        log.info("GET /api/timetree/pages");
        List<Page> pages = pageRepository.findAllByOrderByDisplayOrderAsc();
        List<Map<String, Object>> response = pages.stream().map(this::pageToMap).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pages/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<Map<String, Object>> getPage(@PathVariable Long id) {
        log.info("GET /api/timetree/pages/{}", id);
        return pageRepository.findById(id).map(p -> ResponseEntity.ok(pageToMap(p)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/pages")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> createPage(@RequestBody Map<String, Object> requestBody) {
        log.info("POST /api/timetree/pages");
        try {
            Long categoryId = requestBody.get("categoryId") != null ? Long.valueOf(requestBody.get("categoryId").toString()) : null;
            if (categoryId == null) {
                return ResponseEntity.badRequest().body("categoryId is required");
            }
            Optional<Category> categoryOpt = categoryRepository.findById(categoryId);
            if (!categoryOpt.isPresent()) {
                return ResponseEntity.badRequest().body("Category not found with ID " + categoryId);
            }

            Page page = Page.builder()
                    .category(categoryOpt.get())
                    .name(requestBody.containsKey("name") ? (String) requestBody.get("name") : (String) requestBody.get("title"))
                    .route((String) requestBody.get("route"))
                    .icon((String) requestBody.get("icon"))
                    .componentName((String) requestBody.get("componentName"))
                    .displayOrder(requestBody.get("displayOrder") != null ? Integer.valueOf(requestBody.get("displayOrder").toString()) : 0)
                    .active(requestBody.get("active") == null || Boolean.parseBoolean(requestBody.get("active").toString()))
                    .allowedRoles((String) requestBody.get("allowedRoles"))
                    .allowedUsers((String) requestBody.get("allowedUsers"))
                    .createdAt(LocalDateTime.now())
                    .build();

            Page saved = pageRepository.save(page);
            audit("CREATE", "Page", saved.getId(), "Created page: " + saved.getName());
            return ResponseEntity.status(HttpStatus.CREATED).body(pageToMap(saved));
        } catch (Exception e) {
            log.error("Failed to create page", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    @PutMapping("/pages/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> updatePage(@PathVariable Long id, @RequestBody Map<String, Object> requestBody) {
        log.info("PUT /api/timetree/pages/{}", id);
        return pageRepository.findById(id).map(existing -> {
            Long categoryId = requestBody.get("categoryId") != null ? Long.valueOf(requestBody.get("categoryId").toString()) : null;
            if (categoryId != null) {
                Optional<Category> catOpt = categoryRepository.findById(categoryId);
                catOpt.ifPresent(existing::setCategory);
            }
            if (requestBody.containsKey("name")) {
                existing.setName((String) requestBody.get("name"));
            } else if (requestBody.containsKey("title")) {
                existing.setName((String) requestBody.get("title"));
            }
            if (requestBody.containsKey("route")) {
                existing.setRoute((String) requestBody.get("route"));
            }
            if (requestBody.containsKey("icon")) {
                existing.setIcon((String) requestBody.get("icon"));
            }
            if (requestBody.containsKey("componentName")) {
                existing.setComponentName((String) requestBody.get("componentName"));
            }
            if (requestBody.containsKey("displayOrder")) {
                existing.setDisplayOrder(requestBody.get("displayOrder") != null ? Integer.valueOf(requestBody.get("displayOrder").toString()) : 0);
            }
            if (requestBody.containsKey("active")) {
                existing.setActive(requestBody.get("active") != null && Boolean.parseBoolean(requestBody.get("active").toString()));
            }
            if (requestBody.containsKey("allowedRoles")) {
                existing.setAllowedRoles((String) requestBody.get("allowedRoles"));
            }
            if (requestBody.containsKey("allowedUsers")) {
                existing.setAllowedUsers((String) requestBody.get("allowedUsers"));
            }
            existing.setUpdatedAt(LocalDateTime.now());
            Page saved = pageRepository.save(existing);
            audit("UPDATE", "Page", saved.getId(), "Updated page: " + saved.getName());
            return ResponseEntity.ok(pageToMap(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/pages/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Void> deletePage(@PathVariable Long id) {
        log.info("DELETE /api/timetree/pages/{}", id);
        return pageRepository.findById(id).map(existing -> {
            pageRepository.delete(existing);
            audit("DELETE", "Page", id, "Deleted page: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── ROLES ───────────────────────────────────────────────────────────────
    @GetMapping("/roles")
    public ResponseEntity<List<Map<String, String>>> getRoles() {
        log.info("GET /api/timetree/roles");
        try {
            String url = "https://duxweb.pre-produx.asmtechtn.com/api/Typeuser/findall";
            String json = duxHttpClient.get(url);
            if (json != null && !json.trim().isEmpty()) {
                List<Map<String, Object>> externalRoles = objectMapper.readValue(json, new com.fasterxml.jackson.core.type.TypeReference<List<Map<String, Object>>>() {});
                List<Map<String, String>> parsedRoles = new ArrayList<>();
                for (Map<String, Object> map : externalRoles) {
                    String libelle = map.get("libelle") != null ? map.get("libelle").toString().trim() : 
                                    map.get("libellé") != null ? map.get("libellé").toString().trim() :
                                    map.get("designation") != null ? map.get("designation").toString().trim() :
                                    map.get("code") != null ? map.get("code").toString().trim() : "";
                    String id = map.get("idTypeuser") != null ? map.get("idTypeuser").toString().trim() :
                                map.get("id") != null ? map.get("id").toString().trim() : libelle;
                    
                    String code = !libelle.isEmpty() ? libelle : id;
                    String label = !libelle.isEmpty() ? libelle : id;
                    if (!code.isEmpty()) {
                        parsedRoles.add(Map.of("code", code, "name", label));
                    }
                }
                if (!parsedRoles.isEmpty()) {
                    return ResponseEntity.ok(parsedRoles);
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch roles from Typeuser/findall", e);
        }

        // Fallback defaults in case of network or parsing failure
        List<Map<String, String>> roles = new ArrayList<>();
        roles.add(Map.of("code", "admin", "name", "Admin"));
        roles.add(Map.of("code", "dashboard-viewer", "name", "Dashboard Viewer"));
        roles.add(Map.of("code", "dashboard-editor", "name", "Dashboard Editor"));
        roles.add(Map.of("code", "dashboard-admin", "name", "Dashboard Admin"));
        roles.add(Map.of("code", "report-admin", "name", "Report Admin"));
        roles.add(Map.of("code", "report-editor", "name", "Report Editor"));
        return ResponseEntity.ok(roles);
    }

    // ─── PERMISSIONS ─────────────────────────────────────────────────────────
    @GetMapping("/permissions")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<Map<String, Object>> getPermissions() {
        log.info("GET /api/timetree/permissions");
        List<Category> categories = categoryRepository.findAll();
        List<Map<String, Object>> categoryPermissions = categories.stream().map(cat -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("categoryId", cat.getId().toString());
            map.put("categoryName", cat.getName());
            return map;
        }).collect(Collectors.toList());

        List<Page> pages = pageRepository.findAll();
        List<Map<String, Object>> pagePermissions = pages.stream().map(p -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("pageId", p.getId().toString());
            map.put("pageName", p.getName());
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("categories", categoryPermissions);
        response.put("pages", pagePermissions);
        
        return ResponseEntity.ok(response);
    }

    // ─── MEMBERS CRUD ────────────────────────────────────────────────────────
    @GetMapping("/members")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<List<Member>> getMembers() {
        log.info("GET /api/timetree/members");
        return ResponseEntity.ok(memberRepository.findAll());
    }

    @PostMapping("/members")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Member> createMember(@RequestBody Member member) {
        log.info("POST /api/timetree/members - {}", member.getUsername());
        if (member.getCalendars() != null) {
            List<Long> calendarIds = member.getCalendars().stream()
                    .map(com.asm.dux.timetree.domain.Calendar::getId)
                    .filter(java.util.Objects::nonNull)
                    .collect(Collectors.toList());
            List<com.asm.dux.timetree.domain.Calendar> calendars = calendarRepository.findAllById(calendarIds);
            member.setCalendars(calendars);
        }
        Member saved = memberRepository.save(member);
        audit("CREATE", "Member", saved.getId(), "Created member: " + saved.getFullName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/members/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Member> updateMember(@PathVariable Long id, @RequestBody Member request) {
        log.info("PUT /api/timetree/members/{}", id);
        return memberRepository.findById(id).map(existing -> {
            existing.setUsername(request.getUsername());
            existing.setFullName(request.getFullName());
            existing.setEmail(request.getEmail());
            if (request.getRole() != null) {
                existing.setRole(request.getRole());
                if ("MEMBER".equalsIgnoreCase(request.getRole())) {
                    existing.setCanCreateAgendas(false);
                    existing.setCanAddMembers(false);
                } else if ("CHEF".equalsIgnoreCase(request.getRole()) || "ADMIN".equalsIgnoreCase(request.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(request.getRole())) {
                    existing.setCanCreateAgendas(true);
                    existing.setCanAddMembers(true);
                }
            }
            if (request.getCanCreateAgendas() != null) {
                existing.setCanCreateAgendas(request.getCanCreateAgendas());
            }
            if (request.getCanAddMembers() != null) {
                existing.setCanAddMembers(request.getCanAddMembers());
            }
            if (request.getProfilePicture() != null) {
                existing.setProfilePicture(request.getProfilePicture());
            }
            if (request.getCalendars() != null) {
                List<Long> calendarIds = request.getCalendars().stream()
                        .map(com.asm.dux.timetree.domain.Calendar::getId)
                        .filter(java.util.Objects::nonNull)
                        .collect(Collectors.toList());
                List<com.asm.dux.timetree.domain.Calendar> calendars = calendarRepository.findAllById(calendarIds);
                existing.setCalendars(calendars);
            }
            Member saved = memberRepository.save(existing);
            audit("UPDATE", "Member", saved.getId(), "Updated member: " + saved.getFullName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/members/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Void> deleteMember(@PathVariable Long id) {
        log.info("DELETE /api/timetree/members/{}", id);
        return memberRepository.findById(id).map(existing -> {
            memberRepository.delete(existing);
            audit("DELETE", "Member", id, "Deleted member: " + existing.getFullName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── CALENDARS CRUD ──────────────────────────────────────────────────────
    @GetMapping("/calendars")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager", readOnly = true)
    public ResponseEntity<List<com.asm.dux.timetree.domain.Calendar>> getCalendars() {
        log.info("GET /api/timetree/calendars");
        Member current = securityService.getCurrentMember();
        if (current != null && !("ADMIN".equalsIgnoreCase(current.getRole()) || "ADMINISTRATEUR".equalsIgnoreCase(current.getRole()))) {
            List<Long> allowedIds = securityService.getAllowedCalendarIds(current);
            List<com.asm.dux.timetree.domain.Calendar> calendars = calendarRepository.findAll().stream()
                    .filter(c -> allowedIds.contains(c.getId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(calendars);
        }
        return ResponseEntity.ok(calendarRepository.findAll());
    }

    @PostMapping("/calendars")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<com.asm.dux.timetree.domain.Calendar> createCalendar(@RequestBody com.asm.dux.timetree.domain.Calendar calendar) {
        log.info("POST /api/timetree/calendars - {}", calendar.getName());
        Member current = securityService.getCurrentMember();
        if (current != null) {
            if (calendar.getMembers() == null) {
                calendar.setMembers(new java.util.ArrayList<>());
            }
            if (!calendar.getMembers().contains(current)) {
                calendar.getMembers().add(current);
            }
        }
        com.asm.dux.timetree.domain.Calendar saved = calendarRepository.save(calendar);
        audit("CREATE", "Calendar", saved.getId(), "Created calendar: " + saved.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/calendars/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<com.asm.dux.timetree.domain.Calendar> updateCalendar(@PathVariable Long id, @RequestBody com.asm.dux.timetree.domain.Calendar request) {
        log.info("PUT /api/timetree/calendars/{}", id);
        return calendarRepository.findById(id).map(existing -> {
            existing.setName(request.getName());
            existing.setDescription(request.getDescription());
            existing.setColor(request.getColor());
            existing.setAttachedDocuments(request.getAttachedDocuments());
            com.asm.dux.timetree.domain.Calendar saved = calendarRepository.save(existing);
            audit("UPDATE", "Calendar", saved.getId(), "Updated calendar: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/calendars/{id}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<Void> deleteCalendar(@PathVariable Long id) {
        log.info("DELETE /api/timetree/calendars/{}", id);
        return calendarRepository.findById(id).map(existing -> {
            calendarRepository.delete(existing);
            audit("DELETE", "Calendar", id, "Deleted calendar: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── CALENDAR MEMBER ASSIGNMENTS ─────────────────────────────────────────
    @PostMapping("/calendars/{calendarId}/members")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> addMemberToCalendar(@PathVariable Long calendarId, @RequestBody Map<String, String> request) {
        log.info("POST /api/timetree/calendars/{}/members", calendarId);
        String memberIdStr = request.get("memberId");
        if (memberIdStr == null) {
            return ResponseEntity.badRequest().body("memberId is required");
        }
        Long memberId = Long.valueOf(memberIdStr);
        return calendarRepository.findById(calendarId).flatMap(calendar ->
            memberRepository.findById(memberId).map(member -> {
                if (calendar.getMembers() == null) {
                    calendar.setMembers(new ArrayList<>());
                }
                if (!calendar.getMembers().contains(member)) {
                    if (member.getCalendars() == null) {
                        member.setCalendars(new ArrayList<>());
                    }
                    if (!member.getCalendars().contains(calendar)) {
                        member.getCalendars().add(calendar);
                    }
                    memberRepository.save(member);
                    calendar.getMembers().add(member);
                    calendarRepository.save(calendar);
                    audit("ADD_MEMBER", "Calendar", calendarId, "Added member " + member.getFullName() + " to calendar: " + calendar.getName());
                }
                return ResponseEntity.ok(Map.of("status", "ok"));
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/calendars/{calendarId}/members/{memberId}")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> removeMemberFromCalendar(@PathVariable Long calendarId, @PathVariable Long memberId) {
        log.info("DELETE /api/timetree/calendars/{}/members/{}", calendarId, memberId);
        return calendarRepository.findById(calendarId).flatMap(calendar ->
            memberRepository.findById(memberId).map(member -> {
                boolean removed = false;
                if (member.getCalendars() != null) {
                    removed = member.getCalendars().remove(calendar);
                    if (removed) {
                        memberRepository.save(member);
                    }
                }
                if (calendar.getMembers() != null) {
                    calendar.getMembers().remove(member);
                }
                calendarRepository.save(calendar);
                if (removed) {
                    audit("REMOVE_MEMBER", "Calendar", calendarId, "Removed member " + member.getFullName() + " from calendar: " + calendar.getName());
                    return ResponseEntity.ok().build();
                }
                return ResponseEntity.badRequest().body("Member not assigned to this calendar");
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/calendars/{calendarId}/members")
    @org.springframework.transaction.annotation.Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> setCalendarMembers(@PathVariable Long calendarId, @RequestBody Map<String, List<String>> request) {
        log.info("PUT /api/timetree/calendars/{}/members", calendarId);
        List<String> memberIdsStr = request.get("memberIds");
        if (memberIdsStr == null) {
            return ResponseEntity.badRequest().body("memberIds is required");
        }
        return calendarRepository.findById(calendarId).map(calendar -> {
            List<Long> ids = memberIdsStr.stream().map(Long::valueOf).collect(Collectors.toList());
            List<Member> targetMembers = memberRepository.findAllById(ids);
            List<Member> currentMembers = calendar.getMembers();
            if (currentMembers == null) currentMembers = new ArrayList<>();

            for (Member m : currentMembers) {
                if (!targetMembers.contains(m)) {
                    if (m.getCalendars() != null) {
                        m.getCalendars().remove(calendar);
                        memberRepository.save(m);
                    }
                }
            }

            for (Member m : targetMembers) {
                if (!currentMembers.contains(m)) {
                    if (m.getCalendars() == null) {
                        m.setCalendars(new ArrayList<>());
                    }
                    if (!m.getCalendars().contains(calendar)) {
                        m.getCalendars().add(calendar);
                        memberRepository.save(m);
                    }
                }
            }

            calendar.setMembers(targetMembers);
            calendarRepository.save(calendar);
            audit("SET_MEMBERS", "Calendar", calendarId, "Set " + targetMembers.size() + " members on calendar: " + calendar.getName());
            return ResponseEntity.ok(Map.of("status", "ok", "count", targetMembers.size()));
        }).orElse(ResponseEntity.notFound().build());
    }
}
