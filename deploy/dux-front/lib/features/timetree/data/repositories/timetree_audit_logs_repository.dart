import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/network/dio_client.dart';
import 'package:dux_front/core/network/api_exceptions.dart';
import 'package:dux_front/features/timetree/data/timetree_api.dart';
import 'package:dux_front/features/timetree/domain/models/timetree_audit_log.dart';

class TimetreeAuditLogsRepository {
  final TimetreeApi _api;

  TimetreeAuditLogsRepository(this._api);

  Future<List<TimetreeAuditLog>> getAuditLogs({
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final response = await _api.getAuditLogs(
        username: username,
        action: action,
        entityType: entityType,
        entityId: entityId,
        startDate: startDate,
        endDate: endDate,
        search: search,
      );

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TimetreeAuditLog.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<List<int>> downloadAuditLogsCsv({
    String? username,
    String? action,
    String? entityType,
    String? entityId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final response = await _api.downloadAuditLogsCsv(
        username: username,
        action: action,
        entityType: entityType,
        entityId: entityId,
        startDate: startDate,
        endDate: endDate,
        search: search,
      );
      if (response.data is List<int>) {
        return response.data as List<int>;
      }
      throw Exception("Unexpected CSV response content");
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final timetreeAuditLogsRepositoryProvider = Provider<TimetreeAuditLogsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TimetreeAuditLogsRepository(TimetreeApi(dio));
});
