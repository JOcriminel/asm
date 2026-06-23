package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TT_TAG", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tag {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "NAME", nullable = false, unique = true, length = 50)
    private String name;

    @Column(name = "COLOR", length = 50)
    private String color;
}
