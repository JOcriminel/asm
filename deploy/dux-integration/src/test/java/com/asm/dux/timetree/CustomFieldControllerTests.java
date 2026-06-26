package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.AuditService;
import com.asm.dux.timetree.service.NotificationService;
import com.asm.dux.web.CustomFieldController;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CustomFieldControllerTests {

    @Mock private CustomFieldRepository customFieldRepository;
    @Mock private CustomFieldValueRepository customFieldValueRepository;
    @Mock private MemberRepository memberRepository;
    @Mock private EventRepository eventRepository;
    @Mock private EventMessageRepository eventMessageRepository;
    @Mock private NotificationService notificationService;
    @Mock private AuditService auditService;

    private CustomFieldController controller;
    private Member adminMember;
    private CustomFieldCategory mockCategory;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        controller = new CustomFieldController(
                customFieldRepository,
                customFieldValueRepository,
                memberRepository,
                eventRepository,
                eventMessageRepository,
                notificationService,
                auditService
        );

        adminMember = Member.builder()
                .id(1L)
                .username("admin")
                .role("ADMIN")
                .build();

        mockCategory = CustomFieldCategory.builder()
                .id(10L)
                .name("Test Category")
                .displayOrder(1)
                .active(true)
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
    void testCreateCustomField_SavesCategory() {
        CustomField request = CustomField.builder()
                .name("Custom Field 1")
                .label("CF 1")
                .fieldType("STRING")
                .scopeType("GLOBAL")
                .category(mockCategory)
                .active(true)
                .build();

        when(customFieldRepository.save(any(CustomField.class))).thenAnswer(invocation -> {
            CustomField saved = invocation.getArgument(0);
            saved.setId(100L);
            return saved;
        });

        ResponseEntity<?> response = controller.createCustomField(request);
        assertEquals(HttpStatus.CREATED, response.getStatusCode());

        CustomField result = (CustomField) response.getBody();
        assertNotNull(result);
        assertEquals(100L, result.getId());
        assertEquals("Custom Field 1", result.getName());
        assertNotNull(result.getCategory());
        assertEquals(10L, result.getCategory().getId());
        verify(customFieldRepository, times(1)).save(any(CustomField.class));
    }

    @Test
    void testUpdateCustomField_UpdatesCategory() {
        CustomField existing = CustomField.builder()
                .id(100L)
                .name("Old Name")
                .label("Old Label")
                .fieldType("STRING")
                .scopeType("GLOBAL")
                .active(true)
                .build();

        CustomField request = CustomField.builder()
                .id(100L)
                .name("New Name")
                .label("New Label")
                .fieldType("STRING")
                .scopeType("GLOBAL")
                .category(mockCategory)
                .active(true)
                .build();

        when(customFieldRepository.findById(100L)).thenReturn(Optional.of(existing));
        when(customFieldRepository.save(any(CustomField.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ResponseEntity<?> response = controller.updateCustomField(100L, request);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        CustomField result = (CustomField) response.getBody();
        assertNotNull(result);
        assertEquals("New Name", result.getName());
        assertNotNull(result.getCategory());
        assertEquals(10L, result.getCategory().getId());
        verify(customFieldRepository, times(1)).save(existing);
    }
}
