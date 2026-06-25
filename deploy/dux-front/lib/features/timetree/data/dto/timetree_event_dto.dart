import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_tag.dart';

/// DTO representing the backend payload for a TimeTree Event.
class TimetreeEventDto {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String? color;
  final String calendarId;
  final String? calendarName;
  final String? groupId;
  final String? groupName;
  final String recurrenceRule; // NONE, DAILY, WEEKLY, MONTHLY
  final DateTime? recurrenceEndDate;
  final List<TimetreeMemberDto> participants;
  final bool locked;
  final bool isPrivate;
  final String status;
  final String priority;
  final List<TimetreeTag> tags;
  final List<Map<String, dynamic>> dependencies;
  final List<String> reminders;
  final String? nomEvent;
  final bool titleModifiedDirectly;

  const TimetreeEventDto({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.allDay,
    this.color,
    required this.calendarId,
    this.calendarName,
    this.groupId,
    this.groupName,
    required this.recurrenceRule,
    this.recurrenceEndDate,
    this.participants = const [],
    this.locked = false,
    this.isPrivate = false,
    this.status = 'PLANNED',
    this.priority = 'NORMAL',
    this.tags = const [],
    this.dependencies = const [],
    this.reminders = const [],
    this.nomEvent,
    this.titleModifiedDirectly = false,
  });

  factory TimetreeEventDto.fromJson(Map<String, dynamic> json) {
    return TimetreeEventDto(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      allDay: json['allDay'] as bool? ?? false,
      color: json['color'] as String?,
      calendarId: (json['calendarId'] ?? '').toString(),
      calendarName: json['calendarName'] as String?,
      groupId: json['groupId']?.toString(),
      groupName: json['groupName'] as String?,
      recurrenceRule: json['recurrenceRule'] as String? ?? 'NONE',
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      participants: (json['participants'] as List?)
              ?.map((e) => TimetreeMemberDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      locked: json['locked'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      status: json['status'] as String? ?? 'PLANNED',
      priority: json['priority'] as String? ?? 'NORMAL',
      tags: (json['tags'] as List?)
              ?.map((e) => TimetreeTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dependencies: (json['dependencies'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      reminders: (json['reminders'] as List?)?.map((e) => e.toString()).toList() ?? [],
      nomEvent: json['nomEvent'] as String?,
      titleModifiedDirectly: json['titleModifiedDirectly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': int.tryParse(id) ?? id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'allDay': allDay,
      'color': color,
      'calendarId': int.tryParse(calendarId) ?? calendarId,
      'groupId': groupId != null ? (int.tryParse(groupId!) ?? groupId) : null,
      'recurrenceRule': recurrenceRule,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'participantIds': participants.map((e) => int.tryParse(e.id) ?? e.id).toList(),
      'locked': locked,
      'isPrivate': isPrivate,
      'status': status,
      'priority': priority,
      'tags': tags.map((e) => e.toJson()).toList(),
      'dependencyIds': dependencies.map((e) => int.tryParse(e['id'].toString()) ?? e['id']).toList(),
      'reminders': reminders,
      'nomEvent': nomEvent,
      'titleModifiedDirectly': titleModifiedDirectly,
    };
  }
}

