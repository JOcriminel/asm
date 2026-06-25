import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_roles_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_role.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_permission.dart';


/// StateNotifier for managing available Roles.
class TimetreeRolesNotifier extends StateNotifier<AsyncValue<List<TimetreeRole>>> {
  final TimetreeRolesRepository _repository;
  final Ref _ref;

  TimetreeRolesNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadRoles();
  }

  Future<void> loadRoles() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getRoles();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Assigns a role to a group (deprecated — kept for API compatibility).
  Future<void> assignRoleToGroup(String groupId, String roleCode) async {
    try {
      await _repository.assignRoleToGroup(groupId, roleCode);
    } catch (e) {
      rethrow;
    }
  }

  /// Removes a role from a group (deprecated — kept for API compatibility).
  Future<void> removeRoleFromGroup(String groupId, String roleCode) async {
    try {
      await _repository.removeRoleFromGroup(groupId, roleCode);
    } catch (e) {
      rethrow;
    }
  }
}

final timetreeRolesProvider =
    StateNotifierProvider.autoDispose<TimetreeRolesNotifier, AsyncValue<List<TimetreeRole>>>((ref) {
  final repo = ref.watch(timetreeRolesRepositoryProvider);
  return TimetreeRolesNotifier(repo, ref);
});

/// StateNotifier for managing Permissions Matrix.
class TimetreePermissionsNotifier extends StateNotifier<AsyncValue<TimetreePermissionMatrix>> {
  final TimetreeRolesRepository _repository;

  TimetreePermissionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPermissions();
  }

  Future<void> loadPermissions() async {
    state = const AsyncValue.loading();
    try {
      final matrix = await _repository.getPermissions();
      state = AsyncValue.data(matrix);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Assigns category groups (permissions)
  Future<void> updateCategoryPermissions(String categoryId, List<String> groupIds) async {
    try {
      await _repository.assignCategoryToGroups(categoryId, groupIds);
      // Reload permissions matrix
      await loadPermissions();
    } catch (e) {
      rethrow;
    }
  }

  /// Assigns page groups (permissions)
  Future<void> updatePagePermissions(String pageId, List<String> groupIds) async {
    try {
      await _repository.assignPageToGroups(pageId, groupIds);
      // Reload permissions matrix
      await loadPermissions();
    } catch (e) {
      rethrow;
    }
  }
}

final timetreePermissionsProvider =
    StateNotifierProvider.autoDispose<TimetreePermissionsNotifier, AsyncValue<TimetreePermissionMatrix>>((ref) {
  final repo = ref.watch(timetreeRolesRepositoryProvider);
  return TimetreePermissionsNotifier(repo);
});
