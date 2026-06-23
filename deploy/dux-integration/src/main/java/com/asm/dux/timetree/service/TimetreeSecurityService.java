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
    private final GroupRepository groupRepository;

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
            return memberRepository.findByUsername(username).orElse(null);
        } catch (Exception e) {
            log.error("Failed to resolve current member", e);
            return null;
        }
    }

    public List<Long> getAllowedCalendarIds(Member member) {
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role)) {
            return calendarRepository.findAll().stream().map(Calendar::getId).collect(Collectors.toList());
        }

        List<Group> allGroups = groupRepository.findAll();
        List<Group> allowedGroups = allGroups.stream().filter(g -> {
            boolean isChef = g.getChef() != null && g.getChef().getId().equals(member.getId());
            boolean isMember = g.getMembers() != null && g.getMembers().stream().anyMatch(m -> m.getId().equals(member.getId()));
            return isChef || isMember;
        }).collect(Collectors.toList());

        List<Long> calendarIds = new ArrayList<>();
        for (Group g : allowedGroups) {
            if (g.getCalendars() != null) {
                for (Calendar c : g.getCalendars()) {
                    if (!calendarIds.contains(c.getId())) {
                        calendarIds.add(c.getId());
                    }
                }
            }
        }
        return calendarIds;
    }

    public boolean canReadEvent(Member member, Event event) {
        if (member == null || event == null) return false;
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role)) {
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
        if ("ADMIN".equals(role)) {
            return true;
        }
        if (Boolean.TRUE.equals(event.getLocked())) {
            if ("CHEF".equals(role) && event.getGroup() != null && event.getGroup().getChef() != null) {
                return event.getGroup().getChef().getId().equals(member.getId());
            }
            return false;
        }
        return canWriteEvent(member, event.getCalendar().getId(), event.getGroup() != null ? event.getGroup().getId() : null);
    }

    public boolean canWriteEvent(Member member, Long calendarId, Long groupId) {
        String role = member.getRole().toUpperCase();
        if ("ADMIN".equals(role)) {
            return true;
        }

        Optional<Calendar> calOpt = calendarRepository.findById(calendarId);
        if (!calOpt.isPresent()) return false;
        Calendar calendar = calOpt.get();

        List<Group> allGroups = groupRepository.findAll();
        List<Group> calendarGroups = allGroups.stream()
                .filter(g -> g.getCalendars() != null && g.getCalendars().contains(calendar))
                .collect(Collectors.toList());

        if (calendarGroups.isEmpty()) {
            return false;
        }

        if ("CHEF".equals(role)) {
            return calendarGroups.stream().anyMatch(g -> 
                g.getChef() != null && g.getChef().getId().equals(member.getId()));
        }

        if ("MEMBER".equals(role)) {
            return calendarGroups.stream().anyMatch(g -> 
                g.getMembers() != null && g.getMembers().stream().anyMatch(m -> m.getId().equals(member.getId())));
        }

        return false;
    }
}
