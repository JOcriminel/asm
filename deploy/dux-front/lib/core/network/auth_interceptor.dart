import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../services/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  static const _tokenKey = 'auth_token';

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid injecting Bearer token for Keycloak token retrieval
    final isKeycloakTokenUrl = options.path.contains('/protocol/openid-connect/token');

    if (!isKeycloakTokenUrl) {
      final storageService = _ref.read(storageServiceProvider);
      final token = await storageService.read(_tokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Unauthorized or token expired. Trigger reactive logout.
      Future.microtask(() {
        _ref.read(authControllerProvider.notifier).logout();
      });
    }
    return handler.next(err);
  }
}
