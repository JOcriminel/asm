package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_USER_DEVICE", schema = "dbo")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDevice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "MEMBER_ID", nullable = false)
    private Member member;

    @Column(name = "DEVICE_TOKEN", nullable = false, length = 500)
    private String deviceToken;

    @Column(name = "PLATFORM", nullable = false, length = 50) // "ANDROID", "IOS"
    private String platform;

    @Column(name = "LAST_ACTIVE")
    private LocalDateTime lastActive;
}
