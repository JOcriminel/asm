import 'package:dux_front/features/timetree/data/dto/timetree_calendar_dto.dart';

/// Clean domain model representing a TimeTree Calendar.
class TimetreeCalendar {
  final String id;
  final String name;
  final String description;
  final String color;

  const TimetreeCalendar({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });

  factory TimetreeCalendar.fromDto(TimetreeCalendarDto dto) {
    return TimetreeCalendar(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      color: dto.color,
    );
  }

  TimetreeCalendar copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
  }) {
    return TimetreeCalendar(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  @override
  String toString() => 'TimetreeCalendar(id: $id, name: $name, color: $color)';
}
