import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/client_filter.dart';

class ClientApiService {
  final Dio _dio;

  ClientApiService(this._dio);

  Future<List<dynamic>> fetchClientsList({
    required ClientFilter filter,
    required int first,
    required int rows,
    String? companyId,
    String? userId,
  }) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');

      final defaultFrom = DateTime(2000, 1, 1);
      final defaultTo = DateTime(2099, 12, 31);

      final fromStr = filter.startDate != null ? '${formatter.format(filter.startDate!)} 00:00:00' : '${formatter.format(defaultFrom)} 00:00:00';
      final toStr = filter.endDate != null ? '${formatter.format(filter.endDate!)} 23:59:59' : '${formatter.format(defaultTo)} 23:59:59';
      
      final typeTier = filter.typeTier;
      final cId = companyId ?? '11249'; // Default from user JSON
      final uId = userId ?? '11'; // Default from user JSON

      final path = '/tier/getAllTierByType/$typeTier/$cId/$uId/$fromStr/$toStr/false/false/false/false/false/false/dateTrans/false';

      // Body parameters
      final Map<String, dynamic> body = {
        "first": first,
        "rows": rows,
        "sortOrder": 1,
        "filters": {},
        "globalFilter": filter.searchTerm.isNotEmpty ? filter.searchTerm : null,
        "typeTier": [typeTier],
        "checkMail": false
      };

      final response = await _dio.post(path, data: body);

      if (response.data == null) return [];

      dynamic data = response.data;
      if (data is String && data.trim().isNotEmpty) {
        try {
          data = json.decode(data.trim());
        } catch (_) {
          return [];
        }
      }

      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is List) {
          return inner;
        }
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

final clientApiServiceProvider = Provider<ClientApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ClientApiService(dio);
});
