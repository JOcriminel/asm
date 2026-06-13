import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/station.dart';
import '../../domain/usecases/get_station_use_case.dart';
import '../../data/repositories/station_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class StationState {
  final Station? station;
  final bool isLoading;
  final String? error;

  const StationState({
    this.station,
    this.isLoading = true,
    this.error,
  });

  StationState copyWith({
    Station? station,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StationState(
      station: station ?? this.station,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Depends on [GetStationUseCase] — Dependency Inversion applied.
class StationController extends StateNotifier<StationState> {
  final Ref _ref;
  final GetStationUseCase _getStationUseCase;
  bool _waitingForAuth = false;

  StationController(this._ref, this._getStationUseCase)
      : super(const StationState()) {
    Future.microtask(fetchStationDetails);
  }

  Future<void> fetchStationDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = _ref.read(authControllerProvider);

      if (authState.isChecking) {
        if (!_waitingForAuth) {
          _waitingForAuth = true;
          _ref.listen<AuthState>(authControllerProvider, (_, next) {
            if (!next.isChecking) {
              _waitingForAuth = false;
              fetchStationDetails();
            }
          });
        }
        return;
      }

      String stationId = authState.user?.station ?? '1';
      if (stationId.isEmpty || int.tryParse(stationId) == null) {
        stationId = '1';
      }

      final station = await _getStationUseCase(stationId);
      state = StationState(station: station, isLoading: false);
    } catch (e) {
      state = StationState(isLoading: false, error: e.toString());
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _getStationUseCaseProvider = Provider<GetStationUseCase>((ref) {
  return GetStationUseCase(ref.watch(stationRepositoryProvider));
});

final stationControllerProvider =
    StateNotifierProvider<StationController, StationState>((ref) {
  return StationController(ref, ref.watch(_getStationUseCaseProvider));
});
