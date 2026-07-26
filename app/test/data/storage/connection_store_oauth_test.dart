import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/domain/models/oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for OAuth session persistence in ConnectionStore against an
/// in-memory [KeyValueStore] fake — FlutterSecureStorage is never
/// instantiated in tests (platform channel).
void main() {
  group('ConnectionStore OAuth session', () {
    test('loadOAuthSession returns null when nothing was saved', () async {
      final store = ConnectionStore(InMemoryKeyValueStore());
      expect(await store.loadOAuthSession(), isNull);
    });

    test('save/load round-trips an OAuth session', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);
      final session = OAuthSession(
        accessToken: 'at-secret',
        refreshToken: 'rt-secret',
        expiresAt: 1700000000,
        provider: 'nous',
      );

      await store.saveOAuthSession(session);
      final loaded = await store.loadOAuthSession();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'at-secret');
      expect(loaded.refreshToken, 'rt-secret');
      expect(loaded.expiresAt, 1700000000);
      expect(loaded.provider, 'nous');
      expect(loaded, session);
    });

    test('clearOAuthSession drops the stored session', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);
      await store.saveOAuthSession(
        const OAuthSession(
          accessToken: 'at-secret',
          refreshToken: 'rt-secret',
          expiresAt: 1700000000,
          provider: 'nous',
        ),
      );

      await store.clearOAuthSession();

      expect(await store.loadOAuthSession(), isNull);
      expect(kv.values[ConnectionStore.oauthAccessTokenKey], isNull);
      expect(kv.values[ConnectionStore.oauthRefreshTokenKey], isNull);
      expect(kv.values[ConnectionStore.oauthExpiresAtKey], isNull);
      expect(kv.values[ConnectionStore.oauthProviderKey], isNull);
    });

    test('forget() wipes config AND OAuth session', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);
      await store.saveOAuthSession(
        const OAuthSession(
          accessToken: 'at-secret',
          refreshToken: 'rt-secret',
          expiresAt: 1700000000,
          provider: 'nous',
        ),
      );

      await store.forget();

      expect(await store.loadOAuthSession(), isNull);
      expect(kv.values, isEmpty);
    });

    test('a corrupt stored expiresAt is dropped instead of crashing', () async {
      final kv = InMemoryKeyValueStore()
        ..values[ConnectionStore.oauthAccessTokenKey] = 'at'
        ..values[ConnectionStore.oauthRefreshTokenKey] = 'rt'
        ..values[ConnectionStore.oauthExpiresAtKey] = 'not-a-number'
        ..values[ConnectionStore.oauthProviderKey] = 'nous';
      final store = ConnectionStore(kv);

      expect(await store.loadOAuthSession(), isNull);
      expect(kv.values, isEmpty); // clearOAuthSession was called
    });

    test('a partial stored session is dropped (missing fields)', () async {
      final kv = InMemoryKeyValueStore()
        ..values[ConnectionStore.oauthAccessTokenKey] = 'at'
        ..values[ConnectionStore.oauthProviderKey] = 'nous';
      final store = ConnectionStore(kv);

      expect(await store.loadOAuthSession(), isNull);
    });
  });
}

/// In-memory [KeyValueStore] fake for tests.
final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
