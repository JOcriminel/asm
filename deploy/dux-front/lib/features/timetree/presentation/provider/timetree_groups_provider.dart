import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_groups_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';

/// StateNotifier for managing the list of TimeTree Groups.
class TimetreeGroupsNotifier extends StateNotifier<AsyncValue<List<TimetreeGroup>>> {
  final TimetreeGroupsRepository _repository;

  TimetreeGroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  /// Fetches the group list from repository.
  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getGroups();
      // Sort alphabetically by name
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new group and updates the local state.
  Future<void> createGroup({
    required String name,
    required String description,
    required bool active,
  }) async {
    final currentList = state.value ?? [];
    try {
      final newGroup = await _repository.createGroup(
        name: name,
        description: description,
        active: active,
      );
      final updatedList = List<TimetreeGroup>.from(currentList)..add(newGroup);
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing group and updates the local state.
  Future<void> updateGroup({
    required String id,
    required String name,
    required String description,
    required bool active,
  }) async {
    final currentList = state.value ?? [];
    try {
      final updatedGroup = await _repository.updateGroup(
        id: id,
        name: name,
        description: description,
        active: active,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedGroup : item;
      }).toList();
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Deletes a group and updates the local state.
  Future<void> deleteGroup(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deleteGroup(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Toggles activation state optimistically.
  Future<void> toggleGroupActivation(String id, bool active) async {
    final currentList = state.value ?? [];
    final originalGroup = currentList.firstWhere((g) => g.id == id);

    // Optimistic update
    final optimisticList = currentList.map((item) {
      return item.id == id ? item.copyWith(active: active) : item;
    }).toList();
    state = AsyncValue.data(optimisticList);

    try {
      final updatedGroup = await _repository.updateGroup(
        id: id,
        name: originalGroup.name,
        description: originalGroup.description,
        active: active,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedGroup : item;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

/// Provider for [TimetreeGroupsNotifier].
final timetreeGroupsProvider =
    StateNotifierProvider.autoDispose<TimetreeGroupsNotifier, AsyncValue<List<TimetreeGroup>>>((ref) {
  final repo = ref.watch(timetreeGroupsRepositoryProvider);
  return TimetreeGroupsNotifier(repo);
});

/// Holds the search filter query for Groups.
final timetreeGroupSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider that exposes a filtered list of groups based on the search query.
final filteredTimetreeGroupsProvider = Provider.autoDispose<AsyncValue<List<TimetreeGroup>>>((ref) {
  final groupsAsync = ref.watch(timetreeGroupsProvider);
  final searchQuery = ref.watch(timetreeGroupSearchQueryProvider).trim().toLowerCase();

  return groupsAsync.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list
        .where((g) =>
            g.name.toLowerCase().contains(searchQuery) ||
            g.description.toLowerCase().contains(searchQuery))
        .toList();
  });
});
