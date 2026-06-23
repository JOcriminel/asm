import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_dashboard_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_dashboard.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_dashboard_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [widget] with [ProviderScope] + [MaterialApp] and overrides
/// [timetreeDashboardProvider] with [override].
Widget buildHarness(
  Widget widget,
  Override override,
) {
  return ProviderScope(
    overrides: [override],
    child: MaterialApp(home: widget),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DTO unit tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('TimetreeDashboardDto.fromJson', () {
    test('parses full nested payload correctly', () {
      final json = {
        'summary': {
          'categoriesCount': 12,
          'pagesCount': 34,
          'groupsCount': 5,
        },
        'recentActivities': [
          {
            'id': 'abc',
            'type': 'CATEGORY_CREATED',
            'title': 'Finance créée',
            'timestamp': '2026-06-20T14:32:10Z',
          },
        ],
      };

      final dto = TimetreeDashboardDto.fromJson(json);

      expect(dto.summary.categoriesCount, 12);
      expect(dto.summary.pagesCount, 34);
      expect(dto.summary.groupsCount, 5);
      expect(dto.recentActivities, hasLength(1));
      expect(dto.recentActivities.first.id, 'abc');
      expect(dto.recentActivities.first.type, 'CATEGORY_CREATED');
      expect(dto.recentActivities.first.title, 'Finance créée');
      expect(dto.recentActivities.first.timestamp, '2026-06-20T14:32:10Z');
    });

    test('defaults to 0 counts when summary is missing', () {
      final dto = TimetreeDashboardDto.fromJson({});

      expect(dto.summary.categoriesCount, 0);
      expect(dto.summary.pagesCount, 0);
      expect(dto.summary.groupsCount, 0);
      expect(dto.recentActivities, isEmpty);
    });

    test('defaults counts to 0 when summary fields are null', () {
      final dto = TimetreeDashboardDto.fromJson({
        'summary': {'categoriesCount': null, 'pagesCount': null},
        'recentActivities': [],
      });

      expect(dto.summary.categoriesCount, 0);
      expect(dto.summary.pagesCount, 0);
      expect(dto.summary.groupsCount, 0);
    });

    test('skips non-map entries in recentActivities', () {
      final dto = TimetreeDashboardDto.fromJson({
        'summary': {'categoriesCount': 1, 'pagesCount': 1, 'groupsCount': 1},
        'recentActivities': ['not-a-map', 42, null],
      });

      expect(dto.recentActivities, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Domain model unit tests
  // ─────────────────────────────────────────────────────────────────────────

  group('TimetreeDashboard.fromDto', () {
    test('maps DTO fields to domain model', () {
      final dto = TimetreeDashboardDto.fromJson({
        'summary': {
          'categoriesCount': 3,
          'pagesCount': 7,
          'groupsCount': 2,
        },
        'recentActivities': [
          {
            'id': 'x1',
            'type': 'PAGE_UPDATED',
            'title': 'Updated Invoices',
            'timestamp': '2026-06-19T09:11:45Z',
          },
        ],
      });

      final domain = TimetreeDashboard.fromDto(dto);

      expect(domain.categoriesCount, 3);
      expect(domain.pagesCount, 7);
      expect(domain.groupsCount, 2);
      expect(domain.recentActivities, hasLength(1));
      expect(domain.recentActivities.first.title, 'Updated Invoices');
      expect(domain.recentActivities.first.timestamp, isNotNull);
      expect(
        domain.recentActivities.first.timestamp,
        DateTime.parse('2026-06-19T09:11:45Z'),
      );
    });

    test('TimetreeDashboard.empty() has zero counts and empty list', () {
      const d = TimetreeDashboard.empty();
      expect(d.categoriesCount, 0);
      expect(d.pagesCount, 0);
      expect(d.groupsCount, 0);
      expect(d.recentActivities, isEmpty);
    });

    test('handles null timestamp in activity', () {
      final dto = TimetreeDashboardDto.fromJson({
        'summary': {'categoriesCount': 0, 'pagesCount': 0, 'groupsCount': 0},
        'recentActivities': [
          {'id': 'y1', 'type': 'GROUP_CREATED', 'title': 'Sales group'},
        ],
      });

      final domain = TimetreeDashboard.fromDto(dto);
      expect(domain.recentActivities.first.timestamp, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Widget tests
  // ─────────────────────────────────────────────────────────────────────────

  group('TimetreeDashboardScreen widget', () {
    testWidgets('shows loading indicator while provider is loading',
        (tester) async {
      final completer = Completer<TimetreeDashboard>();
      final override = timetreeDashboardProvider.overrideWith(
        (ref) => completer.future,
      );

      await tester.pumpWidget(
        buildHarness(const TimetreeDashboardScreen(), override),
      );
      // First frame — loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button on failure',
        (tester) async {
      final override = timetreeDashboardProvider.overrideWith(
        (ref) => throw Exception('HTTP 500'),
      );

      await tester.pumpWidget(
        buildHarness(const TimetreeDashboardScreen(), override),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('shows empty-activities state when list is empty',
        (tester) async {
      final override = timetreeDashboardProvider.overrideWith(
        (ref) => const TimetreeDashboard(
          categoriesCount: 0,
          pagesCount: 0,
          groupsCount: 0,
          recentActivities: [],
        ),
      );

      await tester.pumpWidget(
        buildHarness(const TimetreeDashboardScreen(), override),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Aucune activité récente'),
        100.0,
        scrollable: scrollable,
      );

      expect(find.text('Aucune activité récente'), findsOneWidget);
    });

    testWidgets('shows stat cards with correct counts on success',
        (tester) async {
      final override = timetreeDashboardProvider.overrideWith(
        (ref) => TimetreeDashboard(
          categoriesCount: 12,
          pagesCount: 34,
          groupsCount: 5,
          recentActivities: [
            TimetreeActivity(
              id: 'a1',
              type: 'CATEGORY_CREATED',
              title: 'Finance créée',
              timestamp: DateTime.parse('2026-06-20T14:32:10Z'),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        buildHarness(const TimetreeDashboardScreen(), override),
      );
      await tester.pumpAndSettle();

      // Stat counts rendered
      expect(find.text('12'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Labels
      expect(find.text('Catégories'), findsOneWidget);
      expect(find.text('Pages'), findsOneWidget);
      expect(find.text('Groupes'), findsOneWidget);

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Finance créée'),
        100.0,
        scrollable: scrollable,
      );

      // Activity entry title
      expect(find.text('Finance créée'), findsOneWidget);
    });
  });
}
