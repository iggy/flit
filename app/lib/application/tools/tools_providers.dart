/// Riverpod wiring for tool catalog and configuration (tickets P4-03, P4-04).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/tools_repository.dart';
import 'package:flit/domain/models/tool_catalog.dart';
import 'package:flit/domain/repositories/tools_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tools repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final toolsRepositoryProvider = Provider<ToolsRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ToolsRepositoryImpl(client);
});

/// Refreshable list of toolsets (from `tools.list`).
final toolsListProvider = FutureProvider<List<Toolset>>((ref) async {
  final repository = ref.watch(toolsRepositoryProvider);
  if (repository == null) {
    return const <Toolset>[];
  }
  final sessionId = ref.watch(activeSessionProvider).liveId;
  return repository.listTools(sessionId: sessionId);
});

/// Interaction state for tool configuration.
final class ToolsConfigureState {
  const ToolsConfigureState({
    this.busy = false,
    this.error,
    this.lastResult,
  });

  /// A configure call is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  /// The last configure result (so UI can surface missing_servers).
  final ToolsConfigureResult? lastResult;

  @override
  bool operator ==(Object other) {
    return other is ToolsConfigureState &&
        other.busy == busy &&
        other.error == error &&
        other.lastResult == lastResult;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastResult);

  @override
  String toString() {
    return 'ToolsConfigureState(busy: $busy, error: $error, '
        'lastResult: $lastResult)';
  }
}

/// Controller for tool configuration: enable/disable toolsets.
final toolsConfigureControllerProvider =
    NotifierProvider<ToolsConfigureController, ToolsConfigureState>(
      ToolsConfigureController.new,
    );

class ToolsConfigureController extends Notifier<ToolsConfigureState> {
  @override
  ToolsConfigureState build() => const ToolsConfigureState();

  /// Enable or disable a single toolset. NEVER throws — failures land in
  /// [ToolsConfigureState.error].
  Future<void> setEnabled(String name, bool enabled) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(toolsRepositoryProvider);
    if (repository == null) {
      state = const ToolsConfigureState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ToolsConfigureState(busy: true);
    try {
      final sessionId = ref.read(activeSessionProvider).liveId;
      final result = await repository.configure(
        action: enabled ? 'enable' : 'disable',
        names: <String>[name],
        sessionId: sessionId,
      );
      state = ToolsConfigureState(lastResult: result);
      ref.invalidate(toolsListProvider);
    } on GatewayException catch (error) {
      state = ToolsConfigureState(error: error.message);
    } on Object catch (error) {
      state = ToolsConfigureState(error: error.toString());
    }
  }

  void clearError() {
    state = ToolsConfigureState(
      busy: state.busy,
      lastResult: state.lastResult,
    );
  }
}
