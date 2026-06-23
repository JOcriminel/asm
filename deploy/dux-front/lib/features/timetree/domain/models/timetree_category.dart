import 'package:dux_front/features/timetree/data/dto/timetree_category_dto.dart';

/// Clean domain model representing a TimeTree Category.
///
/// Used directly by UI components.
class TimetreeCategory {
  final String id;
  final String name;
  final bool active;
  final int displayOrder;

  const TimetreeCategory({
    required this.id,
    required this.name,
    required this.active,
    required this.displayOrder,
  });

  factory TimetreeCategory.fromDto(TimetreeCategoryDto dto) {
    return TimetreeCategory(
      id: dto.id,
      name: dto.name,
      active: dto.active,
      displayOrder: dto.displayOrder,
    );
  }

  TimetreeCategory copyWith({
    String? id,
    String? name,
    bool? active,
    int? displayOrder,
  }) {
    return TimetreeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  String toString() => 'TimetreeCategory(id: $id, name: $name, active: $active)';
}
