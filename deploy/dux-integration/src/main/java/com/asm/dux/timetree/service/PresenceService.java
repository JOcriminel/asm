package com.asm.dux.timetree.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.messaging.SessionConnectEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.security.Principal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * Redis-backed presence service.
 *
 * Redis key schema:
 *   timetree:presence:{username}  →  "ONLINE"   TTL: configurable (default 30 s)
 *
 * Heartbeat flow:
 *   Client sends /app/heartbeat every 10 s → server calls refreshHeartbeat() → Redis TTL reset.
 *   Cleanup task runs every minute: scans active session registry; if Redis key is gone → OFFLINE.
 */
@Slf4j
@Service
public class PresenceService {

    private static final String PRESENCE_PREFIX = "timetree:presence:";

    /** sessionId → username (in-memory for session routing; presence state is in Redis) */
    private final Map<String, String> sessionToUser = new ConcurrentHashMap<>();
    /** username → set of sessionIds (multi-tab support) */
    private final Map<String, Set<String>> userToSessions = new ConcurrentHashMap<>();

    private final StringRedisTemplate redis;
    private final SimpMessageSendingOperations messagingTemplate;

    @Value("${timetree.websocket.presence.session-ttl-seconds:30}")
    private long sessionTtlSeconds;

    @Autowired
    public PresenceService(StringRedisTemplate redis,
                           SimpMessageSendingOperations messagingTemplate) {
        this.redis = redis;
        this.messagingTemplate = messagingTemplate;
    }

    // ─── Session lifecycle ───────────────────────────────────────────────────────

    @EventListener
    public void handleConnect(SessionConnectEvent event) {
        Principal principal = event.getUser();
        if (principal == null) return;
        String username = principal.getName();
        String sessionId = extractSessionId(event.getMessage().getHeaders());
        log.info("WebSocket CONNECT sessionId={} user={}", sessionId, username);
        registerUserSession(sessionId, username);
    }

    @EventListener
    public void handleDisconnect(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();
        String username = sessionToUser.remove(sessionId);
        log.info("WebSocket SessionDisconnectEvent sessionId={}", sessionId);
        if (username != null) {
            Set<String> sessions = userToSessions.getOrDefault(username, Collections.emptySet());
            sessions.remove(sessionId);
            if (sessions.isEmpty()) {
                userToSessions.remove(username);
                markOffline(username);
            }
        }
    }

    // ─── Presence operations ─────────────────────────────────────────────────────

    public void registerUserSession(String sessionId, String username) {
        sessionToUser.put(sessionId, username);
        userToSessions.computeIfAbsent(username, u -> ConcurrentHashMap.newKeySet()).add(sessionId);
        setOnline(username);
    }

    public void refreshHeartbeat(String username) {
        try {
            redis.expire(PRESENCE_PREFIX + username, sessionTtlSeconds, TimeUnit.SECONDS);
            log.debug("Heartbeat refreshed for user={} TTL={}s", username, sessionTtlSeconds);
        } catch (Exception e) {
            log.warn("Failed to refresh heartbeat for user={}", username, e);
        }
    }

    public boolean isOnline(String username) {
        try {
            return Boolean.TRUE.equals(redis.hasKey(PRESENCE_PREFIX + username));
        } catch (Exception e) {
            log.warn("Redis hasKey failed for user={}", username, e);
            return false;
        }
    }

    public Set<String> getActiveUsers() {
        return Collections.unmodifiableSet(userToSessions.keySet());
    }

    public int getActiveSessionCount() {
        return sessionToUser.size();
    }

    // ─── Internal helpers ────────────────────────────────────────────────────────

    private void setOnline(String username) {
        try {
            redis.opsForValue().set(PRESENCE_PREFIX + username, "ONLINE", sessionTtlSeconds, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.warn("Redis SET failed for user={}", username, e);
        }
        log.info("Presence update: user={} status=ONLINE", username);
    }

    private void markOffline(String username) {
        try {
            redis.delete(PRESENCE_PREFIX + username);
        } catch (Exception e) {
            log.warn("Redis DEL failed for user={}", username, e);
        }
        log.info("Presence update: user={} status=OFFLINE", username);
    }

    private String extractSessionId(org.springframework.messaging.MessageHeaders headers) {
        Object sessionId = headers.get("simpSessionId");
        return sessionId != null ? sessionId.toString() : "unknown";
    }

    // ─── TTL expiry cleanup (every configurable interval) ───────────────────────

    /**
     * Runs every minute (or per timetree.websocket.presence.cleanup-interval-ms).
     * Any user in the in-memory registry whose Redis key has expired → mark OFFLINE.
     */
    @Scheduled(fixedDelayString = "${timetree.websocket.presence.cleanup-interval-ms:60000}")
    public void cleanExpiredSessions() {
        Set<String> activeUsernames = new HashSet<>(userToSessions.keySet());
        for (String username : activeUsernames) {
            try {
                Boolean exists = redis.hasKey(PRESENCE_PREFIX + username);
                if (!Boolean.TRUE.equals(exists)) {
                    log.info("Presence TTL expired for user={} — marking OFFLINE", username);
                    userToSessions.remove(username);
                    // Remove associated sessions
                    sessionToUser.entrySet().removeIf(e -> username.equals(e.getValue()));
                    markOffline(username);
                }
            } catch (Exception e) {
                log.warn("Cleanup check failed for user={}", username, e);
            }
        }
    }
}
