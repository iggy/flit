/// Riverpod wiring for insights (ticket P6-03): repository provider,
/// window selector, and the refreshable `insights.get` fetch.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/insights_repository_impl.dart';
import 'package:flit/domain/models/insights.dart';
import 'package:flit/domain/repositories/insights_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The insights repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final insightsRepositoryProvider = Provider<InsightsRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return InsightsRepositoryImpl(client);
});

/// The selected rolling window in days (7 / 30 / 90). Defaults to 30.
final insightsWindowProvider =
    NotifierProvider<InsightsWindowNotifier, int>(InsightsWindowNotifier.new);

/// Holds the selected insights window; `set` swaps it (the codebase uses a
/// [Notifier] for mutable UI state rather than the removed `StateProvider`).
class InsightsWindowNotifier extends Notifier<int> {
  @override
  int build() => 30;

  void set(int days) => state = days;
}

/// `insights.get {days}` for the selected window. Returns null when
/// disconnected (no repository). Re-fetches on window change or client swap
/// (reconnect); refresh with `ref.invalidate(insightsProvider)`.
final insightsProvider = FutureProvider<Insights?>((ref) async {
  final repository = ref.watch(insightsRepositoryProvider);
  if (repository == null) {
    return null;
  }
  final window = ref.watch(insightsWindowProvider);
  return repository.get(days: window);
});
