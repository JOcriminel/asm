package com.asm.dux.timetree.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.util.UUID;

@Slf4j
@Service("localFileStorageService")
public class LocalFileStorageService implements FileStorageService {

    private final Path fileStorageLocation;

    public LocalFileStorageService(@Value("${timetree.upload-dir:uploads/attachments}") String uploadDir) {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
            log.info("Initialized file storage location at: {}", this.fileStorageLocation);
        } catch (Exception ex) {
            log.error("Could not create the directory where the uploaded files will be stored.", ex);
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored.", ex);
        }
    }

    @Override
    public String storeFile(MultipartFile file, String subDir) throws IOException {
        // Clean original filename
        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename() != null ? file.getOriginalFilename() : "unnamed");
        
        // Prevent path traversal
        if (originalFilename.contains("..")) {
            throw new SecurityException("Filename contains invalid path sequence: " + originalFilename);
        }

        // Generate unique stored filename
        String extension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex >= 0) {
            extension = originalFilename.substring(dotIndex);
        }
        String storedFilename = UUID.randomUUID().toString() + extension;

        // Resolve target folder and target file path
        Path targetDir = this.fileStorageLocation.resolve(subDir).normalize();
        Files.createDirectories(targetDir);
        Path targetFilePath = targetDir.resolve(storedFilename);

        // Save file to disk
        Files.copy(file.getInputStream(), targetFilePath, StandardCopyOption.REPLACE_EXISTING);
        log.info("Stored file on local disk: {}", targetFilePath);

        // Return relative path to target folder (for database reference)
        return subDir + "/" + storedFilename;
    }

    @Override
    public byte[] loadFile(String filePath) throws IOException {
        Path path = this.fileStorageLocation.resolve(filePath).normalize();
        if (!path.startsWith(this.fileStorageLocation)) {
            throw new SecurityException("Access outside storage sandbox is denied: " + filePath);
        }
        if (!Files.exists(path)) {
            throw new NoSuchFileException("File not found: " + filePath);
        }
        return Files.readAllBytes(path);
    }

    @Override
    public void deleteFile(String filePath) throws IOException {
        Path path = this.fileStorageLocation.resolve(filePath).normalize();
        if (!path.startsWith(this.fileStorageLocation)) {
            throw new SecurityException("Access outside storage sandbox is denied: " + filePath);
        }
        if (Files.exists(path)) {
            Files.delete(path);
            log.info("Deleted file from disk: {}", path);
        }
    }
}
