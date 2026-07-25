/// Riverpod wiring for slash commands (tickets P3-01/P3-02/P3-03).
///
/// Mirrors the nullable-repository pattern: repositories are null when
/// disconnected, and callers handle null.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/slash_repository.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flit/domain/repositories/slash_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The slash repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final slashRepositoryProvider = Provider<SlashRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return SlashRepositoryImpl(client);
});

/// Full command catalog from `commands.catalog` (P3-01).
/// Null when disconnected.
final slashCatalogProvider = FutureProvider<SlashCatalog?>((ref) async {
  final repository = ref.watch(slashRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.catalog();
});
