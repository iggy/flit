/// Orchestrates the connect flow (ticket P0-07, gated auth added post-MVP):
/// probe `GET /api/status` → token form (loopback) or provider/user/pass
/// form (gated) → login (cookies) → mint a WS ticket → open the socket.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/auth_provider.dart';
import 'package:flit/domain/models/gateway_status.dart';
import 'package:flit/domain/models/oauth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the connect flow currently stands.
enum ConnectPhase { idle, probing, probed, connecting, connected, error }

/// UI state for the connect screen.
final class ConnectUiState {
  const ConnectUiState({
    this.phase = ConnectPhase.idle,
    this.status,
    this.errorMessage,
    this.authMode,
    this.providers,
  });

  final ConnectPhase phase;

  /// The probed gateway status (available from `probed` onward on success).
  final GatewayStatus? status;

  /// User-facing, token-redacted error description when [phase] is error.
  final String? errorMessage;

  /// The auth shape detected at probe time (drives which form renders).
  final AuthMode? authMode;

  /// Gated mode: the interactive providers from `GET /api/auth/providers`.
  final List<AuthProviderInfo>? providers;

  bool get busy =>
      phase == ConnectPhase.probing || phase == ConnectPhase.connecting;
}

final connectControllerProvider =
    NotifierProvider<ConnectController, ConnectUiState>(ConnectController.new);

class ConnectController extends Notifier<ConnectUiState> {
  @override
  ConnectUiState build() => const ConnectUiState();

  /// Step 1 (both modes): probe `/api/status`, then for gated gateways also
  /// `/api/auth/providers`, and set [ConnectPhase.probed] so the UI renders
  /// the right form. Never throws.
  Future<void> probe({required String url}) async {
    state = const ConnectUiState(phase: ConnectPhase.probing);

    final ConnectionConfig probeConfig;
    try {
      probeConfig = ConnectionConfig(baseUrl: url);
    } on ArgumentError catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        errorMessage: error.message.toString(),
      );
      return;
    }

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

    if (!status.authRequired) {
      // Loopback / --insecure: legacy session token (protocol §2.1).
      state = ConnectUiState(
        phase: ConnectPhase.probed,
        status: status,
        authMode: AuthMode.token,
      );
      return;
    }

    // Gated: discover the interactive providers (protocol §2.2 step 1).
    final List<AuthProviderInfo> providers;
    try {
      providers = await ref.read(providersProbeProvider)(probeConfig);
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        errorMessage: error.message,
      );
      return;
    }
    final passwordProviders = providers
        .where((p) => p.supportsPassword)
        .toList();
    if (passwordProviders.isEmpty) {
      // OAuth-only gateway: the UI renders "Sign in with <provider>" buttons.
      state = ConnectUiState(
        phase: ConnectPhase.probed,
        status: status,
        authMode: AuthMode.oauth,
        providers: providers,
      );
      return;
    }
    state = ConnectUiState(
      phase: ConnectPhase.probed,
      status: status,
      authMode: AuthMode.password,
      providers: passwordProviders,
    );
  }

  /// Token-mode connect (loopback; protocol §2.1). Never throws.
  Future<void> connectToken({
    required String url,
    required String token,
  }) async {
    final status = state.status;
    state = ConnectUiState(
      phase: ConnectPhase.connecting,
      status: status,
      authMode: AuthMode.token,
    );
    final config = ConnectionConfig(
      baseUrl: url,
      token: token,
      authMode: AuthMode.token,
    );
    final client = ref.read(rpcClientProvider.notifier).ensureClient();
    try {
      await client.connect(() async => wsUriFor(config));
    } on GatewayAuthException {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: AuthMode.token,
        errorMessage:
            'The gateway rejected the token (close 4401). '
            'Check it and retry.',
      );
      return;
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: AuthMode.token,
        errorMessage: error.message,
      );
      return;
    }
    await _succeed(config, status);
  }

  /// Gated user/pass connect (protocol §2.2): login → cookies → per-attempt
  /// ticket → WS. Never throws.
  Future<void> connectPassword({
    required String url,
    required String provider,
    required String username,
    required String password,
  }) async {
    final status = state.status;
    state = ConnectUiState(
      phase: ConnectPhase.connecting,
      status: status,
      authMode: AuthMode.password,
    );
    final config = ConnectionConfig(
      baseUrl: url,
      authMode: AuthMode.password,
      username: username,
      authProvider: provider,
    );

    // Login mints the session cookies into the shared jar (step 2).
    ref.read(sessionCookiesProvider).clear();
    try {
      await ref.read(passwordLoginProvider)(
        config: config,
        provider: provider,
        username: username,
        password: password,
      );
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: AuthMode.password,
        providers: state.providers,
        errorMessage: error.message,
      );
      return;
    }

    await _connectGated(config, status);
  }

  /// Reconnect with the persisted cookies or OAuth session (app restart).
  /// Password mode: the 30-day refresh cookie usually still holds.
  /// OAuth mode: refresh the access token if needed, then connect.
  /// Fails back to the login form on 401.
  Future<void> connectStored() async {
    final config = ref.read(connectionConfigProvider);
    if (config == null) {
      return;
    }
    if (config.authMode == AuthMode.password) {
      await ref.read(sessionCookiesProvider.notifier).ready;
      final jar = ref.read(sessionCookiesProvider);
      if (jar.isEmpty) {
        return; // No session to resume — the UI shows the login form.
      }
      state = ConnectUiState(
        phase: ConnectPhase.connecting,
        authMode: AuthMode.password,
      );
      // Best-effort display probe (version etc.); never blocks the connect.
      GatewayStatus? status;
      try {
        status = await ref.read(statusProbeProvider)(config);
      } on GatewayException {
        status = null;
      }
      await _connectGated(config, status);
    } else if (config.authMode == AuthMode.oauth) {
      await ref.read(oauthSessionProvider.notifier).ready;
      final session = ref.read(oauthSessionProvider);
      if (session == null) {
        return; // No session to resume — the UI shows the login form.
      }
      state = ConnectUiState(
        phase: ConnectPhase.connecting,
        authMode: AuthMode.oauth,
      );
      // Refresh if the access token is expired or expires soon.
      final refreshed = await _refreshIfNeeded(config, session);
      if (refreshed == null) {
        return; // Refresh failed, error state set.
      }
      GatewayStatus? status;
      try {
        status = await ref.read(statusProbeProvider)(config);
      } on GatewayException {
        status = null;
      }
      await _connectGated(config, status);
    }
  }

  /// OAuth login: PKCE flow → code exchange → store tokens → connect gated.
  Future<void> connectOAuth({
    required String url,
    required String provider,
  }) async {
    final status = state.status;
    state = ConnectUiState(
      phase: ConnectPhase.connecting,
      status: status,
      authMode: AuthMode.oauth,
    );
    final config = ConnectionConfig(
      baseUrl: url,
      authMode: AuthMode.oauth,
      authProvider: provider,
    );

    final OAuthSession session;
    try {
      session = await ref.read(oauthLoginProvider)(
        config: config,
        provider: provider,
      );
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: AuthMode.oauth,
        providers: state.providers,
        errorMessage: error.message,
      );
      return;
    }

    await ref.read(oauthSessionProvider.notifier).set(session);
    await _connectGated(config, status);
  }

  /// Shared gated-mode tail: record the config (so [restClientProvider]
  /// rebuilds with the jar) and open the WS with a per-attempt ticket.
  Future<void> _connectGated(
    ConnectionConfig config,
    GatewayStatus? status,
  ) async {
    await ref.read(connectionConfigProvider.notifier).setConfig(config);
    final rest = ref.read(restClientProvider);
    if (rest == null) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: config.authMode,
        errorMessage: 'Internal error: REST client unavailable after login.',
      );
      return;
    }
    final client = ref.read(rpcClientProvider.notifier).ensureClient();
    try {
      // The URI factory mints a FRESH single-use ticket on the initial
      // connect and on every reconnect attempt (protocol §2.2 step 5).
      await client.connect(() async {
        final ticket = await rest.mintWsTicket();
        return wsTicketUriFor(config, ticket);
      });
    } on GatewayAuthException {
      await ref.read(sessionCookiesProvider.notifier).clear();
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: config.authMode,
        errorMessage: 'The gateway rejected the session. Sign in again.',
      );
      return;
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: status,
        authMode: config.authMode,
        errorMessage: error.message,
      );
      return;
    }
    await _succeed(config, status);
  }

  Future<void> _succeed(ConnectionConfig config, GatewayStatus? status) async {
    await ref.read(connectionConfigProvider.notifier).setConfig(config);
    ref.read(sessionExpiredProvider.notifier).acknowledge();
    final probed = status ?? state.status;
    if (probed != null) {
      // Record the probed status for the rest of the app (ticket P1-16: the
      // session drawer footer shows 'Gateway vX.Y.Z').
      ref.read(gatewayStatusProvider.notifier).set(probed);
    }
    state = ConnectUiState(
      phase: ConnectPhase.connected,
      status: probed,
      authMode: config.authMode,
    );
  }

  /// Sign out of a gated session: revoke best-effort, clear cookies/oauth and
  /// the stored connection, and return the UI to the connect screen.
  Future<void> signOut() async {
    final rest = ref.read(restClientProvider);
    await rest?.logout();
    await ref.read(sessionCookiesProvider.notifier).clear();
    await ref.read(oauthSessionProvider.notifier).clear();
    await ref.read(connectionConfigProvider.notifier).clear();
    ref.read(gatewayStatusProvider.notifier).clear();
    state = const ConnectUiState();
  }

  /// Refresh the OAuth access token if it's expired or expires soon. Returns
  /// the refreshed session (or the original if no refresh was needed), or
  /// null on failure (sets error state). Called before connect and reconnect.
  Future<OAuthSession?> _refreshIfNeeded(
    ConnectionConfig config,
    OAuthSession session,
  ) async {
    if (!session.expiresSoon()) {
      return session;
    }
    try {
      final refreshed = await ref.read(oauthRefreshProvider)(
        config: config,
        session: session,
      );
      await ref.read(oauthSessionProvider.notifier).set(refreshed);
      return refreshed;
    } on GatewayAuthException {
      await ref.read(oauthSessionProvider.notifier).clear();
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: state.status,
        authMode: AuthMode.oauth,
        errorMessage: 'The OAuth session expired. Sign in again.',
      );
      return null;
    } on GatewayException catch (error) {
      state = ConnectUiState(
        phase: ConnectPhase.error,
        status: state.status,
        authMode: AuthMode.oauth,
        errorMessage: error.message,
      );
      return null;
    }
  }

  /// Reset to idle (e.g. after showing an error).
  void reset() {
    state = const ConnectUiState();
  }
}
