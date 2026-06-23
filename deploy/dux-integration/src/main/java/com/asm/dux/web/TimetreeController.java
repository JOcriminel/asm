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
    private final GroupRepository groupRepository;
    private final TimetreeAuditLogRepository auditLogRepository;
    private final MemberRepository memberRepository;
    private final CalendarRepository calendarRepository;
    private final EventRepository eventRepository;
    private final com.asm.dux.timetree.service.AuditService auditService;
    private final com.asm.dux.timetree.service.TimetreeSecurityService securityService;

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
    public ResponseEntity<List<Map<String, Object>>> getMenu() {
        log.info("GET /api/timetree/menu");
        List<Category> categories = categoryRepository.findAllByActiveTrueOrderByDisplayOrderAsc();
        List<Map<String, Object>> menu = categories.stream().map(cat -> {
            Map<String, Object> catMap = new LinkedHashMap<>();
            catMap.put("id", cat.getId().toString());
            catMap.put("title", cat.getName());
            catMap.put("path", cat.getCode() != null ? cat.getCode() : "");
            catMap.put("displayOrder", cat.getDisplayOrder() != null ? cat.getDisplayOrder() : 0);

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
    public ResponseEntity<Map<String, Object>> getDashboard() {
        log.info("GET /api/timetree/dashboard");
        long catCount = categoryRepository.count();
        long pageCount = pageRepository.count();
        long groupCount = groupRepository.count();

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("categoriesCount", (int) catCount);
        summary.put("pagesCount", (int) pageCount);
        summary.put("groupsCount", (int) groupCount);

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

        // Most Active Groups
        Map<String, Long> groupEventCounts = allEvents.stream()
                .filter(e -> e.getGroup() != null)
                .collect(Collectors.groupingBy(e -> e.getGroup().getName(), Collectors.counting()));
        List<Map<String, Object>> mostActiveGroups = groupEventCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(5)
                .map(entry -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("groupName", entry.getKey());
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
        dashboard.put("mostActiveGroups", mostActiveGroups);
        dashboard.put("mostActiveMembers", mostActiveMembers);
        dashboard.put("calendarUtilization", calendarUtilization);

        return ResponseEntity.ok(dashboard);
    }

    // ─── CATEGORIES CRUD ─────────────────────────────────────────────────────
    @GetMapping("/categories")
    public ResponseEntity<List<Category>> getCategories() {
        log.info("GET /api/timetree/categories");
        return ResponseEntity.ok(categoryRepository.findAllByOrderByDisplayOrderAsc());
    }

    @GetMapping("/categories/{id}")
    public ResponseEntity<Category> getCategory(@PathVariable Long id) {
        log.info("GET /api/timetree/categories/{}", id);
        return categoryRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/categories")
    public ResponseEntity<Category> createCategory(@RequestBody Category category) {
        log.info("POST /api/timetree/categories - {}", category.getName());
        category.setCreatedAt(LocalDateTime.now());
        category.setCreatedBy("admin");
        Category saved = categoryRepository.save(category);
        audit("CREATE", "Category", saved.getId(), "Created category: " + saved.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/categories/{id}")
    public ResponseEntity<Category> updateCategory(@PathVariable Long id, @RequestBody Category request) {
        log.info("PUT /api/timetree/categories/{}", id);
        return categoryRepository.findById(id).map(existing -> {
            existing.setName(request.getName());
            existing.setCode(request.getCode());
            existing.setIcon(request.getIcon());
            existing.setColor(request.getColor());
            existing.setDisplayOrder(request.getDisplayOrder());
            existing.setActive(request.getActive());
            existing.setUpdatedAt(LocalDateTime.now());
            existing.setUpdatedBy("admin");
            Category saved = categoryRepository.save(existing);
            audit("UPDATE", "Category", saved.getId(), "Updated category: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/categories/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable Long id) {
        log.info("DELETE /api/timetree/categories/{}", id);
        return categoryRepository.findById(id).map(existing -> {
            categoryRepository.delete(existing);
            audit("DELETE", "Category", id, "Deleted category: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/categories/{id}/activate")
    public ResponseEntity<Category> activateCategory(@PathVariable Long id) {
        log.info("PATCH /api/timetree/categories/{}/activate", id);
        return categoryRepository.findById(id).map(existing -> {
            existing.setActive(true);
            existing.setUpdatedAt(LocalDateTime.now());
            Category saved = categoryRepository.save(existing);
            audit("ACTIVATE", "Category", saved.getId(), "Activated category: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/categories/{id}/deactivate")
    public ResponseEntity<Category> deactivateCategory(@PathVariable Long id) {
        log.info("PATCH /api/timetree/categories/{}/deactivate", id);
        return categoryRepository.findById(id).map(existing -> {
            existing.setActive(false);
            existing.setUpdatedAt(LocalDateTime.now());
            Category saved = categoryRepository.save(existing);
            audit("DEACTIVATE", "Category", saved.getId(), "Deactivated category: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── PAGES CRUD ──────────────────────────────────────────────────────────
    @GetMapping("/pages")
    public ResponseEntity<List<Map<String, Object>>> getPages() {
        log.info("GET /api/timetree/pages");
        List<Page> pages = pageRepository.findAllByOrderByDisplayOrderAsc();
        List<Map<String, Object>> response = pages.stream().map(p -> {
            Map<String, Object> pMap = new LinkedHashMap<>();
            pMap.put("id", p.getId());
            pMap.put("name", p.getName());
            pMap.put("route", p.getRoute());
            pMap.put("icon", p.getIcon());
            pMap.put("componentName", p.getComponentName());
            pMap.put("displayOrder", p.getDisplayOrder());
            pMap.put("active", p.getActive());
            pMap.put("createdAt", p.getCreatedAt());
            pMap.put("updatedAt", p.getUpdatedAt());
            pMap.put("categoryId", p.getCategory() != null ? p.getCategory().getId() : null);
            pMap.put("categoryName", p.getCategory() != null ? p.getCategory().getName() : null);
            return pMap;
        }).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/pages/{id}")
    public ResponseEntity<Page> getPage(@PathVariable Long id) {
        log.info("GET /api/timetree/pages/{}", id);
        return pageRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/pages")
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
                    .name((String) requestBody.get("name"))
                    .route((String) requestBody.get("route"))
                    .icon((String) requestBody.get("icon"))
                    .componentName((String) requestBody.get("componentName"))
                    .displayOrder(requestBody.get("displayOrder") != null ? Integer.valueOf(requestBody.get("displayOrder").toString()) : 0)
                    .active(requestBody.get("active") == null || Boolean.parseBoolean(requestBody.get("active").toString()))
                    .createdAt(LocalDateTime.now())
                    .build();

            Page saved = pageRepository.save(page);
            audit("CREATE", "Page", saved.getId(), "Created page: " + saved.getName());
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception e) {
            log.error("Failed to create page", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    @PutMapping("/pages/{id}")
    public ResponseEntity<?> updatePage(@PathVariable Long id, @RequestBody Map<String, Object> requestBody) {
        log.info("PUT /api/timetree/pages/{}", id);
        return pageRepository.findById(id).map(existing -> {
            Long categoryId = requestBody.get("categoryId") != null ? Long.valueOf(requestBody.get("categoryId").toString()) : null;
            if (categoryId != null) {
                Optional<Category> catOpt = categoryRepository.findById(categoryId);
                catOpt.ifPresent(existing::setCategory);
            }
            existing.setName((String) requestBody.get("name"));
            existing.setRoute((String) requestBody.get("route"));
            existing.setIcon((String) requestBody.get("icon"));
            existing.setComponentName((String) requestBody.get("componentName"));
            existing.setDisplayOrder(requestBody.get("displayOrder") != null ? Integer.valueOf(requestBody.get("displayOrder").toString()) : 0);
            existing.setActive(requestBody.get("active") == null || Boolean.parseBoolean(requestBody.get("active").toString()));
            existing.setUpdatedAt(LocalDateTime.now());
            Page saved = pageRepository.save(existing);
            audit("UPDATE", "Page", saved.getId(), "Updated page: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().<Page>build());
    }

    @DeleteMapping("/pages/{id}")
    public ResponseEntity<Void> deletePage(@PathVariable Long id) {
        log.info("DELETE /api/timetree/pages/{}", id);
        return pageRepository.findById(id).map(existing -> {
            pageRepository.delete(existing);
            audit("DELETE", "Page", id, "Deleted page: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── GROUPS CRUD ─────────────────────────────────────────────────────────
    @GetMapping("/groups")
    public ResponseEntity<List<Group>> getGroups() {
        log.info("GET /api/timetree/groups");
        return ResponseEntity.ok(groupRepository.findAllByOrderByCreatedAtDesc());
    }

    @GetMapping("/groups/{id}")
    public ResponseEntity<Group> getGroup(@PathVariable Long id) {
        log.info("GET /api/timetree/groups/{}", id);
        return groupRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/groups")
    public ResponseEntity<Group> createGroup(@RequestBody Group group) {
        log.info("POST /api/timetree/groups - {}", group.getName());
        group.setCreatedAt(LocalDateTime.now());
        Group saved = groupRepository.save(group);
        audit("CREATE", "Group", saved.getId(), "Created group: " + saved.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/groups/{id}")
    public ResponseEntity<Group> updateGroup(@PathVariable Long id, @RequestBody Group request) {
        log.info("PUT /api/timetree/groups/{}", id);
        return groupRepository.findById(id).map(existing -> {
            existing.setName(request.getName());
            existing.setDescription(request.getDescription());
            existing.setActive(request.getActive());
            existing.setUpdatedAt(LocalDateTime.now());
            Group saved = groupRepository.save(existing);
            audit("UPDATE", "Group", saved.getId(), "Updated group: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/groups/{id}")
    public ResponseEntity<Void> deleteGroup(@PathVariable Long id) {
        log.info("DELETE /api/timetree/groups/{}", id);
        return groupRepository.findById(id).map(existing -> {
            groupRepository.delete(existing);
            audit("DELETE", "Group", id, "Deleted group: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── ROLES ───────────────────────────────────────────────────────────────
    @GetMapping("/roles")
    public ResponseEntity<List<Map<String, String>>> getRoles() {
        log.info("GET /api/timetree/roles");
        List<Map<String, String>> roles = new ArrayList<>();
        roles.add(Map.of("code", "admin", "name", "Admin"));
        roles.add(Map.of("code", "dashboard-viewer", "name", "Dashboard Viewer"));
        roles.add(Map.of("code", "dashboard-editor", "name", "Dashboard Editor"));
        roles.add(Map.of("code", "dashboard-admin", "name", "Dashboard Admin"));
        roles.add(Map.of("code", "report-admin", "name", "Report Admin"));
        roles.add(Map.of("code", "report-editor", "name", "Report Editor"));
        return ResponseEntity.ok(roles);
    }

    @PostMapping("/groups/{groupId}/roles")
    public ResponseEntity<?> assignRoleToGroup(@PathVariable Long groupId, @RequestBody Map<String, String> request) {
        log.info("POST /api/timetree/groups/{}/roles", groupId);
        String roleCode = request.get("roleCode");
        if (roleCode == null) {
            return ResponseEntity.badRequest().body("roleCode is required");
        }
        return groupRepository.findById(groupId).map(group -> {
            if (group.getRoles() == null) {
                group.setRoles(new HashSet<>());
            }
            group.getRoles().add(roleCode);
            group.setUpdatedAt(LocalDateTime.now());
            Group saved = groupRepository.save(group);
            audit("ASSIGN_ROLE", "Group", groupId, "Assigned role '" + roleCode + "' to group: " + group.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/groups/{groupId}/roles/{roleCode}")
    public ResponseEntity<?> removeRoleFromGroup(@PathVariable Long groupId, @PathVariable String roleCode) {
        log.info("DELETE /api/timetree/groups/{}/roles/{}", groupId, roleCode);
        return groupRepository.findById(groupId).map(group -> {
            if (group.getRoles() != null && group.getRoles().remove(roleCode)) {
                group.setUpdatedAt(LocalDateTime.now());
                groupRepository.save(group);
                audit("REMOVE_ROLE", "Group", groupId, "Removed role '" + roleCode + "' from group: " + group.getName());
                return ResponseEntity.ok().build();
            }
            return ResponseEntity.badRequest().body("Role not assigned to this group");
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── PERMISSIONS ─────────────────────────────────────────────────────────
    @GetMapping("/permissions")
    public ResponseEntity<Map<String, Object>> getPermissions() {
        log.info("GET /api/timetree/permissions");
        List<Category> categories = categoryRepository.findAll();
        List<Map<String, Object>> categoryPermissions = categories.stream().map(cat -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("categoryId", cat.getId().toString());
            map.put("categoryName", cat.getName());
            List<String> groupIds = cat.getGroups() != null 
                ? cat.getGroups().stream().map(g -> g.getId().toString()).collect(Collectors.toList())
                : Collections.emptyList();
            map.put("groupIds", groupIds);
            return map;
        }).collect(Collectors.toList());

        List<Page> pages = pageRepository.findAll();
        List<Map<String, Object>> pagePermissions = pages.stream().map(p -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("pageId", p.getId().toString());
            map.put("pageName", p.getName());
            List<String> groupIds = p.getGroups() != null 
                ? p.getGroups().stream().map(g -> g.getId().toString()).collect(Collectors.toList())
                : Collections.emptyList();
            map.put("groupIds", groupIds);
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("categories", categoryPermissions);
        response.put("pages", pagePermissions);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/categories/{categoryId}/groups")
    public ResponseEntity<?> assignCategoryToGroups(@PathVariable Long categoryId, @RequestBody Map<String, List<String>> request) {
        log.info("POST /api/timetree/categories/{}/groups", categoryId);
        List<String> groupIdsStr = request.get("groupIds");
        if (groupIdsStr == null) {
            return ResponseEntity.badRequest().body("groupIds is required");
        }
        return categoryRepository.findById(categoryId).map(category -> {
            List<Long> ids = groupIdsStr.stream().map(Long::valueOf).collect(Collectors.toList());
            List<Group> groups = groupRepository.findAllById(ids);
            category.setGroups(groups);
            category.setUpdatedAt(LocalDateTime.now());
            Category saved = categoryRepository.save(category);
            audit("ASSIGN_GROUPS", "Category", categoryId, "Assigned " + groups.size() + " groups to category: " + category.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/pages/{pageId}/groups")
    public ResponseEntity<?> assignPageToGroups(@PathVariable Long pageId, @RequestBody Map<String, List<String>> request) {
        log.info("POST /api/timetree/pages/{}/groups", pageId);
        List<String> groupIdsStr = request.get("groupIds");
        if (groupIdsStr == null) {
            return ResponseEntity.badRequest().body("groupIds is required");
        }
        return pageRepository.findById(pageId).map(page -> {
            List<Long> ids = groupIdsStr.stream().map(Long::valueOf).collect(Collectors.toList());
            List<Group> groups = groupRepository.findAllById(ids);
            page.setGroups(groups);
            page.setUpdatedAt(LocalDateTime.now());
            Page saved = pageRepository.save(page);
            audit("ASSIGN_GROUPS", "Page", pageId, "Assigned " + groups.size() + " groups to page: " + page.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── MEMBERS CRUD ────────────────────────────────────────────────────────
    @GetMapping("/members")
    public ResponseEntity<List<Member>> getMembers() {
        log.info("GET /api/timetree/members");
        return ResponseEntity.ok(memberRepository.findAll());
    }

    @PostMapping("/members")
    public ResponseEntity<Member> createMember(@RequestBody Member member) {
        log.info("POST /api/timetree/members - {}", member.getUsername());
        Member saved = memberRepository.save(member);
        audit("CREATE", "Member", saved.getId(), "Created member: " + saved.getFullName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/members/{id}")
    public ResponseEntity<Member> updateMember(@PathVariable Long id, @RequestBody Member request) {
        log.info("PUT /api/timetree/members/{}", id);
        return memberRepository.findById(id).map(existing -> {
            existing.setUsername(request.getUsername());
            existing.setFullName(request.getFullName());
            existing.setEmail(request.getEmail());
            existing.setRole(request.getRole());
            Member saved = memberRepository.save(existing);
            audit("UPDATE", "Member", saved.getId(), "Updated member: " + saved.getFullName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/members/{id}")
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
    public ResponseEntity<List<com.asm.dux.timetree.domain.Calendar>> getCalendars() {
        log.info("GET /api/timetree/calendars");
        return ResponseEntity.ok(calendarRepository.findAll());
    }

    @PostMapping("/calendars")
    public ResponseEntity<com.asm.dux.timetree.domain.Calendar> createCalendar(@RequestBody com.asm.dux.timetree.domain.Calendar calendar) {
        log.info("POST /api/timetree/calendars - {}", calendar.getName());
        com.asm.dux.timetree.domain.Calendar saved = calendarRepository.save(calendar);
        audit("CREATE", "Calendar", saved.getId(), "Created calendar: " + saved.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @PutMapping("/calendars/{id}")
    public ResponseEntity<com.asm.dux.timetree.domain.Calendar> updateCalendar(@PathVariable Long id, @RequestBody com.asm.dux.timetree.domain.Calendar request) {
        log.info("PUT /api/timetree/calendars/{}", id);
        return calendarRepository.findById(id).map(existing -> {
            existing.setName(request.getName());
            existing.setDescription(request.getDescription());
            existing.setColor(request.getColor());
            com.asm.dux.timetree.domain.Calendar saved = calendarRepository.save(existing);
            audit("UPDATE", "Calendar", saved.getId(), "Updated calendar: " + saved.getName());
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/calendars/{id}")
    public ResponseEntity<Void> deleteCalendar(@PathVariable Long id) {
        log.info("DELETE /api/timetree/calendars/{}", id);
        return calendarRepository.findById(id).map(existing -> {
            calendarRepository.delete(existing);
            audit("DELETE", "Calendar", id, "Deleted calendar: " + existing.getName());
            return ResponseEntity.noContent().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    // ─── GROUP MEMBERSHIP & ASSIGNMENTS ──────────────────────────────────────
    @PostMapping("/groups/{groupId}/members")
    public ResponseEntity<?> addMemberToGroup(@PathVariable Long groupId, @RequestBody Map<String, String> request) {
        log.info("POST /api/timetree/groups/{}/members", groupId);
        String memberIdStr = request.get("memberId");
        if (memberIdStr == null) {
            return ResponseEntity.badRequest().body("memberId is required");
        }
        Long memberId = Long.valueOf(memberIdStr);
        return groupRepository.findById(groupId).flatMap(group -> 
            memberRepository.findById(memberId).map(member -> {
                if (group.getMembers() == null) {
                    group.setMembers(new ArrayList<>());
                }
                if (!group.getMembers().contains(member)) {
                    group.getMembers().add(member);
                    groupRepository.save(group);
                    audit("ADD_MEMBER", "Group", groupId, "Added member " + member.getFullName() + " to group: " + group.getName());
                }
                return ResponseEntity.ok(group);
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/groups/{groupId}/members/{memberId}")
    public ResponseEntity<?> removeMemberFromGroup(@PathVariable Long groupId, @PathVariable Long memberId) {
        log.info("DELETE /api/timetree/groups/{}/members/{}", groupId, memberId);
        return groupRepository.findById(groupId).flatMap(group -> 
            memberRepository.findById(memberId).map(member -> {
                if (group.getMembers() != null && group.getMembers().remove(member)) {
                    groupRepository.save(group);
                    audit("REMOVE_MEMBER", "Group", groupId, "Removed member " + member.getFullName() + " from group: " + group.getName());
                    return ResponseEntity.ok().build();
                }
                return ResponseEntity.badRequest().body("Member not in this group");
            })
        ).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/groups/{groupId}/chef")
    public ResponseEntity<?> assignChefToGroup(@PathVariable Long groupId, @RequestBody Map<String, String> request) {
        log.info("PUT /api/timetree/groups/{}/chef", groupId);
        String chefIdStr = request.get("chefId");
        Long chefId = (chefIdStr != null && !chefIdStr.isEmpty()) ? Long.valueOf(chefIdStr) : null;
        
        return groupRepository.findById(groupId).map(group -> {
            if (chefId == null) {
                group.setChef(null);
                groupRepository.save(group);
                audit("ASSIGN_CHEF", "Group", groupId, "Removed Chef from group: " + group.getName());
                return ResponseEntity.ok(group);
            } else {
                return memberRepository.findById(chefId).map(chef -> {
                    group.setChef(chef);
                    groupRepository.save(group);
                    audit("ASSIGN_CHEF", "Group", groupId, "Assigned Chef " + chef.getFullName() + " to group: " + group.getName());
                    return ResponseEntity.ok(group);
                }).orElse(ResponseEntity.badRequest().build());
            }
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/groups/{groupId}/calendars")
    public ResponseEntity<?> assignCalendarsToGroup(@PathVariable Long groupId, @RequestBody Map<String, List<String>> request) {
        log.info("POST /api/timetree/groups/{}/calendars", groupId);
        List<String> calendarIdsStr = request.get("calendarIds");
        if (calendarIdsStr == null) {
            return ResponseEntity.badRequest().body("calendarIds is required");
        }
        return groupRepository.findById(groupId).map(group -> {
            List<Long> ids = calendarIdsStr.stream().map(Long::valueOf).collect(Collectors.toList());
            List<com.asm.dux.timetree.domain.Calendar> calendars = calendarRepository.findAllById(ids);
            group.setCalendars(calendars);
            groupRepository.save(group);
            audit("ASSIGN_CALENDARS", "Group", groupId, "Assigned " + calendars.size() + " calendars to group: " + group.getName());
            return ResponseEntity.ok(group);
        }).orElse(ResponseEntity.notFound().build());
    }
}
