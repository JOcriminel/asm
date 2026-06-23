import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_custom_field_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_custom_field.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_calendar.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_menu_item.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_custom_fields_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_groups_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_calendars_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_custom_fields_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_calendars_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_menu_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/custom_fields_screen.dart';
import 'package:dux_front/features/timetree/presentation/widgets/dynamic_event_form_renderer.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/auth/domain/models/user.dart';
import 'package:dux_front/features/auth/domain/usecases/login_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/logout_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/check_session_use_case.dart';

Widget buildCustomFieldsHarness(Widget widget, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('TimetreeCustomFieldDto & Value Parsing Tests', () {
    test('parses definition correctly from json', () {
      final json = {
        'id': 'cf-1',
        'name': 'phone_num',
        'label': 'Téléphone',
        'fieldType': 'PHONE',
        'required': true,
        'defaultValue': '+33123456789',
        'options': 'Option 1, Option 2',
        'scopeType': 'GROUP',
        'scopeId': '10',
        'sortOrder': 2,
        'active': true,
        'minValue': 0.0,
        'maxValue': 100.0,
        'minLength': 5,
        'maxLength': 15,
        'regexPattern': r'^\+?[0-9]{8,15}$',
        'hidden': false,
        'readOnly': false,
        'visibilityRule': 'otherField==val',
      };

      final dto = TimetreeCustomFieldDto.fromJson(json);
      expect(dto.id, 'cf-1');
      expect(dto.name, 'phone_num');
      expect(dto.label, 'Téléphone');
      expect(dto.fieldType, 'PHONE');
      expect(dto.required, true);
      expect(dto.defaultValue, '+33123456789');
      expect(dto.options, 'Option 1, Option 2');
      expect(dto.scopeType, 'GROUP');
      expect(dto.scopeId, '10');
      expect(dto.sortOrder, 2);
      expect(dto.active, true);
      expect(dto.minValue, 0.0);
      expect(dto.maxValue, 100.0);
      expect(dto.minLength, 5);
      expect(dto.maxLength, 15);
      expect(dto.regexPattern, r'^\+?[0-9]{8,15}$');
      expect(dto.hidden, false);
      expect(dto.readOnly, false);
      expect(dto.visibilityRule, 'otherField==val');
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeCustomFieldDto.fromJson({});
      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.label, '');
      expect(dto.fieldType, 'STRING');
      expect(dto.required, false);
      expect(dto.scopeType, 'GLOBAL');
      expect(dto.sortOrder, 0);
      expect(dto.active, true);
      expect(dto.hidden, false);
      expect(dto.readOnly, false);
    });

    test('serializes definition correctly to json', () {
      const dto = TimetreeCustomFieldDto(
        id: 'cf-2',
        name: 'notes',
        label: 'Notes',
        fieldType: 'TEXT_AREA',
        required: false,
        scopeType: 'GLOBAL',
        sortOrder: 1,
        active: true,
        hidden: false,
        readOnly: false,
      );
      final json = dto.toJson();
      expect(json['name'], 'notes');
      expect(json['label'], 'Notes');
      expect(json['fieldType'], 'TEXT_AREA');
      expect(json['required'], false);
      expect(json['scopeType'], 'GLOBAL');
      expect(json['sortOrder'], 1);
      expect(json['active'], true);
    });
  });

  group('Domain Model Mapping Tests', () {
    test('CustomField DTO maps to Domain Model', () {
      const dto = TimetreeCustomFieldDto(
        id: '1',
        name: 'age',
        label: 'Âge',
        fieldType: 'INTEGER',
        required: true,
        scopeType: 'CALENDAR',
        scopeId: '5',
        sortOrder: 3,
        active: true,
        hidden: false,
        readOnly: true,
      );
      final domain = TimetreeCustomField.fromDto(dto);
      expect(domain.id, '1');
      expect(domain.name, 'age');
      expect(domain.label, 'Âge');
      expect(domain.fieldType, 'INTEGER');
      expect(domain.required, true);
      expect(domain.scopeType, 'CALENDAR');
      expect(domain.scopeId, '5');
      expect(domain.sortOrder, 3);
      expect(domain.active, true);
      expect(domain.hidden, false);
      expect(domain.readOnly, true);
    });
  });

  group('Custom Fields Provider Tests', () {
    test('filters fields based on search query', () {
      final container = ProviderContainer(
        overrides: [
          timetreeCustomFieldsProvider.overrideWith(
            (ref) => _FakeCustomFieldsNotifier(
              AsyncValue.data([
                const TimetreeCustomField(id: '1', name: 'mail', label: 'Adresse email', fieldType: 'EMAIL', required: true, scopeType: 'GLOBAL', sortOrder: 1, active: true, hidden: false, readOnly: false),
                const TimetreeCustomField(id: '2', name: 'desc', label: 'Description', fieldType: 'TEXT_AREA', required: false, scopeType: 'GLOBAL', sortOrder: 2, active: true, hidden: false, readOnly: false),
              ]),
            ),
          )
        ],
      );

      expect(container.read(filteredTimetreeCustomFieldsProvider).value, hasLength(2));

      container.read(timetreeCustomFieldSearchQueryProvider.notifier).state = 'email';
      expect(container.read(filteredTimetreeCustomFieldsProvider).value, hasLength(1));
      expect(container.read(filteredTimetreeCustomFieldsProvider).value!.first.name, 'mail');
    });
  });

  group('TimetreeCustomFieldsScreen Widget Tests', () {
    testWidgets('renders loading state for custom fields', (tester) async {
      final fieldsOverride = timetreeCustomFieldsProvider.overrideWith(
        (ref) => _FakeCustomFieldsNotifier(const AsyncValue.loading()),
      );
      final groupsOverride = timetreeGroupsProvider.overrideWith(
        (ref) => _FakeGroupsNotifier(const AsyncValue.data([])),
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
              id: 'admin-1',
              username: 'admin',
              fullName: 'Admin User',
              email: 'admin@test.com',
              role: 'ADMIN',
              station: 'Station 1',
              phone: '123',
              tierId: '1',
            ),
            isChecking: false,
          ),
        ),
      );

      await tester.pumpWidget(
        buildCustomFieldsHarness(
          const TimetreeCustomFieldsScreen(),
          [fieldsOverride, groupsOverride, calendarsOverride, menuOverride, authOverride],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('non-admin/non-chef sees restricted access warning', (tester) async {
      final fieldsOverride = timetreeCustomFieldsProvider.overrideWith(
        (ref) => _FakeCustomFieldsNotifier(const AsyncValue.data([])),
      );
      final groupsOverride = timetreeGroupsProvider.overrideWith(
        (ref) => _FakeGroupsNotifier(const AsyncValue.data([])),
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
              username: 'member1',
              fullName: 'Member One',
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
        buildCustomFieldsHarness(
          const TimetreeCustomFieldsScreen(),
          [fieldsOverride, groupsOverride, calendarsOverride, menuOverride, authOverride],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Accès Restreint'), findsOneWidget);
    });
  });

  group('DynamicEventFormRenderer Widget Tests', () {
    testWidgets('renders fields and validates inputs', (tester) async {
      final List<TimetreeCustomField> fields = [
        const TimetreeCustomField(
          id: 'cf-string',
          name: 'text_field',
          label: 'Nom complet',
          fieldType: 'STRING',
          required: true,
          scopeType: 'GLOBAL',
          sortOrder: 1,
          active: true,
          hidden: false,
          readOnly: false,
        ),
        const TimetreeCustomField(
          id: 'cf-email',
          name: 'email_field',
          label: 'Courriel',
          fieldType: 'EMAIL',
          required: true,
          scopeType: 'GLOBAL',
          sortOrder: 2,
          active: true,
          hidden: false,
          readOnly: false,
        ),
      ];

      final values = <String, String>{};
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DynamicEventFormRenderer(
                fields: fields,
                values: values,
                formKey: formKey,
                onValuesChanged: (updated) {
                  values.addAll(updated);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text('Courriel'), findsOneWidget);

      // Trigger validation on empty required fields
      formKey.currentState?.validate();
      await tester.pumpAndSettle();

      expect(find.text('Ce champ est requis'), findsNWidgets(2));
    });

    testWidgets('respects conditional visibility rules', (tester) async {
      final List<TimetreeCustomField> fields = [
        const TimetreeCustomField(
          id: 'cf-parent',
          name: 'has_child',
          label: 'Afficher le champ enfant ?',
          fieldType: 'BOOLEAN',
          required: false,
          defaultValue: 'false',
          scopeType: 'GLOBAL',
          sortOrder: 1,
          active: true,
          hidden: false,
          readOnly: false,
        ),
        const TimetreeCustomField(
          id: 'cf-child',
          name: 'child_text',
          label: 'Texte Enfant',
          fieldType: 'STRING',
          required: false,
          scopeType: 'GLOBAL',
          sortOrder: 2,
          active: true,
          hidden: false,
          readOnly: false,
          visibilityRule: 'has_child==true',
        ),
      ];

      final values = <String, String>{};
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DynamicEventFormRenderer(
                  fields: fields,
                  values: values,
                  formKey: formKey,
                  onValuesChanged: (updated) {
                    setState(() {
                      values.clear();
                      values.addAll(updated);
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Child should be hidden initially
      expect(find.text('Texte Enfant'), findsNothing);

      // Toggle switch to true
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Child should now be visible
      expect(find.text('Texte Enfant'), findsOneWidget);
    });
  });
}

// ─── MOCKS FOR TESTING ──────────────────────────────────────────────────────

class _FakeCustomFieldsNotifier extends TimetreeCustomFieldsNotifier {
  _FakeCustomFieldsNotifier(AsyncValue<List<TimetreeCustomField>> initialValue)
      : super(_FakeCustomFieldsRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadFields({String? scopeType, String? scopeId}) async {}
}

class _FakeCustomFieldsRepo extends TimetreeCustomFieldsRepository {
  _FakeCustomFieldsRepo() : super(TimetreeApi(Dio()));
}

class _FakeGroupsNotifier extends TimetreeGroupsNotifier {
  _FakeGroupsNotifier(AsyncValue<List<TimetreeGroup>> initialValue)
      : super(_FakeGroupsRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadGroups() async {}
}

class _FakeGroupsRepo extends TimetreeGroupsRepository {
  _FakeGroupsRepo() : super(TimetreeApi(Dio()));
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
