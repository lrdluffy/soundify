class AppConfig {
  AppConfig._();

  static const String origin = 'https://soundify.easyfound.ir';
  static const String baseUrl = '$origin/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  static const int maxRetries = 3;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int otpResendSeconds = 60;
}
