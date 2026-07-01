import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_notification_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';

/// Data class for user notification preferences.
class NotificationPreferences {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool mentionsEnabled;
  final bool remindersEnabled;
  final bool chatEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime? snoozeUntil;
  final bool muteAllExceptSpecific;
  final bool notifyOwnActions;

  const NotificationPreferences({
    this.emailEnabled = false,
    this.pushEnabled = true,
    this.mentionsEnabled = true,
    this.remindersEnabled = true,
    this.chatEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.snoozeUntil,
    this.muteAllExceptSpecific = false,
    this.notifyOwnActions = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      mentionsEnabled: json['mentionsEnabled'] as bool? ?? true,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
      chatEnabled: json['chatEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      snoozeUntil: json['snoozeUntil'] != null ? DateTime.parse(json['snoozeUntil'] as String) : null,
      muteAllExceptSpecific: json['muteAllExceptSpecific'] as bool? ?? false,
      notifyOwnActions: json['notifyOwnActions'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'emailEnabled': emailEnabled,
        'pushEnabled': pushEnabled,
        'mentionsEnabled': mentionsEnabled,
        'remindersEnabled': remindersEnabled,
        'chatEnabled': chatEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'snoozeUntil': snoozeUntil?.toIso8601String(),
        'muteAllExceptSpecific': muteAllExceptSpecific,
        'notifyOwnActions': notifyOwnActions,
      };

  NotificationPreferences copyWith({
    bool? emailEnabled,
    bool? pushEnabled,
    bool? mentionsEnabled,
    bool? remindersEnabled,
    bool? chatEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    DateTime? snoozeUntil,
    bool resetSnooze = false,
    bool? muteAllExceptSpecific,
    bool? notifyOwnActions,
  }) {
    return NotificationPreferences(
      emailEnabled: emailEnabled ?? this.emailEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      mentionsEnabled: mentionsEnabled ?? this.mentionsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeUntil: resetSnooze ? null : (snoozeUntil ?? this.snoozeUntil),
      muteAllExceptSpecific: muteAllExceptSpecific ?? this.muteAllExceptSpecific,
      notifyOwnActions: notifyOwnActions ?? this.notifyOwnActions,
    );
  }
}

/// Paginated result wrapper for notification history.
class NotificationPage {
  final List<TimetreeNotification> notifications;
  final int totalElements;
  final int totalPages;
  final bool hasMore;
  final int page;
  final int size;

  const NotificationPage({
    required this.notifications,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
    required this.page,
    required this.size,
  });
}

/// Paginated result wrapper for activity timeline.
class ActivityPage {
  final List<Map<String, dynamic>> activity;
  final int totalElements;
  final int totalPages;
  final bool hasMore;
  final int page;
  final int size;

  const ActivityPage({
    required this.activity,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
    required this.page,
    required this.size,
  });
}

class TimetreeNotificationsRepository {
  final TimetreeApi _api;
  TimetreeNotificationsRepository(this._api);

  // ─── Notification History ─────────────────────────────────────────────────

  Future<NotificationPage> getNotifications({int page = 0, int size = 20}) async {
    try {
      final response = await _api.getNotifications(page: page, size: size);
      final data = response.data as Map<String, dynamic>;
      final rawList = data['notifications'] as List? ?? [];

      final notifications = rawList
          .whereType<Map<String, dynamic>>()
          .map(TimetreeNotificationDto.fromJson)
          .map(TimetreeNotification.fromDto)
          .toList();

      return NotificationPage(
        notifications: notifications,
        totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        hasMore: data['hasMore'] as bool? ?? false,
        page: page,
        size: size,
      );
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'getNotifications failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<List<TimetreeNotification>> getAllNotifications() async {
    final firstPage = await getNotifications(page: 0, size: 50);
    return firstPage.notifications;
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

  Future<void> deleteNotification(String id) async {
    try {
      await _api.deleteNotification(id);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'deleteNotification failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  // ─── Preferences ──────────────────────────────────────────────────────────

  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _api.getNotificationPreferences();
      return NotificationPreferences.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'getPreferences failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs) async {
    try {
      final response = await _api.updateNotificationPreferences(prefs.toJson());
      return NotificationPreferences.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'updatePreferences failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  // ─── Activity Timeline ────────────────────────────────────────────────────

  Future<ActivityPage> getCalendarActivity(
    String calendarId, {
    int page = 0,
    int size = 20,
    String? action,
  }) async {
    try {
      final response = await _api.getCalendarActivity(
        calendarId,
        page: page,
        size: size,
        action: action,
      );
      final data = response.data as Map<String, dynamic>;
      final rawList = data['activity'] as List? ?? [];
      final activity = rawList.whereType<Map<String, dynamic>>().toList();

      return ActivityPage(
        activity: activity,
        totalElements: (data['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        hasMore: data['hasMore'] as bool? ?? false,
        page: page,
        size: size,
      );
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'getCalendarActivity failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  // ─── Misc ─────────────────────────────────────────────────────────────────

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

  Future<void> registerDeviceToken(String deviceToken, String platform) async {
    try {
      await _api.registerDevice(deviceToken, platform);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'registerDeviceToken failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<void> sendAnnouncement(String title, String content, List<String> calendarIds) async {
    try {
      await _api.sendAnnouncement(title, content, calendarIds);
    } catch (e) {
      AppLogger.e('TimetreeNotificationsRepository', 'sendAnnouncement failed', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final timetreeNotificationsRepositoryProvider = Provider<TimetreeNotificationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeNotificationsRepository(TimetreeApi(dio));
});
