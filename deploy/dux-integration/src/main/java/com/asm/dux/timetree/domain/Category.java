package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.Builder;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "TT_CATEGORY", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "NAME", nullable = false, length = 150)
    private String name;

    @Column(name = "CODE", nullable = false, unique = true, length = 100)
    private String code;

    @Column(name = "ICON", length = 100)
    private String icon;

    @Column(name = "COLOR", length = 50)
    private String color;

    @Column(name = "DISPLAY_ORDER")
    private Integer displayOrder;

    @Column(name = "ACTIVE")
    private Boolean active = true;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    @Column(name = "CREATED_BY", length = 100)
    private String createdBy;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    @Column(name = "UPDATED_BY", length = 100)
    private String updatedBy;

    @OneToMany(mappedBy = "category", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<Page> pages;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_CATEGORY_GROUP",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "CATEGORY_ID"),
        inverseJoinColumns = @JoinColumn(name = "GROUP_ID")
    )
    private List<Group> groups;
}
