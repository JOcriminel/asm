package com.asm.dux.timetree.security;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.repository.*;
import com.asm.dux.timetree.service.PresenceService;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import com.asm.dux.timetree.service.WebSocketMetricsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.context.annotation.Lazy;

@Slf4j
@Component
public class WebSocketSecurityInterceptor implements ChannelInterceptor {

    private final JwtDecoder jwtDecoder;
    private final MemberRepository memberRepository;
    private final EventRepository eventRepository;
    private final GroupRepository groupRepository;
    private final TimetreeSecurityService securityService;
    private final PresenceService presenceService;
    private final WebSocketMetricsService metricsService;

    public WebSocketSecurityInterceptor(
            JwtDecoder jwtDecoder,
            MemberRepository memberRepository,
            EventRepository eventRepository,
            GroupRepository groupRepository,
            TimetreeSecurityService securityService,
            @Lazy PresenceService presenceService,
            WebSocketMetricsService metricsService) {
        this.jwtDecoder = jwtDecoder;
        this.memberRepository = memberRepository;
        this.eventRepository = eventRepository;
        this.groupRepository = groupRepository;
        this.securityService = securityService;
        this.presenceService = presenceService;
        this.metricsService = metricsService;
    }

    private static final Pattern EVENT_TOPIC_PATTERN = Pattern.compile("^/(topic|app)/event\\.(\\d+)\\.(chat|typing|send)$");
    private static final Pattern GROUP_TOPIC_PATTERN = Pattern.compile("^/topic/group\\.(\\d+)\\.presence$");
    private static final Pattern USER_TOPIC_PATTERN = Pattern.compile("^/topic/user\\.(\\d+)\\.unread$");

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null) return message;

        StompCommand command = accessor.getCommand();
        if (StompCommand.CONNECT.equals(command)) {
            handleConnect(accessor);
        } else if (StompCommand.SUBSCRIBE.equals(command)) {
            handleSubscribeOrSend(accessor, accessor.getDestination(), "SUBSCRIBE");
        } else if (StompCommand.SEND.equals(command)) {
            handleSubscribeOrSend(accessor, accessor.getDestination(), "SEND");
        }

        return message;
    }

    private void handleConnect(StompHeaderAccessor accessor) {
        String authHeader = accessor.getFirstNativeHeader("Authorization");
        String passcode = accessor.getFirstNativeHeader("passcode");
        String token = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);
        } else if (passcode != null && !passcode.trim().isEmpty()) {
            token = passcode;
        }

        if (token == null) {
            metricsService.incrementFailedReconnects();
            throw new AccessDeniedException("Missing authentication token in CONNECT frame");
        }

        try {
            Jwt jwt = jwtDecoder.decode(token);
            String preferredUsername = jwt.getClaimAsString("preferred_username");
            String username = preferredUsername != null ? preferredUsername : jwt.getSubject();

            Optional<Member> memberOpt = memberRepository.findByUsername(username);
            if (!memberOpt.isPresent()) {
                metricsService.incrementFailedReconnects();
                throw new AccessDeniedException("User not registered in the system: " + username);
            }

            Member member = memberOpt.get();
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(member.getUsername(), null, List.of(() -> "ROLE_" + member.getRole().toUpperCase()));
            
            accessor.setUser(authentication);
            SecurityContextHolder.getContext().setAuthentication(authentication);

            // Register in presence engine
            presenceService.registerUserSession(accessor.getSessionId(), member.getUsername());
            log.info("WebSocket CONNECT authenticated user={} sessionId={}", member.getUsername(), accessor.getSessionId());

        } catch (Exception e) {
            log.error("WebSocket CONNECT token validation failed", e);
            metricsService.incrementFailedReconnects();
            throw new AccessDeniedException("Invalid authentication token", e);
        }
    }

    private void handleSubscribeOrSend(StompHeaderAccessor accessor, String destination, String actionType) {
        if (destination == null) return;

        // Resolve authenticated user from STOMP user principal
        if (accessor.getUser() == null) {
            throw new AccessDeniedException("Unauthenticated frame command=" + actionType);
        }
        
        String username = accessor.getUser().getName();
        Optional<Member> memberOpt = memberRepository.findByUsername(username);
        if (!memberOpt.isPresent()) {
            throw new AccessDeniedException("Invalid security principal");
        }
        Member current = memberOpt.get();

        // Refresh presence TTL on every authorized frame
        presenceService.refreshHeartbeat(username);

        // 1. Authorize Event-centric destinations
        Matcher eventMatcher = EVENT_TOPIC_PATTERN.matcher(destination);
        if (eventMatcher.find()) {
            Long eventId = Long.parseLong(eventMatcher.group(2));
            Optional<Event> eventOpt = eventRepository.findById(eventId);
            if (!eventOpt.isPresent()) {
                throw new AccessDeniedException("Event not found with ID: " + eventId);
            }
            Event event = eventOpt.get();
            if (!securityService.canReadEvent(current, event)) {
                log.warn("Access denied: User={} attempted {} to unauthorized event={}", username, actionType, eventId);
                throw new AccessDeniedException("Access denied to event room " + eventId);
            }
            return;
        }

        // 2. Authorize Group-centric destinations
        Matcher groupMatcher = GROUP_TOPIC_PATTERN.matcher(destination);
        if (groupMatcher.find()) {
            Long groupId = Long.parseLong(groupMatcher.group(1));
            boolean isAdmin = "ADMIN".equalsIgnoreCase(current.getRole());

            if (!isAdmin) {
                List<Group> userGroups = groupRepository.findGroupsByMemberId(current.getId());
                boolean isAuthorized = userGroups.stream().anyMatch(g -> g.getId().equals(groupId));
                if (!isAuthorized) {
                    log.warn("Access denied: User={} attempted {} to unauthorized group={}", username, actionType, groupId);
                    throw new AccessDeniedException("Access denied to group presence " + groupId);
                }
            }
            return;
        }

        // 3. Authorize User-specific destinations (Unread Sync)
        Matcher userMatcher = USER_TOPIC_PATTERN.matcher(destination);
        if (userMatcher.find()) {
            Long memberId = Long.parseLong(userMatcher.group(1));
            // Never trust client-provided values: Resolve identity exclusively from the authenticated principal
            if (!memberId.equals(current.getId()) && !"ADMIN".equalsIgnoreCase(current.getRole())) {
                log.warn("Access denied: User={} attempted {} to mismatching user={}", username, actionType, memberId);
                throw new AccessDeniedException("Cannot subscribe or publish to another user's stream");
            }
        }
    }
}
