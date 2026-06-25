/// DTO representing the backend payload for a TimeTree Category.
///
/// Handles fields: `id`, `name`, `active`, and `displayOrder`.
class TimetreeCategoryDto {
  final String id;
  final String name;
  final bool active;
  final int displayOrder;

  const TimetreeCategoryDto({
    required this.id,
    required this.name,
    required this.active,
    required this.displayOrder,
  });

  factory TimetreeCategoryDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCategoryDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'active': active,
      'displayOrder': displayOrder,
    };
  }
}
