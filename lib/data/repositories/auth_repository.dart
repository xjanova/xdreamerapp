import 'package:dio/dio.dart';

import '../../core/net/api_client.dart';
import '../../core/net/api_exception.dart';
import '../../core/net/token_store.dart';
import '../models/session.dart';

/// Sign-in, session restore and sign-out.
///
/// Login and refresh deliberately go through [ApiClient.unauthenticated] — they
/// must not be retried by the bearer interceptor.
class AuthRepository {
  AuthRepository({required ApiClient client, required TokenStore tokens})
      : _client = client,
        _tokens = tokens;

  final ApiClient _client;
  final TokenStore _tokens;

  Future<MobileSession> login({required String email, required String password}) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _client.unauthenticated.post<Map<String, dynamic>>(
        '/api/mobile/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
    } catch (error) {
      throw ApiException.from(error);
    }

    final result = AuthResult.fromJson(response.data ?? const {});
    if (!result.isUsable) {
      throw ApiException('เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่');
    }

    await _tokens.save(access: result.accessToken, refresh: result.refreshToken);
    return result.session;
  }

  /// Cold start: is there still a usable session on this device?
  ///
  /// Returns null rather than throwing when there is simply nobody signed in —
  /// that is the normal first-launch path, not an error.
  Future<MobileSession?> restore() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final data = await _client.getJson('/api/mobile/me');
      return MobileSession.fromJson(data);
    } on ApiException catch (error) {
      // The interceptor already tried a refresh. A 401 here means the refresh
      // token is dead too.
      if (error.isAuthFailure) {
        await _tokens.clear();
        return null;
      }
      // A network blip must not silently sign the customer out — let the
      // caller decide whether to retry or show the error.
      rethrow;
    }
  }

  Future<MobileSession> refreshSession() async {
    final data = await _client.getJson('/api/mobile/me');
    return MobileSession.fromJson(data);
  }

  /// Tokens are stateless, so signing out is entirely local: forget them.
  Future<void> logout() => _tokens.clear();
}
