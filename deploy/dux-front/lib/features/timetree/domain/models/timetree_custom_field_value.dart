import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_value_dto.dart';
import 'timetree_custom_field.dart';

/// Clean domain model representing a Custom Field Value.
class TimetreeCustomFieldValue {
  final String id;
  final TimetreeCustomField field;
  final String entityType;
  final String entityId;
  final String? value;
  final bool showEmojiInTitle;

  const TimetreeCustomFieldValue({
    required this.id,
    required this.field,
    required this.entityType,
    required this.entityId,
    this.value,
    this.showEmojiInTitle = false,
  });

  factory TimetreeCustomFieldValue.fromDto(TimetreeCustomFieldValueDto dto) {
    return TimetreeCustomFieldValue(
      id: dto.id,
      field: TimetreeCustomField.fromDto(dto.field),
      entityType: dto.entityType,
      entityId: dto.entityId,
      value: dto.value,
      showEmojiInTitle: dto.showEmojiInTitle,
    );
  }

  TimetreeCustomFieldValueDto toDto() {
    return TimetreeCustomFieldValueDto(
      id: id,
      field: field.toDto(),
      entityType: entityType,
      entityId: entityId,
      value: value,
      showEmojiInTitle: showEmojiInTitle,
    );
  }

  TimetreeCustomFieldValue copyWith({
    String? id,
    TimetreeCustomField? field,
    String? entityType,
    String? entityId,
    String? value,
    bool? showEmojiInTitle,
  }) {
    return TimetreeCustomFieldValue(
      id: id ?? this.id,
      field: field ?? this.field,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      value: value ?? this.value,
      showEmojiInTitle: showEmojiInTitle ?? this.showEmojiInTitle,
    );
  }
}

