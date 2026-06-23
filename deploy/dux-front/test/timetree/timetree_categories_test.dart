import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_category_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_categories_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_categories_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/categories_screen.dart';

Widget buildCategoriesHarness(
  Widget widget,
  List<Override> overrides,
) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('TimetreeCategoryDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 'cat-123',
        'name': 'Sales',
        'active': true,
        'displayOrder': 4,
      };
      final dto = TimetreeCategoryDto.fromJson(json);
      expect(dto.id, 'cat-123');
      expect(dto.name, 'Sales');
      expect(dto.active, true);
      expect(dto.displayOrder, 4);
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeCategoryDto.fromJson({});
      expect(dto.id, '');
      expect(dto.name, '');
      expect(dto.active, false);
      expect(dto.displayOrder, 0);
    });

    test('serializes correctly to json', () {
      const dto = TimetreeCategoryDto(
        id: 'cat-1',
        name: 'Finance',
        active: false,
        displayOrder: 2,
      );
      final json = dto.toJson();
      expect(json['id'], 'cat-1');
      expect(json['name'], 'Finance');
      expect(json['active'], false);
      expect(json['displayOrder'], 2);
    });
  });

  group('TimetreeCategory Domain Model Mapping Tests', () {
    test('maps correctly from DTO', () {
      const dto = TimetreeCategoryDto(
        id: 'dto-1',
        name: 'Marketing',
        active: true,
        displayOrder: 5,
      );
      final domain = TimetreeCategory.fromDto(dto);
      expect(domain.id, 'dto-1');
      expect(domain.name, 'Marketing');
      expect(domain.active, true);
      expect(domain.displayOrder, 5);
    });

    test('copyWith works correctly', () {
      const cat = TimetreeCategory(
        id: 'c1',
        name: 'HR',
        active: true,
        displayOrder: 10,
      );
      final updated = cat.copyWith(name: 'Staff', active: false);
      expect(updated.id, 'c1');
      expect(updated.name, 'Staff');
      expect(updated.active, false);
      expect(updated.displayOrder, 10);
    });
  });

  group('Timetree Categories Provider Filtering Tests', () {
    test('filters list based on search query', () {
      final container = ProviderContainer(
        overrides: [
          timetreeCategoriesProvider.overrideWith(
            (ref) => _FakeNotifier(
              AsyncValue.data([
                const TimetreeCategory(id: '1', name: 'Finance', active: true, displayOrder: 1),
                const TimetreeCategory(id: '2', name: 'Ventes', active: true, displayOrder: 2),
                const TimetreeCategory(id: '3', name: 'Ressources Humaines', active: false, displayOrder: 3),
              ]),
            ),
          )
        ],
      );

      // Initial state: no search query, should return all
      expect(
        container.read(filteredTimetreeCategoriesProvider).value,
        hasLength(3),
      );

      // Search 'vent'
      container.read(timetreeCategorySearchQueryProvider.notifier).state = 'vent';
      expect(
        container.read(filteredTimetreeCategoriesProvider).value,
        hasLength(1),
      );
      expect(
        container.read(filteredTimetreeCategoriesProvider).value!.first.name,
        'Ventes',
      );

      // Search 'ce'
      container.read(timetreeCategorySearchQueryProvider.notifier).state = 'ce';
      expect(
        container.read(filteredTimetreeCategoriesProvider).value,
        hasLength(2), // Finance & Ressources Humaines
      );
    });
  });

  group('TimetreeCategoriesScreen Widget Tests', () {
    testWidgets('renders loading state correctly', (tester) async {
      final override = filteredTimetreeCategoriesProvider.overrideWith(
        (ref) => const AsyncValue.loading(),
      );

      await tester.pumpWidget(
        buildCategoriesHarness(const TimetreeCategoriesScreen(), [override]),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des catégories…'), findsOneWidget);
    });

    testWidgets('renders error state correctly', (tester) async {
      final override = filteredTimetreeCategoriesProvider.overrideWith(
        (ref) => AsyncValue.error(Exception('HTTP 500 Internal Error'), StackTrace.empty),
      );

      await tester.pumpWidget(
        buildCategoriesHarness(const TimetreeCategoriesScreen(), [override]),
      );
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('HTTP 500'), findsOneWidget);
    });

    testWidgets('renders empty state correctly', (tester) async {
      final override = filteredTimetreeCategoriesProvider.overrideWith(
        (ref) => const AsyncValue.data([]),
      );

      await tester.pumpWidget(
        buildCategoriesHarness(const TimetreeCategoriesScreen(), [override]),
      );
      await tester.pump();

      expect(find.text('Aucune catégorie enregistrée'), findsOneWidget);
    });

    testWidgets('renders categories list on success state', (tester) async {
      final override = filteredTimetreeCategoriesProvider.overrideWith(
        (ref) => const AsyncValue.data([
          TimetreeCategory(id: '1', name: 'Logistique', active: true, displayOrder: 1),
          TimetreeCategory(id: '2', name: 'Achats', active: false, displayOrder: 2),
        ]),
      );

      await tester.pumpWidget(
        buildCategoriesHarness(const TimetreeCategoriesScreen(), [override]),
      );
      await tester.pump();

      // Category names should render
      expect(find.text('Logistique'), findsOneWidget);
      expect(find.text('Achats'), findsOneWidget);

      // Subtitles
      expect(find.text('Ordre d\'affichage : 1'), findsOneWidget);
      expect(find.text('Ordre d\'affichage : 2'), findsOneWidget);

      // Buttons
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
    });
  });
}

// Fake state notifier for testing
class _FakeNotifier extends TimetreeCategoriesNotifier {
  _FakeNotifier(AsyncValue<List<TimetreeCategory>> initialValue)
      : super(_FakeRepo()) {
    state = initialValue;
  }
}

class _FakeRepo extends TimetreeCategoriesRepository {
  _FakeRepo() : super(TimetreeApi(Dio()));

  @override
  Future<List<TimetreeCategory>> getCategories() async => const [];
}
