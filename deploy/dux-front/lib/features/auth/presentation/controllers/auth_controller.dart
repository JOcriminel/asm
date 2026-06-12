import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/auth/domain/models/user.dart';
import 'package:dux_front/features/auth/data/repositories/auth_repository.dart';
import 'package:dux_front/core/services/storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isChecking; // Initial startup session verification state
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

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final StorageService _storageService;

  static const _tokenKey = 'auth_token';

  AuthController(this._authRepository, this._storageService) : super(const AuthState()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = state.copyWith(isChecking: true, clearError: true);
    try {
      final persist = await _storageService.read('persist_session');
      final token = await _storageService.read(_tokenKey);

      if (persist == 'false') {
        await _storageService.delete(_tokenKey);
        await _storageService.delete('persist_session');
        state = state.copyWith(isChecking: false, clearUser: true);
        return;
      }

      if (token != null && token.isNotEmpty) {
        final user = await _authRepository.getCurrentUser(token);
        state = state.copyWith(user: user, isChecking: false);
      } else {
        state = state.copyWith(isChecking: false, clearUser: true);
      }
    } catch (e) {
      state = state.copyWith(isChecking: false, clearUser: true);
    }
  }

  Future<bool> login(String username, String password, bool rememberMe) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.login(username, password);
      
      if (rememberMe) {
        await _storageService.write('persist_session', 'true');
      } else {
        await _storageService.write('persist_session', 'false');
      }
      
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
      await _authRepository.logout();
      await _storageService.delete(_tokenKey);
      state = const AuthState(isChecking: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthController(authRepository, storageService);
});
