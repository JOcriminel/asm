import 'package:dux_front/features/timetree/data/dto/timetree_page_dto.dart';

/// Clean domain model representing a TimeTree Page.
///
/// Used directly by UI components.
class TimetreePage {
  final String id;
  final String title;
  final bool active;
  final int displayOrder;
  final String categoryId;
  final String? allowedRoles;
  final String? allowedUsers;

  const TimetreePage({
    required this.id,
    required this.title,
    required this.active,
    required this.displayOrder,
    required this.categoryId,
    this.allowedRoles,
    this.allowedUsers,
  });

  factory TimetreePage.fromDto(TimetreePageDto dto) {
    return TimetreePage(
      id: dto.id,
      title: dto.title,
      active: dto.active,
      displayOrder: dto.displayOrder,
      categoryId: dto.categoryId,
      allowedRoles: dto.allowedRoles,
      allowedUsers: dto.allowedUsers,
    );
  }

  TimetreePage copyWith({
    String? id,
    String? title,
    bool? active,
    int? displayOrder,
    String? categoryId,
    String? allowedRoles,
    String? allowedUsers,
  }) {
    return TimetreePage(
      id: id ?? this.id,
      title: title ?? this.title,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
      categoryId: categoryId ?? this.categoryId,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      allowedUsers: allowedUsers ?? this.allowedUsers,
    );
  }

  @override
  String toString() => 'TimetreePage(id: $id, title: $title, active: $active, allowedRoles: $allowedRoles, allowedUsers: $allowedUsers)';
}
