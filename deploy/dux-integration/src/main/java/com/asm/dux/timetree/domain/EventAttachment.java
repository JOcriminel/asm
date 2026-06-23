package com.asm.dux.timetree.domain;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.SQLDelete;
import org.hibernate.annotations.SQLRestriction;
import java.time.LocalDateTime;

@Entity
@Table(name = "TT_EVENT_ATTACHMENT", schema = "dbo")
@SQLDelete(sql = "UPDATE dbo.TT_EVENT_ATTACHMENT SET deleted = 1 WHERE id = ?")
@SQLRestriction("deleted = 0")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventAttachment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "EVENT_ID", nullable = false)
    private Event event;

    @Column(name = "FILE_NAME", nullable = false, length = 255)
    private String fileName;

    @Column(name = "FILE_PATH", nullable = false, length = 500)
    private String filePath;

    @Column(name = "FILE_TYPE", nullable = false, length = 100)
    private String fileType;

    @Column(name = "ORIGINAL_FILENAME", length = 255)
    private String originalFilename;

    @Column(name = "STORED_FILENAME", length = 255)
    private String storedFilename;

    @Column(name = "FILE_SIZE")
    private Long fileSize;

    @Column(name = "UPLOADED_AT", nullable = false)
    private LocalDateTime uploadedAt;

    @Column(name = "UPLOADED_BY", nullable = false, length = 100)
    private String uploadedBy;

    @Column(name = "DELETED", nullable = false)
    @Builder.Default
    private Boolean deleted = false;
}
