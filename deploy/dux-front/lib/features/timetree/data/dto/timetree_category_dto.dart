class TimetreeCategoryDto {
  final String id;
  final String name;
  final bool active;
  final int displayOrder;
  final String? allowedRoles;
  final String? allowedUsers;

  const TimetreeCategoryDto({
    required this.id,
    required this.name,
    required this.active,
    required this.displayOrder,
    this.allowedRoles,
    this.allowedUsers,
  });

  factory TimetreeCategoryDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCategoryDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      allowedRoles: json['allowedRoles'] as String?,
      allowedUsers: json['allowedUsers'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'active': active,
      'displayOrder': displayOrder,
      'allowedRoles': allowedRoles,
      'allowedUsers': allowedUsers,
    };
  }
}
