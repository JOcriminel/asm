import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_category_dto.dart';

/// Clean domain model representing a Custom Field Category.
class TimetreeCustomFieldCategory {
  final String id;
  final String name;
  final int displayOrder;
  final bool active;

  const TimetreeCustomFieldCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.active,
  });

  factory TimetreeCustomFieldCategory.fromDto(TimetreeCustomFieldCategoryDto dto) {
    return TimetreeCustomFieldCategory(
      id: dto.id,
      name: dto.name,
      displayOrder: dto.displayOrder,
      active: dto.active,
    );
  }

  TimetreeCustomFieldCategory copyWith({
    String? id,
    String? name,
    int? displayOrder,
    bool? active,
  }) {
    return TimetreeCustomFieldCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      active: active ?? this.active,
    );
  }

  TimetreeCustomFieldCategoryDto toDto() {
    return TimetreeCustomFieldCategoryDto(
      id: id,
      name: name,
      displayOrder: displayOrder,
      active: active,
    );
  }

  @override
  String toString() => 'TimetreeCustomFieldCategory(id: $id, name: $name, active: $active)';
}

