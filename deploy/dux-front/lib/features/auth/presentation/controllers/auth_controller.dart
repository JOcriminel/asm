import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/auth/domain/models/user.dart';
import 'package:dux_front/features/auth/data/repositories/auth_repository.dart';
import 'package:dux_front/features/auth/domain/usecases/login_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/logout_use_case.dart';
import 'package:dux_front/features/auth/domain/usecases/check_session_use_case.dart';
import 'package:dux_front/core/services/storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isChecking;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isChecking = true,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isChecking,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Presentation controller — depends on use-cases, never on repositories directly.
/// Dependency Inversion: wired to [LoginUseCase], [LogoutUseCase], [CheckSessionUseCase].
class AuthController extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckSessionUseCase _checkSessionUseCase;

  AuthController(
    this._loginUseCase,
    this._logoutUseCase,
    this._checkSessionUseCase,
  ) : super(const AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(isChecking: true, clearError: true);
    try {
      final user = await _checkSessionUseCase();
      state = state.copyWith(user: user, isChecking: false, clearUser: user == null);
    } catch (_) {
      state = state.copyWith(isChecking: false, clearUser: true);
    }
  }

  Future<bool> login(String username, String password, bool rememberMe) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _loginUseCase(username, password, rememberMe: rememberMe);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _logoutUseCase();
      state = const AuthState(isChecking: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _loginUseCaseProvider = Provider<LoginUseCase>((ref) => LoginUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(storageServiceProvider),
    ));

final _logoutUseCaseProvider = Provider<LogoutUseCase>((ref) => LogoutUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(storageServiceProvider),
    ));

final _checkSessionUseCaseProvider =
    Provider<CheckSessionUseCase>((ref) => CheckSessionUseCase(
          ref.watch(authRepositoryProvider),
          ref.watch(storageServiceProvider),
        ));

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(_loginUseCaseProvider),
    ref.watch(_logoutUseCaseProvider),
    ref.watch(_checkSessionUseCaseProvider),
  );
});
