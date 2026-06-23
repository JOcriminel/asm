import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';

/// State notifier for managing the list of Custom Fields.
class TimetreeCustomFieldsNotifier extends StateNotifier<AsyncValue<List<TimetreeCustomField>>> {
  final TimetreeCustomFieldsRepository _repository;
  String? _scopeType;
  String? _scopeId;

  TimetreeCustomFieldsNotifier(this._repository) : super(const AsyncValue.loading());

  /// Sets the scope and loads the custom fields
  Future<void> loadFields({String? scopeType, String? scopeId}) async {
    _scopeType = scopeType;
    _scopeId = scopeId;
    state = const AsyncValue.loading();
    try {
      final fields = await _repository.getCustomFields(scopeType: _scopeType, scopeId: _scopeId);
      state = AsyncValue.data(fields);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refreshes the fields list
  Future<void> refresh() async {
    try {
      final fields = await _repository.getCustomFields(scopeType: _scopeType, scopeId: _scopeId);
      state = AsyncValue.data(fields);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates a new custom field definition
  Future<void> createField(TimetreeCustomField field) async {
    try {
      final newField = await _repository.createCustomField(field);
      state.whenData((currentList) {
        state = AsyncValue.data([...currentList, newField]);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing custom field definition
  Future<void> updateField(TimetreeCustomField field) async {
    try {
      final updated = await _repository.updateCustomField(field);
      state.whenData((currentList) {
        state = AsyncValue.data(
          currentList.map((f) => f.id == updated.id ? updated : f).toList(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a custom field definition
  Future<void> deleteField(String id) async {
    try {
      await _repository.deleteCustomField(id);
      state.whenData((currentList) {
        state = AsyncValue.data(
          currentList.where((f) => f.id != id).toList(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Locally reorders fields for instant feedback, then persists to the backend
  Future<void> reorderFields(int oldIndex, int newIndex) async {
    state.whenData((currentList) async {
      final mutableList = List<TimetreeCustomField>.from(currentList);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = mutableList.removeAt(oldIndex);
      mutableList.insert(newIndex, item);
      
      // Update sortOrder values locally
      final updatedList = mutableList.asMap().entries.map((entry) {
        return entry.value.copyWith(sortOrder: entry.key + 1);
      }).toList();

      // Show immediate local change
      state = AsyncValue.data(updatedList);

      try {
        await _repository.reorderCustomFields(updatedList);
      } catch (e, stack) {
        // Rollback to original order on backend error
        state = AsyncValue.error(e, stack);
        refresh();
      }
    });
  }
}

/// Provider for [TimetreeCustomFieldsNotifier] managing all Custom Fields.
final timetreeCustomFieldsProvider =
    StateNotifierProvider<TimetreeCustomFieldsNotifier, AsyncValue<List<TimetreeCustomField>>>((ref) {
  final repo = ref.watch(timetreeCustomFieldsRepositoryProvider);
  final notifier = TimetreeCustomFieldsNotifier(repo);
  // Default to load all fields on creation
  notifier.loadFields();
  return notifier;
});

/// State provider for search query
final timetreeCustomFieldSearchQueryProvider = StateProvider<String>((ref) => '');

/// State provider for filtering fields list
final filteredTimetreeCustomFieldsProvider = Provider<AsyncValue<List<TimetreeCustomField>>>((ref) {
  final fieldsAsync = ref.watch(timetreeCustomFieldsProvider);
  final query = ref.watch(timetreeCustomFieldSearchQueryProvider).toLowerCase();

  return fieldsAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((f) {
      return f.name.toLowerCase().contains(query) ||
          f.label.toLowerCase().contains(query) ||
          f.fieldType.toLowerCase().contains(query);
    }).toList();
  });
});
