import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';

/// DTO representing the backend payload for a TimeTree Calendar.
class TimetreeCalendarDto {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<TimetreeMemberDto> members;
  final String? attachedDocuments;

  const TimetreeCalendarDto({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.members,
    this.attachedDocuments,
  });

  factory TimetreeCalendarDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCalendarDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '',
      members: (json['members'] as List?)
              ?.map((e) => TimetreeMemberDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachedDocuments: json['attachedDocuments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'members': members.map((m) => m.toJson()).toList(),
      if (attachedDocuments != null) 'attachedDocuments': attachedDocuments,
    };
  }
}
