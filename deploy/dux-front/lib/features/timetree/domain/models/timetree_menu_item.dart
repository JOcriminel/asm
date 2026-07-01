/// Domain model representing a single item in the TimeTree navigation menu.
///
/// This replaces the placeholder [MenuItem] that was in lib/core/models/menu_item.dart.
/// The shape mirrors the JSON returned by /api/timetree/menu.
class TimetreeMenuItem {
  final String id;
  final String title;
  final String path;
  final int displayOrder;
  final List<TimetreeMenuItem> children;
  final String? allowedRoles;
  final String? allowedUsers;

  const TimetreeMenuItem({
    required this.id,
    required this.title,
    required this.path,
    required this.displayOrder,
    this.children = const [],
    this.allowedRoles,
    this.allowedUsers,
  });

  factory TimetreeMenuItem.fromJson(Map<String, dynamic> json) {
    return TimetreeMenuItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      path: json['path'] as String? ?? '',
      displayOrder: json['displayOrder'] as int? ?? 0,
      allowedRoles: json['allowedRoles'] as String?,
      allowedUsers: json['allowedUsers'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) =>
                  TimetreeMenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'displayOrder': displayOrder,
        'allowedRoles': allowedRoles,
        'allowedUsers': allowedUsers,
        'children': children.map((c) => c.toJson()).toList(),
      };

  @override
  String toString() =>
      'TimetreeMenuItem(id: $id, title: $title, path: $path)';
}
