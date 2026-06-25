import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_dto.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_value_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field_value.dart';

/// Repository for managing generic Custom Fields and their values.
class TimetreeCustomFieldsRepository {
  final TimetreeApi _api;
  TimetreeCustomFieldsRepository(this._api);

  /// Fetch fields with optional filters
  Future<List<TimetreeCustomField>> getCustomFields({String? scopeType, String? scopeId}) async {
    try {
      final response = await _api.getCustomFields(scopeType: scopeType, scopeId: scopeId);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeCustomFieldDto.fromJson)
            .map(TimetreeCustomField.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'getCustomFields failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Get dynamic event fields aggregated from its group, calendar, and event-specific
  Future<List<TimetreeCustomField>> getEventFields({String? groupId, String? calendarId, String? eventId}) async {
    try {
      final response = await _api.getEventFields(groupId: groupId, calendarId: calendarId, eventId: eventId);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeCustomFieldDto.fromJson)
            .map(TimetreeCustomField.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'getEventFields failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetch a single custom field definition
  Future<TimetreeCustomField> getCustomField(String id) async {
    try {
      final response = await _api.getCustomField(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCustomFieldDto.fromJson(data);
        return TimetreeCustomField.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'getCustomField($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Create custom field definition
  Future<TimetreeCustomField> createCustomField(TimetreeCustomField field) async {
    try {
      final response = await _api.createCustomField(field.toDto().toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCustomFieldDto.fromJson(data);
        return TimetreeCustomField.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'createCustomField failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Update custom field definition
  Future<TimetreeCustomField> updateCustomField(TimetreeCustomField field) async {
    try {
      final response = await _api.updateCustomField(field.id, field.toDto().toJson());
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeCustomFieldDto.fromJson(data);
        return TimetreeCustomField.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'updateCustomField failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Delete custom field definition
  Future<void> deleteCustomField(String id) async {
    try {
      await _api.deleteCustomField(id);
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'deleteCustomField failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Bulk reorder fields
  Future<void> reorderCustomFields(List<TimetreeCustomField> fields) async {
    try {
      final List<Map<String, dynamic>> reorderList = [];
      for (int i = 0; i < fields.length; i++) {
        reorderList.add({
          'id': int.tryParse(fields[i].id) ?? fields[i].id,
          'sortOrder': i + 1,
        });
      }
      await _api.reorderCustomFields(reorderList);
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'reorderCustomFields failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetch custom field values for a specific entity
  Future<List<TimetreeCustomFieldValue>> getCustomFieldValues(String entityType, String entityId) async {
    try {
      final response = await _api.getCustomFieldValues(entityType, entityId);
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeCustomFieldValueDto.fromJson)
            .map(TimetreeCustomFieldValue.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'getCustomFieldValues failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Save custom field values for a specific entity
  Future<void> saveCustomFieldValues(String entityType, String entityId, Map<String, dynamic> values) async {
    try {
      await _api.saveCustomFieldValues(entityType, entityId, values);
    } catch (e) {
      AppLogger.e('TimetreeCustomFieldsRepository', 'saveCustomFieldValues failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

}

/// Provider for [TimetreeCustomFieldsRepository].
final timetreeCustomFieldsRepositoryProvider = Provider<TimetreeCustomFieldsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeCustomFieldsRepository(TimetreeApi(dio));
});
