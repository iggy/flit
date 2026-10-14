import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/flit/flit_pair_controller.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/presentation/connect/connect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _MemoryStore implements KeyValueStore {
  final Map<String, String> data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  late _MemoryStore kv;
  late List<String> paired;

  ProviderContainer container({GatewayException? failWith}) {
    kv = _MemoryStore();
    paired = <String>[];
    final c = ProviderContainer(
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        flitDefaultDeviceNameProvider.overrideWithValue('test-laptop'),
        flitPairFnProvider.overrideWithValue(({
          required serverUrl,
          required code,
          required deviceName,
        }) async {
          paired.add('$serverUrl|$code|$deviceName');
          if (failWith != null) {
            throw failWith;
          }
          return (deviceId: 'dev_1', deviceName: deviceName, token: 'flitd_x');
        }),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Widget app(ProviderContainer c) {
    final router = GoRouter(
      initialLocation: '/connect',
      routes: <RouteBase>[
        GoRoute(path: '/connect', builder: (_, _) => const ConnectScreen()),
        GoRoute(
          path: '/flit',
          builder: (_, _) => const Scaffold(body: Text('flit sessions')),
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pump(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('flit'));
    await tester.pumpAndSettle();
  }

  testWidgets('pairing by hand saves a flit connection', (tester) async {
    final c = container();
    await pump(tester, c);
    expect(find.text('Connect to flit'), findsOneWidget);
    // flutter_test runs as Android, which can scan.
    expect(find.text('Scan QR code'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server URL'),
      'https://flit.example.com/',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pairing code'),
      'abcd-efgh',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Pair'));
    await tester.pumpAndSettle();

    expect(paired, <String>['https://flit.example.com|abcd-efgh|test-laptop']);
    final config = c.read(connectionConfigProvider);
    expect(config?.backend, BackendKind.flit);
    expect(config?.token, 'flitd_x');
    expect(config?.deviceName, 'test-laptop');
    expect(kv.data[ConnectionStore.backendKey], 'flit');
    expect(c.read(flitPairControllerProvider).paired, isTrue);
    expect(find.text('flit sessions'), findsOneWidget);
  });

  testWidgets('a rejected code shows the server message', (tester) async {
    final c = container(
      failWith: const GatewayAuthException('pairing code is wrong'),
    );
    await pump(tester, c);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server URL'),
      'https://flit.example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Pairing code'),
      'nope',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Pair'));
    await tester.pumpAndSettle();
    expect(find.text('pairing code is wrong'), findsOneWidget);
    expect(c.read(connectionConfigProvider), isNull);
  });

  testWidgets('Hermes stays the default', (tester) async {
    final c = container();
    await tester.pumpWidget(app(c));
    await tester.pumpAndSettle();
    expect(find.text('Connect to Hermes'), findsOneWidget);
    expect(find.text('Gateway URL'), findsOneWidget);
  });
}
