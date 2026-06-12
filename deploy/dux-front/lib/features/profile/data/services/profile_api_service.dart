import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';

class ProfileApiService {
  final Dio _dio;

  ProfileApiService(this._dio);

  Future<Map<String, dynamic>> fetchUserProfile(String login) async {
    try {
      final response = await _dio.get(
        '/user',
        queryParameters: {'login': login},
      );
      if (response.data != null) {
        final dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is String) {
          return json.decode(data) as Map<String, dynamic>;
        }
      }
      throw UnknownApiException('Empty response from user profile endpoint');
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final profileApiServiceProvider = Provider<ProfileApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileApiService(dio);
});
