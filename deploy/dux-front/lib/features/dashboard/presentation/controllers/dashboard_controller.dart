import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats? stats;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(DashboardState()) {
    fetchStats();
  }

  Future<void> fetchStats({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final startStr = startDate?.toIso8601String().split('T').first;
      final endStr = endDate?.toIso8601String().split('T').first;
      final stats = await _repository.getStats(startDate: startStr, endDate: endStr);
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});
