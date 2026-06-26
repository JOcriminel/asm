/// DTO representing the backend payload for a Custom Field Category.
class TimetreeCustomFieldCategoryDto {
  final String id;
  final String name;
  final int displayOrder;
  final bool active;

  const TimetreeCustomFieldCategoryDto({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.active,
  });

  factory TimetreeCustomFieldCategoryDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCustomFieldCategoryDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': int.tryParse(id) ?? id,
      'name': name,
      'displayOrder': displayOrder,
      'active': active,
    };
  }
}
