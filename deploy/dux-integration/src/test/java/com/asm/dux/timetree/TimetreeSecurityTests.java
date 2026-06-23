package com.asm.dux.timetree;

import com.asm.dux.timetree.domain.Calendar;
import com.asm.dux.timetree.domain.Event;
import com.asm.dux.timetree.domain.Group;
import com.asm.dux.timetree.domain.Member;
import com.asm.dux.timetree.repository.CalendarRepository;
import com.asm.dux.timetree.repository.GroupRepository;
import com.asm.dux.timetree.repository.MemberRepository;
import com.asm.dux.timetree.service.TimetreeSecurityService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class TimetreeSecurityTests {

    @Mock
    private MemberRepository memberRepository;

    @Mock
    private CalendarRepository calendarRepository;

    @Mock
    private GroupRepository groupRepository;

    @InjectMocks
    private TimetreeSecurityService securityService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testAdminAllowedCalendars() {
        Member admin = Member.builder()
                .id(1L)
                .username("admin")
                .role("ADMIN")
                .build();

        Calendar cal1 = Calendar.builder().id(101L).name("Cal 1").build();
        Calendar cal2 = Calendar.builder().id(102L).name("Cal 2").build();
        List<Calendar> allCalendars = Arrays.asList(cal1, cal2);

        when(calendarRepository.findAll()).thenReturn(allCalendars);

        List<Long> allowedIds = securityService.getAllowedCalendarIds(admin);

        assertEquals(2, allowedIds.size());
        assertTrue(allowedIds.contains(101L));
        assertTrue(allowedIds.contains(102L));
        verify(calendarRepository, times(1)).findAll();
    }

    @Test
    void testChefAllowedCalendars() {
        Member chef = Member.builder()
                .id(2L)
                .username("chef1")
                .role("CHEF")
                .build();

        when(calendarRepository.findAllowedCalendarIdsByMemberId(2L)).thenReturn(Collections.singletonList(101L));

        List<Long> allowedIds = securityService.getAllowedCalendarIds(chef);

        assertEquals(1, allowedIds.size());
        assertTrue(allowedIds.contains(101L));
        assertFalse(allowedIds.contains(102L));
    }

    @Test
    void testMemberAllowedCalendars() {
        Member member = Member.builder()
                .id(4L)
                .username("member1")
                .role("MEMBER")
                .build();

        when(calendarRepository.findAllowedCalendarIdsByMemberId(4L)).thenReturn(Collections.singletonList(101L));

        List<Long> allowedIds = securityService.getAllowedCalendarIds(member);

        assertEquals(1, allowedIds.size());
        assertTrue(allowedIds.contains(101L));
        assertFalse(allowedIds.contains(102L));
    }

    @Test
    void testCanReadEvent() {
        Member member = Member.builder()
                .id(4L)
                .username("member1")
                .role("MEMBER")
                .build();

        Calendar cal1 = Calendar.builder().id(101L).build();
        Event event = Event.builder().id(200L).calendar(cal1).build();

        when(calendarRepository.findAllowedCalendarIdsByMemberId(4L)).thenReturn(Collections.singletonList(101L));

        assertTrue(securityService.canReadEvent(member, event));
    }

    @Test
    void testChefCanWriteEvent() {
        Member chef = Member.builder()
                .id(2L)
                .username("chef1")
                .role("CHEF")
                .build();

        Calendar cal1 = Calendar.builder().id(101L).build();

        Group managedGroup = Group.builder()
                .id(10L)
                .chef(chef)
                .calendars(Collections.singletonList(cal1))
                .build();

        when(calendarRepository.findById(101L)).thenReturn(Optional.of(cal1));
        when(groupRepository.findAll()).thenReturn(Collections.singletonList(managedGroup));

        assertTrue(securityService.canWriteEvent(chef, 101L, 10L));
    }

    @Test
    void testMemberCanWriteEvent() {
        Member member = Member.builder()
                .id(4L)
                .username("member1")
                .role("MEMBER")
                .build();

        Calendar cal1 = Calendar.builder().id(101L).build();

        Group memberGroup = Group.builder()
                .id(10L)
                .members(Collections.singletonList(member))
                .calendars(Collections.singletonList(cal1))
                .build();

        when(calendarRepository.findById(101L)).thenReturn(Optional.of(cal1));
        when(groupRepository.findAll()).thenReturn(Collections.singletonList(memberGroup));

        assertTrue(securityService.canWriteEvent(member, 101L, 10L));
    }
}
