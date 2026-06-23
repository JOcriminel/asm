package com.asm.dux.timetree.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

@Slf4j
@Service
public class WebSocketMetricsService {

    private final Set<String> activeSessions = ConcurrentHashMap.newKeySet();
    private final Set<String> connectedUsers = ConcurrentHashMap.newKeySet();
    
    private final AtomicLong messagesCount = new AtomicLong(0);
    private final AtomicLong typingCount = new AtomicLong(0);
    private final AtomicLong failedReconnects = new AtomicLong(0);

    // Track latencies (in milliseconds) of recent message deliveries
    private final Queue<Long> deliveryLatencies = new ConcurrentLinkedQueue<>();
    private static final int MAX_LATENCY_SAMPLES = 1000;

    // For rates calculation (sliding 1-second window)
    private final Queue<Long> messageTimestamps = new ConcurrentLinkedQueue<>();
    private final Queue<Long> typingTimestamps = new ConcurrentLinkedQueue<>();

    public void registerSession(String sessionId, String username) {
        activeSessions.add(sessionId);
        if (username != null) {
            connectedUsers.add(username);
        }
    }

    public void removeSession(String sessionId, String username) {
        activeSessions.remove(sessionId);
        if (username != null) {
            // Check if user has other active sessions
            // Since we don't have a full registry mapping here, we can keep track of user count or sessions per user
        }
    }

    public void setUsers(Set<String> users) {
        connectedUsers.clear();
        connectedUsers.addAll(users);
    }

    public void incrementMessages() {
        messagesCount.incrementAndGet();
        messageTimestamps.add(System.currentTimeMillis());
        cleanOldTimestamps(messageTimestamps);
    }

    public void incrementTyping() {
        typingCount.incrementAndGet();
        typingTimestamps.add(System.currentTimeMillis());
        cleanOldTimestamps(typingTimestamps);
    }

    public void incrementFailedReconnects() {
        failedReconnects.incrementAndGet();
    }

    public void recordDeliveryLatency(long ms) {
        deliveryLatencies.add(ms);
        if (deliveryLatencies.size() > MAX_LATENCY_SAMPLES) {
            deliveryLatencies.poll();
        }
    }

    private void cleanOldTimestamps(Queue<Long> queue) {
        long now = System.currentTimeMillis();
        while (!queue.isEmpty() && now - queue.peek() > 1000) {
            queue.poll();
        }
    }

    public double getMessagesPerSec() {
        cleanOldTimestamps(messageTimestamps);
        return messageTimestamps.size();
    }

    public double getTypingPerSec() {
        cleanOldTimestamps(typingTimestamps);
        return typingTimestamps.size();
    }

    public long getActiveSessions() {
        return activeSessions.size();
    }

    public long getConnectedUsers() {
        return connectedUsers.size();
    }

    public long getFailedReconnectAttempts() {
        return failedReconnects.get();
    }

    public double getAverageDeliveryLatency() {
        List<Long> latencies = new ArrayList<>(deliveryLatencies);
        if (latencies.isEmpty()) return 0.0;
        return latencies.stream().mapToLong(Long::longValue).average().orElse(0.0);
    }

    public Map<String, Double> getPercentileLatencies() {
        List<Long> latencies = new ArrayList<>(deliveryLatencies).stream().sorted().collect(Collectors.toList());
        Map<String, Double> percentiles = new LinkedHashMap<>();
        if (latencies.isEmpty()) {
            percentiles.put("P50", 0.0);
            percentiles.put("P95", 0.0);
            percentiles.put("P99", 0.0);
            return percentiles;
        }
        percentiles.put("P50", (double) latencies.get((int) (latencies.size() * 0.50)));
        percentiles.put("P95", (double) latencies.get((int) (latencies.size() * 0.95)));
        percentiles.put("P99", (double) latencies.get((int) (latencies.size() * 0.99)));
        return percentiles;
    }

    public Map<String, Object> getMetricsReport() {
        Map<String, Object> report = new LinkedHashMap<>();
        report.put("activeSessions", getActiveSessions());
        report.put("connectedUsers", getConnectedUsers());
        report.put("messagesPerSec", getMessagesPerSec());
        report.put("typingEventsPerSec", getTypingPerSec());
        report.put("failedReconnectAttempts", getFailedReconnectAttempts());
        report.put("avgDeliveryLatencyMs", getAverageDeliveryLatency());
        
        Map<String, Double> percentiles = getPercentileLatencies();
        report.put("p50LatencyMs", percentiles.get("P50"));
        report.put("p95LatencyMs", percentiles.get("P95"));
        report.put("p99LatencyMs", percentiles.get("P99"));
        return report;
    }
}
