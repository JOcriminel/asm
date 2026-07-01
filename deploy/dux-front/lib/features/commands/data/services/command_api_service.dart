import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/command.dart';

class CommandApiService {
  final Dio _dio;

  CommandApiService(this._dio);

  Future<List<dynamic>> fetchCommandsList({
    required CommandFilter filter,
    String? userStationId,
    String? userId,
    String? userTierId,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');

      final now = DateTime.now();
      final defaultFrom = DateTime(now.year, now.month, 1);
      final defaultTo = DateTime(now.year, now.month + 1, 0);

      final fromStr =
          filter.dateFrom != null ? '${formatter.format(filter.dateFrom!)} 00:00:00' : '${formatter.format(defaultFrom)} 00:00:00';
      final toStr =
          filter.dateTo != null ? '${formatter.format(filter.dateTo!)} 23:59:59' : '${formatter.format(defaultTo)} 23:59:59';
      
      final idTierStr = (filter.tier != null && filter.tier!.isNotEmpty)
          ? filter.tier!
          : (userId != null && userId.isNotEmpty ? userId : 'all');
      final represStr =
          (filter.representative != null && filter.representative!.isNotEmpty)
              ? filter.representative!
              : (userTierId != null && userTierId.isNotEmpty ? userTierId : 'all');
      final codeDocStr = (filter.documentCode != null && filter.documentCode!.isNotEmpty)
          ? filter.documentCode!
          : 'BCC';
      final idEtatStr =
          (filter.status != null && filter.status!.isNotEmpty)
              ? filter.status!
              : 'all';

      // The 7th segment controls inclusion of all documents; default is false (no extra inclusion)
      const allStr = 'false';
      // allDocuments: whether to return all document types (true) or just a subset
      final allDocsStr = filter.allDocuments ? 'true' : 'false';
      final idArticleStr =
          (filter.articleFilter != null && filter.articleFilter!.isNotEmpty)
              ? filter.articleFilter!
              : 'null';
      final affichAvancStr = filter.advancedFilterActive ? 'true' : 'false';

      final path = '/list-documents/'
          '$fromStr/'
          '$toStr/'
          '$idTierStr/'
          '$represStr/'
          '$codeDocStr/'
          '$idEtatStr/'
          '$allStr/'
          '$allDocsStr/'
          '$idArticleStr/'
          '$affichAvancStr';

      // The DUX PHP API expects no body for this endpoint
      final response = await _dio.post(
        path,
        queryParameters: userStationId != null && userStationId.isNotEmpty && userStationId != 'Default Station'
            ? {'stationId': userStationId}
            : null,
      );

      if (response.data == null) return [];

      dynamic data = response.data;

      // Dio may return it as a String if Content-Type wasn't application/json
      if (data is String && data.trim().isNotEmpty) {
        try {
          data = json.decode(data.trim());
        } catch (_) {
          return [];
        }
      }

      // Check for API-level error/success envelope from the DUX PHP API
      if (data is Map<String, dynamic>) {
        final status = data['status']?.toString();
        if (status == 'error') {
          final msg = data['data']?.toString() ?? '';

          // "Undefined offset: 0", "count():", and "array_key_exists()" are PHP empty-result bugs in the DUX API:
          // when no documents are found, PHP tries to access arrays incorrectly and crashes. 
          // Treat it as an empty list, NOT an error.
          if (msg.contains('Undefined offset') || msg.contains('count():') || msg.contains('array_key_exists')) {
            return [];
          }

          // Any other API error → propagate
          throw Exception('API error: $msg');
        }

        // DUX success envelope: {"data":[...], "totalMntTTc":"...", "recordsTotal":N}
        // The records list is always in the "data" field
        final inner = data['data'] ?? data['content'] ?? data['results'] ?? data['documents'];
        if (inner is List) {
          return inner;
        }
        // Single result wrapped in a map — treat as a one-item list
        return [data];
      }

      if (data is List) {
        return data;
      }

      return [];
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final commandApiServiceProvider = Provider<CommandApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CommandApiService(dio);
});

