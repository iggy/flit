/// Riverpod wiring for the transport layer (ticket P0-07).
///
/// Provider dependency direction: store → config → clients → state/events.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hermes/data/storage/connection_store.dart';
import 'package:hermes/data/transport/connection_config.dart';
import 'package:hermes/data/transport/gateway_rest_client.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';

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

/// Authenticated REST client for the current config; null when disconnected.
final restClientProvider = Provider<GatewayRestClient?>((ref) {
  final config = ref.watch(connectionConfigProvider);
  if (config == null) {
    return null;
  }
  return GatewayRestClient(config);
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
