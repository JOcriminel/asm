package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.EventMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

@Repository("timetreeEventMessageRepository")
public interface EventMessageRepository extends JpaRepository<EventMessage, Long> {
    List<EventMessage> findAllByEventIdOrderBySentAtAsc(Long eventId);
    Page<EventMessage> findAllByEventId(Long eventId, Pageable pageable);
    long countByEventId(Long eventId);
    long countByEventIdAndIdGreaterThan(Long eventId, Long id);
}
