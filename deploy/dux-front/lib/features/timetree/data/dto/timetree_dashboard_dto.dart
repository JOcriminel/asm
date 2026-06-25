/// DTO that mirrors the raw JSON returned by
/// GET /api/timetree/dashboard
class TimetreeDashboardDto {
  final TimetreeSummaryDto summary;
  final List<TimetreeActivityDto> recentActivities;
  final Map<String, int> eventsByStatus;
  final Map<String, int> eventsByPriority;
  final List<TimetreeUpcomingEventDto> upcomingEvents;
  final List<TimetreeActiveGroupDto> mostActiveGroups;
  final List<TimetreeActiveMemberDto> mostActiveMembers;
  final double calendarUtilization;

  const TimetreeDashboardDto({
    required this.summary,
    required this.recentActivities,
    this.eventsByStatus = const {},
    this.eventsByPriority = const {},
    this.upcomingEvents = const [],
    this.mostActiveGroups = const [],
    this.mostActiveMembers = const [],
    this.calendarUtilization = 0.0,
  });

  factory TimetreeDashboardDto.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    final summary = rawSummary is Map<String, dynamic>
        ? TimetreeSummaryDto.fromJson(rawSummary)
        : const TimetreeSummaryDto();

    final rawActivities = json['recentActivities'];
    final activities = rawActivities is List
        ? rawActivities
            .whereType<Map<String, dynamic>>()
            .map(TimetreeActivityDto.fromJson)
            .toList()
        : <TimetreeActivityDto>[];

    final rawStatus = json['eventsByStatus'];
    final statusMap = rawStatus is Map
        ? rawStatus.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
        : <String, int>{};

    final rawPriority = json['eventsByPriority'];
    final priorityMap = rawPriority is Map
        ? rawPriority.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
        : <String, int>{};

    final rawUpcoming = json['upcomingEvents'];
    final upcomingList = rawUpcoming is List
        ? rawUpcoming
            .whereType<Map<String, dynamic>>()
            .map(TimetreeUpcomingEventDto.fromJson)
            .toList()
        : <TimetreeUpcomingEventDto>[];

    final rawGroups = json['mostActiveGroups'];
    final activeGroupsList = rawGroups is List
        ? rawGroups
            .whereType<Map<String, dynamic>>()
            .map(TimetreeActiveGroupDto.fromJson)
            .toList()
        : <TimetreeActiveGroupDto>[];

    final rawMembers = json['mostActiveMembers'];
    final activeMembersList = rawMembers is List
        ? rawMembers
            .whereType<Map<String, dynamic>>()
            .map(TimetreeActiveMemberDto.fromJson)
            .toList()
        : <TimetreeActiveMemberDto>[];

    final utilization = (json['calendarUtilization'] as num?)?.toDouble() ?? 0.0;

    return TimetreeDashboardDto(
      summary: summary,
      recentActivities: activities,
      eventsByStatus: statusMap,
      eventsByPriority: priorityMap,
      upcomingEvents: upcomingList,
      mostActiveGroups: activeGroupsList,
      mostActiveMembers: activeMembersList,
      calendarUtilization: utilization,
    );
  }
}

class TimetreeSummaryDto {
  final int categoriesCount;
  final int pagesCount;
  final int groupsCount;

  const TimetreeSummaryDto({
    this.categoriesCount = 0,
    this.pagesCount = 0,
    this.groupsCount = 0,
  });

  factory TimetreeSummaryDto.fromJson(Map<String, dynamic> json) {
    return TimetreeSummaryDto(
      categoriesCount: (json['categoriesCount'] as num?)?.toInt() ?? 0,
      pagesCount: (json['pagesCount'] as num?)?.toInt() ?? 0,
      groupsCount: (json['groupsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimetreeActivityDto {
  final String id;
  final String type;
  final String title;
  final String? timestamp;

  const TimetreeActivityDto({
    required this.id,
    required this.type,
    required this.title,
    this.timestamp,
  });

  factory TimetreeActivityDto.fromJson(Map<String, dynamic> json) {
    return TimetreeActivityDto(
      id: (json['id'] ?? '').toString(),
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      timestamp: json['timestamp'] as String?,
    );
  }
}

class TimetreeUpcomingEventDto {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? color;

  const TimetreeUpcomingEventDto({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.color,
  });

  factory TimetreeUpcomingEventDto.fromJson(Map<String, dynamic> json) {
    return TimetreeUpcomingEventDto(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      color: json['color'] as String?,
    );
  }
}

class TimetreeActiveGroupDto {
  final String groupName;
  final int eventCount;

  const TimetreeActiveGroupDto({
    required this.groupName,
    required this.eventCount,
  });

  factory TimetreeActiveGroupDto.fromJson(Map<String, dynamic> json) {
    return TimetreeActiveGroupDto(
      groupName: json['groupName'] as String? ?? '',
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimetreeActiveMemberDto {
  final String memberName;
  final int eventCount;

  const TimetreeActiveMemberDto({
    required this.memberName,
    required this.eventCount,
  });

  factory TimetreeActiveMemberDto.fromJson(Map<String, dynamic> json) {
    return TimetreeActiveMemberDto(
      memberName: json['memberName'] as String? ?? '',
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
    );
  }
}
