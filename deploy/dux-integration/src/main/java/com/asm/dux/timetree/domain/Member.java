package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

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

    @Column(name = "LAST_SEEN")
    private java.time.LocalDateTime lastSeen;

    @Column(name = "CAN_CREATE_AGENDAS", nullable = false)
    @Builder.Default
    private Boolean canCreateAgendas = true;

    @Column(name = "CAN_ADD_MEMBERS", nullable = false)
    @Builder.Default
    private Boolean canAddMembers = true;

    @Column(name = "PROFILE_PICTURE")
    private String profilePicture;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_MEMBER_CALENDAR",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "MEMBER_ID"),
        inverseJoinColumns = @JoinColumn(name = "CALENDAR_ID")
    )
    @com.fasterxml.jackson.annotation.JsonProperty(access = com.fasterxml.jackson.annotation.JsonProperty.Access.WRITE_ONLY)
    private List<Calendar> calendars;
}
