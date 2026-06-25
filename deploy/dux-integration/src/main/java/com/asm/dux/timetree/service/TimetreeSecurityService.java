package com.asm.dux.timetree.service;

import com.asm.dux.timetree.domain.*;
import com.asm.dux.timetree.domain.Calendar;
import com.asm.dux.timetree.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TimetreeSecurityService {

    private final MemberRepository memberRepository;
    private final CalendarRepository calendarRepository;

    public Member getCurrentMember() {
        try {
            org.springframework.security.core.Authentication auth = 
                org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) return null;
            String username = auth.getName();
            if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                org.springframework.security.oauth2.jwt.Jwt jwt = 
                    ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                String preferredUsername = jwt.getClaimAsString("preferred_username");
                if (preferredUsername != null && !preferredUsername.isEmpty()) {
                    username = preferredUsername;
                }
            }
            final String finalUsername = username;
            Optional<Member> memberOpt = memberRepository.findByUsername(finalUsername);
            if (memberOpt.isPresent()) {
                return memberOpt.get();
            }

            // Auto-provision user if they exist in Keycloak token but not in TT_MEMBER
            if (auth instanceof org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) {
                org.springframework.security.oauth2.jwt.Jwt jwt = 
                    ((org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken) auth).getToken();
                String fullName = jwt.getClaimAsString("name");
                if (fullName == null || fullName.trim().isEmpty()) {
                    fullName = jwt.getClaimAsString("given_name");
                    String familyName = jwt.getClaimAsString("family_name");
                    if (fullName != null && familyName != null) {
                        fullName = fullName + " " + familyName;
                    }
                }
                if (fullName == null || fullName.trim().isEmpty()) {
                    fullName = finalUsername;
                }
                String email = jwt.getClaimAsString("email");
                
                String role = "MEMBER";
                if ("admin".equalsIgnoreCase(finalUsername)) {
                    role = "ADMIN";
                }
                
                Member newMember = Member.builder()
                        .username(finalUsername)
                        .fullName(fullName)
                        .email(email)
                        .role(role)
                        .canCreateAgendas(true)
                        .canAddMembers(true)
                        .build();
                
                log.info("Auto-provisioning member: {}", finalUsername);
                return memberRepository.save(newMember);
            }
            return null;
        } catch (Exception e) {
            log.error("Failed to resolve current member", e);
            return null;
        }
    }

    public List<Long> getAllowedCalendarIds(Member member) {
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role)) {
            return calendarRepository.findAll().stream().map(Calendar::getId).collect(Collectors.toList());
        }
        return calendarRepository.findAllowedCalendarIdsByMemberId(member.getId());
    }

    public boolean canReadEvent(Member member, Event event) {
        if (member == null || event == null) return false;
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role)) {
            return true;
        }
        if (Boolean.TRUE.equals(event.getIsPrivate())) {
            return event.getParticipants() != null && event.getParticipants().stream()
                    .anyMatch(p -> p.getId().equals(member.getId()));
        }
        List<Long> allowedIds = getAllowedCalendarIds(member);
        return allowedIds.contains(event.getCalendar().getId());
    }

    public boolean canModifyEvent(Member member, Event event) {
        if (member == null || event == null) return false;
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role)) {
            return true;
        }
        if (Boolean.TRUE.equals(event.getLocked())) {
            if ("CHEF".equals(role)) {
                return getAllowedCalendarIds(member).contains(event.getCalendar().getId());
            }
            return false;
        }
        return canWriteEvent(member, event.getCalendar().getId());
    }

    public boolean canWriteEvent(Member member, Long calendarId) {
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role) || "ADMINISTRATEUR".equals(role)) {
            return true;
        }
        List<Long> allowedIds = getAllowedCalendarIds(member);
        return allowedIds.contains(calendarId);
    }
}
