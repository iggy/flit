// P9-07: AppearanceScreen renders skin toggle and info.

import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/config/skin_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/storage/preferences_store.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flit/presentation/settings/appearance_screen.dart';
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
  testWidgets('renders with no skin (switch disabled)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinProvider.overrideWith(() => _FakeSkinNotifier(null)),
          skinEnabledProvider.overrideWith(
            () => _FakeSkinEnabledNotifier(false),
          ),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
          gatewayEventsProvider.overrideWith(
            (ref) => const Stream<GatewayEvent>.empty(),
          ),
        ],
        child: const MaterialApp(home: AppearanceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Match Hermes skin'), findsOneWidget);
    expect(find.text('No skin available from the gateway'), findsOneWidget);

    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.value, isFalse);
    expect(switchTile.onChanged, isNull);
  });

  testWidgets('renders with skin (switch toggleable, name shown)', (
    tester,
  ) async {
    const skin = GatewaySkin(
      name: 'hermes',
      colors: <String, String>{
        'background': '#1e1e1e',
        'ui_text': '#e6e6e6',
        'ui_accent': '#4a9eff',
      },
      branding: <String, String>{'agent_name': 'Hermes'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinProvider.overrideWith(() => _FakeSkinNotifier(skin)),
          skinEnabledProvider.overrideWith(
            () => _FakeSkinEnabledNotifier(false),
          ),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
          gatewayEventsProvider.overrideWith(
            (ref) => const Stream<GatewayEvent>.empty(),
          ),
        ],
        child: const MaterialApp(home: AppearanceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Match Hermes skin'), findsOneWidget);
    expect(
      find.text('Use the color palette pushed by the connected gateway'),
      findsOneWidget,
    );

    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.value, isFalse);
    expect(switchTile.onChanged, isNotNull);

    expect(find.text('Current skin'), findsOneWidget);
    expect(find.text('Name: hermes'), findsOneWidget);
    expect(find.text('Agent: Hermes'), findsOneWidget);
  });

  testWidgets('shows color swatches when enabled', (tester) async {
    const skin = GatewaySkin(
      name: 'hermes',
      colors: <String, String>{
        'background': '#f7f7f8',
        'ui_text': '#161616',
        'ui_accent': '#4a9eff',
      },
      branding: <String, String>{},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinProvider.overrideWith(() => _FakeSkinNotifier(skin)),
          skinEnabledProvider.overrideWith(
            () => _FakeSkinEnabledNotifier(true),
          ),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
          gatewayEventsProvider.overrideWith(
            (ref) => const Stream<GatewayEvent>.empty(),
          ),
        ],
        child: const MaterialApp(home: AppearanceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Light mode colors'), findsOneWidget);
    expect(find.text('Dark mode colors'), findsOneWidget);
    expect(find.text('Primary'), findsNWidgets(2)); // light + dark
    expect(find.text('Surface'), findsNWidgets(2));
    expect(find.text('Error'), findsNWidgets(2));
  });

  testWidgets('toggle calls setEnabled', (tester) async {
    const skin = GatewaySkin(
      name: 'hermes',
      colors: <String, String>{'background': '#1e1e1e', 'ui_text': '#e6e6e6'},
      branding: <String, String>{},
    );

    bool? capturedEnabled;
    final notifier = _FakeSkinEnabledNotifier(
      false,
      onSetEnabled: (enabled) => capturedEnabled = enabled,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skinProvider.overrideWith(() => _FakeSkinNotifier(skin)),
          skinEnabledProvider.overrideWith(() => notifier),
          preferencesStoreProvider.overrideWithValue(
            PreferencesStore(InMemoryKeyValueStore()),
          ),
          gatewayEventsProvider.overrideWith(
            (ref) => const Stream<GatewayEvent>.empty(),
          ),
        ],
        child: const MaterialApp(home: AppearanceScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final switchTile = find.byType(SwitchListTile);
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    expect(capturedEnabled, isTrue);
  });
}

final class _FakeSkinNotifier extends SkinNotifier {
  _FakeSkinNotifier(this._skin);

  final GatewaySkin? _skin;

  @override
  GatewaySkin? build() => _skin;
}

final class _FakeSkinEnabledNotifier extends SkinEnabledNotifier {
  _FakeSkinEnabledNotifier(this._enabled, {this.onSetEnabled});

  final bool _enabled;
  final void Function(bool enabled)? onSetEnabled;

  @override
  bool build() => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (onSetEnabled != null) {
      onSetEnabled!(enabled);
    }
  }
}
