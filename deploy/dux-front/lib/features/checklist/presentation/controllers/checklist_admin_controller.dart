import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist_models.dart';

// ==========================================
// GROUPS PROVIDER
// ==========================================
final groupsProvider = FutureProvider<List<ChecklistGroup>>((ref) {
  return ref.watch(checklistRepositoryProvider).getGroups();
});

// ==========================================
// TYPES PROVIDER
// ==========================================
final taskTypesProvider = FutureProvider<List<ChecklistTaskType>>((ref) {
  return ref.watch(checklistRepositoryProvider).getTaskTypes();
});

// ==========================================
// TASKS PROVIDER
// ==========================================
final tasksProvider = FutureProvider<List<ChecklistTask>>((ref) {
  return ref.watch(checklistRepositoryProvider).getAllTasks();
});

// ==========================================
// FAMILY MAPPINGS PROVIDER
// ==========================================
final familyMappingsProvider = FutureProvider.family<List<ChecklistFamilyMapping>, int>((ref, groupId) {
  return ref.watch(checklistRepositoryProvider).getFamiliesByGroup(groupId);
});

// ==========================================
// ERP FAMILIES PROVIDER
// ==========================================
final erpFamiliesProvider = FutureProvider<List<ErpFamily>>((ref) {
  return ref.watch(checklistRepositoryProvider).getErpFamilies();
});

// ==========================================
// ADMIN CONTROLLER
// ==========================================
class ChecklistAdminController extends StateNotifier<AsyncValue<void>> {
  final ChecklistRepository _repository;
  final Ref _ref;

  ChecklistAdminController(this._repository, this._ref) : super(const AsyncData(null));

  Future<void> createGroup(String name) async {
    state = const AsyncLoading();
    try {
      await _repository.createGroup(name);
      _ref.invalidate(groupsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteGroup(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteGroup(id);
      _ref.invalidate(groupsProvider);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createTaskType(String name, {String? information, String? codeDoc, List<String>? roles}) async {
    state = const AsyncLoading();
    try {
      await _repository.createTaskType(name, information: information, codeDoc: codeDoc, roles: roles);
      _ref.invalidate(taskTypesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTaskType(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteTaskType(id);
      _ref.invalidate(taskTypesProvider);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createTask(int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) async {
    state = const AsyncLoading();
    try {
      await _repository.createTask(groupId, codeFamille, typeId, nomTache, information: information);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteTask(id);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTaskType(int id, String name, {String? information, String? codeDoc, List<String>? roles}) async {
    state = const AsyncLoading();
    try {
      await _repository.updateTaskType(id, name, information: information, codeDoc: codeDoc, roles: roles);
      _ref.invalidate(taskTypesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTask(int id, int? groupId, String? codeFamille, int typeId, String nomTache, {String? information}) async {
    state = const AsyncLoading();
    try {
      await _repository.updateTask(id, groupId, codeFamille, typeId, nomTache, information: information);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleTaskActive(int id, bool active) async {
    state = const AsyncLoading();
    try {
      await _repository.toggleTaskActive(id, active);
      _ref.invalidate(tasksProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleGroupActive(int id, bool active) async {
    state = const AsyncLoading();
    try {
      await _repository.toggleGroupActive(id, active);
      _ref.invalidate(groupsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleTaskTypeActive(int id, bool active) async {
    state = const AsyncLoading();
    try {
      await _repository.toggleTaskTypeActive(id, active);
      _ref.invalidate(taskTypesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addFamilyToGroup(int groupId, String codeFamille) async {
    state = const AsyncLoading();
    try {
      await _repository.addFamilyToGroup(groupId, codeFamille);
      _ref.invalidate(familyMappingsProvider(groupId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteFamilyMapping(int groupId, int mappingId) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteFamilyMapping(mappingId);
      _ref.invalidate(familyMappingsProvider(groupId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final checklistAdminControllerProvider = StateNotifierProvider<ChecklistAdminController, AsyncValue<void>>((ref) {
  return ChecklistAdminController(ref.watch(checklistRepositoryProvider), ref);
});
