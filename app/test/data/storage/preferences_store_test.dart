import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for PreferencesStore against an in-memory [KeyValueStore] fake
/// (P9-01, P9-03, P9-07).
void main() {
  group('PreferencesStore', () {
    test('saveSkinEnabled/loadSkinEnabled round-trip', () async {
      final store = PreferencesStore(InMemoryKeyValueStore());

      // Default is false.
      expect(await store.loadSkinEnabled(), false);

      await store.saveSkinEnabled(true);
      expect(await store.loadSkinEnabled(), true);

      await store.saveSkinEnabled(false);
      expect(await store.loadSkinEnabled(), false);
    });

    test(
      'saveNotificationsEnabled/loadNotificationsEnabled round-trip',
      () async {
        final store = PreferencesStore(InMemoryKeyValueStore());

        // Default is false.
        expect(await store.loadNotificationsEnabled(), false);

        await store.saveNotificationsEnabled(true);
        expect(await store.loadNotificationsEnabled(), true);

        await store.saveNotificationsEnabled(false);
        expect(await store.loadNotificationsEnabled(), false);
      },
    );

    test(
      'WindowGeometry round-trips through saveWindowGeometry/loadWindowGeometry',
      () async {
        final store = PreferencesStore(InMemoryKeyValueStore());

        final geometry = const WindowGeometry(
          width: 1024.0,
          height: 768.0,
          x: 50.0,
          y: 100.0,
          maximized: true,
        );

        await store.saveWindowGeometry(geometry);
        final loaded = await store.loadWindowGeometry();

        expect(loaded, geometry);
      },
    );

    test('loadWindowGeometry returns null when nothing was saved', () async {
      final store = PreferencesStore(InMemoryKeyValueStore());
      expect(await store.loadWindowGeometry(), isNull);
    });

    test('a corrupt stored string reads back as null', () async {
      final kv = InMemoryKeyValueStore()
        ..values[PreferencesStore.windowGeometryKey] = 'not json';
      final store = PreferencesStore(kv);

      expect(await store.loadWindowGeometry(), isNull);
    });

    test('a JSON object missing width reads back as null', () async {
      final kv = InMemoryKeyValueStore()
        ..values[PreferencesStore.windowGeometryKey] =
            '{"height": 800, "maximized": false}';
      final store = PreferencesStore(kv);

      expect(await store.loadWindowGeometry(), isNull);
    });

    test('a JSON object missing height reads back as null', () async {
      final kv = InMemoryKeyValueStore()
        ..values[PreferencesStore.windowGeometryKey] =
            '{"width": 1000, "maximized": false}';
      final store = PreferencesStore(kv);

      expect(await store.loadWindowGeometry(), isNull);
    });

    test('an absent key for booleans reads as false', () async {
      final store = PreferencesStore(InMemoryKeyValueStore());

      expect(await store.loadSkinEnabled(), false);
      expect(await store.loadNotificationsEnabled(), false);
    });

    test('WindowGeometry with null x/y round-trips', () async {
      final store = PreferencesStore(InMemoryKeyValueStore());

      final geometry = const WindowGeometry(width: 1200.0, height: 900.0);

      await store.saveWindowGeometry(geometry);
      final loaded = await store.loadWindowGeometry();

      expect(loaded, geometry);
      expect(loaded!.x, isNull);
      expect(loaded.y, isNull);
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
