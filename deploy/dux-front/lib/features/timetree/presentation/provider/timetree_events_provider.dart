import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/services/storage_service.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_events_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/core/services/push_notification_service.dart';

/// Provider for the calendar view mode: MONTH, WEEK, or DAY.
final calendarViewModeProvider = StateProvider<String>((ref) => 'MONTH');

/// Provider for the currently focused date in the calendar.
final currentCalendarDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Notifier to persist selected calendar filters using [StorageService].
class SelectedCalendarFiltersNotifier extends StateNotifier<Set<String>> {
  final StorageService _storageService;
  static const _storageKey = 'timetree_selected_calendars';

  SelectedCalendarFiltersNotifier(this._storageService) : super({}) {
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final saved = await _storageService.read(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        state = saved.split(',').toSet();
      }
    } catch (_) {
      // Ignored
    }
  }

  Future<void> toggleCalendar(String id, bool selected) async {
    final newState = Set<String>.from(state);
    if (selected) {
      newState.add(id);
    } else {
      newState.remove(id);
    }
    state = newState;
    await _storageService.write(_storageKey, newState.join(','));
  }

  Future<void> setAll(Set<String> ids) async {
    state = ids;
    await _storageService.write(_storageKey, ids.join(','));
  }
}

/// Provider for the active calendar filters.
final selectedCalendarIdsProvider =
    StateNotifierProvider<SelectedCalendarFiltersNotifier, Set<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SelectedCalendarFiltersNotifier(storage);
});

class CalendarDateRange {
  final DateTime start;
  final DateTime end;
  CalendarDateRange(this.start, this.end);
}

/// Helper to resolve the dates range based on focused date and view mode.
CalendarDateRange getRangeForDate(DateTime date, String viewMode) {
  if (viewMode == 'MONTH' || viewMode == 'ANALYTICS') {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0);
    return CalendarDateRange(
      monthStart.subtract(const Duration(days: 7)),
      monthEnd.add(const Duration(days: 7)),
    );
  } else if (viewMode == 'WEEK') {
    final weekday = date.weekday;
    final weekStart = date.subtract(Duration(days: weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return CalendarDateRange(
      DateTime(weekStart.year, weekStart.month, weekStart.day, 0, 0, 0),
      DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    );
  } else {
    return CalendarDateRange(
      DateTime(date.year, date.month, date.day, 0, 0, 0),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }
}

/// StateNotifier for managing the loaded events list.
class TimetreeEventsNotifier extends StateNotifier<AsyncValue<List<TimetreeEvent>>> {
  final TimetreeEventsRepository _repository;
  final Ref _ref;
  bool _isDisposed = false;

  TimetreeEventsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    // Reload events automatically when filters or dates change.
    _ref.listen(selectedCalendarIdsProvider, (previous, next) {
      if (!_isDisposed) loadEvents();
    });
    _ref.listen(currentCalendarDateProvider, (previous, next) {
      if (!_isDisposed) loadEvents();
    });
    _ref.listen(calendarViewModeProvider, (previous, next) {
      if (!_isDisposed) loadEvents();
    });

    loadEvents();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Fetches raw events from backend.
  Future<void> loadEvents({bool silent = false}) async {
    final selectedCalendarIds = _ref.read(selectedCalendarIdsProvider);
    final focusedDate = _ref.read(currentCalendarDateProvider);
    final viewMode = _ref.read(calendarViewModeProvider);

    if (selectedCalendarIds.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    if (!silent) {
      state = const AsyncValue.loading();
    }
    try {
      final range = getRangeForDate(focusedDate, viewMode);
      final list = await _repository.getEvents(
        calendarIds: selectedCalendarIds.toList(),
        start: range.start,
        end: range.end,
      );
      if (!_isDisposed) {
        state = AsyncValue.data(list);
        _syncNotifications(list);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _syncNotifications(List<TimetreeEvent> events) async {
    final pushService = _ref.read(pushNotificationServiceProvider);
    for (final event in events) {
      await pushService.cancelEventReminders(event.id, event.reminders.length);
      for (int i = 0; i < event.reminders.length; i++) {
        await pushService.scheduleEventReminder(
          eventId: event.id,
          title: event.title,
          reminderTime: event.reminders[i],
          index: i,
        );
      }
    }
  }

  /// Creates a new event.
  Future<TimetreeEvent> createEvent(TimetreeEvent event) async {
    final currentList = state.value ?? [];
    try {
      final newEvent = await _repository.createEvent(event);
      state = AsyncValue.data(List<TimetreeEvent>.from(currentList)..add(newEvent));
      await loadEvents(silent: true);
      return newEvent;
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Updates an existing event details.
  Future<void> updateEvent(String id, TimetreeEvent event) async {
    final currentList = state.value ?? [];
    try {
      final baseId = id.split('_rec_').first;
      final updatedEvent = await _repository.updateEvent(baseId, event);
      state = AsyncValue.data(currentList.map((item) {
        final itemBaseId = item.id.split('_rec_').first;
        return itemBaseId == baseId ? updatedEvent : item;
      }).toList());
      await loadEvents(silent: true);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Deletes an event.
  Future<void> deleteEvent(String id) async {
    final currentList = state.value ?? [];
    try {
      final baseId = id.split('_rec_').first;
      
      try {
        final eventToDelete = currentList.firstWhere((e) => e.id.split('_rec_').first == baseId);
        await _ref.read(pushNotificationServiceProvider).cancelEventReminders(eventToDelete.id, eventToDelete.reminders.length);
      } catch (_) {}

      await _repository.deleteEvent(baseId);
      state = AsyncValue.data(currentList.where((item) {
        final itemBaseId = item.id.split('_rec_').first;
        return itemBaseId != baseId;
      }).toList());
      await loadEvents(silent: true);
    } catch (e) {
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Reschedule an event with optimistic updates (for drag and drop).
  Future<void> rescheduleEvent(String eventId, DateTime newStart, DateTime newEnd) async {
    final currentList = state.value ?? [];
    final baseId = eventId.split('_rec_').first;

    final index = currentList.indexWhere((e) => e.id.split('_rec_').first == baseId);
    if (index == -1) return;

    final originalEvent = currentList[index];
    final updatedEventOptimistic = originalEvent.copyWith(
      startDate: newStart,
      endDate: newEnd,
    );

    // Optimistic update
    state = AsyncValue.data(currentList.map((item) {
      return item.id.split('_rec_').first == baseId ? updatedEventOptimistic : item;
    }).toList());

    try {
      final updatedEvent = await _repository.updateEvent(baseId, updatedEventOptimistic);
      state = AsyncValue.data(currentList.map((item) {
        return item.id.split('_rec_').first == baseId ? updatedEvent : item;
      }).toList());
      await loadEvents(silent: true);
    } catch (e) {
      // Revert on failure
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  /// Adds a participant to an event.
  Future<void> addParticipant(String eventId, String memberId) async {
    final currentList = state.value ?? [];
    final baseId = eventId.split('_rec_').first;
    try {
      final updatedEvent = await _repository.addParticipant(baseId, memberId);
      state = AsyncValue.data(currentList.map((item) {
        final itemBaseId = item.id.split('_rec_').first;
        return itemBaseId == baseId ? updatedEvent : item;
      }).toList());
      await loadEvents(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Removes a participant from an event.
  Future<void> removeParticipant(String eventId, String memberId) async {
    final currentList = state.value ?? [];
    final baseId = eventId.split('_rec_').first;
    try {
      final updatedEvent = await _repository.removeParticipant(baseId, memberId);
      state = AsyncValue.data(currentList.map((item) {
        final itemBaseId = item.id.split('_rec_').first;
        return itemBaseId == baseId ? updatedEvent : item;
      }).toList());
      await loadEvents(silent: true);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for raw events fetched from backend.
final timetreeEventsProvider =
    StateNotifierProvider.autoDispose<TimetreeEventsNotifier, AsyncValue<List<TimetreeEvent>>>((ref) {
  final repo = ref.watch(timetreeEventsProviderProvider);
  return TimetreeEventsNotifier(repo, ref);
});

/// Provider for the repository itself.
final timetreeEventsProviderProvider = Provider<TimetreeEventsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeEventsRepository(TimetreeApi(dio));
});

/// Provider that returns the virtually expanded events for the active date range.
final expandedEventsProvider = Provider.autoDispose<AsyncValue<List<TimetreeEvent>>>((ref) {
  final eventsAsync = ref.watch(timetreeEventsProvider);
  final viewMode = ref.watch(calendarViewModeProvider);
  final focusedDate = ref.watch(currentCalendarDateProvider);

  final range = getRangeForDate(focusedDate, viewMode);

  return eventsAsync.whenData((rawEvents) {
    final List<TimetreeEvent> expanded = [];
    for (final event in rawEvents) {
      expanded.addAll(event.expandRecurrence(range.start, range.end));
    }
    return expanded;
  });
});

class CalendarFilterState {
  final String? participantSearch;
  final String? textSearch;
  final String? status;
  final Map<String, String> customFieldsSearch;

  CalendarFilterState({
    this.participantSearch,
    this.textSearch,
    this.status = 'ALL',
    this.customFieldsSearch = const {},
  });

  CalendarFilterState copyWith({
    String? participantSearch,
    String? textSearch,
    String? status,
    Map<String, String>? customFieldsSearch,
  }) {
    return CalendarFilterState(
      participantSearch: participantSearch ?? this.participantSearch,
      textSearch: textSearch ?? this.textSearch,
      status: status ?? this.status,
      customFieldsSearch: customFieldsSearch ?? this.customFieldsSearch,
    );
  }

  bool get isEmpty {
    return (participantSearch == null || participantSearch!.isEmpty) &&
        (textSearch == null || textSearch!.isEmpty) &&
        (status == null || status == 'ALL') &&
        customFieldsSearch.values.every((v) => v.isEmpty);
  }
}

final calendarFilterProvider = StateProvider<CalendarFilterState>((ref) => CalendarFilterState());

final filteredEventsProvider = Provider.autoDispose<AsyncValue<List<TimetreeEvent>>>((ref) {
  final expandedAsync = ref.watch(expandedEventsProvider);
  final filter = ref.watch(calendarFilterProvider);

  return expandedAsync.whenData((events) {
    if (filter.isEmpty) {
      return events;
    }

    return events.where((event) {
      // 1. Participant Filter
      if (filter.participantSearch != null && filter.participantSearch!.isNotEmpty) {
        final query = filter.participantSearch!.toLowerCase();
        final matchesParticipant = event.participants.any((p) =>
            p.fullName.toLowerCase().contains(query) ||
            p.username.toLowerCase().contains(query) ||
            p.email.toLowerCase().contains(query) ||
            p.id.toLowerCase().contains(query));
        if (!matchesParticipant) return false;
      }

      // 2. Text Search (title / description)
      if (filter.textSearch != null && filter.textSearch!.isNotEmpty) {
        final query = filter.textSearch!.toLowerCase();
        final matchesText = event.title.toLowerCase().contains(query) ||
            (event.description?.toLowerCase().contains(query) ?? false);
        if (!matchesText) return false;
      }

      // 3. Status filter
      if (filter.status != null && filter.status != 'ALL') {
        if (event.status.toUpperCase() != filter.status!.toUpperCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
