import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_notification_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';

class TimetreeNotificationsRepository {
  final TimetreeApi _api;
  TimetreeNotificationsRepository(this._api);

  Future<List<TimetreeNotification>> getNotifications() async {
    try {
      final response = await _api.getNotifications();
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeNotificationDto.fromJson)
            .map(TimetreeNotification.fromDto)
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'getNotifications failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.markNotificationRead(id);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'markRead failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'markAllRead failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<String> resolveEventId(String type, String id) async {
    try {
      final response = await _api.resolveEventId(type, id);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['eventId'] ?? '').toString();
      }
      throw Exception('Format de réponse invalide');
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'resolveEventId failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final timetreeNotificationsRepositoryProvider = Provider<TimetreeNotificationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeNotificationsRepository(TimetreeApi(dio));
});
