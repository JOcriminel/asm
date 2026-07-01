import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/auth/presentation/screens/workspace_selector_screen.dart';
import 'package:dux_front/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dux_front/features/profile/domain/repositories/profile_repository.dart';
import 'package:dux_front/features/profile/data/repositories/profile_repository.dart';
import 'package:dux_front/features/profile/domain/models/profile.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController() : super(null as dynamic, null as dynamic, null as dynamic);

  @override
  Future<void> checkSession() async {
    // Noop to avoid pending timers
  }
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<Profile> getProfile(String login) async {
    return Profile(
      userId: 'admin',
      fullName: 'Utilisateur Test',
      email: 'test@dux.com',
      role: 'admin',
      station: 'station',
      phone: '123456789',
      location: 'Tunis',
      employeeId: '1',
      joinedDate: DateTime.now(),
      cellule: 'Tunis',
      createur: 'admin',
      isActive: true,
      isSuperAdmin: true,
      motDePasse: '',
    );
  }
}

void main() {
  testWidgets('WorkspaceSelectorScreen renders workspace options correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith((ref) => _FakeAuthController()),
          profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
        ],
        child: const MaterialApp(
          home: WorkspaceSelectorScreen(),
        ),
      ),
    );

    // Pump a frame to let any async profile loading resolve
    await tester.pump();

    // Verify workspace screen title or subtitle
    expect(find.textContaining('Sélectionnez votre espace'), findsOneWidget);

    // Verify option cards are rendered
    expect(find.text('DUX Mobile'), findsOneWidget);
    expect(find.text('Dux Calender'), findsOneWidget);

    // Verify buttons are rendered
    expect(find.text('Accéder à l\'espace'), findsNWidgets(2));
  });
}
