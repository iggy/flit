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
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/presentation/connect/connect_screen.dart';

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
  Future<void> connect(Future<Uri> Function() wsUriFactory) async {
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

  /// Step 1: enter the URL and probe. Step 2 (token mode): enter the token
  /// and connect. Each stage lets async work settle.
  Future<void> probe(WidgetTester tester) async {
    await tester.enterText(
      find.byType(TextFormField).first,
      'https://gateway.example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump(); // probe runs
    await tester.pump(); // state emitted, form updated
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

    await probe(tester);

    expect(find.textContaining('Could not reach the gateway'), findsOneWidget);
    // The probe button is back (not stuck busy) so the user can retry.
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
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

    await probe(tester);

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

    await probe(tester);

    // Probe detected token mode → the token form renders.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Session token'),
      'secret-token',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pump(); // connect() runs
    await tester.pump(); // error state shown
    await tester.pump();

    expect(find.textContaining('rejected the token'), findsOneWidget);
    expect(find.textContaining('Check it and retry'), findsOneWidget);
  });
}
