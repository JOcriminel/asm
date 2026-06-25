package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "TT_EVENT", schema = "dbo")
@SQLDelete(sql = "UPDATE dbo.TT_EVENT SET deleted = 1 WHERE id = ?")
@SQLRestriction("deleted = 0")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "TITLE", nullable = false, length = 150)
    private String title;

    @Column(name = "DESCRIPTION", length = 500)
    private String description;

    @Column(name = "START_DATE", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "END_DATE", nullable = false)
    private LocalDateTime endDate;

    @Column(name = "ALL_DAY", nullable = false)
    @Builder.Default
    private Boolean allDay = false;

    @Column(name = "COLOR", length = 50)
    private String color;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "CALENDAR_ID", nullable = false)
    private Calendar calendar;

    @Column(name = "RECURRENCE_RULE", nullable = false, length = 50)
    @Builder.Default
    private String recurrenceRule = "NONE"; // NONE, DAILY, WEEKLY, MONTHLY

    @Column(name = "RECURRENCE_END_DATE")
    private LocalDateTime recurrenceEndDate;

    @Column(name = "CREATED_AT")
    private LocalDateTime createdAt;

    @Column(name = "UPDATED_AT")
    private LocalDateTime updatedAt;

    @Column(name = "CREATED_BY", length = 100)
    private String createdBy;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;

    @Column(name = "LOCKED", nullable = false)
    @Builder.Default
    private Boolean locked = false;

    @Column(name = "NOM_EVENT", length = 150)
    private String nomEvent;

    @Column(name = "TITLE_MODIFIED_DIRECTLY", nullable = false)
    @Builder.Default
    private Boolean titleModifiedDirectly = false;


    @Column(name = "IS_PRIVATE", nullable = false)
    @Builder.Default
    private Boolean isPrivate = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "STATUS", nullable = false, length = 50)
    @Builder.Default
    private EventStatus status = EventStatus.PLANNED;

    @Enumerated(EnumType.STRING)
    @Column(name = "PRIORITY", nullable = false, length = 50)
    @Builder.Default
    private EventPriority priority = EventPriority.NORMAL;

    // Event Participants Many-to-Many
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_EVENT_PARTICIPANT",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "EVENT_ID"),
        inverseJoinColumns = @JoinColumn(name = "MEMBER_ID")
    )
    private List<Member> participants;

    // Event Tags Many-to-Many
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_EVENT_TAG",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "EVENT_ID"),
        inverseJoinColumns = @JoinColumn(name = "TAG_ID")
    )
    private Set<Tag> tags;

    // Event Dependencies Many-to-Many (Self-Referential)
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "TT_EVENT_DEPENDENCY",
        schema = "dbo",
        joinColumns = @JoinColumn(name = "EVENT_ID"),
        inverseJoinColumns = @JoinColumn(name = "DEPENDS_ON_EVENT_ID")
    )
    private Set<Event> dependencies;

    // Reminders One-to-Many
    @OneToMany(mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<EventReminder> reminders;

    // Event Chat reserved relation for Sprint 9
    @OneToMany(mappedBy = "event", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<EventMessage> messages;

    // Event Attachments reserved relation for Sprint 9
    @OneToMany(mappedBy = "event", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private List<EventAttachment> attachments;
}
