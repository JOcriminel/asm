package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Member;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class NotificationEvent extends ApplicationEvent {

    private final Member recipient;
    private final Member sender;
    private final String title;
    private final String content;
    private final String type;
    private final String entityType;
    private final Long entityId;
    private final String actionType;

    public NotificationEvent(Object source, Member recipient, Member sender, String title, String content, 
                             String type, String entityType, Long entityId, String actionType) {
        super(source);
        this.recipient = recipient;
        this.sender = sender;
        this.title = title;
        this.content = content;
        this.type = type;
        this.entityType = entityType;
        this.entityId = entityId;
        this.actionType = actionType;
    }
}
