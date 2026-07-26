// Tests for the OAuth connect flow: probe → login (browser) → connect gated.

import 'package:flit/application/connection/connect_controller.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/auth_provider.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/domain/models/oauth_session.dart';
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
  authProviders: <String>['nous'],
);

const _oauthProvider = AuthProviderInfo(
  name: 'nous',
  displayName: 'Nous Research',
  supportsPassword: false,
);

const _testSession = OAuthSession(
  accessToken: 'at-token',
  refreshToken: 'rt-token',
  expiresAt: 1700000000,
  provider: 'nous',
);

void main() {
  late ProviderContainer container;
  late FakeRpcClient rpcClient;
  late _MemoryStore kv;

  Future<OAuthSession> oauthLoginStub({
    required ConnectionConfig config,
    required String provider,
  }) async {
    return _testSession;
  }

  ProviderContainer buildContainer() {
    return ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue((config) async => _gatedStatus),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[_oauthProvider],
        ),
        oauthLoginProvider.overrideWithValue(oauthLoginStub),
        rpcClientProvider.overrideWith(() => FakeRpcClientNotifier(rpcClient)),
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

  test('probe detects an OAuth-only gateway and offers the provider', () async {
    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.probed);
    expect(state.authMode, AuthMode.oauth);
    expect(state.providers, <AuthProviderInfo>[_oauthProvider]);
    expect(state.errorMessage, isNull);
  });

  test('connectOAuth logs in, stores the session, connects the WS', () async {
    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');
    await controller.connectOAuth(
      url: 'https://gw.example.com',
      provider: 'nous',
    );

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.connected);

    // Config saved with the OAuth provider.
    final config = container.read(connectionConfigProvider);
    expect(config?.authMode, AuthMode.oauth);
    expect(config?.authProvider, 'nous');

    // Session stored in secure storage.
    final session = container.read(oauthSessionProvider);
    expect(session, _testSession);
    expect(kv.data['connection.oauth_access_token'], 'at-token');
    expect(kv.data['connection.oauth_refresh_token'], 'rt-token');
    expect(kv.data['connection.oauth_expires_at'], '1700000000');
    expect(kv.data['connection.oauth_provider'], 'nous');

    // The WS URI factory was called.
    expect(rpcClient.capturedFactory, isNotNull);

    // Gateway version recorded.
    expect(container.read(gatewayStatusProvider)?.version, '0.18.0');
  });

  test('OAuth login failure → error, no config saved', () async {
    container.dispose();
    kv = _MemoryStore();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectionStoreProvider.overrideWithValue(ConnectionStore(kv)),
        statusProbeProvider.overrideWithValue((config) async => _gatedStatus),
        providersProbeProvider.overrideWithValue(
          (config) async => <AuthProviderInfo>[_oauthProvider],
        ),
        oauthLoginProvider.overrideWithValue(
          ({required config, required provider}) =>
              throw const GatewayAuthException(
                'OAuth login failed: access_denied',
              ),
        ),
        rpcClientProvider.overrideWith(() => FakeRpcClientNotifier(rpcClient)),
      ],
    );

    final controller = container.read(connectControllerProvider.notifier);
    await controller.probe(url: 'https://gw.example.com');
    await controller.connectOAuth(
      url: 'https://gw.example.com',
      provider: 'nous',
    );

    final state = container.read(connectControllerProvider);
    expect(state.phase, ConnectPhase.error);
    expect(state.errorMessage, contains('OAuth login failed'));
    expect(container.read(connectionConfigProvider), isNull);
    expect(kv.data, isEmpty);
  });
}
