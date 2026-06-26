import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field_category.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';

/// State notifier managing the list of custom field categories.
class TimetreeCustomFieldCategoriesNotifier extends StateNotifier<AsyncValue<List<TimetreeCustomFieldCategory>>> {
  final TimetreeCustomFieldsRepository _repository;

  TimetreeCustomFieldCategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// Fetches the custom field categories list from the repository.
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getCustomFieldCategories();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a new custom field category and inserts it into the state list.
  Future<void> createCategory(String name, int displayOrder) async {
    final currentList = state.value ?? [];
    try {
      final newCategory = await _repository.createCustomFieldCategory(name, displayOrder);
      final updatedList = List<TimetreeCustomFieldCategory>.from(currentList)..add(newCategory);
      updatedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing custom field category in the state list.
  Future<void> updateCategory(String id, String name, int displayOrder, bool active) async {
    final currentList = state.value ?? [];
    try {
      final updatedCategory = await _repository.updateCustomFieldCategory(id, name, displayOrder, active);
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

  /// Deletes a custom field category and removes it from the state list.
  Future<void> deleteCategory(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deleteCustomFieldCategory(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

/// Provider for [TimetreeCustomFieldCategoriesNotifier] exposing [AsyncValue<List<TimetreeCustomFieldCategory>>].
final timetreeCustomFieldCategoriesProvider =
    StateNotifierProvider<TimetreeCustomFieldCategoriesNotifier, AsyncValue<List<TimetreeCustomFieldCategory>>>((ref) {
  final repo = ref.watch(timetreeCustomFieldsRepositoryProvider);
  return TimetreeCustomFieldCategoriesNotifier(repo);
});
