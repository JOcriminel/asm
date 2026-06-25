import 'timetree_custom_field_dto.dart';

/// DTO representing the backend payload for a Custom Field Value.
class TimetreeCustomFieldValueDto {
  final String id;
  final TimetreeCustomFieldDto field;
  final String entityType;
  final String entityId;
  final String? value;
  final bool showEmojiInTitle;

  const TimetreeCustomFieldValueDto({
    required this.id,
    required this.field,
    required this.entityType,
    required this.entityId,
    this.value,
    this.showEmojiInTitle = false,
  });

  factory TimetreeCustomFieldValueDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCustomFieldValueDto(
      id: (json['id'] ?? '').toString(),
      field: TimetreeCustomFieldDto.fromJson(json['field'] as Map<String, dynamic>),
      entityType: json['entityType'] as String? ?? 'EVENT',
      entityId: (json['entityId'] ?? '').toString(),
      value: json['value'] as String?,
      showEmojiInTitle: json['showEmojiInTitle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': int.tryParse(id) ?? id,
      'field': field.toJson(),
      'entityType': entityType,
      'entityId': entityId,
      'value': value,
      'showEmojiInTitle': showEmojiInTitle,
    };
  }
}

