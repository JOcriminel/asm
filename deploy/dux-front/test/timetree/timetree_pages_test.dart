import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_page_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_page.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_category.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_pages_repository.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_categories_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_categories_provider.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_pages_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/pages_screen.dart';

Widget buildPagesHarness(
  Widget widget,
  List<Override> overrides,
) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('TimetreePageDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'id': 'page-123',
        'title': 'Conditions Générales',
        'active': true,
        'displayOrder': 3,
        'categoryId': 'cat-99',
      };
      final dto = TimetreePageDto.fromJson(json);
      expect(dto.id, 'page-123');
      expect(dto.title, 'Conditions Générales');
      expect(dto.active, true);
      expect(dto.displayOrder, 3);
      expect(dto.categoryId, 'cat-99');
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreePageDto.fromJson({});
      expect(dto.id, '');
      expect(dto.title, '');
      expect(dto.active, false);
      expect(dto.displayOrder, 0);
      expect(dto.categoryId, '');
    });

    test('serializes correctly to json', () {
      const dto = TimetreePageDto(
        id: 'p-1',
        title: 'Rules',
        active: false,
        displayOrder: 10,
        categoryId: 'cat-2',
      );
      final json = dto.toJson();
      expect(json['id'], 'p-1');
      expect(json['title'], 'Rules');
      expect(json['active'], false);
      expect(json['displayOrder'], 10);
      expect(json['categoryId'], 'cat-2');
    });
  });

  group('TimetreePage Domain Model Mapping Tests', () {
    test('maps correctly from DTO', () {
      const dto = TimetreePageDto(
        id: 'dto-page-1',
        title: 'Privacy Policy',
        active: true,
        displayOrder: 1,
        categoryId: 'c-3',
      );
      final domain = TimetreePage.fromDto(dto);
      expect(domain.id, 'dto-page-1');
      expect(domain.title, 'Privacy Policy');
      expect(domain.active, true);
      expect(domain.displayOrder, 1);
      expect(domain.categoryId, 'c-3');
    });

    test('copyWith works correctly', () {
      const page = TimetreePage(
        id: 'p1',
        title: 'Contact Us',
        active: true,
        displayOrder: 4,
        categoryId: 'c2',
      );
      final updated = page.copyWith(title: 'Feedback', active: false);
      expect(updated.id, 'p1');
      expect(updated.title, 'Feedback');
      expect(updated.active, false);
      expect(updated.displayOrder, 4);
      expect(updated.categoryId, 'c2');
    });
  });

  group('Timetree Pages Provider Filtering Tests', () {
    test('filters list based on search query and category id', () {
      final container = ProviderContainer(
        overrides: [
          timetreePagesProvider.overrideWith(
            (ref) => _FakeNotifier(
              AsyncValue.data([
                const TimetreePage(id: '1', title: 'Accueil CGU', active: true, displayOrder: 1, categoryId: 'cat-1'),
                const TimetreePage(id: '2', title: 'Sales Guidelines', active: true, displayOrder: 2, categoryId: 'cat-2'),
                const TimetreePage(id: '3', title: 'FAQ Finance', active: false, displayOrder: 3, categoryId: 'cat-1'),
              ]),
            ),
          )
        ],
      );

      // Initial state: no filters, should return all
      expect(
        container.read(filteredTimetreePagesProvider).value,
        hasLength(3),
      );

      // Search 'cgu'
      container.read(timetreePageSearchQueryProvider.notifier).state = 'cgu';
      expect(
        container.read(filteredTimetreePagesProvider).value,
        hasLength(1),
      );
      expect(
        container.read(filteredTimetreePagesProvider).value!.first.title,
        'Accueil CGU',
      );

      // Reset query, and filter by Category 'cat-1'
      container.read(timetreePageSearchQueryProvider.notifier).state = '';
      container.read(timetreePageCategoryFilterProvider.notifier).state = 'cat-1';
      expect(
        container.read(filteredTimetreePagesProvider).value,
        hasLength(2), // 'Accueil CGU' and 'FAQ Finance'
      );
    });
  });

  group('TimetreePagesScreen Widget Tests', () {
    testWidgets('renders loading state correctly', (tester) async {
      final override = filteredTimetreePagesProvider.overrideWith(
        (ref) => const AsyncValue.loading(),
      );

      await tester.pumpWidget(
        buildPagesHarness(const TimetreePagesScreen(), [
          override,
          timetreeCategoriesProvider.overrideWith(
            (ref) => _FakeCategoriesNotifier(const AsyncValue.data([])),
          ),
        ]),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des pages…'), findsOneWidget);
    });

    testWidgets('renders error state correctly', (tester) async {
      final override = filteredTimetreePagesProvider.overrideWith(
        (ref) => AsyncValue.error(Exception('HTTP 500 Internal Error'), StackTrace.empty),
      );

      await tester.pumpWidget(
        buildPagesHarness(const TimetreePagesScreen(), [
          override,
          timetreeCategoriesProvider.overrideWith(
            (ref) => _FakeCategoriesNotifier(const AsyncValue.data([])),
          ),
        ]),
      );
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('HTTP 500'), findsOneWidget);
    });

    testWidgets('renders empty state correctly', (tester) async {
      final override = filteredTimetreePagesProvider.overrideWith(
        (ref) => const AsyncValue.data([]),
      );

      await tester.pumpWidget(
        buildPagesHarness(const TimetreePagesScreen(), [
          override,
          timetreeCategoriesProvider.overrideWith(
            (ref) => _FakeCategoriesNotifier(const AsyncValue.data([])),
          ),
        ]),
      );
      await tester.pump();

      expect(find.text('Aucune page enregistrée'), findsOneWidget);
    });

    testWidgets('renders pages list on success state', (tester) async {
      final override = filteredTimetreePagesProvider.overrideWith(
        (ref) => const AsyncValue.data([
          TimetreePage(id: '1', title: 'Aide client', active: true, displayOrder: 1, categoryId: 'cat-1'),
          TimetreePage(id: '2', title: 'Formulaires', active: false, displayOrder: 2, categoryId: 'cat-2'),
        ]),
      );

      await tester.pumpWidget(
        buildPagesHarness(const TimetreePagesScreen(), [
          override,
          timetreeCategoriesProvider.overrideWith(
            (ref) => _FakeCategoriesNotifier(const AsyncValue.data([
              TimetreeCategory(id: 'cat-1', name: 'Finance', active: true, displayOrder: 1),
              TimetreeCategory(id: 'cat-2', name: 'Logistique', active: true, displayOrder: 2),
            ])),
          ),
        ]),
      );
      await tester.pump();

      // Page titles rendered
      expect(find.text('Aide client'), findsOneWidget);
      expect(find.text('Formulaires'), findsOneWidget);

      // Subtitle details (verifying Category lookup works)
      expect(find.textContaining('Catégorie : Finance'), findsOneWidget);
      expect(find.textContaining('Catégorie : Logistique'), findsOneWidget);

      // Switch & delete controls
      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });

    testWidgets('opens edit dialog and handles category loading error with retry button', (tester) async {
      final override = filteredTimetreePagesProvider.overrideWith(
        (ref) => const AsyncValue.data([
          TimetreePage(id: '1', title: 'Aide client', active: true, displayOrder: 1, categoryId: 'cat-1'),
        ]),
      );

      var loadCategoriesCalled = 0;
      final categoriesNotifier = _FakeCategoriesNotifierWithError(
        const AsyncValue.error('Network failure', StackTrace.empty),
        onLoadCategories: () {
          loadCategoriesCalled++;
        },
      );

      await tester.pumpWidget(
        buildPagesHarness(const TimetreePagesScreen(), [
          override,
          timetreeCategoriesProvider.overrideWith((ref) => categoriesNotifier),
        ]),
      );
      await tester.pump();

      // Tap on Edit button to open the dialog
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Verify that the dialog is open and displays the title 'Modifier la page'
      expect(find.text('Modifier la page'), findsOneWidget);

      // Verify categories error is shown along with Réessayer button
      expect(find.textContaining('Erreur de chargement des catégories: Network failure'), findsOneWidget);
      final retryBtn = find.widgetWithText(FilledButton, 'Réessayer');
      expect(retryBtn, findsOneWidget);

      // Tap Réessayer and verify it triggers loadCategories
      await tester.tap(retryBtn);
      await tester.pump();
      expect(loadCategoriesCalled, 2);
    });
  });
}

// Fake state notifier for testing
class _FakeNotifier extends TimetreePagesNotifier {
  _FakeNotifier(AsyncValue<List<TimetreePage>> initialValue)
      : super(_FakeRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadPages() async {}
}

class _FakeRepo extends TimetreePagesRepository {
  _FakeRepo() : super(TimetreeApi(Dio()));

  @override
  Future<List<TimetreePage>> getPages() async => const [];
}

class _FakeCategoriesNotifier extends TimetreeCategoriesNotifier {
  _FakeCategoriesNotifier(AsyncValue<List<TimetreeCategory>> initialValue)
      : super(_FakeCategoriesRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadCategories() async {}
}

class _FakeCategoriesRepo extends TimetreeCategoriesRepository {
  _FakeCategoriesRepo() : super(TimetreeApi(Dio()));

  @override
  Future<List<TimetreeCategory>> getCategories() async => const [];
}

class _FakeCategoriesNotifierWithError extends TimetreeCategoriesNotifier {
  _FakeCategoriesNotifierWithError(AsyncValue<List<TimetreeCategory>> initialValue, {required this.onLoadCategories})
      : super(_FakeCategoriesRepo()) {
    state = initialValue;
  }

  final VoidCallback onLoadCategories;

  @override
  Future<void> loadCategories() async {
    onLoadCategories();
  }
}
