import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/profile.dart';
import '../../domain/usecases/get_profile_use_case.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileState {
  final Profile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Depends on [GetProfileUseCase] — Dependency Inversion applied.
class ProfileController extends StateNotifier<ProfileState> {
  final Ref _ref;
  final GetProfileUseCase _getProfileUseCase;

  ProfileController(this._ref, this._getProfileUseCase) : super(const ProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final login = _ref.read(authControllerProvider).user?.username ?? 'admin';
      final profile = await _getProfileUseCase(login);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String location,
  }) async {
    if (state.profile == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      // Backend does not expose updateProfile API — simulate local change
      await Future.delayed(const Duration(milliseconds: 500));
      final updated = state.profile!.copyWith(
        fullName: fullName,
        email: email,
        phone: phone,
        location: location,
        cellule: location,
      );
      state = state.copyWith(profile: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref, ref.watch(_getProfileUseCaseProvider));
});
