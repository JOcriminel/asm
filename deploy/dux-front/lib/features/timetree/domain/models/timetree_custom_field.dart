import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_dto.dart';

/// Clean domain model representing a Custom Field definition.
class TimetreeCustomField {
  final String id;
  final String name;
  final String label;
  final String fieldType; // STRING, TEXT_AREA, INTEGER, FLOAT, BOOLEAN, DATE, DATETIME, EMAIL, PHONE, URL, RADIO, CHECKBOX, DROPDOWN, MULTI_SELECT
  final bool required;
  final String? defaultValue;
  final String? options;
  final String scopeType; // GROUP, CALENDAR, EVENT, GLOBAL
  final String? scopeId;
  final int sortOrder;
  final bool active;
  
  // Validation limits
  final double? minValue;
  final double? maxValue;
  final int? minLength;
  final int? maxLength;
  final String? regexPattern;

  // Display rules
  final bool hidden;
  final bool readOnly;
  final String? visibilityRule;

  const TimetreeCustomField({
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
  });

  factory TimetreeCustomField.fromDto(TimetreeCustomFieldDto dto) {
    return TimetreeCustomField(
      id: dto.id,
      name: dto.name,
      label: dto.label,
      fieldType: dto.fieldType,
      required: dto.required,
      defaultValue: dto.defaultValue,
      options: dto.options,
      scopeType: dto.scopeType,
      scopeId: dto.scopeId,
      sortOrder: dto.sortOrder,
      active: dto.active,
      minValue: dto.minValue,
      maxValue: dto.maxValue,
      minLength: dto.minLength,
      maxLength: dto.maxLength,
      regexPattern: dto.regexPattern,
      hidden: dto.hidden,
      readOnly: dto.readOnly,
      visibilityRule: dto.visibilityRule,
    );
  }

  TimetreeCustomFieldDto toDto() {
    return TimetreeCustomFieldDto(
      id: id,
      name: name,
      label: label,
      fieldType: fieldType,
      required: required,
      defaultValue: defaultValue,
      options: options,
      scopeType: scopeType,
      scopeId: scopeId,
      sortOrder: sortOrder,
      active: active,
      minValue: minValue,
      maxValue: maxValue,
      minLength: minLength,
      maxLength: maxLength,
      regexPattern: regexPattern,
      hidden: hidden,
      readOnly: readOnly,
      visibilityRule: visibilityRule,
    );
  }

  TimetreeCustomField copyWith({
    String? id,
    String? name,
    String? label,
    String? fieldType,
    bool? required,
    String? defaultValue,
    String? options,
    String? scopeType,
    String? scopeId,
    int? sortOrder,
    bool? active,
    double? minValue,
    double? maxValue,
    int? minLength,
    int? maxLength,
    String? regexPattern,
    bool? hidden,
    bool? readOnly,
    String? visibilityRule,
  }) {
    return TimetreeCustomField(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      regexPattern: regexPattern ?? this.regexPattern,
      hidden: hidden ?? this.hidden,
      readOnly: readOnly ?? this.readOnly,
      visibilityRule: visibilityRule ?? this.visibilityRule,
    );
  }
}
