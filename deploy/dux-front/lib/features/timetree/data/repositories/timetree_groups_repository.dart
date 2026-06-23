import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_group_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';

/// Repository for managing TimeTree Groups.
///
/// Uses [TimetreeApi] configured with the shared auth-intercepted Dio instance.
class TimetreeGroupsRepository {
  final TimetreeApi _api;
  TimetreeGroupsRepository(this._api);

  /// Fetches the list of all groups.
  Future<List<TimetreeGroup>> getGroups() async {
    try {
      final response = await _api.getGroups();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeGroupDto.fromJson)
            .map(TimetreeGroup.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeGroupsRepository', 'getGroups failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches a single group by ID.
  Future<TimetreeGroup> getGroup(String id) async {
    try {
      final response = await _api.getGroup(id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeGroupDto.fromJson(data);
        return TimetreeGroup.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeGroupsRepository', 'getGroup($id) failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Creates a new group.
  Future<TimetreeGroup> createGroup({
    required String name,
    required String description,
    required bool active,
  }) async {
    try {
      final response = await _api.createGroup({
        'name': name,
        'description': description,
        'active': active,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeGroupDto.fromJson(data);
        return TimetreeGroup.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeGroupsRepository', 'createGroup failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Updates an existing group name, description, or active status.
  Future<TimetreeGroup> updateGroup({
    required String id,
    required String name,
    required String description,
    required bool active,
  }) async {
    try {
      final response = await _api.updateGroup(id, {
        'name': name,
        'description': description,
        'active': active,
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreeGroupDto.fromJson(data);
        return TimetreeGroup.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeGroupsRepository', 'updateGroup failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Deletes a group by ID.
  Future<void> deleteGroup(String id) async {
    try {
      await _api.deleteGroup(id);
    } catch (e) {
      AppLogger.e('TimetreeGroupsRepository', 'deleteGroup failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeGroupsRepository].
final timetreeGroupsRepositoryProvider = Provider<TimetreeGroupsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeGroupsRepository(TimetreeApi(dio));
});
