import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Session expired. Please log in again.']) : super(message, 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException([String message = 'Access denied.']) : super(message, 403);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.statusCode = 404]);
}

class ServerException extends AppException {
  const ServerException(super.message, [super.statusCode = 500]);
}

class UnknownAppException extends AppException {
  const UnknownAppException(super.message, [super.statusCode]);
}

typedef ApiException = AppException;
typedef UnknownApiException = UnknownAppException;

class ApiExceptionHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException('Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final response = error.response;
          final statusCode = response?.statusCode;
          final statusMessage = response?.statusMessage ?? 'An error occurred';
          
          String message = statusMessage;
          if (response?.data != null && response?.data is Map) {
            final data = response!.data as Map<String, dynamic>;
            message = data['error'] ?? data['message'] ?? data['detail'] ?? statusMessage;
          } else if (response?.data != null && response?.data is String) {
            message = response!.data.toString();
          }

          if (statusCode == 401) {
            return UnauthorizedException(message);
          } else if (statusCode == 403) {
            return ForbiddenException(message);
          } else if (statusCode == 404) {
            return NotFoundException(message, statusCode);
          } else if (statusCode != null && statusCode >= 500) {
            return ServerException('Server error ($statusCode): $message', statusCode);
          } else {
            return UnknownAppException('Request failed with status $statusCode: $message', statusCode);
          }
        case DioExceptionType.cancel:
          return const NetworkException('Request was cancelled.');
        case DioExceptionType.connectionError:
          return const NetworkException('Connection error. Could not connect to the server.');
        default:
          return const NetworkException('Network error occurred. Please try again.');
      }
    } else if (error is AppException) {
      return error;
    }
    return UnknownAppException(error.toString());
  }
}

