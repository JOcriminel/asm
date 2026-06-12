import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exceptions.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final Map<String, dynamic> requestBody = {
        'grant_type': 'password',
        'client_id': AppConfig.keycloakClientId,
        'username': username.trim(),
        'password': password,
      };

      if (AppConfig.keycloakClientSecret.isNotEmpty) {
        requestBody['client_secret'] = AppConfig.keycloakClientSecret;
      }

      final response = await _dio.post(
        AppConfig.keycloakTokenUrl,
        data: requestBody,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else {
        throw UnknownApiException(
          'Invalid response from authentication server',
        );
      }
    } catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio);
});
