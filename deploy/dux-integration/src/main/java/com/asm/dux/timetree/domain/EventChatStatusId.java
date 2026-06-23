package com.asm.dux.timetree.domain;

import java.io.Serializable;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EventChatStatusId implements Serializable {
    private Long event;
    private Long member;
}
