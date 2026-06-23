package com.asm.dux.timetree.security;

import com.asm.dux.timetree.service.DuplicateMessageDetector;
import com.asm.dux.timetree.service.WebSocketMetricsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

/**
 * Rate-limiting interceptor with configurable thresholds (application.yml) and UUID v4 validation.
 *
 * Rate limits (configurable via timetree.websocket.rate-limit.*):
 *   Typing    : 1 event / 2 s = 0.5/s  capacity=2
 *   Chat SEND : 5 msg/s               capacity=10
 *
 * UUID v4 validation: any SEND frame without a valid clientMessageId UUID v4 is rejected.
 */
@Slf4j
@Component
public class WebSocketRateLimitingInterceptor implements ChannelInterceptor {

    private static final Pattern TYPING_PATTERN = Pattern.compile("^/app/event\\.(\\d+)\\.typing$");
    private static final Pattern SEND_PATTERN   = Pattern.compile("^/app/event\\.(\\d+)\\.send$");

    private final Map<String, TokenBucket> limiters = new ConcurrentHashMap<>();
    private final DuplicateMessageDetector duplicateMessageDetector;
    private final WebSocketMetricsService metricsService;

    @Value("${timetree.websocket.rate-limit.typing-events-per-second:0.5}")
    private double typingRatePerSecond;

    @Value("${timetree.websocket.rate-limit.typing-bucket-capacity:2}")
    private double typingBucketCapacity;

    @Value("${timetree.websocket.rate-limit.chat-messages-per-second:5}")
    private double chatRatePerSecond;

    @Value("${timetree.websocket.rate-limit.chat-bucket-capacity:10}")
    private double chatBucketCapacity;

    public WebSocketRateLimitingInterceptor(DuplicateMessageDetector duplicateMessageDetector,
                                            WebSocketMetricsService metricsService) {
        this.duplicateMessageDetector = duplicateMessageDetector;
        this.metricsService = metricsService;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;

        StompCommand command = accessor.getCommand();
        if (!StompCommand.SEND.equals(command)) return message;

        String destination = accessor.getDestination();
        if (destination == null || accessor.getUser() == null) return message;

        String username = accessor.getUser().getName();

        // ── UUID v4 validation on chat SEND frames ────────────────────────────────
        if (SEND_PATTERN.matcher(destination).matches()) {
            String clientMessageId = accessor.getFirstNativeHeader("clientMessageId");
            if (!duplicateMessageDetector.isValidUUID(clientMessageId)) {
                log.warn("Rejected SEND from user={}: invalid or missing clientMessageId='{}'",
                        username, clientMessageId);
                metricsService.incrementMessagesRejected(destination, "CHAT", "invalid_uuid");
                throw new AccessDeniedException(
                        "clientMessageId must be a valid UUID v4 (RFC 4122)");
            }
        }

        // ── Rate limiting ─────────────────────────────────────────────────────────
        if (TYPING_PATTERN.matcher(destination).matches()) {
            TokenBucket bucket = limiters.computeIfAbsent(
                    username + ":typing",
                    k -> new TokenBucket(typingBucketCapacity, typingRatePerSecond));
            if (!bucket.tryConsume()) {
                log.debug("Typing rate limit exceeded user={} — dropping frame silently", username);
                metricsService.incrementMessagesRejected(destination, "TYPING", "rate_limited");
                return null; // Drop typing frames silently to avoid client noise
            }
        } else if (SEND_PATTERN.matcher(destination).matches()) {
            TokenBucket bucket = limiters.computeIfAbsent(
                    username + ":send",
                    k -> new TokenBucket(chatBucketCapacity, chatRatePerSecond));
            if (!bucket.tryConsume()) {
                log.warn("Chat rate limit exceeded for user={}", username);
                metricsService.incrementMessagesRejected(destination, "CHAT", "rate_limited");
                throw new AccessDeniedException("Rate limit exceeded: max " + (int) chatRatePerSecond + " msg/s");
            }
        }

        return message;
    }

    // ── Token bucket ─────────────────────────────────────────────────────────────

    private static class TokenBucket {
        private final double capacity;
        private final double refillRatePerMs;
        private double tokens;
        private long lastRefillTimestamp;

        TokenBucket(double capacity, double refillRatePerSecond) {
            this.capacity = capacity;
            this.tokens = capacity;
            this.refillRatePerMs = refillRatePerSecond / 1000.0;
            this.lastRefillTimestamp = System.currentTimeMillis();
        }

        synchronized boolean tryConsume() {
            refill();
            if (tokens >= 1.0) { tokens -= 1.0; return true; }
            return false;
        }

        private void refill() {
            long now = System.currentTimeMillis();
            long delta = now - lastRefillTimestamp;
            if (delta > 0) {
                tokens = Math.min(capacity, tokens + delta * refillRatePerMs);
                lastRefillTimestamp = now;
            }
        }
    }
}
