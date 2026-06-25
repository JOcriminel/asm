import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_notifications_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_websocket_service.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';

// ─── Notifications state ─────────────────────────────────────────────────────

class TimetreeNotificationsNotifier
    extends StateNotifier<AsyncValue<List<TimetreeNotification>>> {
  final TimetreeNotificationsRepository _repository;
  final TimetreeWebSocketService _wsService;
  StreamSubscription<int>? _unreadCountSub;

  TimetreeNotificationsNotifier(this._repository, this._wsService)
      : super(const AsyncValue.loading()) {
    loadNotifications();
    _listenToWebSocketUnreadCounts();
  }

  void _listenToWebSocketUnreadCounts() {
    // When the backend pushes a new UNREAD_COUNT, reload the notification list
    // so the unread badges stay in sync without the client needing to calculate counts.
    _unreadCountSub = _wsService.unreadCountStream.listen((_) {
      // A count update means something changed; refresh the list.
      loadNotifications();
    });
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      // Load first page eagerly — app bar badge uses this.
      final page = await _repository.getNotifications(page: 0, size: 50);
      state = AsyncValue.data(page.notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.markRead(id);
      // Optimistically update local state; server will push UNREAD_COUNT to confirm.
      state = AsyncValue.data(
        currentList
            .map((n) => n.id == id
                ? TimetreeNotification(
                    id: n.id,
                    recipientId: n.recipientId,
                    title: n.title,
                    content: n.content,
                    type: n.type,
                    entityType: n.entityType,
                    entityId: n.entityId,
                    actionType: n.actionType,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final currentList = state.value ?? [];
    try {
      await _repository.markAllRead();
      state = AsyncValue.data(
        currentList
            .map((n) => TimetreeNotification(
                  id: n.id,
                  recipientId: n.recipientId,
                  title: n.title,
                  content: n.content,
                  type: n.type,
                  entityType: n.entityType,
                  entityId: n.entityId,
                  actionType: n.actionType,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((n) => n.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }

  Future<String> resolveEventId(String type, String id) async {
    return _repository.resolveEventId(type, id);
  }

  @override
  void dispose() {
    _unreadCountSub?.cancel();
    super.dispose();
  }
}

final timetreeNotificationsProvider = StateNotifierProvider.autoDispose<
    TimetreeNotificationsNotifier, AsyncValue<List<TimetreeNotification>>>((ref) {
  final repository = ref.watch(timetreeNotificationsRepositoryProvider);
  final wsService = ref.watch(timetreeWebSocketServiceProvider);
  return TimetreeNotificationsNotifier(repository, wsService);
});

/// Derived provider: current unread count from the in-memory notification list.
/// This updates reactively whenever the list changes (driven by WebSocket pushes
/// via the notifier's _unreadCountSub listener).
final timetreeUnreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final asyncNotifs = ref.watch(timetreeNotificationsProvider);
  return asyncNotifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ─── Preferences state ───────────────────────────────────────────────────────

class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final TimetreeNotificationsRepository _repository;

  NotificationPreferencesNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repository.getPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(NotificationPreferences prefs) async {
    try {
      final saved = await _repository.updatePreferences(prefs);
      state = AsyncValue.data(saved);
    } catch (e) {
      rethrow;
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider.autoDispose<
    NotificationPreferencesNotifier, AsyncValue<NotificationPreferences>>((ref) {
  final repository = ref.watch(timetreeNotificationsRepositoryProvider);
  return NotificationPreferencesNotifier(repository);
});
