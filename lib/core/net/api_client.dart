import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The single way this app talks to `ai.xman4289.com`.
///
/// Two Dio instances on purpose:
///
/// * [_authed] carries the bearer token and knows how to refresh it.
/// * [_plain] does not, and is the only one that may call the login and refresh
///   endpoints — otherwise a 401 from `/auth/refresh` would trigger a refresh,
///   which would 401, forever.
class ApiClient {
  ApiClient({required TokenStore tokens, required VoidCallback onSessionLost})
    : _tokens = tokens,
      _onSessionLost = onSessionLost {
    AppConfig.assertTransportIsSafe();
    _authed.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _recoverOrGiveUp),
    );
    if (kDebugMode) {
      // Method, path and status only. Never headers (bearer token) and never
      // bodies (passwords, prompts).
      _authed.interceptors.add(_TerseLogInterceptor());
      _plain.interceptors.add(_TerseLogInterceptor());
    }
  }

  final TokenStore _tokens;
  final VoidCallback _onSessionLost;

  static BaseOptions _options() => BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    // Generous: `POST /api/generate` blocks until a synchronous provider
    // returns, and an image can take 40s on a busy pool.
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 60),
    headers: const {'Accept': 'application/json'},
    // Let the interceptor decide what a non-2xx means.
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  );

  final Dio _authed = Dio(_options());
  final Dio _plain = Dio(_options());

  /// For the auth repository only — login and refresh.
  Dio get unauthenticated => _plain;

  Future<void> _attachToken(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokens.readAccess();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _recoverOrGiveUp(DioException error, ErrorInterceptorHandler handler) async {
    final isAuthFailure = error.response?.statusCode == 401;
    final alreadyRetried = error.requestOptions.extra['xdr.retried'] == true;

    if (!isAuthFailure || alreadyRetried) {
      return handler.next(error);
    }

    final refreshed = await _refreshOnce();
    if (!refreshed) {
      // The refresh token is gone or rejected. Nothing the app can do but ask
      // for the password again.
      await _tokens.clear();
      _onSessionLost();
      return handler.next(error);
    }

    try {
      final retryOptions = error.requestOptions..extra['xdr.retried'] = true;
      final token = await _tokens.readAccess();
      if (token != null) retryOptions.headers['Authorization'] = 'Bearer $token';
      handler.resolve(await _authed.fetch<dynamic>(retryOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool>? _refreshInFlight;

  /// Several requests can 401 at the same instant when a token expires mid-
  /// screen. They all wait on one refresh rather than racing to burn the
  /// refresh token three times.
  Future<bool> _refreshOnce() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _performRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _plain.post<Map<String, dynamic>>(
        '/api/mobile/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = response.data;
      final access = data?['accessToken'];
      final nextRefresh = data?['refreshToken'];
      if (access is! String || nextRefresh is! String) return false;

      await _tokens.save(access: access, refresh: nextRefresh);
      return true;
    } on DioException {
      return false;
    }
  }

  // ── Verbs ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) => _send(() => _authed.get<dynamic>(path, queryParameters: query, cancelToken: cancelToken));

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    CancelToken? cancelToken,
    Duration? receiveTimeout,
  }) => _send(
    () => _authed.post<dynamic>(
      path,
      data: body,
      cancelToken: cancelToken,
      options: receiveTimeout == null ? null : Options(receiveTimeout: receiveTimeout),
    ),
  );

  Future<Map<String, dynamic>> deleteJson(String path, {Object? body, CancelToken? cancelToken}) =>
      _send(() => _authed.delete<dynamic>(path, data: body, cancelToken: cancelToken));

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      // Every endpoint in this API answers with a JSON object. Anything else
      // means we are talking to something that is not the API — a captive
      // portal, an error page, a proxy.
      throw ApiException('เซิร์ฟเวอร์ตอบกลับในรูปแบบที่ไม่รู้จัก');
    } catch (error) {
      throw ApiException.from(error);
    }
  }
}

class _TerseLogInterceptor extends Interceptor {
  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[api] ${response.requestOptions.method} '
      '${response.requestOptions.path} → ${response.statusCode}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[api] ${err.requestOptions.method} ${err.requestOptions.path} '
      '→ ${err.response?.statusCode ?? err.type.name}',
    );
    handler.next(err);
  }
}
