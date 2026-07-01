import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_event.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_event_dto.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_calendar_view_screen.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/auth/domain/models/user.dart';
import 'package:dux_front/features/auth/domain/usecases/login_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/logout_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/check_session_use_case.dart';
import 'package:dux_front/core/services/storage_service.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_chat_service.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_notifications_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_notification.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_message.dart';

Widget buildEventsHarness(
  Widget widget,
  List<Override> overrides,
) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('fr', 'FR'),
      home: widget,
    ),
  );
}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  group('TimetreeEventDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 101,
        'title': 'Sprint Review',
        'description': 'Reviewing Sprint 8 output',
        'startDate': '2026-06-23T10:00:00.000',
        'endDate': '2026-06-23T11:00:00.000',
        'allDay': false,
        'color': '4280358912',
        'calendarId': 5,
        'groupId': 2,
        'recurrenceRule': 'NONE',
        'participants': [
          {
            'id': 1,
            'username': 'chef1',
            'fullName': 'Chef Cook',
            'email': 'chef@timetree.com',
            'role': 'CHEF',
          }
        ]
      };

      final dto = TimetreeEventDto.fromJson(json);
      expect(dto.id, '101');
      expect(dto.title, 'Sprint Review');
      expect(dto.startDate, DateTime(2026, 6, 23, 10, 0));
      expect(dto.endDate, DateTime(2026, 6, 23, 11, 0));
      expect(dto.allDay, false);
      expect(dto.calendarId, '5');
      expect(dto.groupId, '2');
      expect(dto.participants, hasLength(1));
      expect(dto.participants.first.fullName, 'Chef Cook');
    });

    test('parses nomEvent and titleModifiedDirectly from json', () {
      final json = {
        'id': 101,
        'title': 'Sprint Review',
        'nomEvent': 'Review Sprint',
        'titleModifiedDirectly': true,
        'startDate': '2026-06-23T10:00:00.000',
        'endDate': '2026-06-23T11:00:00.000',
        'calendarId': 5,
      };

      final dto = TimetreeEventDto.fromJson(json);
      expect(dto.nomEvent, 'Review Sprint');
      expect(dto.titleModifiedDirectly, true);
    });

    test('serializes correctly to json', () {
      final dto = TimetreeEventDto(
        id: '101',
        title: 'Daily Meeting',
        startDate: DateTime(2026, 6, 23, 9, 0),
        endDate: DateTime(2026, 6, 23, 9, 30),
        allDay: false,
        calendarId: '5',
        groupId: '2',
        recurrenceRule: 'DAILY',
        recurrenceEndDate: DateTime(2026, 6, 30),
        nomEvent: 'Daily Meeting',
        titleModifiedDirectly: false,
      );

      final json = dto.toJson();
      expect(json['id'], 101);
      expect(json['title'], 'Daily Meeting');
      expect(json['startDate'], DateTime(2026, 6, 23, 9, 0).toIso8601String());
      expect(json['recurrenceRule'], 'DAILY');
      expect(json['recurrenceEndDate'], DateTime(2026, 6, 30).toIso8601String());
      expect(json['nomEvent'], 'Daily Meeting');
      expect(json['titleModifiedDirectly'], false);
    });
  });


  group('TimetreeEvent Recurrence Expansion Tests', () {
    test('non-recurring event does not duplicate', () {
      final event = TimetreeEvent(
        id: 'evt-1',
        title: 'Single Event',
        startDate: DateTime(2026, 6, 23, 10, 0),
        endDate: DateTime(2026, 6, 23, 11, 0),
        allDay: false,
        calendarId: 'cal-1',
        recurrenceRule: 'NONE',
      );

      final rangeStart = DateTime(2026, 6, 1);
      final rangeEnd = DateTime(2026, 6, 30);
      final expanded = event.expandRecurrence(rangeStart, rangeEnd);

      expect(expanded, hasLength(1));
      expect(expanded.first.id, 'evt-1');
    });

    test('daily event expands every day within window', () {
      final event = TimetreeEvent(
        id: 'evt-1',
        title: 'Daily Sync',
        startDate: DateTime(2026, 6, 20, 9, 0),
        endDate: DateTime(2026, 6, 20, 9, 30),
        allDay: false,
        calendarId: 'cal-1',
        recurrenceRule: 'DAILY',
        recurrenceEndDate: DateTime(2026, 6, 25),
      );

      final rangeStart = DateTime(2026, 6, 20);
      final rangeEnd = DateTime(2026, 6, 26);
      final expanded = event.expandRecurrence(rangeStart, rangeEnd);

      // Should happen on June 20, 21, 22, 23, 24, 25 (6 occurrences)
      expect(expanded, hasLength(6));
      expect(expanded[0].startDate, DateTime(2026, 6, 20, 9, 0));
      expect(expanded[1].startDate, DateTime(2026, 6, 21, 9, 0));
      expect(expanded[5].startDate, DateTime(2026, 6, 25, 9, 0));
    });

    test('weekly event expands weekly', () {
      final event = TimetreeEvent(
        id: 'evt-1',
        title: 'Weekly Sync',
        startDate: DateTime(2026, 6, 22, 14, 0), // Mon
        endDate: DateTime(2026, 6, 22, 15, 0),
        allDay: false,
        calendarId: 'cal-1',
        recurrenceRule: 'WEEKLY',
        recurrenceEndDate: DateTime(2026, 7, 10),
      );

      final rangeStart = DateTime(2026, 6, 20);
      final rangeEnd = DateTime(2026, 7, 15);
      final expanded = event.expandRecurrence(rangeStart, rangeEnd);

      // Occurrences on: Jun 22, Jun 29, Jul 6 (3 occurrences)
      expect(expanded, hasLength(3));
      expect(expanded[0].startDate, DateTime(2026, 6, 22, 14, 0));
      expect(expanded[1].startDate, DateTime(2026, 6, 29, 14, 0));
      expect(expanded[2].startDate, DateTime(2026, 7, 6, 14, 0));
    });
  });

  group('TimetreeCalendarViewScreen UI & State Tests', () {
    final mockCalendars = [
      const TimetreeCalendar(
        id: 'cal-1',
        name: 'Cal A',
        description: 'Calendar A',
        color: '#2196F3',
        members: [
          TimetreeMember(id: '1', username: 'user_1', fullName: 'User One', email: 'u1@t.com', role: 'MEMBER'),
        ],
      ),
    ];

    final defaultOverrides = [
      storageServiceProvider.overrideWithValue(FakeStorageService()),
      authControllerProvider.overrideWith(
        (ref) => _FakeAuthController(
          const AuthState(
            user: User(
              id: 'm-1',
              username: 'user_1',
              fullName: 'User One',
              email: 'u1@t.com',
              role: 'MEMBER',
              station: 'Station 1',
              phone: '123',
              tierId: '1',
            ),
            isChecking: false,
          ),
        ),
      ),
      timetreeChatServiceProvider.overrideWithValue(_FakeChatService()),
      timetreeNotificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
    ];

    testWidgets('renders loading state correctly', (tester) async {
      final overrides = [
        ...defaultOverrides,
        timetreeCalendarsProvider.overrideWith((ref) => _FakeCalendarsNotifier(const AsyncValue.loading())),
      ];

      await tester.pumpWidget(buildEventsHarness(const TimetreeCalendarViewScreen(), overrides));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state correctly', (tester) async {
      final overrides = [
        ...defaultOverrides,
        timetreeCalendarsProvider.overrideWith((ref) => _FakeCalendarsNotifier(AsyncValue.error('API Error', StackTrace.empty))),
      ];

      await tester.pumpWidget(buildEventsHarness(const TimetreeCalendarViewScreen(), overrides));
      await tester.pump();

      expect(find.textContaining('Erreur de chargement: API Error'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('renders empty state when no calendars assigned', (tester) async {
      final overrides = [
        ...defaultOverrides,
        timetreeCalendarsProvider.overrideWith((ref) => _FakeCalendarsNotifier(const AsyncValue.data([]))),
      ];

      await tester.pumpWidget(buildEventsHarness(const TimetreeCalendarViewScreen(), overrides));
      await tester.pump();

      expect(find.text('Aucun calendrier affecté.'), findsOneWidget);
    });

    testWidgets('renders monthly calendar and events on success', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final events = [
        TimetreeEvent(
          id: 'evt-1',
          title: 'Daily Meeting',
          startDate: DateTime(2026, 6, 23, 9, 0),
          endDate: DateTime(2026, 6, 23, 9, 30),
          allDay: false,
          calendarId: 'cal-1',
          recurrenceRule: 'NONE',
          groupId: 'group-1',
        ),
      ];

      final overrides = [
        ...defaultOverrides,
        timetreeCalendarsProvider.overrideWith((ref) => _FakeCalendarsNotifier(AsyncValue.data(mockCalendars))),
        expandedEventsProvider.overrideWith((ref) => AsyncValue.data(events)),
        currentCalendarDateProvider.overrideWith((ref) => DateTime(2026, 6, 23)),
        calendarViewModeProvider.overrideWith((ref) => 'MONTH'),
      ];

      await tester.pumpWidget(buildEventsHarness(const TimetreeCalendarViewScreen(), overrides));
      await tester.pumpAndSettle();

      // Verify months text
      expect(find.textContaining('Juin 2026'), findsOneWidget);
      
      // Verify monthly grid headers
      expect(find.text('Lun'), findsOneWidget);
      expect(find.text('Dim'), findsOneWidget);

      // Verify event details chip rendered
      expect(find.text('Daily Meeting'), findsOneWidget);
    });

    testWidgets('switches views correctly between Month, Week, and Day', (tester) async {
      final overrides = [
        ...defaultOverrides,
        timetreeCalendarsProvider.overrideWith((ref) => _FakeCalendarsNotifier(AsyncValue.data(mockCalendars))),
        expandedEventsProvider.overrideWith((ref) => const AsyncValue.data([])),
        currentCalendarDateProvider.overrideWith((ref) => DateTime(2026, 6, 23)),
      ];

      await tester.pumpWidget(buildEventsHarness(const TimetreeCalendarViewScreen(), overrides));
      await tester.pump();

      // Open options popup menu
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Find view segmented buttons inside popup menu
      expect(find.text('Mois'), findsOneWidget);
      expect(find.text('Semaine'), findsOneWidget);
      expect(find.text('Jour'), findsOneWidget);
    });
  });
}

class FakeStorageService implements StorageService {
  final Map<String, String> _data = {};
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> delete(String key) async => _data.remove(key);
  @override
  Future<void> clear() async => _data.clear();
}

class _FakeCalendarsRepo extends TimetreeCalendarsRepository {
  _FakeCalendarsRepo() : super(TimetreeApi(Dio()));

  @override
  Future<List<TimetreeCalendar>> getCalendars() async => const [];
}

class _FakeCalendarsNotifier extends TimetreeCalendarsNotifier {
  _FakeCalendarsNotifier(AsyncValue<List<TimetreeCalendar>> initialValue)
      : super(_FakeCalendarsRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadCalendars() async {}
}

class _FakeLoginUseCase implements LoginUseCase {
  @override
  Future<User> call(String username, String password, {bool rememberMe = false}) async {
    throw UnimplementedError();
  }
}

class _FakeLogoutUseCase implements LogoutUseCase {
  @override
  Future<void> call() async {}
}

class _FakeCheckSessionUseCase implements CheckSessionUseCase {
  @override
  Future<User?> call() async => null;
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(AuthState stateVal)
      : super(
          _FakeLoginUseCase(),
          _FakeLogoutUseCase(),
          _FakeCheckSessionUseCase(),
        ) {
    state = stateVal;
  }

  @override
  Future<void> checkSession() async {}
}

class _FakeChatService implements IChatService {
  @override
  Future<TimetreeChatPage> getMessages(String eventId, {required int page, required int size}) async {
    return const TimetreeChatPage(messages: [], hasMore: false, page: 0, size: 20);
  }
  @override
  Future<TimetreeMessage> sendMessage(String eventId, String text, {String messageType = 'TEXT', String? metadata}) async {
    throw UnimplementedError();
  }
  @override
  Future<void> markRead(String eventId) async {}
  @override
  Future<Map<String, int>> getUnreadCounts() async => {};
}

class _FakeNotificationsRepository implements TimetreeNotificationsRepository {
  @override
  Future<NotificationPage> getNotifications({int page = 0, int size = 20}) async {
    return const NotificationPage(notifications: [], totalElements: 0, totalPages: 0, hasMore: false, page: 0, size: 20);
  }
  @override
  Future<List<TimetreeNotification>> getAllNotifications() async => [];
  @override
  Future<void> markRead(String id) async {}
  @override
  Future<void> markAllRead() async {}
  @override
  Future<void> deleteNotification(String id) async {}
  @override
  Future<NotificationPreferences> getPreferences() async => const NotificationPreferences();
  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs) async => prefs;
  @override
  Future<ActivityPage> getCalendarActivity(String calendarId, {int page = 0, int size = 20, String? action}) async {
    return const ActivityPage(activity: [], totalElements: 0, totalPages: 0, hasMore: false, page: 0, size: 20);
  }
  @override
  Future<String> resolveEventId(String type, String id) async => '';

  @override
  Future<void> registerDeviceToken(String deviceToken, String platform) async {}

  @override
  Future<void> sendAnnouncement(String title, String content, List<String> calendarIds) async {}
}
