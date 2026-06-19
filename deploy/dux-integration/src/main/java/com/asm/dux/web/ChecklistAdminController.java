package com.asm.dux.web;

import com.asm.dux.domain.model.*;
import com.asm.dux.infrastructure.db.repository.*;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Value;
import com.asm.dux.infrastructure.dux.DuxHttpClient;

import java.util.List;

@RestController
@RequestMapping("/api/dux/admin/checklists")
public class ChecklistAdminController {

    private final ChecklistGroupRepository groupRepository;
    private final ChecklistFamilyMappingRepository mappingRepository;
    private final ChecklistTaskTypeRepository typeRepository;
    private final ChecklistTaskRepository taskRepository;
    private final DuxHttpClient duxHttpClient;
    private final JdbcTemplate jdbcTemplate;

    @Value("${dux.family-url:https://duxweb.pre-produx.asmtechtn.com/api/Famille/findall}")
    private String familyUrl;

    public ChecklistAdminController(ChecklistGroupRepository groupRepository,
                                    ChecklistFamilyMappingRepository mappingRepository,
                                    ChecklistTaskTypeRepository typeRepository,
                                    ChecklistTaskRepository taskRepository,
                                    DuxHttpClient duxHttpClient,
                                    JdbcTemplate jdbcTemplate) {
        this.groupRepository = groupRepository;
        this.mappingRepository = mappingRepository;
        this.typeRepository = typeRepository;
        this.taskRepository = taskRepository;
        this.duxHttpClient = duxHttpClient;
        this.jdbcTemplate = jdbcTemplate;
    }

    // ============================================
    // GROUPS
    // ============================================
    @GetMapping("/groups")
    public List<ChecklistGroup> getAllGroups() {
        return groupRepository.findAll();
    }

    @PostMapping("/groups")
    public ChecklistGroup createGroup(@RequestBody ChecklistGroup group) {
        return groupRepository.save(group);
    }

    @DeleteMapping("/groups/{id}")
    public ResponseEntity<?> deleteGroup(@PathVariable Long id) {
        mappingRepository.deleteByGroupId(id);
        List<ChecklistTask> tasks = taskRepository.findByGroupId(id);
        taskRepository.deleteAll(tasks);
        groupRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ============================================
    // ERP FAMILIES
    // ============================================
    @GetMapping("/erp-families")
    public ResponseEntity<String> getErpFamilies() {
        try {
            String response = duxHttpClient.get(familyUrl);
            return ResponseEntity.ok()
                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                .body(response);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body("{\"error\": \"" + e.getMessage() + "\"}");
        }
    }

    // ============================================
    // MAPPINGS (Families -> Groups)
    // ============================================
    @GetMapping("/groups/{groupId}/families")
    public List<ChecklistFamilyMapping> getFamiliesByGroup(@PathVariable Long groupId) {
        return mappingRepository.findByGroupId(groupId);
    }

    @GetMapping("/families/{codeFamille}")
    public List<ChecklistFamilyMapping> getMappingByCodeFamille(@PathVariable String codeFamille) {
        return mappingRepository.findByCodeFamille(codeFamille);
    }

    @PostMapping("/groups/{groupId}/families")
    public ChecklistFamilyMapping addFamilyToGroup(@PathVariable Long groupId, @RequestBody ChecklistFamilyMapping mapping) {
        ChecklistGroup group = groupRepository.findById(groupId).orElseThrow();
        mapping.setGroup(group);
        return mappingRepository.save(mapping);
    }

    @DeleteMapping("/families/mappings/{mappingId}")
    public ResponseEntity<?> deleteFamilyMapping(@PathVariable Long mappingId) {
        mappingRepository.deleteById(mappingId);
        return ResponseEntity.ok().build();
    }

    // ============================================
    // TASK TYPES
    // ============================================
    @GetMapping("/types")
    public List<ChecklistTaskType> getAllTypes() {
        return typeRepository.findAll();
    }

    @PostMapping("/types")
    public ChecklistTaskType createType(@RequestBody ChecklistTaskType type) {
        return typeRepository.save(type);
    }

    @PutMapping("/types/{id}")
    public ChecklistTaskType updateType(@PathVariable Long id, @RequestBody ChecklistTaskType typeDetails) {
        ChecklistTaskType type = typeRepository.findById(id).orElseThrow();
        type.setName(typeDetails.getName());
        type.setInformation(typeDetails.getInformation());
        return typeRepository.save(type);
    }

    @DeleteMapping("/types/{id}")
    public ResponseEntity<?> deleteType(@PathVariable Long id) {
        List<ChecklistTask> tasks = taskRepository.findByTypeId(id);
        taskRepository.deleteAll(tasks);
        typeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ============================================
    // TASKS
    // ============================================
    @GetMapping("/tasks")
    public List<ChecklistTask> getAllTasks() {
        return taskRepository.findAll();
    }

    @GetMapping("/groups/{groupId}/tasks")
    public List<ChecklistTask> getTasksByGroup(@PathVariable Long groupId) {
        return taskRepository.findByGroupId(groupId);
    }

    @PostMapping("/tasks")
    public ChecklistTask createTask(
            @RequestParam(required = false) Long groupId,
            @RequestParam(required = false) String codeFamille,
            @RequestParam Long typeId,
            @RequestBody ChecklistTask task) {
        
        ChecklistTaskType type = typeRepository.findById(typeId).orElseThrow();
        task.setType(type);
        
        if (groupId != null) {
            ChecklistGroup group = groupRepository.findById(groupId).orElseThrow();
            task.setGroup(group);
        } else if (codeFamille != null && !codeFamille.trim().isEmpty()) {
            task.setCodeFamille(codeFamille);
        } else {
            throw new IllegalArgumentException("Either groupId or codeFamille must be provided");
        }
        
        return taskRepository.save(task);
    }

    @PutMapping("/tasks/{id}")
    public ChecklistTask updateTask(
            @PathVariable Long id,
            @RequestParam(required = false) Long groupId,
            @RequestParam(required = false) String codeFamille,
            @RequestParam Long typeId,
            @RequestBody ChecklistTask taskDetails) {
        
        ChecklistTask task = taskRepository.findById(id).orElseThrow();
        task.setNomTache(taskDetails.getNomTache());
        task.setInformation(taskDetails.getInformation());
        
        ChecklistTaskType type = typeRepository.findById(typeId).orElseThrow();
        task.setType(type);
        
        if (groupId != null) {
            ChecklistGroup group = groupRepository.findById(groupId).orElseThrow();
            task.setGroup(group);
            task.setCodeFamille(null);
        } else if (codeFamille != null && !codeFamille.trim().isEmpty()) {
            task.setCodeFamille(codeFamille);
            task.setGroup(null);
        } else {
            throw new IllegalArgumentException("Either groupId or codeFamille must be provided");
        }
        
        return taskRepository.save(task);
    }

    @DeleteMapping("/tasks/{id}")
    public ResponseEntity<?> deleteTask(@PathVariable Long id) {
        taskRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/tasks/{id}/active")
    public ChecklistTask toggleTaskActive(@PathVariable Long id, @RequestParam boolean active) {
        ChecklistTask task = taskRepository.findById(id).orElseThrow();
        task.setActive(active);
        return taskRepository.save(task);
    }

    @GetMapping("/articles")
    public List<java.util.Map<String, Object>> getArticles(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        String jsonPayload = String.format(
            "{\"first\":%d,\"rows\":%d,\"sortField\":\"libelle\",\"sortOrder\":1,\"filters\":{},\"globalFilter\":%s}",
            page * size,
            size,
            search != null && !search.trim().isEmpty() ? "\"" + search.trim() + "\"" : "null"
        );
        List<java.util.Map<String, Object>> resultList = new java.util.ArrayList<>();
        try {
            String erpResponse = duxHttpClient.post("https://duxweb.pre-produx.asmtechtn.com/api/article/getAllArticleByServerSide", jsonPayload);
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(erpResponse);
            com.fasterxml.jackson.databind.JsonNode dataNode = root.path("data");
            if (dataNode.isArray()) {
                for (com.fasterxml.jackson.databind.JsonNode articleNode : dataNode) {
                    java.util.Map<String, Object> map = new java.util.HashMap<>();
                    String id = articleNode.path("id").asText("");
                    String code = articleNode.path("code").asText("");
                    String libelle = articleNode.path("libelle").asText("");
                    String libelleFamille = articleNode.path("libelleFamille").asText("");

                    map.put("id", id);
                    map.put("code", code);
                    map.put("libelle", libelle);
                    map.put("libelleFamille", libelleFamille);

                    String codeFamille = "";
                    if (!id.isEmpty()) {
                        try {
                            codeFamille = jdbcTemplate.queryForObject(
                                "SELECT TOP 1 codeFamille FROM P_Article WHERE id = ?",
                                String.class,
                                id
                            );
                        } catch (Exception e) {
                            // ignore
                        }
                    }
                    if ((codeFamille == null || codeFamille.isEmpty()) && !code.isEmpty()) {
                        try {
                            codeFamille = jdbcTemplate.queryForObject(
                                "SELECT TOP 1 codeFamille FROM P_Article WHERE code = ?",
                                String.class,
                                code
                            );
                        } catch (Exception e) {
                            // ignore
                        }
                    }

                    map.put("codeFamille", codeFamille != null ? codeFamille : "");
                    resultList.add(map);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return resultList;
    }
}
