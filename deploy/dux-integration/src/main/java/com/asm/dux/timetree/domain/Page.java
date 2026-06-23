package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "TT_PAGE", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Page {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "CATEGORY_ID", nullable = false)
    private Category category;

    @Column(name = "NAME", nullable = false, length = 150)
    private String name;

    @Column(name = "ROUTE", length = 250)
    private String route;

    @Column(name = "ICON", length = 100)
    private String icon;

    @Column(name = "COMPONENT_NAME", length = 150)
    private String componentName;

    @Column(name = "DISPLAY_ORDER")
    private Integer displayOrder;

    @Column(name = "ACTIVE")
    private Boolean active = true;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_PAGE_GROUP",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "PAGE_ID"),
        inverseJoinColumns = @JoinColumn(name = "GROUP_ID")
    )
    private List<Group> groups;
}
