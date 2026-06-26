package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.CustomFieldValue;
import com.asm.dux.timetree.domain.Event;
import com.asm.dux.timetree.repository.CustomFieldValueRepository;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

public class EventTitleHelper {

    private static String getEffectiveEmoji(CustomFieldValue v) {
        if (v.getField() == null) {
            return "";
        }
        // 1. If field definition has a field-level emoji, use it
        if (v.getField().getEmoji() != null && !v.getField().getEmoji().trim().isEmpty()) {
            return v.getField().getEmoji().trim();
        }
        // 2. Otherwise, check if the value itself has option-level emojis (format: option|emoji)
        String val = v.getValue();
        if (val != null && !val.trim().isEmpty()) {
            List<String> emojis = new ArrayList<>();
            // Split by comma in case of multi-select
            String[] parts = val.split(",");
            for (String part : parts) {
                part = part.trim();
                if (part.contains("|")) {
                    String[] optParts = part.split("\\|");
                    if (optParts.length >= 2) {
                        String emoji = optParts[1].trim();
                        if (!emoji.isEmpty()) {
                            emojis.add(emoji);
                        }
                    }
                }
            }
            if (!emojis.isEmpty()) {
                return String.join("", emojis);
            }
        }
        return "";
    }

    public static void recalculateEventTitle(Event event, CustomFieldValueRepository valueRepo) {
        if (Boolean.TRUE.equals(event.getTitleModifiedDirectly())) {
            return;
        }

        // Find all custom field values for this event
        List<CustomFieldValue> values = valueRepo.findAllByEntityTypeAndEntityId("EVENT", event.getId().toString());

        // Filter and sort the custom fields where showEmojiInTitle is true and an emoji is resolved (field-level or option-level)
        List<CustomFieldValue> emojiValues = values.stream()
                .filter(v -> v.getValue() != null && !v.getValue().trim().isEmpty())
                .filter(v -> Boolean.TRUE.equals(v.getShowEmojiInTitle()))
                .filter(v -> !getEffectiveEmoji(v).isEmpty())
                .sorted(Comparator.comparing((CustomFieldValue v) -> v.getField().getEmojiOrder() != null ? v.getField().getEmojiOrder() : 9999)
                        .thenComparing(v -> v.getField().getSortOrder() != null ? v.getField().getSortOrder() : 0)
                        .thenComparing(v -> v.getField().getId() != null ? v.getField().getId() : 0L))
                .collect(Collectors.toList());

        // Extract emojis in order
        String emojis = emojiValues.stream()
                .map(EventTitleHelper::getEffectiveEmoji)
                .collect(Collectors.joining(""));

        String nom = event.getNomEvent() != null ? event.getNomEvent().trim() : "";
        if (!emojis.isEmpty()) {
            event.setTitle(emojis + " " + nom);
        } else {
            event.setTitle(nom);
        }
    }
}
