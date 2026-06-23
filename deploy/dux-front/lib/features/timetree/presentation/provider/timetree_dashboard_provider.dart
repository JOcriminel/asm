import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/features/timetree/data/repositories/timetree_dashboard_repository.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_dashboard.dart';

/// Exposes the TimeTree dashboard data as an async state.
///
/// Uses [FutureProvider.autoDispose] so the request is automatically
/// cancelled and the cache is released when the screen is no longer visible.
///
/// The screen calls `ref.invalidate(timetreeDashboardProvider)` to trigger
/// a retry on error — identical to the pattern used for [timetreeMenuProvider].
final timetreeDashboardProvider =
    FutureProvider.autoDispose<TimetreeDashboard>((ref) async {
  final repo = ref.watch(timetreeDashboardRepositoryProvider);
  return repo.getDashboard();
});
