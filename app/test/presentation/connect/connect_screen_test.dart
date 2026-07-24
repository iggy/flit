// P1-16 acceptance (widget): the connect screen's failure modes each show
// a clear, actionable message — never a raw exception:
//
// - unreachable host → the network message from the /api/status probe;
// - gateway_running: false → the "start the gateway, then retry" message;
// - a 4401-style WS auth rejection → the "rejected the token" message.
//
// The outcomes are produced by overriding the injectable probe
// (statusProbeProvider) and the RPC client (rpcClientProvider) with fakes;
// the REAL ConnectController maps them to the friendly messages.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/storage/connection_store.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/gateway_status.dart';
import 'package:hermes/presentation/connect/connect_screen.dart';

/// In-memory store — the real one needs a platform channel.
final class InMemoryKeyValueStore implements KeyValueStore {
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

/// An RPC client whose connect() fails the way a 4401 close does.
final class FakeRpcClient extends GatewayRpcClient {
  Exception? connectError;

  @override
  Future<void> connect(Uri wsUri) async {
    final error = connectError;
    if (error != null) {
      throw error;
    }
  }
}

/// Hands the fake client to the connect flow (the real notifier would mint
/// a fresh [GatewayRpcClient] when the current one is closed).
final class FakeRpcClientNotifier extends RpcClientNotifier {
  FakeRpcClientNotifier(this._client);

  final FakeRpcClient _client;

  @override
  GatewayRpcClient? build() => _client;

  @override
  GatewayRpcClient ensureClient() => _client;
}

const healthyStatus = GatewayStatus(
  version: '0.17.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 1,
  authRequired: false,
  authProviders: <String>[],
);

void main() {
  Widget harness({StatusProbe? probe, FakeRpcClient? rpcClient}) {
    return ProviderScope(
      // Deterministic tests: Riverpod 3 retries failing providers by
      // default (backoff), which would leave error assertions pending.
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(
          ConnectionStore(InMemoryKeyValueStore()),
        ),
        if (probe != null) statusProbeProvider.overrideWithValue(probe),
        if (rpcClient != null)
          rpcClientProvider.overrideWith(
            () => FakeRpcClientNotifier(rpcClient),
          ),
      ],
      child: const MaterialApp(home: ConnectScreen()),
    );
  }

  /// Fill the form and tap Connect, then let the flow settle.
  Future<void> tapConnect(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'https://gateway.example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret-token');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump(); // connect() runs
    await tester.pump(); // probe/ws future completes, error state shown
    await tester.pump();
  }

  testWidgets('unreachable host shows the network message', (tester) async {
    await tester.pumpWidget(
      harness(
        probe: (config) => Future<GatewayStatus>.error(
          const GatewayNetworkException(
            'Could not reach the gateway (https://gateway.example.com).',
          ),
        ),
      ),
    );

    await tapConnect(tester);

    expect(find.textContaining('Could not reach the gateway'), findsOneWidget);
    // The form is interactive again (not stuck busy).
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
  });

  testWidgets('gateway_running: false shows the start-the-gateway message', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        probe: (config) async => const GatewayStatus(
          version: '0.17.0',
          gatewayRunning: false,
          gatewayState: 'stopped',
          gatewayBusy: false,
          activeSessions: 0,
          activeAgents: 0,
          authRequired: false,
          authProviders: <String>[],
        ),
      ),
    );

    await tapConnect(tester);

    expect(find.textContaining('gateway_running: false'), findsOneWidget);
    expect(find.textContaining('Start the gateway'), findsOneWidget);
  });

  testWidgets('a 4401-style auth rejection shows the rejected-token message', (
    tester,
  ) async {
    final rpcClient = FakeRpcClient()
      ..connectError = const GatewayAuthException(
        'socket closed during handshake',
        closeCode: kGatewayCloseBadCredential,
      );
    await tester.pumpWidget(
      harness(probe: (config) async => healthyStatus, rpcClient: rpcClient),
    );

    await tapConnect(tester);

    expect(find.textContaining('rejected the token'), findsOneWidget);
    expect(find.textContaining('Check it and retry'), findsOneWidget);
  });
}
