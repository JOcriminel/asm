import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_page.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_pages_repository.dart';

/// State notifier managing the list of pages.
class TimetreePagesNotifier extends StateNotifier<AsyncValue<List<TimetreePage>>> {
  final TimetreePagesRepository _repository;

  TimetreePagesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPages();
  }

  /// Fetches pages from the repository.
  Future<void> loadPages() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getPages();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Creates a page.
  Future<void> createPage({
    required String title,
    required String categoryId,
    required int displayOrder,
    required bool active,
  }) async {
    final currentList = state.value ?? [];
    try {
      final newPage = await _repository.createPage(
        title: title,
        categoryId: categoryId,
        displayOrder: displayOrder,
        active: active,
      );
      final updatedList = List<TimetreePage>.from(currentList)..add(newPage);
      updatedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing page.
  Future<void> updatePage({
    required String id,
    required String title,
    required String categoryId,
    required int displayOrder,
    required bool active,
  }) async {
    final currentList = state.value ?? [];
    try {
      final updatedPage = await _repository.updatePage(
        id: id,
        title: title,
        categoryId: categoryId,
        displayOrder: displayOrder,
        active: active,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedPage : item;
      }).toList();
      updatedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Deletes a page.
  Future<void> deletePage(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deletePage(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Toggles page activation.
  Future<void> togglePageActivation(String id, bool active) async {
    final currentList = state.value ?? [];
    final originalPage = currentList.firstWhere((p) => p.id == id);

    // Optimistic UI update
    final optimisticList = currentList.map((item) {
      return item.id == id ? item.copyWith(active: active) : item;
    }).toList();
    state = AsyncValue.data(optimisticList);

    try {
      final updatedPage = await _repository.updatePage(
        id: id,
        title: originalPage.title,
        categoryId: originalPage.categoryId,
        displayOrder: originalPage.displayOrder,
        active: active,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedPage : item;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Revert if API fails
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

/// Provider for [TimetreePagesNotifier] managing all pages.
final timetreePagesProvider =
    StateNotifierProvider.autoDispose<TimetreePagesNotifier, AsyncValue<List<TimetreePage>>>((ref) {
  final repo = ref.watch(timetreePagesRepositoryProvider);
  return TimetreePagesNotifier(repo);
});

/// Search filter query provider.
final timetreePageSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Category filtering selection provider (null value means "All categories").
final timetreePageCategoryFilterProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Filtered pages provider.
final filteredTimetreePagesProvider = Provider.autoDispose<AsyncValue<List<TimetreePage>>>((ref) {
  final pagesAsync = ref.watch(timetreePagesProvider);
  final searchQuery = ref.watch(timetreePageSearchQueryProvider).trim().toLowerCase();
  final selectedCategoryId = ref.watch(timetreePageCategoryFilterProvider);

  return pagesAsync.whenData((list) {
    var filtered = list;

    // Apply search query filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => p.title.toLowerCase().contains(searchQuery)).toList();
    }

    // Apply category id filter
    if (selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    return filtered;
  });
});
