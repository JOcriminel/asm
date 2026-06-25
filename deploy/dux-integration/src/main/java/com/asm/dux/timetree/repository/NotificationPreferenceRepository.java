package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.NotificationPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository("timetreeNotificationPreferenceRepository")
public interface NotificationPreferenceRepository extends JpaRepository<NotificationPreference, Long> {
    Optional<NotificationPreference> findByMemberId(Long memberId);
    Optional<NotificationPreference> findByMemberUsername(String username);
}
