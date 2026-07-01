package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository("timetreeUserDeviceRepository")
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {
    List<UserDevice> findByMemberId(Long memberId);
    Optional<UserDevice> findByDeviceToken(String deviceToken);
    void deleteByDeviceToken(String deviceToken);
}
