package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.CustomField;
import com.asm.dux.timetree.domain.CustomFieldValue;
import com.asm.dux.timetree.domain.Event;
import com.asm.dux.timetree.repository.CustomFieldValueRepository;
import com.asm.dux.timetree.service.EventTitleHelper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Arrays;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

class CustomFieldTitleTests {

    @Mock
    private CustomFieldValueRepository customFieldValueRepository;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testRecalculateEventTitle_TitleModifiedDirectlyTrue() {
        Event event = Event.builder()
                .id(1L)
                .title("Direct Title")
                .nomEvent("Original Name")
                .titleModifiedDirectly(true)
                .build();

        EventTitleHelper.recalculateEventTitle(event, customFieldValueRepository);

        assertEquals("Direct Title", event.getTitle());
    }

    @Test
    void testRecalculateEventTitle_NoCustomFields() {
        Event event = Event.builder()
                .id(1L)
                .title("Original Name")
                .nomEvent("Original Name")
                .titleModifiedDirectly(false)
                .build();

        when(customFieldValueRepository.findAllByEntityTypeAndEntityId("EVENT", "1"))
                .thenReturn(Collections.emptyList());

        EventTitleHelper.recalculateEventTitle(event, customFieldValueRepository);

        assertEquals("Original Name", event.getTitle());
    }

    @Test
    void testRecalculateEventTitle_WithEmojisAndSorting() {
        Event event = Event.builder()
                .id(1L)
                .title("Test Name")
                .nomEvent("Test Name")
                .titleModifiedDirectly(false)
                .build();

        CustomField cf1 = CustomField.builder()
                .id(101L)
                .name("Field 1")
                .emoji("🍎")
                .emojiOrder(2)
                .sortOrder(1)
                .build();

        CustomField cf2 = CustomField.builder()
                .id(102L)
                .name("Field 2")
                .emoji("⭐")
                .emojiOrder(1)
                .sortOrder(2)
                .build();

        CustomField cf3 = CustomField.builder()
                .id(103L)
                .name("Field 3")
                .emoji("🔥")
                .emojiOrder(3)
                .sortOrder(3)
                .build();

        CustomFieldValue val1 = CustomFieldValue.builder()
                .field(cf1)
                .value("Value 1")
                .showEmojiInTitle(true)
                .build();

        CustomFieldValue val2 = CustomFieldValue.builder()
                .field(cf2)
                .value("Value 2")
                .showEmojiInTitle(true)
                .build();

        CustomFieldValue val3 = CustomFieldValue.builder()
                .field(cf3)
                .value("Value 3")
                .showEmojiInTitle(false) // should be ignored
                .build();

        when(customFieldValueRepository.findAllByEntityTypeAndEntityId("EVENT", "1"))
                .thenReturn(Arrays.asList(val1, val2, val3));

        EventTitleHelper.recalculateEventTitle(event, customFieldValueRepository);

        // Ordered by emojiOrder: cf2 (1) then cf1 (2). cf3 is excluded since showEmojiInTitle = false.
        assertEquals("⭐🍎 Test Name", event.getTitle());
    }

    @Test
    void testRecalculateEventTitle_NullEmojiOrderFallback() {
        Event event = Event.builder()
                .id(1L)
                .title("Event Name")
                .nomEvent("Event Name")
                .titleModifiedDirectly(false)
                .build();

        CustomField cf1 = CustomField.builder()
                .id(101L)
                .name("Field 1")
                .emoji("🎈")
                .emojiOrder(null) // Should default to 9999
                .sortOrder(1)
                .build();

        CustomField cf2 = CustomField.builder()
                .id(102L)
                .name("Field 2")
                .emoji("✨")
                .emojiOrder(5)
                .sortOrder(2)
                .build();

        CustomFieldValue val1 = CustomFieldValue.builder()
                .field(cf1)
                .value("Val 1")
                .showEmojiInTitle(true)
                .build();

        CustomFieldValue val2 = CustomFieldValue.builder()
                .field(cf2)
                .value("Val 2")
                .showEmojiInTitle(true)
                .build();

        when(customFieldValueRepository.findAllByEntityTypeAndEntityId("EVENT", "1"))
                .thenReturn(Arrays.asList(val1, val2));

        EventTitleHelper.recalculateEventTitle(event, customFieldValueRepository);

        // cf2 (5) comes before cf1 (null -> 9999)
        assertEquals("✨🎈 Event Name", event.getTitle());
    }
}
