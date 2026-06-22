package com.asm.dux.web;

import com.asm.dux.domain.model.Category;
import com.asm.dux.infrastructure.db.repository.CategoryRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/dux/categories")
public class CategoryController {

    private final CategoryRepository repository;
    private final JdbcTemplate jdbcTemplate;

    public CategoryController(CategoryRepository repository, JdbcTemplate jdbcTemplate) {
        this.repository = repository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public ResponseEntity<List<Category>> getCategories() {
        log.info("GET /api/dux/categories");
        List<Category> list = repository.findAll();
        if (list.isEmpty()) {
            log.info("No categories found. Initializing default category 'Gestion de Vente'...");
            Category defaultCat = repository.save(new Category("Gestion de Vente", true));
            list = List.of(defaultCat);
        }
        return ResponseEntity.ok(list);
    }

    @PostMapping
    public ResponseEntity<?> createCategory(@RequestBody Category category) {
        log.info("POST /api/dux/categories - name={}", category != null ? category.getName() : "null");
        if (category == null || category.getName() == null || category.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Category name cannot be empty");
        }
        String name = category.getName().trim();
        if (repository.existsById(name)) {
            return ResponseEntity.badRequest().body("Category already exists");
        }
        Category saved = repository.save(new Category(name, category.isActive()));
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{oldName}")
    public ResponseEntity<?> updateCategory(@PathVariable String oldName, @RequestBody Category newCategory) {
        log.info("PUT /api/dux/categories/{} - newName={}, active={}", oldName, newCategory.getName(), newCategory.isActive());
        if (newCategory == null || newCategory.getName() == null || newCategory.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Category name cannot be empty");
        }
        String newName = newCategory.getName().trim();
        
        if (!repository.existsById(oldName)) {
            return ResponseEntity.notFound().build();
        }

        if (!oldName.equals(newName)) {
            // Rename category: primary key changes
            if (repository.existsById(newName)) {
                return ResponseEntity.badRequest().body("Category with new name already exists");
            }
            // 1. Save new category
            Category created = repository.save(new Category(newName, newCategory.isActive()));
            // 2. Cascade update ScreenConfigs referencing oldName
            jdbcTemplate.update("UPDATE dux_screen_configs SET category = ? WHERE category = ?", newName, oldName);
            // 3. Delete old category record
            repository.deleteById(oldName);
            return ResponseEntity.ok(created);
        } else {
            // Simple update (active toggle)
            Category existing = repository.findById(oldName).orElseThrow();
            existing.setActive(newCategory.isActive());
            Category updated = repository.save(existing);
            return ResponseEntity.ok(updated);
        }
    }

    @DeleteMapping("/{name}")
    public ResponseEntity<Void> deleteCategory(@PathVariable String name) {
        log.info("DELETE (soft) /api/dux/categories/{}", name);
        if (repository.existsById(name)) {
            Category category = repository.findById(name).orElseThrow();
            category.setActive(false);
            repository.save(category);
        }
        return ResponseEntity.ok().build();
    }
}
