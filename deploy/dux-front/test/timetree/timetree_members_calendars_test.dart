import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dux_front/core/services/storage_service.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_events_provider.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_member_dto.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_calendar_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_member.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_members_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_members_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_menu_provider.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_menu_item.dart';
import 'package:dux_front/features/timetree/presentation/screens/membership_calendars_screen.dart';
import 'package:dux_front/features/timetree/presentation/screens/timetree_calendar_view_screen.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/auth/domain/models/user.dart';
import 'package:dux_front/features/auth/domain/usecases/login_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/logout_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/check_session_use_case.dart';

Widget buildTestHarness(Widget widget, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  group('TimetreeMemberDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 'm-1',
        'username': 'chef_john',
        'fullName': 'John Doe',
        'email': 'john@chef.com',
        'role': 'CHEF',
      };
      final dto = TimetreeMemberDto.fromJson(json);
      expect(dto.id, 'm-1');
      expect(dto.username, 'chef_john');
      expect(dto.fullName, 'John Doe');
      expect(dto.email, 'john@chef.com');
      expect(dto.role, 'CHEF');
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeMemberDto.fromJson({});
      expect(dto.id, '');
      expect(dto.username, '');
      expect(dto.fullName, '');
      expect(dto.email, '');
      expect(dto.role, '');
    });

    test('serializes correctly to json', () {
      const dto = TimetreeMemberDto(
        id: 'm-2',
        username: 'admin_mary',
        fullName: 'Mary Smith',
        email: 'mary@admin.com',
        role: 'ADMIN',
      );
      final json = dto.toJson();
      expect(json['id'], 'm-2');
      expect(json['username'], 'admin_mary');
      expect(json['fullName'], 'Mary Smith');
      expect(json['email'], 'mary@admin.com');
      expect(json['role'], 'ADMIN');
    });
  });

  group('TimetreeCalendarDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 'c-1',
        'name': 'Cuisine Italienne',
        'description': 'Plats et recettes',
        'color': '#4CAF50',
      };
      final dto = TimetreeCalendarDto.fromJson(json);
      expect(dto.id, 'c-1');
      expect(dto.name, 'Cuisine Italienne');
      expect(dto.description, 'Plats et recettes');
      expect(dto.color, '#4CAF50');
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeCalendarDto.fromJson({});
      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.description, '');
      expect(dto.color, '');
    });
  });

  group('Domain Model Mapping Tests', () {
    test('Member DTO map to Domain Model', () {
      const dto = TimetreeMemberDto(
        id: '1',
        username: 'usr',
        fullName: 'Full Name',
        email: 'usr@test.com',
        role: 'MEMBER',
      );
      final member = TimetreeMember.fromDto(dto);
      expect(member.id, '1');
      expect(member.username, 'usr');
      expect(member.fullName, 'Full Name');
      expect(member.email, 'usr@test.com');
      expect(member.role, 'MEMBER');
    });

    test('Calendar DTO map to Domain Model', () {
      const dto = TimetreeCalendarDto(
        id: '2',
        name: 'My Calendar',
        description: 'Testing cal',
        color: '#FF0000',
        members: [],
      );
      final cal = TimetreeCalendar.fromDto(dto);
      expect(cal.id, '2');
      expect(cal.name, 'My Calendar');
      expect(cal.description, 'Testing cal');
      expect(cal.color, '#FF0000');
    });
  });

  group('Search Filter Query Providers Tests', () {
    test('members list filtering works', () {
      final container = ProviderContainer(
        overrides: [
          timetreeMembersProvider.overrideWith(
            (ref) => _FakeMembersNotifier(
              AsyncValue.data([
                const TimetreeMember(
                  id: '1',
                  username: 'john',
                  fullName: 'John Doe',
                  email: 'john@gmail.com',
                  role: 'CHEF',
                ),
                const TimetreeMember(
                  id: '2',
                  username: 'alex',
                  fullName: 'Alex Page',
                  email: 'alex@gmail.com',
                  role: 'MEMBER',
                ),
              ]),
            ),
          )
        ],
      );

      expect(container.read(filteredTimetreeMembersProvider).value, hasLength(2));

      container.read(timetreeMemberSearchQueryProvider.notifier).state = 'alex';
      expect(container.read(filteredTimetreeMembersProvider).value, hasLength(1));
      expect(container.read(filteredTimetreeMembersProvider).value!.first.fullName, 'Alex Page');
    });

    test('calendars list filtering works', () {
      final container = ProviderContainer(
        overrides: [
          timetreeCalendarsProvider.overrideWith(
            (ref) => _FakeCalendarsNotifier(
              AsyncValue.data([
                const TimetreeCalendar(id: '1', name: 'Plats Chauds', description: 'Cuisine', color: '#FFF', members: []),
                const TimetreeCalendar(id: '2', name: 'Salades', description: 'Frais', color: '#000', members: []),
              ]),
            ),
          )
        ],
      );

      expect(container.read(filteredTimetreeCalendarsProvider).value, hasLength(2));

      container.read(timetreeCalendarSearchQueryProvider.notifier).state = 'salades';
      expect(container.read(filteredTimetreeCalendarsProvider).value, hasLength(1));
      expect(container.read(filteredTimetreeCalendarsProvider).value!.first.name, 'Salades');
    });
  });

  group('TimetreeMembershipCalendarsScreen Widget Tests', () {
    testWidgets('renders loading state for members and calendars', (tester) async {
      final membersOverride = timetreeMembersProvider.overrideWith(
        (ref) => _FakeMembersNotifier(const AsyncValue.loading()),
      );
      final calendarsOverride = timetreeCalendarsProvider.overrideWith(
        (ref) => _FakeCalendarsNotifier(const AsyncValue.loading()),
      );
      final menuOverride = timetreeMenuProvider.overrideWith(
        (ref) => <TimetreeMenuItem>[],
      );
      final authOverride = authControllerProvider.overrideWith(
        (ref) => _FakeAuthController(
          const AuthState(
            user: User(
              id: 'admin-1',
              username: 'admin',
              fullName: 'Admin User',
              email: 'admin@test.com',
              role: 'ADMIN',
              station: 'Station 1',
              phone: '12345678',
              tierId: '1',
            ),
            isChecking: false,
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestHarness(
          const TimetreeMembershipCalendarsScreen(),
          [membersOverride, calendarsOverride, menuOverride, authOverride],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('non-admin sees restricted access warning in Members tab', (tester) async {
      final membersOverride = timetreeMembersProvider.overrideWith(
        (ref) => _FakeMembersNotifier(const AsyncValue.data([])),
      );
      final calendarsOverride = timetreeCalendarsProvider.overrideWith(
        (ref) => _FakeCalendarsNotifier(const AsyncValue.data([])),
      );
      final menuOverride = timetreeMenuProvider.overrideWith(
        (ref) => <TimetreeMenuItem>[],
      );
      final authOverride = authControllerProvider.overrideWith(
        (ref) => _FakeAuthController(
          const AuthState(
            user: User(
              id: 'member-1',
              username: 'memberjohn',
              fullName: 'John Member',
              email: 'member@test.com',
              role: 'MEMBER',
              station: 'Station 1',
              phone: '123',
              tierId: '1',
            ),
            isChecking: false,
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestHarness(
          const TimetreeMembershipCalendarsScreen(),
          [membersOverride, calendarsOverride, menuOverride, authOverride],
        ),
      );

      await tester.pumpAndSettle();

      // Non-admin Chef gets redirected/restricted in Members and Calendars tabs
      expect(find.text('Accès Restreint'), findsAtLeast(1));
    });
  });

  group('TimetreeCalendarViewScreen Widget Tests', () {
    testWidgets('renders monthly grid and sidebar controls', (tester) async {
      // Set test screen size to wide to avoid ExpansionTile collapsing
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authOverride = authControllerProvider.overrideWith(
        (ref) => _FakeAuthController(
          const AuthState(
            user: User(
              id: 'm-1',
              username: 'member_1',
              fullName: 'Member One',
              email: 'member1@test.com',
              role: 'MEMBER',
              station: 'Station 1',
              phone: '123',
              tierId: '1',
            ),
            isChecking: false,
          ),
        ),
      );

      final calendarsOverride = timetreeCalendarsProvider.overrideWith(
        (ref) => _FakeCalendarsNotifier(
          AsyncValue.data([
            const TimetreeCalendar(
              id: 'cal-1',
              name: 'Calendar A',
              description: 'Description',
              color: '#4CAF50',
              members: [
                TimetreeMember(
                  id: 'm1',
                  username: 'member_1',
                  fullName: 'Member One',
                  email: 'member1@test.com',
                  role: 'MEMBER',
                ),
              ],
            ),
          ]),
        ),
      );
      final menuOverride = timetreeMenuProvider.overrideWith(
        (ref) => <TimetreeMenuItem>[],
      );

      await tester.pumpWidget(
        buildTestHarness(
          const TimetreeCalendarViewScreen(),
          [
            authOverride,
            calendarsOverride,
            menuOverride,
            storageServiceProvider.overrideWithValue(FakeStorageService()),
            expandedEventsProvider.overrideWith((ref) => const AsyncValue.data([])),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Check month header contains June 2026
      expect(find.text('Juin 2026'), findsOneWidget);

      // Check sidebar displays calendar filter
      expect(find.textContaining('Calendar A'), findsAtLeast(1));
    });
  });
}

// ─── FAKE NOTIFIERS & REPOSITORIES FOR TESTING ───────────────────────────────

class _FakeMembersNotifier extends TimetreeMembersNotifier {
  _FakeMembersNotifier(AsyncValue<List<TimetreeMember>> initialValue)
      : super(_FakeMembersRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadMembers() async {}
}

class _FakeMembersRepo extends TimetreeMembersRepository {
  _FakeMembersRepo() : super(TimetreeApi(Dio()));
}

class _FakeCalendarsNotifier extends TimetreeCalendarsNotifier {
  _FakeCalendarsNotifier(AsyncValue<List<TimetreeCalendar>> initialValue)
      : super(_FakeCalendarsRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadCalendars() async {}
}

class _FakeCalendarsRepo extends TimetreeCalendarsRepository {
  _FakeCalendarsRepo() : super(TimetreeApi(Dio()));
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
