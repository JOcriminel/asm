import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_categories_repository.dart';

/// State notifier managing the list of categories.
///
/// Handles loading, error, and successful retrieval. Exposes actions to mutate
/// the state and update the backend via [TimetreeCategoriesRepository].
class TimetreeCategoriesNotifier extends StateNotifier<AsyncValue<List<TimetreeCategory>>> {
  final TimetreeCategoriesRepository _repository;

  TimetreeCategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// Fetches the categories list from the repository.
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getCategories();
      // Sort categories by displayOrder locally
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new category and inserts it into the state list.
  Future<void> createCategory(String name, int displayOrder) async {
    final currentList = state.value ?? [];
    try {
      final newCategory = await _repository.createCategory(name, displayOrder);
      final updatedList = List<TimetreeCategory>.from(currentList)..add(newCategory);
      updatedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Keep existing data but forward the error so the UI can notify the user
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing category in the state list.
  Future<void> updateCategory(String id, String name, int displayOrder) async {
    final currentList = state.value ?? [];
    try {
      final updatedCategory = await _repository.updateCategory(id, name, displayOrder);
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedCategory : item;
      }).toList();
      updatedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Deletes a category and removes it from the state list.
  Future<void> deleteCategory(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deleteCategory(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Toggles the active state of a category.
  Future<void> toggleCategoryActivation(String id, bool active) async {
    final currentList = state.value ?? [];
    // Optimistic UI update
    final optimisticList = currentList.map((item) {
      return item.id == id ? item.copyWith(active: active) : item;
    }).toList();
    state = AsyncValue.data(optimisticList);

    try {
      final updatedCategory = await _repository.toggleCategoryActivation(id, active);
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedCategory : item;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Revert to original list if backend call fails
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

/// Provider for [TimetreeCategoriesNotifier] exposing [AsyncValue<List<TimetreeCategory>>].
final timetreeCategoriesProvider =
    StateNotifierProvider.autoDispose<TimetreeCategoriesNotifier, AsyncValue<List<TimetreeCategory>>>((ref) {
  final repo = ref.watch(timetreeCategoriesRepositoryProvider);
  return TimetreeCategoriesNotifier(repo);
});

/// Search filter query provider.
final timetreeCategorySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Filtered categories list provider.
final filteredTimetreeCategoriesProvider = Provider.autoDispose<AsyncValue<List<TimetreeCategory>>>((ref) {
  final categoriesAsync = ref.watch(timetreeCategoriesProvider);
  final searchQuery = ref.watch(timetreeCategorySearchQueryProvider).trim().toLowerCase();

  return categoriesAsync.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list.where((cat) => cat.name.toLowerCase().contains(searchQuery)).toList();
  });
});
