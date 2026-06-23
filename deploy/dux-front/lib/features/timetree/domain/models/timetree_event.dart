import 'package:dux_front/features/timetree/data/dto/timetree_event_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_tag.dart';

/// Clean domain model representing a TimeTree Event.
class TimetreeEvent {
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
  final List<TimetreeMember> participants;
  final bool locked;
  final bool isPrivate;
  final String status; // DRAFT, PLANNED, IN_PROGRESS, COMPLETED, CANCELLED
  final String priority; // LOW, NORMAL, HIGH, CRITICAL
  final List<TimetreeTag> tags;
  final List<Map<String, dynamic>> dependencies;
  final List<DateTime> reminders;
  
  // Custom field values attached to this event instance
  final Map<String, String>? customFields;

  const TimetreeEvent({
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
    this.customFields,
  });

  factory TimetreeEvent.fromDto(TimetreeEventDto dto) {
    return TimetreeEvent(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      startDate: dto.startDate,
      endDate: dto.endDate,
      allDay: dto.allDay,
      color: dto.color,
      calendarId: dto.calendarId,
      calendarName: dto.calendarName,
      groupId: dto.groupId,
      groupName: dto.groupName,
      recurrenceRule: dto.recurrenceRule,
      recurrenceEndDate: dto.recurrenceEndDate,
      participants: dto.participants.map(TimetreeMember.fromDto).toList(),
      locked: dto.locked,
      isPrivate: dto.isPrivate,
      status: dto.status,
      priority: dto.priority,
      tags: dto.tags,
      dependencies: dto.dependencies,
      reminders: dto.reminders.map((r) => DateTime.parse(r).toLocal()).toList(),
    );
  }

  TimetreeEventDto toDto() {
    return TimetreeEventDto(
      id: id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      allDay: allDay,
      color: color,
      calendarId: calendarId,
      calendarName: calendarName,
      groupId: groupId,
      groupName: groupName,
      recurrenceRule: recurrenceRule,
      recurrenceEndDate: recurrenceEndDate,
      participants: participants.map((p) => p.toDto()).toList(),
      locked: locked,
      isPrivate: isPrivate,
      status: status,
      priority: priority,
      tags: tags,
      dependencies: dependencies,
      reminders: reminders.map((r) => r.toUtc().toIso8601String()).toList(),
    );
  }

  TimetreeEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    String? color,
    String? calendarId,
    String? calendarName,
    String? groupId,
    String? groupName,
    String? recurrenceRule,
    DateTime? recurrenceEndDate,
    List<TimetreeMember>? participants,
    bool? locked,
    bool? isPrivate,
    String? status,
    String? priority,
    List<TimetreeTag>? tags,
    List<Map<String, dynamic>>? dependencies,
    List<DateTime>? reminders,
    Map<String, String>? customFields,
  }) {
    return TimetreeEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      allDay: allDay ?? this.allDay,
      color: color ?? this.color,
      calendarId: calendarId ?? this.calendarId,
      calendarName: calendarName ?? this.calendarName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      participants: participants ?? this.participants,
      locked: locked ?? this.locked,
      isPrivate: isPrivate ?? this.isPrivate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      dependencies: dependencies ?? this.dependencies,
      reminders: reminders ?? this.reminders,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Expands recurring event instances within a given date range.
  List<TimetreeEvent> expandRecurrence(DateTime rangeStart, DateTime rangeEnd) {
    if (recurrenceRule == 'NONE') {
      // Check overlap
      if (startDate.isBefore(rangeEnd) && endDate.isAfter(rangeStart)) {
        return [this];
      }
      return [];
    }

    final List<TimetreeEvent> instances = [];
    final duration = endDate.difference(startDate);
    final limit = recurrenceEndDate != null 
        ? (recurrenceEndDate!.isBefore(rangeEnd)
            ? DateTime(recurrenceEndDate!.year, recurrenceEndDate!.month, recurrenceEndDate!.day, 23, 59, 59)
            : rangeEnd)
        : rangeEnd;

    DateTime currentStart = startDate;

    int occurrenceIndex = 0;
    while (currentStart.isBefore(limit)) {
      final currentEnd = currentStart.add(duration);
      
      // Check if this virtual instance intersects with the range window
      if (currentStart.isBefore(rangeEnd) && currentEnd.isAfter(rangeStart)) {
        instances.add(
          copyWith(
            id: '${id}_rec_$occurrenceIndex',
            startDate: currentStart,
            endDate: currentEnd,
          ),
        );
      }

      occurrenceIndex++;

      switch (recurrenceRule.toUpperCase()) {
        case 'DAILY':
          currentStart = currentStart.add(const Duration(days: 1));
          break;
        case 'WEEKLY':
          currentStart = currentStart.add(const Duration(days: 7));
          break;
        case 'MONTHLY':
          // Move to next month safely retaining day
          var nextMonth = currentStart.month + 1;
          var nextYear = currentStart.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear += 1;
          }
          final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          final targetDay = startDate.day > daysInNextMonth ? daysInNextMonth : startDate.day;
          currentStart = DateTime(nextYear, nextMonth, targetDay, currentStart.hour, currentStart.minute);
          break;
        default:
          return [this]; // safety fallback
      }
    }

    return instances;
  }
}
