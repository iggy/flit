import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/storage/connection_store.dart';
import 'package:hermes/data/transport/connection_config.dart';

/// Unit tests for ConnectionStore against an in-memory [KeyValueStore] fake —
/// FlutterSecureStorage is never instantiated in tests (platform channel).
void main() {
  group('ConnectionStore', () {
    test('load returns null when nothing was saved', () async {
      final store = ConnectionStore(InMemoryKeyValueStore());
      expect(await store.load(), isNull);
    });

    test('save/load round-trips a token-mode config', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);
      final config = ConnectionConfig(
        baseUrl: 'https://gw.example.com/hermes/',
        token: 'tok123',
      );

      await store.save(config);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.baseUrl, 'https://gw.example.com/hermes');
      expect(loaded.token, 'tok123');
      expect(loaded.authMode, AuthMode.token);
    });

    test(
      'save/load round-trips an oauth-mode config without a token',
      () async {
        final kv = InMemoryKeyValueStore();
        final store = ConnectionStore(kv);

        await store.save(
          ConnectionConfig(
            baseUrl: 'https://gw.example.com',
            authMode: AuthMode.oauth,
          ),
        );
        final loaded = await store.load();

        expect(loaded, isNotNull);
        expect(loaded!.authMode, AuthMode.oauth);
        expect(loaded.token, isNull);
      },
    );

    test('saving without a token clears a previously stored token', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);

      await store.save(
        ConnectionConfig(baseUrl: 'https://gw.example.com', token: 'tok123'),
      );
      await store.save(ConnectionConfig(baseUrl: 'https://gw.example.com'));

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.token, isNull);
      expect(kv.values[ConnectionStore.tokenKey], isNull);
    });

    test('forget clears everything', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);

      await store.save(
        ConnectionConfig(baseUrl: 'https://gw.example.com', token: 'tok123'),
      );
      await store.forget();

      expect(await store.load(), isNull);
      expect(kv.values, isEmpty);
    });

    test('a corrupt stored URL is dropped instead of crashing', () async {
      final kv = InMemoryKeyValueStore()
        ..values[ConnectionStore.baseUrlKey] = 'ftp://nope';
      final store = ConnectionStore(kv);

      expect(await store.load(), isNull);
      expect(kv.values, isEmpty);
    });

    test('an unknown stored auth mode coerces to token', () async {
      final kv = InMemoryKeyValueStore()
        ..values[ConnectionStore.baseUrlKey] = 'https://gw.example.com'
        ..values[ConnectionStore.authModeKey] = 'weird';
      final store = ConnectionStore(kv);

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.authMode, AuthMode.token);
    });

    test(
      'round-trips a gated config (username + provider, no password)',
      () async {
        final store = ConnectionStore(InMemoryKeyValueStore());
        final config = ConnectionConfig(
          baseUrl: 'https://gw.example.com/',
          authMode: AuthMode.password,
          username: 'iggy',
          authProvider: 'local',
        );

        await store.save(config);
        final loaded = await store.load();

        expect(loaded, config);
        expect(loaded!.authMode, AuthMode.password);
        expect(loaded.username, 'iggy');
        expect(loaded.authProvider, 'local');
        expect(loaded.token, isNull);
      },
    );

    test('persists and clears the session cookies JSON', () async {
      final store = ConnectionStore(InMemoryKeyValueStore());

      expect(await store.loadSessionCookies(), isNull);
      await store.saveSessionCookies('{"a":"1"}');
      expect(await store.loadSessionCookies(), '{"a":"1"}');
      await store.clearSessionCookies();
      expect(await store.loadSessionCookies(), isNull);
    });

    test('forget() wipes config AND session cookies', () async {
      final kv = InMemoryKeyValueStore();
      final store = ConnectionStore(kv);
      await store.save(
        ConnectionConfig(
          baseUrl: 'https://gw.example.com',
          authMode: AuthMode.password,
          username: 'iggy',
          authProvider: 'local',
        ),
      );
      await store.saveSessionCookies('{"a":"1"}');

      await store.forget();

      expect(await store.load(), isNull);
      expect(await store.loadSessionCookies(), isNull);
      expect(kv.values, isEmpty);
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
