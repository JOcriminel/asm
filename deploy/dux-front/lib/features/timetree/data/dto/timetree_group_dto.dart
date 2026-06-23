import 'package:dux_front/features/timetree/data/dto/timetree_calendar_dto.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';

/// DTO representing the backend payload for a TimeTree Group.
class TimetreeGroupDto {
  final String id;
  final String name;
  final String description;
  final bool active;
  final List<String> roles;
  final TimetreeMemberDto? chef;
  final List<TimetreeMemberDto> members;
  final List<TimetreeCalendarDto> calendars;

  const TimetreeGroupDto({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.roles = const [],
    this.chef,
    this.members = const [],
    this.calendars = const [],
  });

  factory TimetreeGroupDto.fromJson(Map<String, dynamic> json) {
    return TimetreeGroupDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chef: json['chef'] != null
          ? TimetreeMemberDto.fromJson(json['chef'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List?)
              ?.map((e) => TimetreeMemberDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calendars: (json['calendars'] as List?)
              ?.map((e) => TimetreeCalendarDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'roles': roles,
      'chef': chef?.toJson(),
      'members': members.map((e) => e.toJson()).toList(),
      'calendars': calendars.map((e) => e.toJson()).toList(),
    };
  }
}
