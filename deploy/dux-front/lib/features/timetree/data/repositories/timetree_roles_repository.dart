import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_role_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_role.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_permission_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_permission.dart';

/// Repository for managing TimeTree Roles & Permissions.
///
/// Uses [TimetreeApi] configured with the shared auth-intercepted Dio instance.
class TimetreeRolesRepository {
  final TimetreeApi _api;
  TimetreeRolesRepository(this._api);

  /// Fetches the list of all available roles.
  Future<List<TimetreeRole>> getRoles() async {
    try {
      final response = await _api.getRoles();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeRoleDto.fromJson)
            .map(TimetreeRole.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'getRoles failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Assigns a role code to a group.
  Future<void> assignRoleToGroup(String groupId, String roleCode) async {
    try {
      await _api.assignRoleToGroup(groupId, roleCode);
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'assignRoleToGroup failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Removes a role code from a group.
  Future<void> removeRoleFromGroup(String groupId, String roleCode) async {
    try {
      await _api.removeRoleFromGroup(groupId, roleCode);
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'removeRoleFromGroup failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Fetches the permissions matrix (categories/pages permission mappings).
  Future<TimetreePermissionMatrix> getPermissions() async {
    try {
      final response = await _api.getPermissions();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final dto = TimetreePermissionMatrixDto.fromJson(data);
        return TimetreePermissionMatrix.fromDto(dto);
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'getPermissions failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Assigns category groups (permissions).
  Future<void> assignCategoryToGroups(String categoryId, List<String> groupIds) async {
    try {
      await _api.assignCategoryToGroup(categoryId, groupIds);
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'assignCategoryToGroups failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Assigns page groups (permissions).
  Future<void> assignPageToGroups(String pageId, List<String> groupIds) async {
    try {
      await _api.assignPageToGroup(pageId, groupIds);
    } catch (e) {
      AppLogger.e('TimetreeRolesRepository', 'assignPageToGroups failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Provider for [TimetreeRolesRepository].
final timetreeRolesRepositoryProvider = Provider<TimetreeRolesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeRolesRepository(TimetreeApi(dio));
});
