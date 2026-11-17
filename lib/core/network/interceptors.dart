import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';

/// Marks a request that must not carry / refresh a token (login, register...).
const String kNoAuth = 'noAuth';

/// Attaches the access token and transparently refreshes it on 401, then
/// replays the original request, so the user is never logged out unexpectedly.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage tokens,
    required Future<String?> Function() refresh,
  })  : _dio = dio,
        _tokens = tokens,
        _refresh = refresh;

  final Dio _dio;
  final TokenStorage _tokens;
  final Future<String?> Function() _refresh;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[kNoAuth] != true) {
      final token = await _tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    if (!is401 ||
        options.extra[kNoAuth] == true ||
        options.extra['authRetried'] == true) {
      return handler.next(err);
    }

    final newToken = await _refresh();
    if (newToken == null) return handler.next(err);

    options.extra['authRetried'] = true;
    options.headers['Authorization'] = 'Bearer $newToken';
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Retries idempotent requests on connectivity problems / 5xx with
/// exponential backoff (400ms, 800ms, 1600ms), at most [maxRetries] times.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio, this.maxRetries = 3}) : _dio = dio;

  final Dio _dio;
  final int maxRetries;

  bool _shouldRetry(DioException e) {
    final method = e.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        return (e.response?.statusCode ?? 0) >= 500;
      default:
        return false;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retryCount'] as int?) ?? 0;
    if (!_shouldRetry(err) || attempt >= maxRetries) {
      return handler.next(err);
    }
    options.extra['retryCount'] = attempt + 1;
    await Future<void>.delayed(Duration(milliseconds: 400 * (1 << attempt)));
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Debug-only log of method/url/status. Never logs headers or bodies, so
/// tokens and passwords cannot leak into logcat.
class DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('-> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('<- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('x  ${err.type.name} ${err.response?.statusCode ?? ''} '
        '${err.requestOptions.uri}');
    handler.next(err);
  }
}
