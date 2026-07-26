/// Riverpod wiring for MCP and environment reloading (ticket P4-05).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/reload_repository.dart';
import 'package:flit/domain/repositories/reload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The reload repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final reloadRepositoryProvider = Provider<ReloadRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ReloadRepositoryImpl(client);
});

/// Interaction state for reload operations.
final class ReloadState {
  const ReloadState({
    this.busy = false,
    this.error,
    this.message,
    this.confirmMessage,
  });

  /// A reload operation is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  /// Success message (e.g. "Reloaded 3 env vars"), or null.
  final String? message;

  /// MCP reload confirmation message, or null. When set, the UI should show
  /// a confirmation dialog.
  final String? confirmMessage;

  @override
  bool operator ==(Object other) {
    return other is ReloadState &&
        other.busy == busy &&
        other.error == error &&
        other.message == message &&
        other.confirmMessage == confirmMessage;
  }

  @override
  int get hashCode => Object.hash(busy, error, message, confirmMessage);

  @override
  String toString() {
    return 'ReloadState(busy: $busy, error: $error, message: $message, '
        'confirmMessage: $confirmMessage)';
  }
}

/// Controller for reload operations: MCP servers and environment variables.
final reloadControllerProvider =
    NotifierProvider<ReloadController, ReloadState>(ReloadController.new);

class ReloadController extends Notifier<ReloadState> {
  @override
  ReloadState build() => const ReloadState();

  /// Reload MCP servers (first call, confirm=false). If confirmation is
  /// required, [ReloadState.confirmMessage] will be set. NEVER throws.
  Future<void> reloadMcp() async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(reloadRepositoryProvider);
    if (repository == null) {
      state = const ReloadState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ReloadState(busy: true);
    try {
      final sessionId = ref.read(activeSessionProvider).liveId;
      final outcome = await repository.reloadMcp(sessionId: sessionId);
      switch (outcome) {
        case ReloadMcpConfirmRequired(:final message):
          state = ReloadState(confirmMessage: message);
        case ReloadMcpDone():
          state = const ReloadState(message: 'MCP servers reloaded');
      }
    } on GatewayException catch (error) {
      state = ReloadState(error: error.message);
    } on Object catch (error) {
      state = ReloadState(error: error.toString());
    }
  }

  /// Re-send MCP reload with confirm=true after user confirms.
  Future<void> confirmReloadMcp() async {
    final repository = ref.read(reloadRepositoryProvider);
    if (repository == null) {
      state = const ReloadState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ReloadState(busy: true);
    try {
      final sessionId = ref.read(activeSessionProvider).liveId;
      final outcome = await repository.reloadMcp(
        sessionId: sessionId,
        confirm: true,
      );
      switch (outcome) {
        case ReloadMcpConfirmRequired(:final message):
          // Defensive: shouldn't happen after confirm=true, but keep the gate.
          state = ReloadState(confirmMessage: message);
        case ReloadMcpDone():
          state = const ReloadState(message: 'MCP servers reloaded');
      }
    } on GatewayException catch (error) {
      state = ReloadState(error: error.message);
    } on Object catch (error) {
      state = ReloadState(error: error.toString());
    }
  }

  /// Cancel the MCP reload confirmation dialog without proceeding.
  void cancelConfirm() {
    state = const ReloadState();
  }

  /// Reload environment variables.
  Future<void> reloadEnv() async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(reloadRepositoryProvider);
    if (repository == null) {
      state = const ReloadState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ReloadState(busy: true);
    try {
      final count = await repository.reloadEnv();
      state = ReloadState(
        message: 'Reloaded $count environment variable${count == 1 ? '' : 's'}',
      );
    } on GatewayException catch (error) {
      state = ReloadState(error: error.message);
    } on Object catch (error) {
      state = ReloadState(error: error.toString());
    }
  }

  void clearError() {
    state = ReloadState(
      busy: state.busy,
      message: state.message,
      confirmMessage: state.confirmMessage,
    );
  }
}
