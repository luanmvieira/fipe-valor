import 'package:dio/dio.dart';

String networkErrorCause(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Verifique sua conexão com a internet.';
      case DioExceptionType.badResponse:
        return 'O servidor está indisponível no momento.';
      default:
        return 'Tente novamente.';
    }
  }
  return 'Tente novamente.';
}
