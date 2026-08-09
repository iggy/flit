import 'package:flit/data/transport/connection_config.dart';

/// Clean domain view of `GET /api/status`
/// (docs/reference/01-gateway-protocol.md §1).
///
/// Translated from `GatewayStatusDto` — the wire's snake_case quirks are
/// absorbed in `data/dto` (05-conventions.md: "DTOs translate; domain models
/// are clean").
///
/// Note: this imports [AuthMode] from `data/transport/connection_config.dart`
/// (the enum is defined there per ticket P0-04); it adds no Flutter or I/O
/// dependency to the domain layer.
final class GatewayStatus {
  const GatewayStatus({
    required this.version,
    required this.gatewayRunning,
    required this.gatewayState,
    required this.gatewayBusy,
    required this.activeSessions,
    required this.activeAgents,
    required this.authRequired,
    required this.authProviders,
    this.releaseDate,
    this.authFlows,
    this.profiles,
    this.gatewayMode,
    this.hermesHome,
    this.configPath,
    this.envPath,
    this.gatewayPid,
    this.gatewayHealthUrl,
  });

  /// Gateway version, e.g. `0.17.0`.
  final String version;

  /// Release date string, e.g. `2026-06-30` (documented always-present in
  /// protocol §1; kept nullable for robustness against older gateways).
  final String? releaseDate;

  /// Whether the gateway process is running.
  final bool gatewayRunning;

  /// Gateway state string (e.g. `ready`), or null.
  final String? gatewayState;

  /// Whether the gateway is busy.
  final bool gatewayBusy;

  /// Number of active sessions.
  final int activeSessions;

  /// Number of active agents.
  final int activeAgents;

  /// THE decisive field (protocol §1): true → OAuth mode, false → token mode.
  final bool authRequired;

  /// OAuth providers, e.g. `["nous"]`; empty in token mode.
  final List<String> authProviders;

  /// Auth capability flags the gateway advertises, e.g.
  /// `["cookie", "native_pkce"]`. Empty in token mode; **null on gateways
  /// older than 0.20**, which never send the field — the difference matters,
  /// see [supportsNativePkce].
  final List<String>? authFlows;

  /// Profile names on the host (gateway 0.20+), or null.
  final List<String>? profiles;

  /// Gateway topology: `multiplex` (one gateway serves several profiles),
  /// `single`, `multiple`, `none`, `unknown`. Null on gateways older than 0.20.
  final String? gatewayMode;

  /// Host recon fields — only present when [authRequired] is false
  /// (loopback/insecure); omitted in OAuth mode (protocol §1).
  final String? hermesHome;
  final String? configPath;
  final String? envPath;
  final int? gatewayPid;
  final String? gatewayHealthUrl;

  /// Auth mode inferred from [authRequired]: false → [AuthMode.token]
  /// (loopback), true → [AuthMode.password] (gated; the providers probe may
  /// refine this to [AuthMode.oauth] when no password provider exists).
  AuthMode get inferredAuthMode =>
      authRequired ? AuthMode.password : AuthMode.token;

  /// Whether the gateway advertises the RFC 8252 native-app flow
  /// (system browser + loopback redirect + PKCE). Null [authFlows] means an
  /// older gateway that never advertised it — the caller falls back to
  /// inferring from `supports_password`, so this is false, not unknown.
  bool get supportsNativePkce => authFlows?.contains('native_pkce') ?? false;

  @override
  bool operator ==(Object other) {
    return other is GatewayStatus &&
        other.version == version &&
        other.releaseDate == releaseDate &&
        other.gatewayRunning == gatewayRunning &&
        other.gatewayState == gatewayState &&
        other.gatewayBusy == gatewayBusy &&
        other.activeSessions == activeSessions &&
        other.activeAgents == activeAgents &&
        other.authRequired == authRequired &&
        _stringListEquals(other.authProviders, authProviders) &&
        _nullableStringListEquals(other.authFlows, authFlows) &&
        _nullableStringListEquals(other.profiles, profiles) &&
        other.gatewayMode == gatewayMode &&
        other.hermesHome == hermesHome &&
        other.configPath == configPath &&
        other.envPath == envPath &&
        other.gatewayPid == gatewayPid &&
        other.gatewayHealthUrl == gatewayHealthUrl;
  }

  @override
  int get hashCode => Object.hash(
    version,
    releaseDate,
    gatewayRunning,
    gatewayState,
    gatewayBusy,
    activeSessions,
    activeAgents,
    authRequired,
    Object.hashAll(authProviders),
    authFlows == null ? null : Object.hashAll(authFlows!),
    profiles == null ? null : Object.hashAll(profiles!),
    gatewayMode,
    hermesHome,
    configPath,
    envPath,
    gatewayPid,
    gatewayHealthUrl,
  );

  @override
  String toString() {
    return 'GatewayStatus(version: $version, releaseDate: $releaseDate, '
        'gatewayRunning: $gatewayRunning, gatewayState: $gatewayState, '
        'gatewayBusy: $gatewayBusy, activeSessions: $activeSessions, '
        'activeAgents: $activeAgents, authRequired: $authRequired, '
        'authProviders: $authProviders, authFlows: $authFlows, '
        'profiles: $profiles, gatewayMode: $gatewayMode, '
        'hermesHome: $hermesHome, configPath: $configPath, envPath: $envPath, '
        'gatewayPid: $gatewayPid, gatewayHealthUrl: $gatewayHealthUrl)';
  }
}

bool _nullableStringListEquals(List<String>? a, List<String>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return _stringListEquals(a, b);
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
