import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/station.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/station_repository.dart';

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

class StationController extends StateNotifier<StationState> {
  final Ref _ref;
  bool _waitingForAuth = false;

  StationController(this._ref) : super(const StationState()) {
    // Defer fetch by one microtask so the auth controller's checkSession()
    // has a chance to run first (they both initialize via Riverpod providers).
    Future.microtask(fetchStationDetails);
  }

  Future<void> fetchStationDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authState = _ref.read(authControllerProvider);

      // If auth is still checking session, register a one-time listener and return.
      // Once auth finishes, we'll be called again automatically.
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

      // Extract the numeric station ID from user profile (e.g. "1")
      String stationId = authState.user?.station ?? '1';
      // Sanitise: fall back to "1" if not a valid integer string
      if (stationId.isEmpty || int.tryParse(stationId) == null) {
        stationId = '1';
      }

      final station = await _ref.read(stationRepositoryProvider).getStation(stationId);
      state = StationState(station: station, isLoading: false);
    } catch (e) {
      state = StationState(isLoading: false, error: e.toString());
    }
  }
}

final stationControllerProvider =
    StateNotifierProvider<StationController, StationState>((ref) {
  return StationController(ref);
});
