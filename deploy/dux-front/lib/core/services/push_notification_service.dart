import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_notifications_repository.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PushNotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  PushNotificationService(this._ref);

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      // 1. Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.w('PushNotification', 'User declined or has not accepted push permissions');
        return;
      }

      // 2. Initialize Android notification channels
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(initializationSettings);

      // Create high-importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'dux_channel_id', // id
        'Dux Notifications', // name
        description: 'This channel is used for important Dux notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Configure foreground presentation options (for iOS)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.i('PushNotification', 'Received foreground message: ${message.messageId}');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // 5. Background / Terminated state click listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.i('PushNotification', 'User clicked on notification that opened the app: ${message.data}');
        // Handle deep linking or routing here if needed
      });

      _initialized = true;
      AppLogger.i('PushNotification', 'Push Notification Service initialized successfully');
      
      // Eagerly try to register device token if user is already logged in
      await registerDevice();
    } catch (e) {
      AppLogger.e('PushNotification', 'Failed to initialize push notifications', e);
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      AppLogger.e('PushNotification', 'Failed to get device registration token', e);
      return null;
    }
  }

  Future<void> registerDevice() async {
    try {
      final token = await getDeviceToken();
      if (token == null) {
        AppLogger.w('PushNotification', 'Cannot register device: token is null');
        return;
      }

      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      AppLogger.i('PushNotification', 'Registering device token on backend: $token');
      await _ref.read(timetreeNotificationsRepositoryProvider).registerDeviceToken(token, platform);
      AppLogger.i('PushNotification', 'Device token registered successfully');
    } catch (e) {
      AppLogger.e('PushNotification', 'Failed to register device token on backend', e);
    }
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime reminderTime,
    required int index,
  }) async {
    if (reminderTime.isBefore(DateTime.now())) return;

    try {
      final localLocation = tz.local;
      final tzTime = tz.TZDateTime.from(reminderTime, localLocation);

      await _localNotifications.zonedSchedule(
        eventId.hashCode + index,
        'Rappel : $title',
        'Votre événement commence bientôt.',
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dux_reminders_channel',
            'Rappels Événements',
            channelDescription: 'Notification de rappels des événements Dux',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      AppLogger.d('PushNotification', 'Reminder scheduled for $eventId at $reminderTime');
    } catch (e) {
      AppLogger.e('PushNotification', 'Failed to schedule event reminder', e);
    }
  }

  Future<void> cancelEventReminders(String eventId, int reminderCount) async {
    for (int i = 0; i < reminderCount + 5; i++) {
      try {
        await _localNotifications.cancel(eventId.hashCode + i);
      } catch (e) {
        // Ignore
      }
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
