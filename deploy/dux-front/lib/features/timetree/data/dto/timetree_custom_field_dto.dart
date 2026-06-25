/// DTO representing the backend payload for a Custom Field definition.
class TimetreeCustomFieldDto {
  final String id;
  final String name;
  final String label;
  final String fieldType;
  final bool required;
  final String? defaultValue;
  final String? options;
  final String scopeType;
  final String? scopeId;
  final int sortOrder;
  final bool active;
  final double? minValue;
  final double? maxValue;
  final int? minLength;
  final int? maxLength;
  final String? regexPattern;
  final bool hidden;
  final bool readOnly;
  final String? visibilityRule;
  final String? emoji;
  final int? emojiOrder;

  const TimetreeCustomFieldDto({
    required this.id,
    required this.name,
    required this.label,
    required this.fieldType,
    required this.required,
    this.defaultValue,
    this.options,
    required this.scopeType,
    this.scopeId,
    required this.sortOrder,
    required this.active,
    this.minValue,
    this.maxValue,
    this.minLength,
    this.maxLength,
    this.regexPattern,
    required this.hidden,
    required this.readOnly,
    this.visibilityRule,
    this.emoji,
    this.emojiOrder,
  });

  factory TimetreeCustomFieldDto.fromJson(Map<String, dynamic> json) {
    return TimetreeCustomFieldDto(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      fieldType: json['fieldType'] as String? ?? 'STRING',
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      options: json['options'] as String?,
      scopeType: json['scopeType'] as String? ?? 'GLOBAL',
      scopeId: json['scopeId']?.toString(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      minValue: json['minValue'] != null ? (json['minValue'] as num).toDouble() : null,
      maxValue: json['maxValue'] != null ? (json['maxValue'] as num).toDouble() : null,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      regexPattern: json['regexPattern'] as String?,
      hidden: json['hidden'] as bool? ?? false,
      readOnly: json['readOnly'] as bool? ?? false,
      visibilityRule: json['visibilityRule'] as String?,
      emoji: json['emoji'] as String?,
      emojiOrder: json['emojiOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty && !id.startsWith('temp_')) 'id': int.tryParse(id) ?? id,
      'name': name,
      'label': label,
      'fieldType': fieldType,
      'required': required,
      'defaultValue': defaultValue,
      'options': options,
      'scopeType': scopeType,
      'scopeId': scopeId,
      'sortOrder': sortOrder,
      'active': active,
      'minValue': minValue,
      'maxValue': maxValue,
      'minLength': minLength,
      'maxLength': maxLength,
      'regexPattern': regexPattern,
      'hidden': hidden,
      'readOnly': readOnly,
      'visibilityRule': visibilityRule,
      'emoji': emoji,
      'emojiOrder': emojiOrder,
    };
  }
}

