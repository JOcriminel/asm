/// DTO representing the backend payload for a TimeTree Page.
///
/// Handles fields: `id`, `title`, `active`, `displayOrder`, and `categoryId`.
class TimetreePageDto {
  final String id;
  final String title;
  final bool active;
  final int displayOrder;
  final String categoryId;
  final String? allowedRoles;
  final String? allowedUsers;

  const TimetreePageDto({
    required this.id,
    required this.title,
    required this.active,
    required this.displayOrder,
    required this.categoryId,
    this.allowedRoles,
    this.allowedUsers,
  });

  factory TimetreePageDto.fromJson(Map<String, dynamic> json) {
    return TimetreePageDto(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] ?? '').toString(),
      allowedRoles: json['allowedRoles'] as String?,
      allowedUsers: json['allowedUsers'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'active': active,
      'displayOrder': displayOrder,
      'categoryId': categoryId,
      'allowedRoles': allowedRoles,
      'allowedUsers': allowedUsers,
    };
  }
}
