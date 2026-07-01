package com.asm.dux.timetree.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3StorageService {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket-name:dux-attachments}")
    private String bucketName;

    @Value("${aws.credentials.access-key:}")
    private String accessKey;

    @Value("${aws.credentials.secret-key:}")
    private String secretKey;

    private final java.nio.file.Path localFileStorageLocation = java.nio.file.Paths.get("uploads/attachments").toAbsolutePath().normalize();

    private boolean isLocalFallback() {
        return accessKey == null || accessKey.isBlank() || secretKey == null || secretKey.isBlank();
    }

    private String getBaseUrl() {
        try {
            org.springframework.web.context.request.RequestAttributes attributes = 
                org.springframework.web.context.request.RequestContextHolder.getRequestAttributes();
            if (attributes instanceof org.springframework.web.context.request.ServletRequestAttributes) {
                jakarta.servlet.http.HttpServletRequest request = 
                    ((org.springframework.web.context.request.ServletRequestAttributes) attributes).getRequest();
                
                String host = request.getHeader("Host");
                if (host == null || host.isBlank()) {
                    host = request.getServerName() + ":" + request.getServerPort();
                }
                
                String forwardedHost = request.getHeader("X-Forwarded-Host");
                if (forwardedHost != null && !forwardedHost.isBlank()) {
                    host = forwardedHost;
                }
                
                String scheme = request.getScheme();
                String forwardedProto = request.getHeader("X-Forwarded-Proto");
                if (forwardedProto != null && !forwardedProto.isBlank()) {
                    scheme = forwardedProto;
                }
                
                String requestUri = request.getRequestURI();
                String contextPrefix = "";
                if (requestUri != null && requestUri.startsWith("/api/dux")) {
                    contextPrefix = "/api/dux";
                }
                
                return scheme + "://" + host + contextPrefix + request.getContextPath();
            }
            return "http://localhost:9090";
        } catch (Exception e) {
            return "http://localhost:9090";
        }
    }

    public String generatePresignedUploadUrl(String key, String contentType, int expirationMinutes) {
        if (isLocalFallback()) {
            try {
                return getBaseUrl() + "/api/timetree/local-upload?key=" + org.springframework.web.util.UriUtils.encode(key, java.nio.charset.StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                return getBaseUrl() + "/api/timetree/local-upload?key=" + key;
            }
        }

        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(contentType)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expirationMinutes))
                .putObjectRequest(putObjectRequest)
                .build();

        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);
        return presignedRequest.url().toString();
    }

    public String generatePresignedDownloadUrl(String key, int expirationMinutes) {
        if (isLocalFallback()) {
            try {
                return getBaseUrl() + "/api/timetree/local-download?key=" + org.springframework.web.util.UriUtils.encode(key, java.nio.charset.StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                return getBaseUrl() + "/api/timetree/local-download?key=" + key;
            }
        }

        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(expirationMinutes))
                .getObjectRequest(getObjectRequest)
                .build();

        PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    public boolean verifyObjectExists(String key) {
        if (isLocalFallback()) {
            java.nio.file.Path filePath = localFileStorageLocation.resolve(key).normalize();
            return java.nio.file.Files.exists(filePath);
        }

        try {
            s3Client.headObject(HeadObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build());
            return true;
        } catch (NoSuchKeyException e) {
            return false;
        } catch (Exception e) {
            log.error("Failed to verify S3 object existence for key: {}", key, e);
            return false;
        }
    }

    public long getObjectSize(String key) {
        if (isLocalFallback()) {
            try {
                java.nio.file.Path filePath = localFileStorageLocation.resolve(key).normalize();
                return java.nio.file.Files.size(filePath);
            } catch (Exception e) {
                log.error("Failed to retrieve local file size for key: {}", key, e);
                throw new RuntimeException("Local file metadata retrieval failed: " + e.getMessage());
            }
        }

        try {
            HeadObjectResponse response = s3Client.headObject(HeadObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build());
            return response.contentLength();
        } catch (Exception e) {
            log.error("Failed to retrieve S3 object size for key: {}", key, e);
            throw new RuntimeException("S3 metadata retrieval failed: " + e.getMessage());
        }
    }

    public void deleteObject(String key) {
        if (isLocalFallback()) {
            try {
                java.nio.file.Path filePath = localFileStorageLocation.resolve(key).normalize();
                java.nio.file.Files.deleteIfExists(filePath);
                log.info("Successfully deleted local fallback file with key: {}", key);
                return;
            } catch (Exception e) {
                log.error("Failed to delete local fallback file with key: {}", key, e);
                throw new RuntimeException("Local file deletion failed: " + e.getMessage());
            }
        }

        try {
            s3Client.deleteObject(DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build());
            log.info("Successfully deleted S3 object with key: {}", key);
        } catch (Exception e) {
            log.error("Failed to delete S3 object with key: {}", key, e);
            throw new RuntimeException("S3 deletion failed: " + e.getMessage());
        }
    }
}
