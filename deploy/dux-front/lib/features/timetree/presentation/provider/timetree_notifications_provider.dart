import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_notifications_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';

class TimetreeNotificationsNotifier extends StateNotifier<AsyncValue<List<TimetreeNotification>>> {
  final TimetreeNotificationsRepository _repository;

  TimetreeNotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    final currentList = state.value ?? [];
    try {
      await _repository.markRead(id);
      state = AsyncValue.data(
        currentList.map((n) => n.id == id ? TimetreeNotification(
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
        ) : n).toList(),
      );
    } catch (e) {
      // Keep existing list on failure
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final currentList = state.value ?? [];
    try {
      await _repository.markAllRead();
      state = AsyncValue.data(
        currentList.map((n) => TimetreeNotification(
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
        )).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> resolveEventId(String type, String id) async {
    return _repository.resolveEventId(type, id);
  }
}

final timetreeNotificationsProvider = StateNotifierProvider.autoDispose<
    TimetreeNotificationsNotifier, AsyncValue<List<TimetreeNotification>>>((ref) {
  final repository = ref.watch(timetreeNotificationsRepositoryProvider);
  return TimetreeNotificationsNotifier(repository);
});

final timetreeUnreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final asyncNotifs = ref.watch(timetreeNotificationsProvider);
  return asyncNotifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
