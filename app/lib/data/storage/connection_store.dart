import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hermes/data/transport/connection_config.dart';

/// Minimal key-value abstraction so persistence is testable without platform
/// channels. The concrete implementation wraps [FlutterSecureStorage] —
/// everything connection-related (base URL, auth mode, token) counts as
/// sensitive, so it all lives in secure storage.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [KeyValueStore] backed by `flutter_secure_storage`
/// (keychain/keystore on mobile, libsecret on Linux).
///
/// Never instantiate this in unit tests — it requires a platform channel.
/// Use an in-memory fake instead.
final class SecureKeyValueStore implements KeyValueStore {
  const SecureKeyValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists the [ConnectionConfig] between app launches (ticket P0-04).
final class ConnectionStore {
  const ConnectionStore(this._store);

  final KeyValueStore _store;

  static const String baseUrlKey = 'connection.base_url';
  static const String authModeKey = 'connection.auth_mode';
  static const String tokenKey = 'connection.token';

  /// Save (or overwrite) the stored connection. A null token clears any
  /// previously stored token.
  Future<void> save(ConnectionConfig config) async {
    await _store.write(baseUrlKey, config.baseUrl);
    await _store.write(authModeKey, config.authMode.name);
    final token = config.token;
    if (token == null) {
      await _store.delete(tokenKey);
    } else {
      await _store.write(tokenKey, token);
    }
  }

  /// Load the stored connection, or null when none was saved.
  ///
  /// Unknown auth-mode values coerce to [AuthMode.token] (mirrors
  /// `normAuthMode`). A corrupt base URL is dropped rather than crashing the
  /// app on boot.
  Future<ConnectionConfig?> load() async {
    final baseUrl = await _store.read(baseUrlKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }

    final authModeRaw = await _store.read(authModeKey);
    final token = await _store.read(tokenKey);
    final authMode = authModeRaw == AuthMode.oauth.name
        ? AuthMode.oauth
        : AuthMode.token;

    try {
      return ConnectionConfig(
        baseUrl: baseUrl,
        token: token,
        authMode: authMode,
      );
    } on ArgumentError {
      await forget();
      return null;
    }
  }

  /// Forget the stored connection entirely.
  Future<void> forget() async {
    await _store.delete(baseUrlKey);
    await _store.delete(authModeKey);
    await _store.delete(tokenKey);
  }
}
