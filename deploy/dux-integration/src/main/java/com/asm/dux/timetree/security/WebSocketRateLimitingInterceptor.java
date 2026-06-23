package com.asm.dux.timetree.security;

import lombok.extern.slf4j.Slf4j;
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

@Slf4j
@Component
public class WebSocketRateLimitingInterceptor implements ChannelInterceptor {

    private final Map<String, TokenBucket> limiters = new ConcurrentHashMap<>();
    private static final Pattern TYPING_PATTERN = Pattern.compile("^/app/event\\.(\\d+)\\.typing$");
    private static final Pattern SEND_PATTERN = Pattern.compile("^/app/event\\.(\\d+)\\.send$");

    private static class TokenBucket {
        private final double capacity;
        private final double refillRatePerMs;
        private double tokens;
        private long lastRefillTimestamp;

        public TokenBucket(double capacity, double refillRatePerSecond) {
            this.capacity = capacity;
            this.tokens = capacity;
            this.refillRatePerMs = refillRatePerSecond / 1000.0;
            this.lastRefillTimestamp = System.currentTimeMillis();
        }

        public synchronized boolean tryConsume() {
            refill();
            if (tokens >= 1.0) {
                tokens -= 1.0;
                return true;
            }
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

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;

        StompCommand command = accessor.getCommand();
        if (StompCommand.SEND.equals(command)) {
            String destination = accessor.getDestination();
            if (destination != null && accessor.getUser() != null) {
                String username = accessor.getUser().getName();
                
                if (TYPING_PATTERN.matcher(destination).matches()) {
                    // Limit typing events: Max 1 per 2 seconds (0.5 events/sec), capacity of 2 tokens
                    String rateKey = username + ":typing";
                    TokenBucket bucket = limiters.computeIfAbsent(rateKey, k -> new TokenBucket(2.0, 0.5));
                    if (!bucket.tryConsume()) {
                        log.warn("Typing indicator rate limit exceeded for user={}", username);
                        // Drop frame silently for typing to avoid client overhead
                        return null; 
                    }
                } else if (SEND_PATTERN.matcher(destination).matches()) {
                    // Limit chat messages: Max 5 messages/sec, capacity of 10 tokens
                    String rateKey = username + ":send";
                    TokenBucket bucket = limiters.computeIfAbsent(rateKey, k -> new TokenBucket(10.0, 5.0));
                    if (!bucket.tryConsume()) {
                        log.warn("Chat message rate limit exceeded for user={}", username);
                        throw new AccessDeniedException("Rate limit exceeded for publishing chat messages (max 5/sec)");
                    }
                }
            }
        }

        return message;
    }
}
