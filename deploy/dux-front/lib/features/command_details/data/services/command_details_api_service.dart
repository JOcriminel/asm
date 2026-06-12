import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';

class CommandDetailsApiService {
  final Dio _dio;

  CommandDetailsApiService(this._dio);

  Future<Map<String, dynamic>> fetchCommandDetails(String id) async {
    try {
      final response = await _dio.get('/document/$id');
      if (response.data != null) {
        final dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is String) {
          return json.decode(data) as Map<String, dynamic>;
        }
      }
      throw UnknownApiException('Empty response from command details endpoint');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final commandDetailsApiServiceProvider = Provider<CommandDetailsApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CommandDetailsApiService(dio);
});
