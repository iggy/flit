/// Repository providers (tickets P1-04/P1-05): construct the data-layer
/// repository impls from the current [rpcClientProvider] client.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/data/repositories/chat_repository_impl.dart';
import 'package:hermes/data/repositories/session_repository_impl.dart';
import 'package:hermes/domain/repositories/chat_repository.dart';
import 'package:hermes/domain/repositories/session_repository.dart';

/// The session repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect) — mirroring the nullable
/// [restClientProvider] pattern. Callers must handle null (the UI only
/// offers session actions while connected).
final sessionRepositoryProvider = Provider<SessionRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return SessionRepositoryImpl(client);
});

/// The chat repository for the current connection, or null when there is no
/// RPC client. A fresh impl is minted on client swap (reconnect), so
/// subscribers re-subscribe to the new client's event stream.
final chatRepositoryProvider = Provider<ChatRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ChatRepositoryImpl(client);
});
