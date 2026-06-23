import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_role_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_role.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_permission_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_permission.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_roles_repository.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_roles_provider.dart';
import 'package:dux_front/features/timetree/presentation/screens/roles_permissions_screen.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_group.dart';
import 'package:dux_front/features/timetree/presentation/provider/timetree_groups_provider.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_groups_repository.dart';

Widget buildRolesHarness(
  Widget widget,
  List<Override> overrides,
) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: widget),
  );
}

void main() {
  group('TimetreeRoleDto Parsing Tests', () {
    test('parses correctly from json', () {
      final json = {
        'code': 'admin',
        'name': 'Admin',
      };
      final dto = TimetreeRoleDto.fromJson(json);
      expect(dto.code, 'admin');
      expect(dto.name, 'Admin');
    });

    test('handles missing or null json values with defaults', () {
      final dto = TimetreeRoleDto.fromJson({});
      expect(dto.code, '');
      expect(dto.name, '');
    });

    test('serializes correctly to json', () {
      const dto = TimetreeRoleDto(
        code: 'viewer',
        name: 'Viewer',
      );
      final json = dto.toJson();
      expect(json['code'], 'viewer');
      expect(json['name'], 'Viewer');
    });
  });

  group('TimetreeRole Domain Model Mapping Tests', () {
    test('maps correctly from DTO', () {
      const dto = TimetreeRoleDto(
        code: 'editor',
        name: 'Editor',
      );
      final domain = TimetreeRole.fromDto(dto);
      expect(domain.code, 'editor');
      expect(domain.name, 'Editor');
    });
  });

  group('TimetreePermissionDto Parsing Tests', () {
    test('parses category permission from json', () {
      final json = {
        'categoryId': 12,
        'categoryName': 'Cat 1',
        'groupIds': [1, 2],
      };
      final dto = TimetreeCategoryPermissionDto.fromJson(json);
      expect(dto.categoryId, '12');
      expect(dto.categoryName, 'Cat 1');
      expect(dto.groupIds, ['1', '2']);
    });

    test('parses page permission from json', () {
      final json = {
        'pageId': 34,
        'pageName': 'Page 1',
        'groupIds': [3],
      };
      final dto = TimetreePagePermissionDto.fromJson(json);
      expect(dto.pageId, '34');
      expect(dto.pageName, 'Page 1');
      expect(dto.groupIds, ['3']);
    });

    test('parses permission matrix from json', () {
      final json = {
        'categories': [
          {'categoryId': '1', 'categoryName': 'Cat 1', 'groupIds': ['10']}
        ],
        'pages': [
          {'pageId': '2', 'pageName': 'Page 1', 'groupIds': ['20']}
        ]
      };
      final dto = TimetreePermissionMatrixDto.fromJson(json);
      expect(dto.categories.length, 1);
      expect(dto.categories[0].categoryId, '1');
      expect(dto.pages.length, 1);
      expect(dto.pages[0].pageId, '2');
    });
  });

  group('TimetreeRolesPermissionsScreen Widget Tests', () {
    testWidgets('renders loading states correctly', (tester) async {
      final overrides = [
        timetreeRolesProvider.overrideWith((ref) => _FakeRolesNotifier(const AsyncValue.loading(), ref)),
        timetreeGroupsProvider.overrideWith((ref) => _FakeGroupsNotifier(const AsyncValue.loading())),
        timetreePermissionsProvider.overrideWith((ref) => _FakePermissionsNotifier(const AsyncValue.loading())),
      ];

      await tester.pumpWidget(
        buildRolesHarness(const TimetreeRolesPermissionsScreen(), overrides),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('renders success state lists of roles and groups', (tester) async {
      final overrides = [
        timetreeRolesProvider.overrideWith((ref) => _FakeRolesNotifier(const AsyncValue.data([
          TimetreeRole(code: 'admin', name: 'Admin'),
          TimetreeRole(code: 'viewer', name: 'Viewer'),
        ]), ref)),
        timetreeGroupsProvider.overrideWith((ref) => _FakeGroupsNotifier(const AsyncValue.data([
          TimetreeGroup(id: '1', name: 'Admin Group', description: 'Group for admins', active: true, roles: ['admin']),
          TimetreeGroup(id: '2', name: 'Viewer Group', description: 'Group for viewers', active: true, roles: []),
        ]))),
        timetreePermissionsProvider.overrideWith((ref) => _FakePermissionsNotifier(const AsyncValue.data(
          TimetreePermissionMatrix(categories: [], pages: []),
        ))),
      ];

      await tester.pumpWidget(
        buildRolesHarness(const TimetreeRolesPermissionsScreen(), overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Group'), findsOneWidget);
      expect(find.text('Viewer Group'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget); // Assigned role chip
      expect(find.text('Aucun rôle assigné à ce groupe.'), findsOneWidget); // For group 2
    });
  });
}

class _FakeRolesNotifier extends TimetreeRolesNotifier {
  _FakeRolesNotifier(AsyncValue<List<TimetreeRole>> initialValue, Ref ref) : super(_FakeRolesRepo(), ref) {
    state = initialValue;
  }

  @override
  Future<void> loadRoles() async {}
}

class _FakeRolesRepo extends TimetreeRolesRepository {
  _FakeRolesRepo() : super(TimetreeApi(Dio()));
}

class _FakeGroupsNotifier extends TimetreeGroupsNotifier {
  _FakeGroupsNotifier(AsyncValue<List<TimetreeGroup>> initialValue) : super(_FakeGroupsRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadGroups() async {}
}

class _FakeGroupsRepo extends TimetreeGroupsRepository {
  _FakeGroupsRepo() : super(TimetreeApi(Dio()));
}

class _FakePermissionsNotifier extends TimetreePermissionsNotifier {
  _FakePermissionsNotifier(AsyncValue<TimetreePermissionMatrix> initialValue) : super(_FakeRolesRepo()) {
    state = initialValue;
  }

  @override
  Future<void> loadPermissions() async {}
}
