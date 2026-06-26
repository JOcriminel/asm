package com.asm.dux.web;

import com.asm.dux.timetree.domain.CustomFieldCategory;
import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.repository.CustomFieldCategoryRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping({"/api/dux/api/timetree/custom-fields/categories", "/api/timetree/custom-fields/categories"})
@RequiredArgsConstructor
public class CustomFieldCategoryController {

    private final CustomFieldCategoryRepository customFieldCategoryRepository;
    private final MemberRepository memberRepository;

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

    private boolean hasPermission() {
        Member member = getCurrentMember();
        if (member == null) {
            log.warn("Permission check failed: User not found in database");
            return false;
        }
        String role = member.getRole().toUpperCase();
        return "ADMIN".equals(role) || "ADMINISTRATEUR".equals(role) || "CHEF".equals(role);
    }

    @GetMapping
    public ResponseEntity<List<CustomFieldCategory>> getCategories() {
        log.info("GET /api/timetree/custom-fields/categories");
        return ResponseEntity.ok(customFieldCategoryRepository.findAllByOrderByDisplayOrderAsc());
    }

    @PostMapping
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> createCategory(@RequestBody CustomFieldCategory category) {
        log.info("POST /api/timetree/custom-fields/categories - name={}", category.getName());
        if (!hasPermission()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
        }
        if (category.getName() == null || category.getName().trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Le nom de la catégorie est requis");
        }
        if (category.getDisplayOrder() == null) {
            category.setDisplayOrder(0);
        }
        CustomFieldCategory saved = customFieldCategoryRepository.save(category);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> updateCategory(@PathVariable Long id, @RequestBody CustomFieldCategory category) {
        log.info("PUT /api/timetree/custom-fields/categories/{} - name={}", id, category.getName());
        if (!hasPermission()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
        }
        return customFieldCategoryRepository.findById(id).map(existing -> {
            if (category.getName() != null && !category.getName().trim().isEmpty()) {
                existing.setName(category.getName());
            }
            if (category.getDisplayOrder() != null) {
                existing.setDisplayOrder(category.getDisplayOrder());
            }
            if (category.getActive() != null) {
                existing.setActive(category.getActive());
            }
            CustomFieldCategory saved = customFieldCategoryRepository.save(existing);
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @Transactional(value = "timertreeTransactionManager")
    public ResponseEntity<?> deleteCategory(@PathVariable Long id) {
        log.info("DELETE /api/timetree/custom-fields/categories/{}", id);
        if (!hasPermission()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Non autorisé");
        }
        return customFieldCategoryRepository.findById(id).map(category -> {
            customFieldCategoryRepository.delete(category);
            return ResponseEntity.ok().build();
        }).orElse(ResponseEntity.notFound().build());
    }
}
