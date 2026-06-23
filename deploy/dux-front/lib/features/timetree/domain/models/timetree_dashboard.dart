import 'package:dux_front/features/timetree/data/dto/timetree_dashboard_dto.dart';

class TimetreeActivity {
  final String id;
  final String type;
  final String title;
  final DateTime? timestamp;

  const TimetreeActivity({
    required this.id,
    required this.type,
    required this.title,
    this.timestamp,
  });

  factory TimetreeActivity.fromDto(TimetreeActivityDto dto) {
    DateTime? ts;
    if (dto.timestamp != null) {
      ts = DateTime.tryParse(dto.timestamp!);
    }
    return TimetreeActivity(
      id: dto.id,
      type: dto.type,
      title: dto.title,
      timestamp: ts,
    );
  }
}

class TimetreeUpcomingEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? color;

  const TimetreeUpcomingEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.color,
  });

  factory TimetreeUpcomingEvent.fromDto(TimetreeUpcomingEventDto dto) {
    return TimetreeUpcomingEvent(
      id: dto.id,
      title: dto.title,
      startDate: dto.startDate.toLocal(),
      endDate: dto.endDate.toLocal(),
      color: dto.color,
    );
  }
}

class TimetreeActiveGroup {
  final String groupName;
  final int eventCount;

  const TimetreeActiveGroup({
    required this.groupName,
    required this.eventCount,
  });

  factory TimetreeActiveGroup.fromDto(TimetreeActiveGroupDto dto) {
    return TimetreeActiveGroup(
      groupName: dto.groupName,
      eventCount: dto.eventCount,
    );
  }
}

class TimetreeActiveMember {
  final String memberName;
  final int eventCount;

  const TimetreeActiveMember({
    required this.memberName,
    required this.eventCount,
  });

  factory TimetreeActiveMember.fromDto(TimetreeActiveMemberDto dto) {
    return TimetreeActiveMember(
      memberName: dto.memberName,
      eventCount: dto.eventCount,
    );
  }
}

class TimetreeDashboard {
  final int categoriesCount;
  final int pagesCount;
  final int groupsCount;
  final List<TimetreeActivity> recentActivities;
  final Map<String, int> eventsByStatus;
  final Map<String, int> eventsByPriority;
  final List<TimetreeUpcomingEvent> upcomingEvents;
  final List<TimetreeActiveGroup> mostActiveGroups;
  final List<TimetreeActiveMember> mostActiveMembers;
  final double calendarUtilization;

  const TimetreeDashboard({
    required this.categoriesCount,
    required this.pagesCount,
    required this.groupsCount,
    required this.recentActivities,
    this.eventsByStatus = const {},
    this.eventsByPriority = const {},
    this.upcomingEvents = const [],
    this.mostActiveGroups = const [],
    this.mostActiveMembers = const [],
    this.calendarUtilization = 0.0,
  });

  const TimetreeDashboard.empty()
      : categoriesCount = 0,
        pagesCount = 0,
        groupsCount = 0,
        recentActivities = const [],
        eventsByStatus = const {},
        eventsByPriority = const {},
        upcomingEvents = const [],
        mostActiveGroups = const [],
        mostActiveMembers = const [],
        calendarUtilization = 0.0;

  factory TimetreeDashboard.fromDto(TimetreeDashboardDto dto) {
    return TimetreeDashboard(
      categoriesCount: dto.summary.categoriesCount,
      pagesCount: dto.summary.pagesCount,
      groupsCount: dto.summary.groupsCount,
      recentActivities: dto.recentActivities
          .map(TimetreeActivity.fromDto)
          .toList(),
      eventsByStatus: dto.eventsByStatus,
      eventsByPriority: dto.eventsByPriority,
      upcomingEvents: dto.upcomingEvents.map(TimetreeUpcomingEvent.fromDto).toList(),
      mostActiveGroups: dto.mostActiveGroups.map(TimetreeActiveGroup.fromDto).toList(),
      mostActiveMembers: dto.mostActiveMembers.map(TimetreeActiveMember.fromDto).toList(),
      calendarUtilization: dto.calendarUtilization,
    );
  }
}
