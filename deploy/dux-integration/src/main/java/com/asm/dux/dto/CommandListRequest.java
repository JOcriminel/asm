package com.asm.dux.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Typed request body for the command-list endpoint.
 * Replaces the raw {@code String body} parameter on the old controller,
 * making the API contract explicit and discoverable.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CommandListRequest {

    private java.util.List<String> idDocCommercial = new java.util.ArrayList<>();
    private String idTierModal;
    private Event event = new Event();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Event {
        private int first = 0;
        private int rows = 20;
        private int sortOrder = 1;
        private java.util.Map<String, Object> filters = new java.util.HashMap<>();
        private String globalFilter;
    }
}
