package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.CustomFieldValue;
import com.asm.dux.timetree.domain.Event;
import com.asm.dux.timetree.repository.CustomFieldValueRepository;

import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class EventTitleHelper {

    public static void recalculateEventTitle(Event event, CustomFieldValueRepository valueRepo) {
        if (Boolean.TRUE.equals(event.getTitleModifiedDirectly())) {
            return;
        }

        // Find all custom field values for this event
        List<CustomFieldValue> values = valueRepo.findAllByEntityTypeAndEntityId("EVENT", event.getId().toString());

        // Filter and sort the custom fields where showEmojiInTitle is true and emoji is defined
        List<CustomFieldValue> emojiValues = values.stream()
                .filter(v -> v.getValue() != null && !v.getValue().trim().isEmpty())
                .filter(v -> Boolean.TRUE.equals(v.getShowEmojiInTitle()))
                .filter(v -> v.getField() != null && v.getField().getEmoji() != null && !v.getField().getEmoji().trim().isEmpty())
                .sorted(Comparator.comparing((CustomFieldValue v) -> v.getField().getEmojiOrder() != null ? v.getField().getEmojiOrder() : 9999)
                        .thenComparing(v -> v.getField().getSortOrder() != null ? v.getField().getSortOrder() : 0)
                        .thenComparing(v -> v.getField().getId() != null ? v.getField().getId() : 0L))
                .collect(Collectors.toList());

        // Extract emojis in order
        String emojis = emojiValues.stream()
                .map(v -> v.getField().getEmoji().trim())
                .collect(Collectors.joining(""));

        String nom = event.getNomEvent() != null ? event.getNomEvent().trim() : "";
        if (!emojis.isEmpty()) {
            event.setTitle(emojis + " " + nom);
        } else {
            event.setTitle(nom);
        }
    }
}
