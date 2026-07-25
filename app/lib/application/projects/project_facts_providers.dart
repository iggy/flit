/// Riverpod wiring for project facts (ticket P6-04): repository provider and
/// the refreshable `project.facts` fetch (family-keyed by cwd).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/project_facts_repository_impl.dart';
import 'package:flit/domain/models/project_facts.dart';
import 'package:flit/domain/repositories/project_facts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The project facts repository for the current connection, or null when there
/// is no RPC client (disconnected / pre-connect).
final projectFactsRepositoryProvider = Provider<ProjectFactsRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ProjectFactsRepositoryImpl(client);
});

/// `project.facts {cwd?}` for the given cwd. Family arg is the cwd (nullable;
/// server defaults when null). Returns null when disconnected (no repository)
/// OR when the cwd is not a code workspace (this is a normal result).
/// Re-fetches on client swap (reconnect); refresh with
/// `ref.invalidate(projectFactsProvider(cwd))`.
final projectFactsProvider =
    FutureProvider.family<ProjectFacts?, String?>((ref, cwd) async {
  final repository = ref.watch(projectFactsRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.facts(cwd: cwd);
});
