package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.CustomFieldCategory;
import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.repository.CustomFieldCategoryRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import com.asm.dux.web.CustomFieldCategoryController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CustomFieldCategoryControllerTests {

    @Mock private CustomFieldCategoryRepository customFieldCategoryRepository;
    @Mock private MemberRepository memberRepository;

    private CustomFieldCategoryController controller;
    private Member adminMember;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        controller = new CustomFieldCategoryController(customFieldCategoryRepository, memberRepository);

        adminMember = Member.builder()
                .id(1L)
                .username("admin")
                .role("ADMIN")
                .build();

        // Setup mock authentication context
        Authentication authentication = mock(Authentication.class);
        when(authentication.getName()).thenReturn("admin");
        SecurityContext securityContext = mock(SecurityContext.class);
        when(securityContext.getAuthentication()).thenReturn(authentication);
        SecurityContextHolder.setContext(securityContext);

        when(memberRepository.findByUsername("admin")).thenReturn(Optional.of(adminMember));
    }

    @Test
    void testCreateCategory_Success() {
        CustomFieldCategory request = CustomFieldCategory.builder()
                .name("New Category")
                .displayOrder(5)
                .active(true)
                .build();

        when(customFieldCategoryRepository.save(any(CustomFieldCategory.class))).thenAnswer(invocation -> {
            CustomFieldCategory saved = invocation.getArgument(0);
            saved.setId(10L);
            return saved;
        });

        ResponseEntity<?> response = controller.createCategory(request);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        CustomFieldCategory result = (CustomFieldCategory) response.getBody();
        assertNotNull(result);
        assertEquals(10L, result.getId());
        assertEquals("New Category", result.getName());
        assertEquals(5, result.getDisplayOrder());
        assertTrue(result.getActive());
        verify(customFieldCategoryRepository, times(1)).save(any(CustomFieldCategory.class));
    }

    @Test
    void testUpdateCategory_Success() {
        CustomFieldCategory existing = CustomFieldCategory.builder()
                .id(10L)
                .name("Old Name")
                .displayOrder(1)
                .active(true)
                .build();

        CustomFieldCategory request = CustomFieldCategory.builder()
                .id(10L)
                .name("Updated Name")
                .displayOrder(2)
                .active(false)
                .build();

        when(customFieldCategoryRepository.findById(10L)).thenReturn(Optional.of(existing));
        when(customFieldCategoryRepository.save(any(CustomFieldCategory.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ResponseEntity<?> response = controller.updateCategory(10L, request);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        CustomFieldCategory result = (CustomFieldCategory) response.getBody();
        assertNotNull(result);
        assertEquals("Updated Name", result.getName());
        assertEquals(2, result.getDisplayOrder());
        assertFalse(result.getActive());
        verify(customFieldCategoryRepository, times(1)).save(existing);
    }
}
