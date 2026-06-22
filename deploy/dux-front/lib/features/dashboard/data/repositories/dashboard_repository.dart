import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/utils/logger.dart';

class DashboardStats {
  final int scansCount;
  final int deletionsCount;
  final int checklistResponsesCount;
  final int totalCommands;
  final double totalRevenue;
  final double avgAccuracy;

  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> byStatus;
  final List<Map<String, dynamic>> timeline;
  final List<Map<String, dynamic>> operatorPerformance;

  DashboardStats({
    required this.scansCount,
    required this.deletionsCount,
    required this.checklistResponsesCount,
    required this.totalCommands,
    required this.totalRevenue,
    required this.avgAccuracy,
    required this.byType,
    required this.byStatus,
    required this.timeline,
    required this.operatorPerformance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final docStats = json['documentStats'] as Map<String, dynamic>? ?? {};

    return DashboardStats(
      scansCount: (summary['scansCount'] ?? 0).toInt(),
      deletionsCount: (summary['deletionsCount'] ?? 0).toInt(),
      checklistResponsesCount: (summary['checklistResponsesCount'] ?? 0).toInt(),
      totalCommands: (summary['totalCommands'] ?? 0).toInt(),
      totalRevenue: (summary['totalRevenue'] ?? 0.0).toDouble(),
      avgAccuracy: (summary['avgAccuracy'] ?? 100.0).toDouble(),
      byType: List<Map<String, dynamic>>.from(docStats['byType'] ?? []),
      byStatus: List<Map<String, dynamic>>.from(docStats['byStatus'] ?? []),
      timeline: List<Map<String, dynamic>>.from(json['timeline'] ?? []),
      operatorPerformance: List<Map<String, dynamic>>.from(json['operatorPerformance'] ?? []),
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
      return DashboardStats(
        scansCount: 0,
        deletionsCount: 0,
        checklistResponsesCount: 0,
        totalCommands: 0,
        totalRevenue: 0.0,
        avgAccuracy: 100.0,
        byType: const [],
        byStatus: const [],
        timeline: const [],
        operatorPerformance: const [],
      );
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
