package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
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

    @Column(name = "DESCRIPTION", length = 500)
    private String description;

    @Column(name = "COLOR", length = 50)
    private String color;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
