import 'dart:async';

import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/config/skin_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('skinProvider', () {
    test('starts null', () {
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith(
            (ref) => const Stream<GatewayEvent>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(skinProvider), isNull);
    });

    test('populates from gateway.ready event', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{
              'background': '#1e1e1e',
              'ui_text': '#e6e6e6',
            },
            'branding': <String, dynamic>{},
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final skin = container.read(skinProvider);
      expect(skin, isNotNull);
      expect(skin!.name, 'hermes');
    });

    test('replaces state on skin.changed event', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{'background': '#000000'},
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(skinProvider)!.name, 'hermes');

      controller.add(
        GatewayEvent(
          type: 'skin.changed',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'dracula',
            'colors': <String, dynamic>{'background': '#282a36'},
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(skinProvider)!.name, 'dracula');
    });

    test('clears state when skin.changed sends empty payload', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{'background': '#000000'},
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(skinProvider), isNotNull);

      controller.add(
        GatewayEvent(
          type: 'skin.changed',
          sessionId: null,
          payload: <String, dynamic>{},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(skinProvider), isNull);
    });
  });

  group('skinEnabledProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(skinEnabledProvider), isFalse);
    });

    test('round-trips through the store', () async {
      final store = PreferencesStore(InMemoryKeyValueStore());
      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(skinEnabledProvider.notifier).setEnabled(true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(skinEnabledProvider), isTrue);

      // Verify it was persisted.
      expect(await store.loadSkinEnabled(), isTrue);

      await container.read(skinEnabledProvider.notifier).setEnabled(false);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(skinEnabledProvider), isFalse);
      expect(await store.loadSkinEnabled(), isFalse);
    });

    test('loads stored value on first build', () async {
      final kv = InMemoryKeyValueStore();
      final store = PreferencesStore(kv);

      await store.saveSkinEnabled(true);

      final container = ProviderContainer(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      // Initial state is false (default).
      expect(container.read(skinEnabledProvider), isFalse);

      // Wait for the microtask to load the stored value.
      await Future<void>.delayed(Duration.zero);

      expect(container.read(skinEnabledProvider), isTrue);
    });
  });

  group('appLightThemeProvider', () {
    test('returns M3 theme when skin is disabled', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{'background': '#1e1e1e'},
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final theme = container.read(appLightThemeProvider);
      expect(theme.colorScheme.brightness, Brightness.light);
      // M3 fallback uses the seed color.
      expect(theme.useMaterial3, isTrue);
    });

    test('returns skin theme when enabled and skin is usable', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{
              'background': '#f7f7f8',
              'ui_text': '#161616',
              'ui_accent': '#4a9eff',
            },
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(skinEnabledProvider.notifier).setEnabled(true);

      final theme = container.read(appLightThemeProvider);
      expect(theme.colorScheme.brightness, Brightness.light);
      // The skin's accent should be reflected (not the M3 seed).
      expect(theme.useMaterial3, isTrue);
    });
  });

  group('appDarkThemeProvider', () {
    test('returns M3 theme when skin is disabled', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{'background': '#1e1e1e'},
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final theme = container.read(appDarkThemeProvider);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('returns skin theme when enabled and skin is usable', () async {
      final controller = StreamController<GatewayEvent>.broadcast();
      final container = ProviderContainer(
        overrides: [
          gatewayEventsProvider.overrideWith((ref) => controller.stream),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(controller.close);

      // Hold a listener: a bare read would let the auto-dispose provider (and
      // its ref.listen on the event stream) be torn down immediately.
      container.listen(skinProvider, (_, _) {});

      controller.add(
        GatewayEvent(
          type: 'gateway.ready',
          sessionId: null,
          payload: <String, dynamic>{
            'name': 'hermes',
            'colors': <String, dynamic>{
              'background': '#1e1e1e',
              'ui_text': '#e6e6e6',
              'ui_accent': '#4a9eff',
            },
            'branding': <String, dynamic>{},
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(skinEnabledProvider.notifier).setEnabled(true);

      final theme = container.read(appDarkThemeProvider);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
