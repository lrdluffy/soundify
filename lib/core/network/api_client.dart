import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../storage/token_storage.dart';
import 'api_contract.dart';
import 'api_exception.dart';
import 'interceptors.dart';

class TokenPair {
  const TokenPair(this.access, this.refresh);
  final String access;
  final String? refresh;

  /// Tolerates both flat and `{ "data": {...} }` wrapped responses.
  static TokenPair? tryParse(dynamic body) {
    if (body is! Map) return null;
    Map source = body;
    String? pick(Map m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    var access = pick(source, ResponseKeys.accessToken);
    if (access == null && body['data'] is Map) {
      source = body['data'] as Map;
      access = pick(source, ResponseKeys.accessToken);
    }
    if (access == null) return null;
    return TokenPair(access, pick(source, ResponseKeys.refreshToken));
  }
}

class ApiClient {
  ApiClient({required TokenStorage tokens}) : _tokens = tokens {
    final options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    dio = Dio(options);
    // Separate client for the refresh call, so it can never recurse through
    // the interceptors below.
    _bare = Dio(options);

    dio.interceptors.addAll([
      if (kDebugMode) DebugLogInterceptor(),
      AuthInterceptor(dio: dio, tokens: _tokens, refresh: _refreshAccessToken),
      RetryInterceptor(dio: dio, maxRetries: AppConfig.maxRetries),
    ]);
  }

  late final Dio dio;
  late final Dio _bare;
  final TokenStorage _tokens;

  /// Called when the refresh token itself is rejected -> user must log in again.
  Future<void> Function()? onSessionExpired;

  Future<String?>? _refreshing;

  /// Single-flight: concurrent 401s share one refresh call.
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) {
      await _expire();
      return null;
    }
    try {
      final res = await _bare.post<dynamic>(
        Endpoints.refresh,
        data: {Keys.refreshToken: refresh},
      );
      final pair = TokenPair.tryParse(res.data);
      if (pair == null) {
        await _expire();
        return null;
      }
      await _tokens.save(access: pair.access, refresh: pair.refresh);
      return pair.access;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // Only a definitive rejection ends the session; a network blip does not.
      if (code == 400 || code == 401 || code == 403 || code == 422) {
        await _expire();
      }
      return null;
    }
  }

  Future<void> _expire() async {
    await _tokens.clear();
    await onSessionExpired?.call();
  }

  // ---- typed helpers: always throw ApiException, never DioException ----

  Future<dynamic> get(String path,
          {Map<String, dynamic>? query, bool auth = true, CancelToken? cancel}) =>
      _run(() => dio.get<dynamic>(path,
          queryParameters: query,
          cancelToken: cancel,
          options: _opts(auth)));

  Future<dynamic> post(String path, {Object? data, bool auth = true}) =>
      _run(() => dio.post<dynamic>(path, data: data, options: _opts(auth)));

  Future<dynamic> patch(String path, {Object? data}) =>
      _run(() => dio.patch<dynamic>(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _run(() => dio.put<dynamic>(path, data: data));

  Future<dynamic> delete(String path) => _run(() => dio.delete<dynamic>(path));

  Options _opts(bool auth) => Options(extra: {kNoAuth: !auth});

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      return (await call()).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
