// Smoke tests for the connect screen's two-step flow
// (probe → token or user/pass form).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/presentation/connect/connect_screen.dart';

class _MemoryStore implements KeyValueStore {
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

const _tokenModeStatus = GatewayStatus(
  version: '0.17.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 1,
  authRequired: false,
  authProviders: <String>[],
);

Widget _harness({StatusProbe? probe}) {
  return ProviderScope(
    retry: (retryCount, error) => null,
    overrides: [
      connectionStoreProvider.overrideWithValue(
        ConnectionStore(_MemoryStore()),
      ),
      if (probe != null) statusProbeProvider.overrideWithValue(probe),
    ],
    child: const MaterialApp(home: ConnectScreen()),
  );
}

Future<void> _enterUrlAndProbe(WidgetTester tester, String url) async {
  await tester.enterText(find.byType(TextFormField).first, url);
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders URL field and Continue button initially', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Gateway URL'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.byTooltip('Offline'), findsOneWidget); // connection chip
  });

  testWidgets('validates an empty URL on Continue', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the gateway URL'), findsOneWidget);
  });

  testWidgets('shows a clear error for a malformed URL (no network call)', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await _enterUrlAndProbe(tester, 'notaurl');

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('not valid'), findsOneWidget);
  });

  testWidgets('a token-mode probe reveals the token form', (tester) async {
    await tester.pumpWidget(
      _harness(probe: (config) async => _tokenModeStatus),
    );
    await tester.pumpAndSettle();

    await _enterUrlAndProbe(tester, 'https://gateway.example.com');

    expect(find.text('Session token'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    expect(find.textContaining('Gateway v0.17.0'), findsOneWidget);
  });
}
