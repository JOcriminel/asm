import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_group_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_groups_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/groups_screen.dart';

Widget buildGroupsHarness(
  Widget widget,
  List<Override> overrides,
) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('TimetreeGroupDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 'g-123',
        'name': 'Administrators',
        'description': 'Root administrative users',
        'active': true,
      };
      final dto = TimetreeGroupDto.fromJson(json);
      expect(dto.id, 'g-123');
      expect(dto.name, 'Administrators');
      expect(dto.description, 'Root administrative users');
      expect(dto.active, true);
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeGroupDto.fromJson({});
      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.description, '');
      expect(dto.active, false);
    });

    test('serializes correctly to json', () {
      const dto = TimetreeGroupDto(
        id: 'g-2',
        name: 'Sellers',
        description: 'Store sellers group',
        active: false,
      );
      final json = dto.toJson();
      expect(json['id'], 'g-2');
      expect(json['name'], 'Sellers');
      expect(json['description'], 'Store sellers group');
      expect(json['active'], false);
    });
  });

  group('TimetreeGroup Domain Model Mapping Tests', () {
    test('maps correctly from DTO', () {
      const dto = TimetreeGroupDto(
        id: 'dto-g-1',
        name: 'Warehouse Managers',
        description: 'Warehouse users group',
        active: true,
      );
      final domain = TimetreeGroup.fromDto(dto);
      expect(domain.id, 'dto-g-1');
      expect(domain.name, 'Warehouse Managers');
      expect(domain.description, 'Warehouse users group');
      expect(domain.active, true);
    });

    test('copyWith works correctly', () {
      const group = TimetreeGroup(
        id: 'g1',
        name: 'Original Name',
        description: 'Original Desc',
        active: true,
      );
      final updated = group.copyWith(name: 'Updated Name', active: false);
      expect(updated.id, 'g1');
      expect(updated.name, 'Updated Name');
      expect(updated.description, 'Original Desc');
      expect(updated.active, false);
    });
  });

  group('Timetree Groups Provider Filtering Tests', () {
    test('filters list based on search query', () {
      final container = ProviderContainer(
        overrides: [
          timetreeGroupsProvider.overrideWith(
            (ref) => _FakeNotifier(
              AsyncValue.data([
                const TimetreeGroup(id: '1', name: 'Administrateurs', description: 'Accès total', active: true),
                const TimetreeGroup(id: '2', name: 'Vendeurs', description: 'Accès ventes', active: true),
                const TimetreeGroup(id: '3', name: 'Préparateurs', description: 'Accès stock', active: false),
              ]),
            ),
          )
        ],
      );

      // Initial: returns all
      expect(container.read(filteredTimetreeGroupsProvider).value, hasLength(3));

      // Filter by 'admin'
      container.read(timetreeGroupSearchQueryProvider.notifier).state = 'admin';
      expect(container.read(filteredTimetreeGroupsProvider).value, hasLength(1));
      expect(container.read(filteredTimetreeGroupsProvider).value!.first.name, 'Administrateurs');

      // Filter by 'ventes' description
      container.read(timetreeGroupSearchQueryProvider.notifier).state = 'ventes';
      expect(container.read(filteredTimetreeGroupsProvider).value, hasLength(1));
      expect(container.read(filteredTimetreeGroupsProvider).value!.first.name, 'Vendeurs');
    });
  });

  group('TimetreeGroupsScreen Widget Tests', () {
    testWidgets('renders loading state correctly', (tester) async {
      final override = filteredTimetreeGroupsProvider.overrideWith(
        (ref) => const AsyncValue.loading(),
      );

      await tester.pumpWidget(
        buildGroupsHarness(const TimetreeGroupsScreen(), [override]),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des groupes…'), findsOneWidget);
    });

    testWidgets('renders error state correctly', (tester) async {
      final override = filteredTimetreeGroupsProvider.overrideWith(
        (ref) => AsyncValue.error(Exception('HTTP 500 Internal Error'), StackTrace.empty),
      );

      await tester.pumpWidget(
        buildGroupsHarness(const TimetreeGroupsScreen(), [override]),
      );
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('HTTP 500'), findsOneWidget);
    });

    testWidgets('renders empty state correctly', (tester) async {
      final override = filteredTimetreeGroupsProvider.overrideWith(
        (ref) => const AsyncValue.data([]),
      );

      await tester.pumpWidget(
        buildGroupsHarness(const TimetreeGroupsScreen(), [override]),
      );
      await tester.pump();

      expect(find.text('Aucun groupe enregistré'), findsOneWidget);
    });

    testWidgets('renders groups list on success state', (tester) async {
      final override = filteredTimetreeGroupsProvider.overrideWith(
        (ref) => const AsyncValue.data([
          TimetreeGroup(id: '1', name: 'Administrateurs', description: 'Accès total', active: true),
          TimetreeGroup(id: '2', name: 'Vendeurs', description: 'Accès boutique', active: false),
        ]),
      );

      await tester.pumpWidget(
        buildGroupsHarness(const TimetreeGroupsScreen(), [override]),
      );
      await tester.pump();

      expect(find.text('Administrateurs'), findsOneWidget);
      expect(find.text('Accès total'), findsOneWidget);
      expect(find.text('Vendeurs'), findsOneWidget);
      expect(find.text('Accès boutique'), findsOneWidget);

      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
    });
  });
}

class _FakeNotifier extends TimetreeGroupsNotifier {
  _FakeNotifier(AsyncValue<List<TimetreeGroup>> initialValue)
      : super(_FakeRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadGroups() async {}
}

class _FakeRepo extends TimetreeGroupsRepository {
  _FakeRepo() : super(TimetreeApi(Dio()));

  @override
  Future<List<TimetreeGroup>> getGroups() async => const [];
}
