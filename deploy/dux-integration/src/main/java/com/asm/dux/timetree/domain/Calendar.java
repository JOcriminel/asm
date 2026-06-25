package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;

@Entity
@Table(name = "TT_CALENDAR", schema = "dbo")
@SQLDelete(sql = "UPDATE dbo.TT_CALENDAR SET deleted = 1 WHERE id = ?")
@SQLRestriction("deleted = 0")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Calendar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "NAME", nullable = false, length = 150)
    private String name;

    @Column(name = "DESCRIPTION", columnDefinition = "VARCHAR(MAX)")
    private String description;

    @Column(name = "COLOR", length = 50)
    private String color;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @ManyToMany(mappedBy = "calendars", fetch = FetchType.EAGER)
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties("calendars")
    private List<Member> members;
}
