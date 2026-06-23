package com.asm.dux.timetree.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

/**
 * Redis-backed duplicate message detector.
 * Keys: timetree:dup:{clientMessageId} → serverMessageId  (TTL configurable, default 5 min)
 * On duplicate: returns the ORIGINAL serverMessageId so the ACK payload is identical.
 */
@Slf4j
@Service
public class DuplicateMessageDetector {

    private static final Pattern UUID_V4 = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"
    );
    private static final String KEY_PREFIX = "timetree:dup:";

    private final StringRedisTemplate redis;

    @Value("${timetree.websocket.duplicate-detection.ttl-minutes:5}")
    private long ttlMinutes;

    public DuplicateMessageDetector(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /** Returns true if clientMessageId is a well-formed UUID v4. */
    public boolean isValidUUID(String clientMessageId) {
        if (clientMessageId == null || clientMessageId.isBlank()) return false;
        return UUID_V4.matcher(clientMessageId).matches();
    }

    /**
     * Returns the original serverMessageId if already processed, or null if new.
     * Callers should return the same ACK to the client without reprocessing.
     */
    public String getExistingServerMessageId(String clientMessageId) {
        try {
            return redis.opsForValue().get(KEY_PREFIX + clientMessageId);
        } catch (Exception e) {
            log.warn("Redis lookup failed for clientMessageId={}, treating as non-duplicate", clientMessageId, e);
            return null;
        }
    }

    public boolean isDuplicate(String clientMessageId) {
        if (clientMessageId == null || clientMessageId.isBlank()) return false;
        return getExistingServerMessageId(clientMessageId) != null;
    }

    /** Registers clientMessageId → serverMessageId with TTL. */
    public void registerMessage(String clientMessageId, String serverMessageId) {
        if (clientMessageId == null || serverMessageId == null) return;
        try {
            redis.opsForValue().set(KEY_PREFIX + clientMessageId, serverMessageId, ttlMinutes, TimeUnit.MINUTES);
            log.debug("Registered dup cache: {} → {} TTL={}min", clientMessageId, serverMessageId, ttlMinutes);
        } catch (Exception e) {
            log.error("Redis write failed for clientMessageId={}", clientMessageId, e);
        }
    }

    /** Backwards-compatible single-arg overload. */
    public void registerMessage(String clientMessageId) {
        registerMessage(clientMessageId, clientMessageId);
    }
}
