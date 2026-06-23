import 'package:dux_front/features/timetree/data/dto/timetree_group_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';

/// Clean domain model representing a TimeTree Group.
class TimetreeGroup {
  final String id;
  final String name;
  final String description;
  final bool active;
  final List<String> roles;
  final TimetreeMember? chef;
  final List<TimetreeMember> members;
  final List<TimetreeCalendar> calendars;

  const TimetreeGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.roles = const [],
    this.chef,
    this.members = const [],
    this.calendars = const [],
  });

  factory TimetreeGroup.fromDto(TimetreeGroupDto dto) {
    return TimetreeGroup(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      active: dto.active,
      roles: dto.roles,
      chef: dto.chef != null ? TimetreeMember.fromDto(dto.chef!) : null,
      members: dto.members.map((m) => TimetreeMember.fromDto(m)).toList(),
      calendars: dto.calendars.map((c) => TimetreeCalendar.fromDto(c)).toList(),
    );
  }

  TimetreeGroup copyWith({
    String? id,
    String? name,
    String? description,
    bool? active,
    List<String>? roles,
    TimetreeMember? chef,
    List<TimetreeMember>? members,
    List<TimetreeCalendar>? calendars,
  }) {
    return TimetreeGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      roles: roles ?? this.roles,
      chef: chef ?? this.chef,
      members: members ?? this.members,
      calendars: calendars ?? this.calendars,
    );
  }

  @override
  String toString() =>
      'TimetreeGroup(id: $id, name: $name, active: $active, roles: $roles, chef: $chef)';
}
