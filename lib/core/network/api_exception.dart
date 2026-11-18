import 'package:dio/dio.dart';

enum ApiErrorType {
  noInternet,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  rateLimited,
  server,
  cancelled,
  unknown,
}

/// Persian messages for the server's machine-readable `error.code` values.
const Map<String, String> _messagesFa = {
  'invalid_credentials': 'ایمیل یا رمز عبور اشتباه است',
  'account_not_verified': 'حساب شما هنوز تأیید نشده است',
  'account_disabled': 'این حساب غیرفعال شده است',
  'email_already_exists': 'این ایمیل قبلاً ثبت شده است',
  'username_already_exists': 'این نام کاربری قبلاً گرفته شده است',
  'invalid_email': 'ایمیل معتبر نیست',
  'weak_password': 'رمز عبور ضعیف است (حداقل ۸ کاراکتر)',
  'invalid_otp': 'کد تأیید اشتباه است',
  'otp_expired': 'کد تأیید منقضی شده؛ کد جدید دریافت کنید',
  'otp_attempts_exceeded': 'تعداد تلاش‌ها زیاد بود؛ کد جدید دریافت کنید',
  'user_not_found': 'حسابی با این ایمیل پیدا نشد',
  'already_favorited': 'این آهنگ قبلاً لایک شده است',
  'already_in_playlist': 'این آهنگ قبلاً در پلی‌لیست است',
  'track_not_found': 'آهنگ پیدا نشد',
};

/// Domain-level error shown to the user. UI never sees [DioException].
class ApiException implements Exception {
  const ApiException(this.type, this.message, {this.statusCode, this.code});

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  /// Server `error.code`, e.g. `account_not_verified`.
  final String? code;

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
    final status = r?.statusCode ?? 0;
    final err = _parseError(r?.data);
    final detail = _messagesFa[err.code] ?? err.message;

    ApiException make(ApiErrorType t, String fallback) => ApiException(
        t, detail ?? fallback,
        statusCode: status, code: err.code);

    switch (status) {
      case 400:
      case 422:
        return make(ApiErrorType.validation, 'اطلاعات واردشده معتبر نیست');
      case 401:
        return make(ApiErrorType.unauthorized, 'احراز هویت ناموفق بود');
      case 403:
        return make(ApiErrorType.forbidden, 'دسترسی مجاز نیست');
      case 404:
        return make(ApiErrorType.notFound, 'مورد یافت نشد');
      case 409:
        return make(ApiErrorType.conflict, 'مورد تکراری است');
      case 429:
        return make(ApiErrorType.rateLimited,
            'درخواست‌های زیاد؛ حدود یک دقیقه صبر کنید');
      default:
        if (status >= 500) {
          return ApiException(ApiErrorType.server, 'خطای سرور، دوباره تلاش کنید',
              statusCode: status);
        }
        return make(ApiErrorType.unknown, 'خطایی رخ داد');
    }
  }

  /// Spec format: {"error": {"code": "...", "message": "...", "details": {}}}
  static ({String? code, String? message}) _parseError(dynamic data) {
    if (data is Map) {
      final e = data['error'];
      if (e is Map) {
        return (code: e['code']?.toString(), message: e['message']?.toString());
      }
      final d = data['detail'] ?? data['message'];
      if (d is String) return (code: null, message: d);
    }
    return (code: null, message: null);
  }

  @override
  String toString() => 'ApiException($type, $statusCode, $code, $message)';
}

String errorText(Object e) =>
    e is ApiException ? e.message : 'خطای غیرمنتظره رخ داد';
