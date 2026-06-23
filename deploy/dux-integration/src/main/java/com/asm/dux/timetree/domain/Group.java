package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDateTime;
import java.util.Set;
import java.util.List;

@Entity
@Table(name = "TT_GROUP", schema = "dbo")
@SQLDelete(sql = "UPDATE dbo.TT_GROUP SET deleted = 1 WHERE id = ?")
@SQLRestriction("deleted = 0")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Group {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "NAME", nullable = false, length = 150)
    private String name;

    @Column(name = "DESCRIPTION", length = 500)
    private String description;

    @Column(name = "ACTIVE")
    @Builder.Default
    private Boolean active = true;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(
        name = "TT_GROUP_ROLE",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "GROUP_ID")
    )
    @Column(name = "ROLE_CODE")
    private Set<String> roles;

    @ManyToMany(mappedBy = "groups", fetch = FetchType.LAZY)
    private List<Page> pages;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "CHEF_ID")
    private Member chef;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_GROUP_MEMBER",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "GROUP_ID"),
        inverseJoinColumns = @JoinColumn(name = "MEMBER_ID")
    )
    private List<Member> members;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_CALENDAR_GROUP",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "GROUP_ID"),
        inverseJoinColumns = @JoinColumn(name = "CALENDAR_ID")
    )
    private List<Calendar> calendars;
}
