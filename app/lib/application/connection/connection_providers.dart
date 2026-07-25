/// Riverpod wiring for the transport layer (ticket P0-07).
///
/// Provider dependency direction: store → config → clients → state/events.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/data/transport/session_cookie_jar.dart';
import 'package:flit/domain/models/auth_provider.dart';
import 'package:flit/domain/models/gateway_status.dart';

/// Persistence for the connection config. Override in tests with an
/// in-memory [KeyValueStore].
final connectionStoreProvider = Provider<ConnectionStore>((ref) {
  return const ConnectionStore(SecureKeyValueStore(FlutterSecureStorage()));
});

/// The current connection config (null until one is saved). Loads the stored
/// config on first build.
final connectionConfigProvider =
    NotifierProvider<ConnectionConfigNotifier, ConnectionConfig?>(
      ConnectionConfigNotifier.new,
    );

class ConnectionConfigNotifier extends Notifier<ConnectionConfig?> {
  @override
  ConnectionConfig? build() {
    Future<void>.microtask(_loadStored);
    return null;
  }

  Future<void> _loadStored() async {
    final stored = await ref.read(connectionStoreProvider).load();
    if (stored != null && state == null) {
      state = stored;
    }
  }

  Future<void> setConfig(ConnectionConfig config) async {
    state = config;
    await ref.read(connectionStoreProvider).save(config);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(connectionStoreProvider).forget();
  }
}

/// The gated-mode session cookie jar (protocol §2.2). Loads the persisted
/// cookies on first build; every mutation is persisted to secure storage.
/// The password is never stored anywhere — the session lives here.
final sessionCookiesProvider =
    NotifierProvider<SessionCookiesNotifier, SessionCookieJar>(
      SessionCookiesNotifier.new,
    );

class SessionCookiesNotifier extends Notifier<SessionCookieJar> {
  final Completer<void> _readyCompleter = Completer<void>();

  /// Completes once the persisted cookies (if any) have been loaded —
  /// await this before branching on the jar's contents at app start.
  Future<void> get ready => _readyCompleter.future;

  @override
  SessionCookieJar build() {
    final jar = SessionCookieJar();
    Future<void>.microtask(() => _loadStored(jar));
    return jar;
  }

  Future<void> _loadStored(SessionCookieJar jar) async {
    try {
      final json = await ref.read(connectionStoreProvider).loadSessionCookies();
      if (json == null || json.isEmpty) {
        return;
      }
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map) {
          jar.replaceFromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
      } on FormatException {
        await ref.read(connectionStoreProvider).clearSessionCookies();
      }
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  /// Persist the jar's current contents (called on every capture).
  Future<void> persist() async {
    await ref
        .read(connectionStoreProvider)
        .saveSessionCookies(jsonEncode(state.toJson()));
  }

  /// Drop the session (logout / expired) locally and in storage.
  Future<void> clear() async {
    state.clear();
    await ref.read(connectionStoreProvider).clearSessionCookies();
  }
}

/// Set when a gated request that presented cookies was rejected (401/403):
/// the session is dead and the user must sign in again. The chat screen
/// watches this to route back to /connect.
final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(
  SessionExpiredNotifier.new,
);

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Mark the gated session dead: clear the cookies and flag the UI.
  Future<void> expire() async {
    if (state) {
      return;
    }
    await ref.read(sessionCookiesProvider.notifier).clear();
    state = true;
  }

  /// Clear the flag (after the UI routed to /connect).
  void acknowledge() {
    state = false;
  }
}

/// Authenticated REST client for the current config; null when disconnected.
final restClientProvider = Provider<GatewayRestClient?>((ref) {
  final config = ref.watch(connectionConfigProvider);
  if (config == null) {
    return null;
  }
  if (config.authMode == AuthMode.token) {
    return GatewayRestClient(config);
  }
  final jar = ref.watch(sessionCookiesProvider);
  return GatewayRestClient(
    config,
    cookieJar: jar,
    onCookiesChanged: () => ref.read(sessionCookiesProvider.notifier).persist(),
    onAuthFailure: () => ref.read(sessionExpiredProvider.notifier).expire(),
  );
});

/// The current RPC client instance, or null before the first connect.
///
/// A [GatewayRpcClient] cannot be reused after `close()`, so a fresh instance
/// is minted per connect attempt via [RpcClientNotifier.ensureClient].
final rpcClientProvider =
    NotifierProvider<RpcClientNotifier, GatewayRpcClient?>(
      RpcClientNotifier.new,
    );

class RpcClientNotifier extends Notifier<GatewayRpcClient?> {
  @override
  GatewayRpcClient? build() => null;

  /// The live client, minting a new one when absent or closed.
  GatewayRpcClient ensureClient() {
    final existing = state;
    if (existing != null && existing.state != GatewayConnectionState.closed) {
      return existing;
    }
    final client = GatewayRpcClient();
    state = client;
    return client;
  }

  Future<void> disconnect() async {
    final client = state;
    state = null;
    await client?.close();
  }
}

/// Stream of the client's connection states (re-emits on client swap).
final connectionStateProvider = StreamProvider<GatewayConnectionState>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return Stream<GatewayConnectionState>.value(GatewayConnectionState.closed);
  }
  return client.connection;
});

/// Stream of all server-pushed gateway events (re-subscribes on client swap).
final gatewayEventsProvider = StreamProvider<GatewayEvent>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return const Stream<GatewayEvent>.empty();
  }
  return client.events;
});

/// The `/api/status` probe behind the connect flow (protocol §1), as a
/// function of the probe config. Injectable so tests can drive the connect
/// screen's failure modes (unreachable host, `gateway_running: false`)
/// without a network (ticket P1-16).
typedef StatusProbe = Future<GatewayStatus> Function(ConnectionConfig config);

/// The default probe: a real [GatewayRestClient] against the probe config.
final statusProbeProvider = Provider<StatusProbe>((ref) {
  return (config) => GatewayRestClient(config).status();
});

/// The `GET /api/auth/providers` probe (protocol §2.2 step 1). Injectable
/// for the same reason as [statusProbeProvider].
typedef ProvidersProbe =
    Future<List<AuthProviderInfo>> Function(ConnectionConfig config);

/// The default providers probe.
final providersProbeProvider = Provider<ProvidersProbe>((ref) {
  return (config) => GatewayRestClient(config).authProviders();
});

/// The `POST /auth/password-login` call (protocol §2.2 step 2). Injectable
/// so tests can drive the gated connect flow without a network.
typedef PasswordLogin =
    Future<void> Function({
      required ConnectionConfig config,
      required String provider,
      required String username,
      required String password,
    });

/// The default login: a real [GatewayRestClient] against the probe config,
/// capturing cookies into the shared jar.
final passwordLoginProvider = Provider<PasswordLogin>((ref) {
  return ({
    required config,
    required provider,
    required username,
    required password,
  }) {
    final jar = ref.read(sessionCookiesProvider);
    return GatewayRestClient(
      config,
      cookieJar: jar,
      onCookiesChanged: () =>
          ref.read(sessionCookiesProvider.notifier).persist(),
    ).passwordLogin(provider: provider, username: username, password: password);
  };
});

/// The probed status of the gateway we are connected to — set by the
/// connect controller on a SUCCESSFUL connect, null before that. Backs the
/// 'Gateway vX.Y.Z' footer in the session drawer (ticket P1-16).
final gatewayStatusProvider =
    NotifierProvider<GatewayStatusNotifier, GatewayStatus?>(
      GatewayStatusNotifier.new,
    );

class GatewayStatusNotifier extends Notifier<GatewayStatus?> {
  @override
  GatewayStatus? build() => null;

  /// Record the status of a successful connect.
  void set(GatewayStatus status) {
    state = status;
  }

  /// Forget the recorded status (e.g. on disconnect).
  void clear() {
    state = null;
  }
}
