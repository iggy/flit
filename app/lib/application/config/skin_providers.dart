/// Riverpod wiring for the Hermes skin (ticket P9-07).
///
/// [skinProvider] subscribes to `gateway.ready` and `skin.changed` events and
/// folds the wire payload through the DTO into state. [skinEnabledProvider]
/// persists the opt-in through [PreferencesStore]. [appLightThemeProvider] and
/// [appDarkThemeProvider] return the skin theme when enabled and usable, else
/// the M3 fallback.
library;

import 'package:flit/application/config/preferences_providers.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/theme/app_theme.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/dto/gateway_skin_dto.dart';
import 'package:flit/domain/models/gateway_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current gateway-pushed skin, or null when absent/unusable. Subscribes
/// to `gateway.ready` and `skin.changed` events.
final skinProvider = NotifierProvider<SkinNotifier, GatewaySkin?>(
  SkinNotifier.new,
);

class SkinNotifier extends Notifier<GatewaySkin?> {
  @override
  GatewaySkin? build() {
    // Subscribe to gateway events and fold skin payloads into state.
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is GatewayReady) {
        final skin = parseGatewaySkinPayload(event.skin);
        state = skin;
      } else if (event is SkinChanged) {
        final skin = parseGatewaySkinPayload(event.skin);
        state = skin;
      }
    });
    return null;
  }
}

/// Whether the user has opted into the Hermes skin (default false, M3 is the
/// default per docs/design/theming.md). Persisted through [PreferencesStore].
final skinEnabledProvider = NotifierProvider<SkinEnabledNotifier, bool>(
  SkinEnabledNotifier.new,
);

class SkinEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load the stored value asynchronously.
    Future<void>.microtask(_loadStored);
    return false;
  }

  Future<void> _loadStored() async {
    final stored = await ref.read(preferencesStoreProvider).loadSkinEnabled();
    if (!state) {
      state = stored;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(preferencesStoreProvider).saveSkinEnabled(enabled);
  }
}

/// Light theme for the app: skin when enabled and usable, else M3.
final appLightThemeProvider = Provider<ThemeData>((ref) {
  final enabled = ref.watch(skinEnabledProvider);
  final skin = ref.watch(skinProvider);
  if (enabled && skin != null && skin.isUsable) {
    return AppTheme.lightFor(skin);
  }
  return AppTheme.light();
});

/// Dark theme for the app: skin when enabled and usable, else M3.
final appDarkThemeProvider = Provider<ThemeData>((ref) {
  final enabled = ref.watch(skinEnabledProvider);
  final skin = ref.watch(skinProvider);
  if (enabled && skin != null && skin.isUsable) {
    return AppTheme.darkFor(skin);
  }
  return AppTheme.dark();
});
