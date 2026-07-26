import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/oauth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const String usernameKey = 'connection.username';
  static const String providerKey = 'connection.auth_provider';
  static const String cookiesKey = 'connection.session_cookies';
  static const String oauthAccessTokenKey = 'connection.oauth_access_token';
  static const String oauthRefreshTokenKey = 'connection.oauth_refresh_token';
  static const String oauthExpiresAtKey = 'connection.oauth_expires_at';
  static const String oauthProviderKey = 'connection.oauth_provider';

  /// Save (or overwrite) the stored connection. A null token clears any
  /// previously stored token; a null username clears any stored username.
  Future<void> save(ConnectionConfig config) async {
    await _store.write(baseUrlKey, config.baseUrl);
    await _store.write(authModeKey, config.authMode.name);
    final token = config.token;
    if (token == null) {
      await _store.delete(tokenKey);
    } else {
      await _store.write(tokenKey, token);
    }
    final username = config.username;
    if (username == null) {
      await _store.delete(usernameKey);
    } else {
      await _store.write(usernameKey, username);
    }
    final provider = config.authProvider;
    if (provider == null) {
      await _store.delete(providerKey);
    } else {
      await _store.write(providerKey, provider);
    }
  }

  /// Load the stored connection, or null when none was saved.
  ///
  /// Unknown auth-mode values coerce to [AuthMode.token]. A corrupt base
  /// URL is dropped rather than crashing the app on boot.
  Future<ConnectionConfig?> load() async {
    final baseUrl = await _store.read(baseUrlKey);
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }

    final authModeRaw = await _store.read(authModeKey);
    final token = await _store.read(tokenKey);
    final username = await _store.read(usernameKey);
    final provider = await _store.read(providerKey);
    final authMode = AuthMode.values.asNameMap()[authModeRaw] ?? AuthMode.token;

    try {
      return ConnectionConfig(
        baseUrl: baseUrl,
        token: token,
        authMode: authMode,
        username: username,
        authProvider: provider,
      );
    } on ArgumentError {
      await forget();
      return null;
    }
  }

  /// Persist the gated-mode session cookies (JSON-encoded name→value map).
  ///
  /// These are session tokens — they live in secure storage and are wiped
  /// by [forget] / [clearSessionCookies]. The password is NEVER stored.
  Future<void> saveSessionCookies(String cookiesJson) async {
    await _store.write(cookiesKey, cookiesJson);
  }

  /// The previously stored cookies JSON, or null.
  Future<String?> loadSessionCookies() => _store.read(cookiesKey);

  /// Drop just the session cookies (session expired / logout).
  Future<void> clearSessionCookies() async {
    await _store.delete(cookiesKey);
  }

  /// Persist the OAuth session tokens (access, refresh, expires_at, provider).
  ///
  /// These are session tokens — they live in secure storage and are wiped by
  /// [forget] / [clearOAuthSession]. The tokens are NEVER stored anywhere else.
  Future<void> saveOAuthSession(OAuthSession session) async {
    await _store.write(oauthAccessTokenKey, session.accessToken);
    await _store.write(oauthRefreshTokenKey, session.refreshToken);
    await _store.write(oauthExpiresAtKey, session.expiresAt.toString());
    await _store.write(oauthProviderKey, session.provider);
  }

  /// The previously stored OAuth session, or null.
  Future<OAuthSession?> loadOAuthSession() async {
    final accessToken = await _store.read(oauthAccessTokenKey);
    final refreshToken = await _store.read(oauthRefreshTokenKey);
    final expiresAtRaw = await _store.read(oauthExpiresAtKey);
    final provider = await _store.read(oauthProviderKey);

    if (accessToken == null ||
        refreshToken == null ||
        expiresAtRaw == null ||
        provider == null) {
      return null;
    }

    final expiresAt = int.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      await clearOAuthSession();
      return null;
    }

    return OAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      provider: provider,
    );
  }

  /// Drop just the OAuth session (session expired / logout).
  Future<void> clearOAuthSession() async {
    await _store.delete(oauthAccessTokenKey);
    await _store.delete(oauthRefreshTokenKey);
    await _store.delete(oauthExpiresAtKey);
    await _store.delete(oauthProviderKey);
  }

  /// Forget the stored connection entirely.
  Future<void> forget() async {
    await _store.delete(baseUrlKey);
    await _store.delete(authModeKey);
    await _store.delete(tokenKey);
    await _store.delete(usernameKey);
    await _store.delete(providerKey);
    await _store.delete(cookiesKey);
    await clearOAuthSession();
  }
}
