package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "CF_VALUE", schema = "dbo", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"ENTITY_TYPE", "ENTITY_ID", "FIELD_ID"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomFieldValue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "FIELD_ID", nullable = false)
    private CustomField field;

    @Column(name = "ENTITY_TYPE", nullable = false, length = 100)
    private String entityType; // e.g. "EVENT", "CHECKLIST_RESPONSE", etc.

    @Column(name = "ENTITY_ID", nullable = false, length = 100)
    private String entityId;

    @Column(name = "VALUE", length = 2000)
    private String value;

    @Column(name = "SHOW_EMOJI_IN_TITLE", nullable = false)
    @Builder.Default
    private Boolean showEmojiInTitle = false;
}

