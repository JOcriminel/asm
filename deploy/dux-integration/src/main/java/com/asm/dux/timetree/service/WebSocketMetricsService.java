package com.asm.dux.timetree.service;

import io.micrometer.core.instrument.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Micrometer-based WebSocket metrics service.
 *
 * Named metrics (all Prometheus-scrape-ready via /actuator/prometheus):
 *   timetree.ws.sessions.active      Gauge
 *   timetree.ws.users.connected      Gauge
 *   timetree.ws.messages.sent        Counter   tags: destination, messageType, result
 *   timetree.ws.messages.received    Counter   tags: destination, messageType
 *   timetree.ws.messages.rejected    Counter   tags: destination, messageType, result
 *   timetree.ws.latency.ms           Timer     tags: destination  (P50/P95/P99 percentiles)
 *   timetree.ws.reconnects.total     Counter   tags: result
 *   timetree.ws.offline.queue.size   Gauge     tags: username
 */
@Slf4j
@Service
public class WebSocketMetricsService {

    private final MeterRegistry registry;

    private final AtomicLong activeSessions = new AtomicLong(0);
    private final AtomicLong connectedUsers = new AtomicLong(0);
    private final Set<String> connectedUserSet = ConcurrentHashMap.newKeySet();

    // Per-username offline queue sizes
    private final java.util.concurrent.ConcurrentHashMap<String, AtomicLong> offlineQueueSizes =
            new java.util.concurrent.ConcurrentHashMap<>();

    public WebSocketMetricsService(MeterRegistry registry) {
        this.registry = registry;

        Gauge.builder("timetree.ws.sessions.active", activeSessions, AtomicLong::get)
                .description("Active WebSocket sessions")
                .register(registry);

        Gauge.builder("timetree.ws.users.connected", connectedUsers, AtomicLong::get)
                .description("Connected unique users")
                .register(registry);
    }

    // ─── Session lifecycle ───────────────────────────────────────────────────────

    public void registerSession(String sessionId, String username) {
        activeSessions.incrementAndGet();
        if (username != null && connectedUserSet.add(username)) {
            connectedUsers.incrementAndGet();
        }
    }

    public void removeSession(String sessionId, String username) {
        long sessions = activeSessions.decrementAndGet();
        if (sessions < 0) activeSessions.set(0);
        if (username != null && connectedUserSet.remove(username)) {
            long users = connectedUsers.decrementAndGet();
            if (users < 0) connectedUsers.set(0);
        }
    }

    // ─── Message counters ────────────────────────────────────────────────────────

    public void incrementMessagesSent(String destination, String messageType) {
        counter("timetree.ws.messages.sent",
                "destination", clean(destination),
                "messageType", clean(messageType),
                "result", "success").increment();
    }

    public void incrementMessagesReceived(String destination, String messageType) {
        counter("timetree.ws.messages.received",
                "destination", clean(destination),
                "messageType", clean(messageType)).increment();
    }

    public void incrementMessagesRejected(String destination, String messageType, String reason) {
        counter("timetree.ws.messages.rejected",
                "destination", clean(destination),
                "messageType", clean(messageType),
                "result", clean(reason)).increment();
    }

    // ─── Latency ────────────────────────────────────────────────────────────────

    public void recordLatency(long latencyMs, String destination) {
        Timer.builder("timetree.ws.latency.ms")
                .tag("destination", clean(destination))
                .description("WebSocket message delivery latency")
                .publishPercentiles(0.50, 0.95, 0.99)
                .register(registry)
                .record(latencyMs, TimeUnit.MILLISECONDS);
    }

    // ─── Reconnects ──────────────────────────────────────────────────────────────

    public void incrementReconnects(String result) {
        counter("timetree.ws.reconnects.total",
                "result", clean(result)).increment();
    }

    public void incrementFailedReconnects() {
        incrementReconnects("failed");
    }

    // ─── Offline queue gauge ─────────────────────────────────────────────────────

    public void updateOfflineQueueSize(String username, long size) {
        AtomicLong gauge = offlineQueueSizes.computeIfAbsent(username, u -> {
            AtomicLong g = new AtomicLong(0);
            Gauge.builder("timetree.ws.offline.queue.size", g, AtomicLong::get)
                    .tag("username", u)
                    .description("Offline queue message count")
                    .register(registry);
            return g;
        });
        gauge.set(size);
    }

    // ─── Legacy compat (called from WebSocketSecurityInterceptor) ────────────────

    public void incrementMessages() {
        incrementMessagesSent("unknown", "TEXT");
    }

    public void incrementTyping() {
        incrementMessagesSent("unknown", "TYPING");
    }

    public void incrementFailedReconnects(int n) {
        for (int i = 0; i < n; i++) incrementFailedReconnects();
    }

    public void recordDeliveryLatency(long ms) {
        recordLatency(ms, "unknown");
    }

    // ─── Internal helpers ────────────────────────────────────────────────────────

    private Counter counter(String name, String... tags) {
        return Counter.builder(name).tags(tags).register(registry);
    }

    private String clean(String value) {
        return value != null && !value.isBlank() ? value : "unknown";
    }

    /**
     * Returns a snapshot map of current metrics for the /metrics/websocket REST endpoint.
     * Prometheus scraping uses /actuator/prometheus; this endpoint is for quick human-readable checks.
     */
    public java.util.Map<String, Object> getMetricsReport() {
        java.util.Map<String, Object> report = new java.util.LinkedHashMap<>();
        report.put("timetree.ws.sessions.active", activeSessions.get());
        report.put("timetree.ws.users.connected", connectedUsers.get());
        report.put("timetree.ws.users.list", new java.util.ArrayList<>(connectedUserSet));
        report.put("note", "Full Prometheus metrics available at /actuator/prometheus");
        return report;
    }
}
