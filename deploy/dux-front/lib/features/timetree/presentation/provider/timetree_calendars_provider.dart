import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';

/// StateNotifier for managing the list of TimeTree Calendars.
class TimetreeCalendarsNotifier extends StateNotifier<AsyncValue<List<TimetreeCalendar>>> {
  final TimetreeCalendarsRepository _repository;

  TimetreeCalendarsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCalendars();
  }

  /// Fetches the calendars list.
  Future<void> loadCalendars() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getCalendars();
      // Sort alphabetically by name
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Creates a new calendar.
  Future<void> createCalendar({
    required String name,
    required String description,
    required String color,
    String? attachedDocuments,
  }) async {
    final currentList = state.value ?? [];
    try {
      final newCalendar = await _repository.createCalendar(
        name: name,
        description: description,
        color: color,
        attachedDocuments: attachedDocuments,
      );
      final updatedList = List<TimetreeCalendar>.from(currentList)..add(newCalendar);
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.data(currentList);
      }
      rethrow;
    }
  }

  /// Updates an existing calendar.
  Future<void> updateCalendar({
    required String id,
    required String name,
    required String description,
    required String color,
    String? attachedDocuments,
  }) async {
    final currentList = state.value ?? [];
    try {
      final updatedCalendar = await _repository.updateCalendar(
        id: id,
        name: name,
        description: description,
        color: color,
        attachedDocuments: attachedDocuments,
      );
      final updatedList = currentList.map((item) {
        return item.id == id ? updatedCalendar : item;
      }).toList();
      updatedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (mounted) {
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.data(currentList);
      }
      rethrow;
    }
  }

  /// Deletes a calendar.
  Future<void> deleteCalendar(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.deleteCalendar(id);
      final updatedList = currentList.where((item) => item.id != id).toList();
      if (mounted) {
        state = AsyncValue.data(updatedList);
      }
    } catch (e) {
      if (mounted) {
        state = AsyncValue.data(currentList);
      }
      rethrow;
    }
  }
}

/// Provider for [TimetreeCalendarsNotifier].
final timetreeCalendarsProvider =
    StateNotifierProvider.autoDispose<TimetreeCalendarsNotifier, AsyncValue<List<TimetreeCalendar>>>((ref) {
  final repo = ref.watch(timetreeCalendarsRepositoryProvider);
  return TimetreeCalendarsNotifier(repo);
});

/// Holds the search filter query for Calendars.
final timetreeCalendarSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider that exposes a filtered list of calendars based on search query.
final filteredTimetreeCalendarsProvider = Provider.autoDispose<AsyncValue<List<TimetreeCalendar>>>((ref) {
  final calendarsAsync = ref.watch(timetreeCalendarsProvider);
  final searchQuery = ref.watch(timetreeCalendarSearchQueryProvider).trim().toLowerCase();

  return calendarsAsync.whenData((list) {
    if (searchQuery.isEmpty) return list;
    return list
        .where((c) =>
            c.name.toLowerCase().contains(searchQuery) ||
            c.description.toLowerCase().contains(searchQuery))
        .toList();
  });
});
