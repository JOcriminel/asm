import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';

class DashboardStats {
  final int scansToday;
  final int deletionsToday;
  final List<Map<String, dynamic>> scansLast7Days;
  final List<Map<String, dynamic>> scansByHour;

  DashboardStats({
    required this.scansToday,
    required this.deletionsToday,
    required this.scansLast7Days,
    required this.scansByHour,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      scansToday: json['scansToday'] ?? 0,
      deletionsToday: json['deletionsToday'] ?? 0,
      scansLast7Days: List<Map<String, dynamic>>.from(json['scansLast7Days'] ?? []),
      scansByHour: List<Map<String, dynamic>>.from(json['scansByHour'] ?? []),
    );
  }
}

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardStats> getStats({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _dio.get('/dashboard/stats', queryParameters: queryParams);
      if (response.data != null && response.data is Map<String, dynamic>) {
        return DashboardStats.fromJson(response.data);
      }
      return DashboardStats(scansToday: 0, deletionsToday: 0, scansLast7Days: [], scansByHour: []);
    } catch (e) {
      AppLogger.e('DashboardRepository', 'Failed to fetch stats', e);
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepository(dio);
});
