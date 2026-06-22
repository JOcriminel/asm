import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';

class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://skimmed-reapprove-editor.ngrok-free.dev/api/dux',
  );

  static const String keycloakTokenUrl = String.fromEnvironment(
    'KEYCLOAK_TOKEN_URL',
    defaultValue:
        'https://duxweb.pre-produx.asmtechtn.com/auth/realms/DuxWeb/protocol/openid-connect/token',
  );

  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'asm-apis',
  );

  static const String keycloakClientSecret = String.fromEnvironment(
    'KEYCLOAK_CLIENT_SECRET',
    defaultValue: 'WIIWVngUsQgSTyXB50AXm1YyeVtaog7V',
  );
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));

  // Enable request and response logging for debug and testing visibility
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});
