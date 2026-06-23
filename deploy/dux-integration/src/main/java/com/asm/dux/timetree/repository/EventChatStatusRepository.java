package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.EventChatStatus;
import com.asm.dux.timetree.domain.EventChatStatusId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository("timetreeEventChatStatusRepository")
public interface EventChatStatusRepository extends JpaRepository<EventChatStatus, EventChatStatusId> {
    Optional<EventChatStatus> findByEventIdAndMemberId(Long eventId, Long memberId);
}
