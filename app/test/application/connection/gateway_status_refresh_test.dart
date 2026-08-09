// `GatewayStatusNotifier.refresh()` — the manual re-probe behind the About
// screen's refresh action (docs/updates/gateway-0.18-to-0.20-optional.md §8).
//
// The connect-time probe is a snapshot; the live fields in it (an FTS
// rebuild's percent, drainability, the config version after a migration) go
// stale with no WS event to say so. This re-probes on demand, and — the point
// of these cases — it must never blank a readout or throw.

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MemoryStore implements KeyValueStore {
  final Map<String, String> data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

final _config = ConnectionConfig(
  baseUrl: 'http://127.0.0.1:8787',
  token: 'tok',
);

/// A rebuild at 25%, as recorded on connect.
const _connected = GatewayStatus(
  version: '0.20.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 0,
  authRequired: false,
  authProviders: <String>[],
  configVersion: 2,
  latestConfigVersion: 3,
  gatewayDrainable: true,
  ftsRebuild: FtsRebuild(total: 5000, indexed: 1250, percent: 25),
);

/// The same gateway later: rebuild done, config migrated, mid-turn so not
/// drainable.
const _later = GatewayStatus(
  version: '0.20.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: true,
  activeSessions: 1,
  activeAgents: 1,
  authRequired: false,
  authProviders: <String>[],
  configVersion: 3,
  latestConfigVersion: 3,
  gatewayDrainable: false,
);

void main() {
  late ProviderContainer container;
  late _MemoryStore kv;

  ProviderContainer buildContainer(StatusProbe probe) {
    return ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue(probe),
      ],
    );
  }

  setUp(() {
    kv = _MemoryStore();
  });

  tearDown(() {
    container.dispose();
  });

  test('re-probes and replaces the recorded status', () async {
    container = buildContainer((config) async => _later);
    await container.read(connectionConfigProvider.notifier).setConfig(_config);
    final notifier = container.read(gatewayStatusProvider.notifier);
    notifier.set(_connected);

    expect(await notifier.refresh(), isTrue);

    final status = container.read(gatewayStatusProvider)!;
    // The rebuild finished: the field is now ABSENT, which is the healthy
    // state — a refresh has to be able to clear it, not just update a percent.
    expect(status.ftsRebuild, isNull);
    expect(status.ftsRebuildPending, isFalse);
    expect(status.configVersion, 3);
    expect(status.configMigrationNeeded, isFalse);
    expect(status.gatewayDrainable, isFalse);
  });

  test('a failed probe keeps the last known status', () async {
    container = buildContainer((config) async {
      throw const GatewayNetworkException('connection refused');
    });
    await container.read(connectionConfigProvider.notifier).setConfig(_config);
    final notifier = container.read(gatewayStatusProvider.notifier);
    notifier.set(_connected);

    expect(await notifier.refresh(), isFalse);
    // Still the connect-time readout — a transient failure must not blank it.
    expect(container.read(gatewayStatusProvider), _connected);
  });

  test('does nothing when there is no connection config', () async {
    var probes = 0;
    container = buildContainer((config) async {
      probes++;
      return _later;
    });
    final notifier = container.read(gatewayStatusProvider.notifier);

    expect(await notifier.refresh(), isFalse);
    expect(probes, 0);
    expect(container.read(gatewayStatusProvider), isNull);
  });
}
