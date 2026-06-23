package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

@Entity
@Table(name = "CF_DEFINITION", schema = "dbo")
@SQLDelete(sql = "UPDATE dbo.CF_DEFINITION SET deleted = 1 WHERE id = ?")
@SQLRestriction("deleted = 0")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomField {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "NAME", nullable = false, length = 100)
    private String name;

    @Column(name = "LABEL", nullable = false, length = 150)
    private String label;

    @Column(name = "FIELD_TYPE", nullable = false, length = 50)
    private String fieldType; // e.g. STRING, TEXT_AREA, INTEGER, FLOAT, BOOLEAN, DATE, DATETIME, EMAIL, PHONE, URL, RADIO, CHECKBOX, DROPDOWN, MULTI_SELECT

    @Column(name = "REQUIRED", nullable = false)
    @Builder.Default
    private Boolean required = false;

    @Column(name = "DEFAULT_VALUE", length = 500)
    private String defaultValue;

    @Column(name = "OPTIONS", length = 1000)
    private String options; // Comma-separated list for select types

    @Column(name = "SCOPE_TYPE", nullable = false, length = 100)
    private String scopeType; // e.g. "GROUP", "CALENDAR", "EVENT", "GLOBAL"

    @Column(name = "SCOPE_ID", length = 100)
    private String scopeId; // The ID of the group, calendar, or event

    @Column(name = "SORT_ORDER", nullable = false)
    private Integer sortOrder;

    @Column(name = "ACTIVE", nullable = false)
    @Builder.Default
    private Boolean active = true;

    // Validation limits
    @Column(name = "MIN_VALUE")
    private Double minValue;

    @Column(name = "MAX_VALUE")
    private Double maxValue;

    @Column(name = "MIN_LENGTH")
    private Integer minLength;

    @Column(name = "MAX_LENGTH")
    private Integer maxLength;

    @Column(name = "REGEX_PATTERN", length = 500)
    private String regexPattern;

    // Display rules
    @Column(name = "HIDDEN", nullable = false)
    @Builder.Default
    private Boolean hidden = false;

    @Column(name = "READ_ONLY", nullable = false)
    @Builder.Default
    private Boolean readOnly = false;

    @Column(name = "VISIBILITY_RULE", length = 1000)
    private String visibilityRule;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
