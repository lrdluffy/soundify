import 'package:dio/dio.dart';

enum ApiErrorType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  server,
  cancelled,
  unknown,
}

/// Domain-level error shown to the user. UI never sees [DioException].
class ApiException implements Exception {
  const ApiException(this.type, this.message, {this.statusCode});

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  bool get isConnectivity =>
      type == ApiErrorType.noInternet || type == ApiErrorType.timeout;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            ApiErrorType.timeout, 'زمان اتصال به سرور به پایان رسید');
      case DioExceptionType.connectionError:
        return const ApiException(
            ApiErrorType.noInternet, 'اتصال به اینترنت برقرار نیست');
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorType.cancelled, 'درخواست لغو شد');
      case DioExceptionType.badCertificate:
        return const ApiException(
            ApiErrorType.unknown, 'گواهی امنیتی سرور معتبر نیست');
      case DioExceptionType.badResponse:
        return _fromStatus(e.response);
      case DioExceptionType.unknown:
        return const ApiException(ApiErrorType.unknown, 'خطایی رخ داد');
    }
  }

  static ApiException _fromStatus(Response<dynamic>? r) {
    final code = r?.statusCode ?? 0;
    final detail = _serverMessage(r?.data);
    switch (code) {
      case 400:
      case 422:
        return ApiException(
            ApiErrorType.validation, detail ?? 'اطلاعات واردشده معتبر نیست',
            statusCode: code);
      case 401:
        return ApiException(
            ApiErrorType.unauthorized, detail ?? 'احراز هویت ناموفق بود',
            statusCode: code);
      case 403:
        return ApiException(
            ApiErrorType.forbidden, detail ?? 'دسترسی مجاز نیست',
            statusCode: code);
      case 404:
        return ApiException(ApiErrorType.notFound, detail ?? 'مورد یافت نشد',
            statusCode: code);
      case 409:
        return ApiException(ApiErrorType.conflict, detail ?? 'مورد تکراری است',
            statusCode: code);
      default:
        if (code >= 500) {
          return ApiException(ApiErrorType.server, 'خطای سرور، دوباره تلاش کنید',
              statusCode: code);
        }
        return ApiException(ApiErrorType.unknown, detail ?? 'خطایی رخ داد',
            statusCode: code);
    }
  }

  /// FastAPI style: {"detail": "msg"} or {"detail": [{"msg": "..."}]}.
  static String? _serverMessage(dynamic data) {
    if (data is Map) {
      final d = data['detail'] ?? data['message'] ?? data['error'];
      if (d is String && d.isNotEmpty) return d;
      if (d is List && d.isNotEmpty) {
        final first = d.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
        return first.toString();
      }
    }
    return null;
  }

  @override
  String toString() => 'ApiException($type, $statusCode, $message)';
}

String errorText(Object e) =>
    e is ApiException ? e.message : 'خطای غیرمنتظره رخ داد';
