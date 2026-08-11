import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the bearer tokens live.
///
/// Keystore-backed `EncryptedSharedPreferences`, never plain SharedPreferences
/// and never a file — a rooted device or an `adb backup` should not hand
/// somebody a 30-day session. Nothing here is ever logged.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessKey = 'xdr.access';
  static const _refreshKey = 'xdr.refresh';

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
