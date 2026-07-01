import 'package:dux_front/features/timetree/data/dto/timetree_category_dto.dart';

class TimetreeCategory {
  final String id;
  final String name;
  final bool active;
  final int displayOrder;
  final String? allowedRoles;
  final String? allowedUsers;

  const TimetreeCategory({
    required this.id,
    required this.name,
    required this.active,
    required this.displayOrder,
    this.allowedRoles,
    this.allowedUsers,
  });

  factory TimetreeCategory.fromDto(TimetreeCategoryDto dto) {
    return TimetreeCategory(
      id: dto.id,
      name: dto.name,
      active: dto.active,
      displayOrder: dto.displayOrder,
      allowedRoles: dto.allowedRoles,
      allowedUsers: dto.allowedUsers,
    );
  }

  TimetreeCategory copyWith({
    String? id,
    String? name,
    bool? active,
    int? displayOrder,
    String? allowedRoles,
    String? allowedUsers,
  }) {
    return TimetreeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      allowedUsers: allowedUsers ?? this.allowedUsers,
    );
  }

  @override
  String toString() => 'TimetreeCategory(id: $id, name: $name, active: $active, allowedRoles: $allowedRoles, allowedUsers: $allowedUsers)';
}
