/// Orchestrates the connect flow (ticket P0-07):
/// probe `GET /api/status` → open the WS → save the config on success.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/connection/connection_providers.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/transport/connection_config.dart';
import 'package:hermes/domain/models/gateway_status.dart';

/// Where the connect flow currently stands.
enum ConnectPhase { idle, probing, connecting, connected, error }

/// UI state for the connect screen.
final class ConnectUiState {
  const ConnectUiState({
    this.phase = ConnectPhase.idle,
    this.status,
    this.errorMessage,
  });

  final ConnectPhase phase;

  /// The probed gateway status (available from `probing` onward on success).
  final GatewayStatus? status;

  /// User-facing, token-redacted error description when [phase] is error.
  final String? errorMessage;

  bool get busy =>
      phase == ConnectPhase.probing || phase == ConnectPhase.connecting;
}

final connectControllerProvider =
    NotifierProvider<ConnectController, ConnectUiState>(ConnectController.new);

class ConnectController extends Notifier<ConnectUiState> {
  @override
  ConnectUiState build() => const ConnectUiState();

  /// Probe then connect. Never throws — failures land in
  /// [ConnectUiState.errorMessage] (05-conventions.md typed errors).
  Future<void> connect({required String url, required String token}) async {
    state = const ConnectUiState(phase: ConnectPhase.probing);

    final ConnectionConfig probeConfig;
    try {
      probeConfig = ConnectionConfig(
        baseUrl: url,
        token: token.isEmpty ? null : token,
      );
    } on ArgumentError catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        errorMessage: error.message.toString(),
      );
      return;
    }

    // Step 1: probe /api/status (public; protocol §1).
    final GatewayStatus status;
    try {
      status = await ref.read(statusProbeProvider)(probeConfig);
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        errorMessage: error.message,
      );
      return;
    }

    if (!status.gatewayRunning) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        errorMessage:
            'The server is reachable but reports gateway_running: false. '
            'Start the gateway, then retry.',
      );
      return;
    }
    if (status.inferredAuthMode == AuthMode.oauth) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        errorMessage:
            'This gateway requires OAuth sign-in, which is not supported '
            'yet (Phase 8). Use a token-mode gateway.',
      );
      return;
    }

    // Step 2: open the WS and wait for gateway.ready (protocol §4).
    final config = ConnectionConfig(
      baseUrl: url,
      token: token,
      authMode: AuthMode.token,
    );
    state = ConnectUiState(phase: ConnectPhase.connecting, status: status);
    final client = ref.read(rpcClientProvider.notifier).ensureClient();
    try {
      await client.connect(wsUriFor(config));
    } on GatewayAuthException {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        errorMessage:
            'The gateway rejected the token (close 4401). '
            'Check it and retry.',
      );
      return;
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        errorMessage: error.message,
      );
      return;
    }

    await ref.read(connectionConfigProvider.notifier).setConfig(config);
    // Record the probed status for the rest of the app (ticket P1-16: the
    // session drawer footer shows 'Gateway vX.Y.Z').
    ref.read(gatewayStatusProvider.notifier).set(status);
    state = ConnectUiState(phase: ConnectPhase.connected, status: status);
  }

  /// Reset to idle (e.g. after showing an error).
  void reset() {
    state = const ConnectUiState();
  }
}
