package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TT_MEMBER", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "USERNAME", nullable = false, unique = true, length = 100)
    private String username;

    @Column(name = "FULL_NAME", nullable = false, length = 150)
    private String fullName;

    @Column(name = "EMAIL", length = 150)
    private String email;

    @Column(name = "ROLE", nullable = false, length = 50)
    private String role; // "ADMIN", "CHEF", "MEMBER"
}
