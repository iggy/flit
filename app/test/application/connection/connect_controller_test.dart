// Tests for the gated (user/pass) connect flow: probe → login → ticket WS.

import 'package:flit/application/connection/connect_controller.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/data/transport/session_cookie_jar.dart';
import 'package:flit/domain/models/auth_provider.dart';
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

/// Records the WS URI factory and completes on demand.
final class FakeRpcClient extends GatewayRpcClient {
  Future<Uri> Function()? capturedFactory;
  Exception? connectError;

  @override
  Future<void> connect(Future<Uri> Function() wsUriFactory) async {
    capturedFactory = wsUriFactory;
    final error = connectError;
    if (error != null) {
      throw error;
    }
  }
}

final class FakeRpcClientNotifier extends RpcClientNotifier {
  FakeRpcClientNotifier(this._client);

  final FakeRpcClient _client;

  @override
  GatewayRpcClient? build() => _client;

  @override
  GatewayRpcClient ensureClient() => _client;
}

const _gatedStatus = GatewayStatus(
  version: '0.18.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 1,
  authRequired: true,
  authProviders: <String>['local'],
);

/// A 0.20 gateway that advertises the RFC 8252 native-app flow alongside the
/// cookie flow, with both a password and a brokerable OAuth provider.
const _nativePkceStatus = GatewayStatus(
  version: '0.20.0',
  gatewayRunning: true,
  gatewayState: 'ready',
  gatewayBusy: false,
  activeSessions: 1,
  activeAgents: 1,
  authRequired: true,
  authProviders: <String>['local', 'nous'],
  authFlows: <String>['cookie', 'native_pkce'],
);

const _passwordProvider = AuthProviderInfo(
  name: 'local',
  displayName: 'Username & password',
  supportsPassword: true,
);

const _oauthProvider = AuthProviderInfo(
  name: 'nous',
  displayName: 'Nous Research',
  supportsPassword: false,
);

void main() {
  late ProviderContainer container;
  late FakeRpcClient rpcClient;
  late _MemoryStore kv;
  late SessionCookieJar jar;

  Future<void> passwordLoginStub({
    required ConnectionConfig config,
    required String provider,
    required String username,
    required String password,
  }) async {
    jar.captureFromHeaders(<String>['__Host-hermes_session_at=at-token']);
  }

  ProviderContainer buildContainer() {
    jar = SessionCookieJar();
    return ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue((config) async => _gatedStatus),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[_passwordProvider],
        ),
        passwordLoginProvider.overrideWithValue(passwordLoginStub),
        rpcClientProvider.overrideWith(() => FakeRpcClientNotifier(rpcClient)),
        sessionCookiesProvider.overrideWith(() {
          return _FixedJarNotifier(jar);
        }),
      ],
    );
  }

  setUp(() {
    kv = _MemoryStore();
    rpcClient = FakeRpcClient();
    container = buildContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'probe detects a gated gateway and offers the password provider',
    () async {
      final controller = container.read(connectControllerProvider.notifier);
      await controller.probe(url: 'https://gw.example.com');

      final state = container.read(connectControllerProvider);
      expect(state.phase, ConnectPhase.probed);
      expect(state.authMode, AuthMode.password);
      expect(state.providers, <AuthProviderInfo>[_passwordProvider]);
    },
  );

  test('auth_flows native_pkce wins over a registered password provider '
      'and keeps the password providers as a fallback', () async {
    container.dispose();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue(
          (config) async => _nativePkceStatus,
        ),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[
            _passwordProvider,
            _oauthProvider,
          ],
        ),
      ],
    );

    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');

    var state = container.read(connectControllerProvider);
    expect(state.authMode, AuthMode.oauth);
    // Only the brokerable provider serves the native flow — a password
    // provider has no IDP round trip to broker.
    expect(state.providers, <AuthProviderInfo>[_oauthProvider]);
    expect(
      state.passwordFallbackProviders,
      <AuthProviderInfo>[_passwordProvider],
    );

    // The user can still opt into the password form.
    controller.usePasswordFallback();
    state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.probed);
    expect(state.authMode, AuthMode.password);
    expect(state.providers, <AuthProviderInfo>[_passwordProvider]);
    expect(state.passwordFallbackProviders, isNull);
  });

  test('native_pkce with no brokerable provider stays on password', () async {
    container.dispose();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue(
          (config) async => _nativePkceStatus,
        ),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[_passwordProvider],
        ),
      ],
    );

    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');

    final state = container.read(connectControllerProvider);
    expect(state.authMode, AuthMode.password);
    expect(state.providers, <AuthProviderInfo>[_passwordProvider]);
    expect(state.passwordFallbackProviders, isNull);
  });

  test('usePasswordFallback is a no-op with nothing set aside', () async {
    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');
    final before = container.read(connectControllerProvider);

    controller.usePasswordFallback();

    expect(container.read(connectControllerProvider), same(before));
  });

  test('an OAuth-only gateway is probed with oauth mode', () async {
    container.dispose();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue((config) async => _gatedStatus),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[
            const AuthProviderInfo(
              name: 'nous',
              displayName: 'Nous Research',
              supportsPassword: false,
            ),
          ],
        ),
      ],
    );

    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.probed);
    expect(state.authMode, AuthMode.oauth);
    expect(state.errorMessage, isNull); // No longer shows "not supported"
    expect(state.providers, hasLength(1));
    expect(state.providers!.first.name, 'nous');
  });

  test('connectPassword logs in, saves config+username, connects the WS '
      'with a ticket-minting factory', () async {
    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');
    await controller.connectPassword(
      url: 'https://gw.example.com',
      provider: 'local',
      username: 'iggy',
      password: 's3cret',
    );

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.connected);

    // Config saved with the username; the password is never stored.
    final config = container.read(connectionConfigProvider);
    expect(config?.authMode, AuthMode.password);
    expect(config?.username, 'iggy');
    expect(kv.data['connection.username'], 'iggy');
    expect(kv.data.keys.any((k) => k.contains('password')), isFalse);

    // The WS URI factory mints tickets via the cookie-authed REST client.
    expect(rpcClient.capturedFactory, isNotNull);

    // Login cookies landed in the shared jar.
    expect(jar.names, contains('__Host-hermes_session_at'));

    // Gateway version recorded for the drawer footer (P1-16).
    expect(container.read(gatewayStatusProvider)?.version, '0.18.0');
  });

  test('invalid credentials → friendly error, no config saved', () async {
    container.dispose();
    kv = _MemoryStore();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue((config) async => _gatedStatus),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[_passwordProvider],
        ),
        passwordLoginProvider.overrideWithValue(
          ({
            required config,
            required provider,
            required username,
            required password,
          }) =>
              throw const GatewayAuthException('Invalid username or password.'),
        ),
      ],
    );

    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');
    await controller.connectPassword(
      url: 'https://gw.example.com',
      provider: 'local',
      username: 'iggy',
      password: 'wrong',
    );

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.error);
    expect(state.errorMessage, 'Invalid username or password.');
    expect(container.read(connectionConfigProvider), isNull);
    expect(kv.data, isEmpty);
  });
}

/// A SessionCookiesNotifier pre-seeded with a specific jar instance.
final class _FixedJarNotifier extends SessionCookiesNotifier {
  _FixedJarNotifier(this._jar);

  final SessionCookieJar _jar;

  @override
  SessionCookieJar build() => _jar;

  @override
  Future<void> persist() async {} // no storage in these tests
}
