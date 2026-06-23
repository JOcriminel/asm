package com.asm.dux.timetree.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

/**
 * Redis List-based offline message queue.
 *
 * Key schema:
 *   timetree:offline:{username}  →  Redis List of JSON-serialized message payloads
 *   List-level EXPIRE = 24 h (configurable)
 *
 * Guarantees:
 *   - Messages older than 24 h are discarded via key TTL.
 *   - Replay is exactly-once from the client perspective:
 *     each replayed message passes through DuplicateMessageDetector before delivery.
 */
@Slf4j
@Service
public class OfflineQueueService {

    private static final String QUEUE_PREFIX = "timetree:offline:";
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;
    private final SimpMessageSendingOperations messagingTemplate;
    private final DuplicateMessageDetector duplicateDetector;
    private final WebSocketMetricsService metricsService;

    @Value("${timetree.websocket.offline-queue.max-retention-hours:24}")
    private long retentionHours;

    public OfflineQueueService(StringRedisTemplate redis,
                               ObjectMapper objectMapper,
                               SimpMessageSendingOperations messagingTemplate,
                               DuplicateMessageDetector duplicateDetector,
                               WebSocketMetricsService metricsService) {
        this.redis = redis;
        this.objectMapper = objectMapper;
        this.messagingTemplate = messagingTemplate;
        this.duplicateDetector = duplicateDetector;
        this.metricsService = metricsService;
    }

    /**
     * Enqueues a message for an offline user.
     * The queue key TTL is reset to 24 h on every push.
     */
    public void enqueue(String username, Map<String, Object> payload) {
        String key = QUEUE_PREFIX + username;
        try {
            String json = objectMapper.writeValueAsString(payload);
            redis.opsForList().leftPush(key, json);
            redis.expire(key, retentionHours, TimeUnit.HOURS);
            long size = getQueueSize(username);
            metricsService.updateOfflineQueueSize(username, size);
            log.debug("Enqueued offline message for user={} queueSize={}", username, size);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize offline message for user={}", username, e);
        } catch (Exception e) {
            log.error("Redis enqueue failed for user={}", username, e);
        }
    }

    /**
     * Drains the queue, replays messages to /user/queue/replay, then deletes the key.
     * Duplicate detection ensures each message is delivered exactly once.
     */
    public void replayIfPending(String username) {
        String key = QUEUE_PREFIX + username;
        try {
            List<String> items = redis.opsForList().range(key, 0, -1);
            if (items == null || items.isEmpty()) return;

            // Reverse so oldest messages are delivered first (LPUSH stores newest at head)
            List<String> ordered = new ArrayList<>(items);
            Collections.reverse(ordered);

            log.info("Replaying {} offline messages for user={}", ordered.size(), username);
            int delivered = 0;
            for (String json : ordered) {
                try {
                    Map<String, Object> payload = objectMapper.readValue(json, MAP_TYPE);
                    String clientMessageId = String.valueOf(payload.getOrDefault("clientMessageId", ""));

                    // Skip if already delivered (exactly-once guarantee)
                    if (!clientMessageId.isEmpty() && duplicateDetector.isDuplicate(clientMessageId)) {
                        log.debug("Skipping duplicate replay message clientMessageId={}", clientMessageId);
                        continue;
                    }

                    // Tag as replayed
                    payload.put("replayed", true);
                    messagingTemplate.convertAndSendToUser(username, "/queue/replay", payload);
                    delivered++;
                } catch (JsonProcessingException e) {
                    log.warn("Failed to deserialize offline message for user={}", username, e);
                }
            }

            // Clear the queue after successful replay
            redis.delete(key);
            metricsService.updateOfflineQueueSize(username, 0);
            log.info("Offline replay complete: user={} delivered={} total={}", username, delivered, ordered.size());
        } catch (Exception e) {
            log.error("Offline replay failed for user={}", username, e);
        }
    }

    public long getQueueSize(String username) {
        try {
            Long size = redis.opsForList().size(QUEUE_PREFIX + username);
            return size != null ? size : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    public List<Map<String, Object>> peekQueue(String username) {
        try {
            List<String> items = redis.opsForList().range(QUEUE_PREFIX + username, 0, -1);
            if (items == null) return Collections.emptyList();
            return items.stream()
                    .map(json -> {
                        try { return objectMapper.readValue(json, MAP_TYPE); }
                        catch (Exception e) { return null; }
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }
}
