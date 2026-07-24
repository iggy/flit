// Smoke tests for the P0-07 connect screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/data/storage/connection_store.dart';
import 'package:hermes/presentation/connect/connect_screen.dart';

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

Widget _harness() {
  return ProviderScope(
    overrides: [
      connectionStoreProvider.overrideWithValue(
        ConnectionStore(_MemoryStore()),
      ),
    ],
    child: const MaterialApp(home: ConnectScreen()),
  );
}

void main() {
  testWidgets('renders URL field, token field, and Connect button', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Gateway URL'), findsOneWidget);
    expect(find.text('Session token'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Connect'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget); // connection chip
  });

  testWidgets('validates empty fields', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the gateway URL'), findsOneWidget);
    expect(find.text('Enter the session token'), findsOneWidget);
  });

  testWidgets('shows a clear error for a malformed URL (no network call)', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Gateway URL'),
      'notaurl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Session token'),
      'tok',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('not valid'), findsOneWidget);
  });
}
