/// DTO representing the backend payload for a TimeTree Calendar.
class TimetreeCalendarDto {
  final String id;
  final String name;
  final String description;
  final String color;

  const TimetreeCalendarDto({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });

  factory TimetreeCalendarDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCalendarDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
    };
  }
}
