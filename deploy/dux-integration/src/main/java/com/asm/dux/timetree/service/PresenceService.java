package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.Group;
import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.repository.GroupRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Lazy;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.messaging.SessionConnectEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class PresenceService {

    private final MemberRepository memberRepository;
    private final GroupRepository groupRepository;
    private final SimpMessageSendingOperations messagingTemplate;
    private final WebSocketMetricsService metricsService;

    // Maps sessionId -> SessionInfo
    private final Map<String, SessionInfo> sessionRegistry = new ConcurrentHashMap<>();
    // Maps username -> last activity timestamp (simulates Redis session TTL)
    private final Map<String, Long> userActivityMap = new ConcurrentHashMap<>();

    private static final long SESSION_TTL_MS = 30000; // 30 seconds TTL

    // Manual constructor with @Lazy to break circular dependency with WebSocket infrastructure
    public PresenceService(
            MemberRepository memberRepository,
            GroupRepository groupRepository,
            @Lazy SimpMessageSendingOperations messagingTemplate,
            WebSocketMetricsService metricsService) {
        this.memberRepository = memberRepository;
        this.groupRepository = groupRepository;
        this.messagingTemplate = messagingTemplate;
        this.metricsService = metricsService;
    }

    @Data
    @Builder
    public static class SessionInfo {
        private String sessionId;
        private String username;
        private Long memberId;
        private long lastSeenTimestamp;
    }

    @Data
    @Builder
    public static class PresencePayload {
        private String memberId;
        private String username;
        private String status; // "ONLINE", "OFFLINE"
        private String lastSeen;
    }

    public void registerUserSession(String sessionId, String username) {
        Optional<Member> memberOpt = memberRepository.findByUsername(username);
        if (memberOpt.isPresent()) {
            Member m = memberOpt.get();
            SessionInfo info = SessionInfo.builder()
                    .sessionId(sessionId)
                    .username(username)
                    .memberId(m.getId())
                    .lastSeenTimestamp(System.currentTimeMillis())
                    .build();
            sessionRegistry.put(sessionId, info);
            userActivityMap.put(username, System.currentTimeMillis());

            metricsService.registerSession(sessionId, username);
            metricsService.setUsers(new HashSet<>(userActivityMap.keySet()));

            broadcastPresence(m, "ONLINE");
        }
    }

    public void updateLastActivity(String username) {
        if (username != null) {
            userActivityMap.put(username, System.currentTimeMillis());
            // Update activity in sessions
            for (SessionInfo info : sessionRegistry.values()) {
                if (username.equals(info.getUsername())) {
                    info.setLastSeenTimestamp(System.currentTimeMillis());
                }
            }
        }
    }

    public void handleExplicitDisconnect(String sessionId) {
        SessionInfo info = sessionRegistry.remove(sessionId);
        if (info != null) {
            String username = info.getUsername();
            metricsService.removeSession(sessionId, username);
            
            // Check if user has other active sessions
            boolean hasOtherSessions = sessionRegistry.values().stream()
                    .anyMatch(s -> s.getUsername().equals(username));

            if (!hasOtherSessions) {
                userActivityMap.remove(username);
                metricsService.setUsers(new HashSet<>(userActivityMap.keySet()));
                
                Optional<Member> memberOpt = memberRepository.findByUsername(username);
                if (memberOpt.isPresent()) {
                    Member m = memberOpt.get();
                    m.setLastSeen(LocalDateTime.now());
                    memberRepository.save(m);
                    broadcastPresence(m, "OFFLINE");
                }
            }
        }
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        log.info("WebSocket SessionDisconnectEvent sessionId={}", event.getSessionId());
        handleExplicitDisconnect(event.getSessionId());
    }

    // Cron job running every 5 seconds to clean up orphaned/expired sessions (Redis TTL presence cleanup strategy)
    @Scheduled(fixedDelay = 5000)
    public void cleanExpiredSessions() {
        long now = System.currentTimeMillis();
        for (Map.Entry<String, SessionInfo> entry : sessionRegistry.entrySet()) {
            SessionInfo info = entry.getValue();
            if (now - info.getLastSeenTimestamp() > SESSION_TTL_MS) {
                log.info("Session TTL expired for sessionId={} user={}. Triggering cleanup.", info.getSessionId(), info.getUsername());
                handleExplicitDisconnect(info.getSessionId());
            }
        }
    }

    private void broadcastPresence(Member member, String status) {
        // Resolve groups this member belongs to
        List<Group> groups = groupRepository.findGroupsByMemberId(member.getId());
        for (Group group : groups) {
            PresencePayload payload = PresencePayload.builder()
                    .memberId(member.getId().toString())
                    .username(member.getUsername())
                    .status(status)
                    .lastSeen(member.getLastSeen() != null ? member.getLastSeen().toString() : LocalDateTime.now().toString())
                    .build();

            String destination = "/topic/group." + group.getId() + ".presence";
            log.info("Broadcasting presence update to {}: user={} status={}", destination, member.getUsername(), status);
            messagingTemplate.convertAndSend(destination, payload);
        }
    }
}
