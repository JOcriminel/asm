package com.asm.dux.timetree.repository;

import com.asm.dux.timetree.domain.EventAttachment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository("timetreeEventAttachmentRepository")
public interface EventAttachmentRepository extends JpaRepository<EventAttachment, Long> {
    List<EventAttachment> findAllByEventId(Long eventId);
}
