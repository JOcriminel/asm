import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';

class StationApiService {
  final Dio _dio;

  StationApiService(this._dio);

  Future<Map<String, dynamic>> fetchStation(String id) async {
    try {
      final response = await _dio.get('/station/$id');
      if (response.data != null) {
        dynamic data = response.data;

        // If response came back as a raw string, decode it
        if (data is String && data.trim().isNotEmpty) {
          data = json.decode(data.trim());
        }

        // The remote viewStation API returns [{...}] — an array with one element
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map<String, dynamic>) return first;
          if (first is Map) return Map<String, dynamic>.from(first);
        }

        // If already a plain map, return directly
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      throw UnknownApiException('Empty or unexpected response from station details endpoint');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final stationApiServiceProvider = Provider<StationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return StationApiService(dio);
});
