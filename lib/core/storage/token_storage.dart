import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens live ONLY in the platform keystore-backed secure
/// storage (EncryptedSharedPreferences on Android). Never in SharedPreferences.
class TokenStorage {
  TokenStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _kAccess = 'soundify_access_token';
  static const _kRefresh = 'soundify_refresh_token';

  final FlutterSecureStorage _storage;

  String? _access;
  String? _refresh;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
    _loaded = true;
  }

  Future<String?> get accessToken async {
    await _ensureLoaded();
    return _access;
  }

  Future<String?> get refreshToken async {
    await _ensureLoaded();
    return _refresh;
  }

  Future<bool> get hasSession async {
    await _ensureLoaded();
    return (_refresh ?? _access) != null;
  }

  Future<void> save({required String access, String? refresh}) async {
    await _ensureLoaded();
    _access = access;
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null) {
      _refresh = refresh;
      await _storage.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
