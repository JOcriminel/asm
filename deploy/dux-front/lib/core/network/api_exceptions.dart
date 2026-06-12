import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Session expired. Please log in again.']) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Access denied.']) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message, [super.statusCode = 404]);
}

class ServerException extends ApiException {
  ServerException(super.message, [super.statusCode = 500]);
}

class UnknownApiException extends ApiException {
  UnknownApiException(super.message, [super.statusCode]);
}

class ApiExceptionHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timeout. Please check your internet connection.');
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
            return UnknownApiException('Request failed with status $statusCode: $message', statusCode);
          }
        case DioExceptionType.cancel:
          return NetworkException('Request was cancelled.');
        case DioExceptionType.connectionError:
          return NetworkException('Connection error. Could not connect to the server.');
        default:
          return NetworkException('Network error occurred. Please try again.');
      }
    } else if (error is ApiException) {
      return error;
    }
    return UnknownApiException(error.toString());
  }
}
