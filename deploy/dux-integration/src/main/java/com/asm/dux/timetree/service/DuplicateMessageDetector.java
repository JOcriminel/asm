package com.asm.dux.timetree.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class DuplicateMessageDetector {

    // Maps clientMessageId -> processing timestamp
    private final Map<String, Long> processedMessages = new ConcurrentHashMap<>();
    
    // 24 hours expiration TTL
    private static final long CACHE_TTL_MS = 24 * 60 * 60 * 1000L;

    public boolean isDuplicate(String clientMessageId) {
        if (clientMessageId == null || clientMessageId.trim().isEmpty()) {
            return false;
        }
        return processedMessages.containsKey(clientMessageId);
    }

    public void registerMessage(String clientMessageId) {
        if (clientMessageId != null && !clientMessageId.trim().isEmpty()) {
            processedMessages.put(clientMessageId, System.currentTimeMillis());
        }
    }

    // Cron running every hour to clean up duplicate cache entries older than 24h
    @Scheduled(fixedDelay = 3600000)
    public void cleanExpiredCache() {
        long now = System.currentTimeMillis();
        processedMessages.entrySet().removeIf(entry -> now - entry.getValue() > CACHE_TTL_MS);
        log.info("Duplicate detection cache cleanup executed. Active records={}", processedMessages.size());
    }
}
