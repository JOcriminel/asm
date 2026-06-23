import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/core/utils/logger.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/data/dto/timetree_dashboard_dto.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_dashboard.dart';

/// Repository responsible for fetching and mapping the TimeTree dashboard data.
///
/// Uses the shared [dioProvider] (auth-intercepted, base-URL configured) via
/// [TimetreeApi].  No local Dio() instantiation.
class TimetreeDashboardRepository {
  TimetreeDashboardRepository(this._api);

  final TimetreeApi _api;

  /// Calls GET /api/timetree/dashboard and returns a [TimetreeDashboard].
  ///
  /// If the server returns an unexpected structure or null body, a
  /// [TimetreeDashboard.empty()] is returned so the UI degrades gracefully.
  /// Network / auth errors are re-thrown as typed [ApiException]s so the
  /// provider and screen can show a proper error + retry UI.
  Future<TimetreeDashboard> getDashboard() async {
    try {
      final response = await _api.getDashboard();

      final data = response.data;
      if (data == null) {
        AppLogger.w(
          'TimetreeDashboardRepository',
          'GET /api/timetree/dashboard returned null body — using empty dashboard',
        );
        return const TimetreeDashboard.empty();
      }

      if (data is! Map<String, dynamic>) {
        AppLogger.w(
          'TimetreeDashboardRepository',
          'Unexpected response type: ${data.runtimeType} — using empty dashboard',
        );
        return const TimetreeDashboard.empty();
      }

      final dto = TimetreeDashboardDto.fromJson(data);
      return TimetreeDashboard.fromDto(dto);
    } catch (e) {
      AppLogger.e(
        'TimetreeDashboardRepository',
        'Failed to fetch dashboard',
        e,
      );
      throw ApiExceptionHandler.handle(e);
    }
  }
}

/// Riverpod provider for [TimetreeDashboardRepository].
///
/// Depends on [dioProvider] so the shared auth-intercepted Dio instance is
/// always used — consistent with how [timetreeMenuProvider] is wired.
final timetreeDashboardRepositoryProvider =
    Provider<TimetreeDashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeDashboardRepository(TimetreeApi(dio));
});
