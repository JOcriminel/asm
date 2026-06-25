package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.web.AttachmentController;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.net.URI;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
@Testcontainers
public class S3AttachmentTests {

    private static final String BUCKET_NAME = "test-attachments";

    @Container
    static LocalStackContainer localstack = new LocalStackContainer(DockerImageName.parse("localstack/localstack:2.3.0"))
            .withServices(LocalStackContainer.Service.S3);

    @DynamicPropertySource
    static void configureS3(DynamicPropertyRegistry registry) {
        registry.add("aws.s3.bucket-name", () -> BUCKET_NAME);
        registry.add("aws.s3.region", localstack::getRegion);
        registry.add("aws.s3.endpoint-override", () -> localstack.getEndpointOverride(LocalStackContainer.Service.S3).toString());
        registry.add("aws.credentials.access-key", localstack::getAccessKey);
        registry.add("aws.credentials.secret-key", localstack::getSecretKey);
        
        // Setup upload configs
        registry.add("timetree.upload.max-file-size", () -> "102400"); // 100 KB limit for testing
        registry.add("timetree.upload.allowed-mime-types", () -> "application/pdf,image/png,image/jpeg,text/plain");
    }

    @BeforeAll
    static void beforeAll() {
        try (S3Client s3Client = S3Client.builder()
                .endpointOverride(localstack.getEndpointOverride(LocalStackContainer.Service.S3))
                .credentialsProvider(
                        StaticCredentialsProvider.create(
                                AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())
                        )
                )
                .region(Region.of(localstack.getRegion()))
                .build()) {
            s3Client.createBucket(CreateBucketRequest.builder().bucket(BUCKET_NAME).build());
        }
    }

    @MockBean
    private JwtDecoder jwtDecoder;

    @Autowired
    private AttachmentController attachmentController;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private CalendarRepository calendarRepository;

    @Autowired
    private EventRepository eventRepository;

    @Autowired
    private EventAttachmentRepository eventAttachmentRepository;

    @Autowired
    private S3Client s3Client;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    private Member testMember;
    private Event testEvent;

    @BeforeEach
    public void setup() {
        // Clear H2 tables
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT_ATTACHMENT");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT_MESSAGE");
        jdbcTemplate.execute("DELETE FROM dbo.TT_EVENT");
        jdbcTemplate.execute("DELETE FROM dbo.TT_CALENDAR");
        jdbcTemplate.execute("DELETE FROM dbo.TT_MEMBER");
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");

        testMember = memberRepository.save(Member.builder()
                .username("testuser")
                .fullName("Test User")
                .role("ADMIN") // Admin role bypasses permission checks
                .build());

        com.asm.dux.timetree.domain.Calendar calendar = calendarRepository.save(com.asm.dux.timetree.domain.Calendar.builder()
                .name("Test Calendar")
                .build());

        testEvent = eventRepository.save(Event.builder()
                .title("Test Event")
                .calendar(calendar)
                .startDate(LocalDateTime.now())
                .endDate(LocalDateTime.now().plusHours(1))
                .status(EventStatus.PLANNED)
                .priority(EventPriority.NORMAL)
                .build());

        mockJwt("testuser");
    }

    private void mockJwt(String username) {
        Jwt jwt = Mockito.mock(Jwt.class);
        when(jwt.getClaimAsString("preferred_username")).thenReturn(username);
        when(jwt.getSubject()).thenReturn(username);
        when(jwtDecoder.decode(anyString())).thenReturn(jwt);

        JwtAuthenticationToken auth = new JwtAuthenticationToken(jwt, Collections.emptyList());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    public void testGetPresignedUploadUrl_Success() {
        AttachmentController.PresignedUploadRequest request = new AttachmentController.PresignedUploadRequest(
                "test.pdf", 1024L, "application/pdf"
        );

        ResponseEntity<?> response = attachmentController.getPresignedUploadUrl(testEvent.getId(), request);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        AttachmentController.PresignedUploadResponse body = (AttachmentController.PresignedUploadResponse) response.getBody();
        assertNotNull(body);
        assertNotNull(body.getUploadUrl());
        assertThat(body.getUploadUrl()).contains(BUCKET_NAME);
        assertThat(body.getS3Key()).startsWith("events/" + testEvent.getId() + "/");
        assertEquals("test.pdf", body.getFileName());
        assertEquals(1024L, body.getFileSize());
        assertEquals("application/pdf", body.getContentType());
    }

    @Test
    public void testGetPresignedUploadUrl_InvalidSize() {
        // Exceeds 100KB (102400 bytes) limit
        AttachmentController.PresignedUploadRequest request = new AttachmentController.PresignedUploadRequest(
                "huge.pdf", 200000L, "application/pdf"
        );

        ResponseEntity<?> response = attachmentController.getPresignedUploadUrl(testEvent.getId(), request);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("Le fichier dépasse la limite autorisée", response.getBody());
    }

    @Test
    public void testGetPresignedUploadUrl_InvalidMime() {
        // Executable format is not in allowed list
        AttachmentController.PresignedUploadRequest request = new AttachmentController.PresignedUploadRequest(
                "malicious.exe", 1024L, "application/octet-stream"
        );

        ResponseEntity<?> response = attachmentController.getPresignedUploadUrl(testEvent.getId(), request);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertThat(response.getBody().toString()).contains("Type de fichier non autorisé");
    }

    @Test
    public void testConfirmUpload_Success() throws Exception {
        String key = "events/" + testEvent.getId() + "/unique-id/doc.txt";
        
        // Put direct to LocalStack S3
        s3Client.putObject(
                PutObjectRequest.builder().bucket(BUCKET_NAME).key(key).contentType("text/plain").build(),
                RequestBody.fromString("Hello S3 content")
        );

        AttachmentController.ConfirmUploadRequest request = new AttachmentController.ConfirmUploadRequest(
                "doc.txt", key, 16L, "text/plain"
        );

        ResponseEntity<?> response = attachmentController.confirmUpload(testEvent.getId(), request);
        assertEquals(HttpStatus.CREATED, response.getStatusCode());

        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertNotNull(body);
        assertEquals("doc.txt", body.get("fileName"));
        assertEquals(key, body.get("filePath"));
        assertEquals(16L, body.get("fileSize"));

        // Verify database persistence
        List<EventAttachment> dbAttachments = eventAttachmentRepository.findAllByEventId(testEvent.getId());
        assertEquals(1, dbAttachments.size());
        assertEquals("doc.txt", dbAttachments.get(0).getFileName());
        assertEquals(key, dbAttachments.get(0).getFilePath());
    }

    @Test
    public void testConfirmUpload_KeyMismatch() {
        // Target key belongs to event 999 instead of testEvent
        String key = "events/999/unique-id/doc.txt";

        AttachmentController.ConfirmUploadRequest request = new AttachmentController.ConfirmUploadRequest(
                "doc.txt", key, 16L, "text/plain"
        );

        ResponseEntity<?> response = attachmentController.confirmUpload(testEvent.getId(), request);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("Clé S3 invalide pour cet événement", response.getBody());
    }

    @Test
    public void testConfirmUpload_NotFoundInS3() {
        String key = "events/" + testEvent.getId() + "/missing-id/doc.txt";

        AttachmentController.ConfirmUploadRequest request = new AttachmentController.ConfirmUploadRequest(
                "doc.txt", key, 16L, "text/plain"
        );

        ResponseEntity<?> response = attachmentController.confirmUpload(testEvent.getId(), request);
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("Le fichier n'a pas été trouvé dans le stockage objet", response.getBody());
    }

    @Test
    public void testGetPresignedDownloadUrl_Success() {
        EventAttachment attachment = eventAttachmentRepository.save(EventAttachment.builder()
                .event(testEvent)
                .fileName("test.pdf")
                .filePath("events/" + testEvent.getId() + "/uuid/test.pdf")
                .fileType("application/pdf")
                .uploadedBy("testuser")
                .uploadedAt(LocalDateTime.now())
                .build());

        ResponseEntity<?> response = attachmentController.getPresignedDownloadUrl(attachment.getId());
        assertEquals(HttpStatus.OK, response.getStatusCode());

        AttachmentController.PresignedDownloadResponse body = (AttachmentController.PresignedDownloadResponse) response.getBody();
        assertNotNull(body);
        assertNotNull(body.getDownloadUrl());
        assertThat(body.getDownloadUrl()).contains(BUCKET_NAME);
        assertThat(body.getDownloadUrl()).contains("events/" + testEvent.getId() + "/uuid/test.pdf");
    }

    @Test
    public void testDeleteAttachment_Success() {
        String key = "events/" + testEvent.getId() + "/uuid/test.pdf";
        s3Client.putObject(
                PutObjectRequest.builder().bucket(BUCKET_NAME).key(key).build(),
                RequestBody.empty()
        );

        EventAttachment attachment = eventAttachmentRepository.save(EventAttachment.builder()
                .event(testEvent)
                .fileName("test.pdf")
                .filePath(key)
                .fileType("application/pdf")
                .uploadedBy("testuser")
                .uploadedAt(LocalDateTime.now())
                .build());

        ResponseEntity<?> response = attachmentController.deleteAttachment(attachment.getId());
        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());

        // Verify deleted from S3
        boolean exists = true;
        try {
            s3Client.headObject(HeadObjectRequest.builder().bucket(BUCKET_NAME).key(key).build());
        } catch (Exception e) {
            exists = false;
        }
        assertThat(exists).isFalse();

        // Verify DB soft deleted
        Optional<EventAttachment> dbAttachment = eventAttachmentRepository.findById(attachment.getId());
        assertThat(dbAttachment.isPresent()).isFalse(); // soft-delete hides it from findById due to @SQLRestriction
    }
}
