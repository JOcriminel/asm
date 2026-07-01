import 'package:dux_front/features/timetree/data/dto/timetree_calendar_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';

/// Clean domain model representing a TimeTree Calendar.
class TimetreeCalendar {
  final String id;
  final String name;
  final String description;
  final String color;
  final List<TimetreeMember> members;
  final String? attachedDocuments;

  const TimetreeCalendar({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.members,
    this.attachedDocuments,
  });

  factory TimetreeCalendar.fromDto(TimetreeCalendarDto dto) {
    return TimetreeCalendar(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      color: dto.color,
      members: dto.members.map(TimetreeMember.fromDto).toList(),
      attachedDocuments: dto.attachedDocuments,
    );
  }

  TimetreeCalendar copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    List<TimetreeMember>? members,
    String? attachedDocuments,
  }) {
    return TimetreeCalendar(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      members: members ?? this.members,
      attachedDocuments: attachedDocuments ?? this.attachedDocuments,
    );
  }

  @override
  String toString() => 'TimetreeCalendar(id: $id, name: $name, color: $color, members: ${members.length}, attachedDocuments: $attachedDocuments)';
}
