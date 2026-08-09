import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/deep_equals.dart';

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
    this.gateways,
    this.configVersion,
    this.latestConfigVersion,
    this.canUpdateHermes,
    this.gatewayDrainable,
    this.restartDrainTimeout,
    this.ftsRebuild,
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

  /// One entry per profile with a LIVE gateway process. Carries host ports, so
  /// the gateway treats it as recon: sent **only when [authRequired] is
  /// false**. Null in gated mode and on gateways older than 0.20 — so "no
  /// entries" and "not told" are different, see [liveGatewayProfiles].
  final List<GatewayTopologyEntry>? gateways;

  /// The config schema version on disk. `0` is a legacy config carrying no
  /// `_config_version` key. Null on gateways older than 0.20.
  final int? configVersion;

  /// The config schema version this gateway build ships. When it exceeds
  /// [configVersion] the user's config wants a migration — see
  /// [configMigrationNeeded]. Null on gateways older than 0.20.
  final int? latestConfigVersion;

  /// Whether this host's Hermes can update itself, or an outer
  /// launcher/container image owns updates. Null on gateways older than 0.20.
  final bool? canUpdateHermes;

  /// Whether the gateway would accept a begin-drain right now (live and
  /// `running`, independent of how busy it is). Null on gateways older
  /// than 0.20.
  final bool? gatewayDrainable;

  /// Seconds a restart spends waiting for in-flight turns to drain. Null on
  /// gateways older than 0.20.
  final double? restartDrainTimeout;

  /// Search-index rebuild progress, or **null when no rebuild is pending** —
  /// the gateway omits the field in the common case, so null is the healthy
  /// state here rather than "unknown".
  final FtsRebuild? ftsRebuild;

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

  /// Whether the on-disk config is behind the schema this gateway ships, so a
  /// `hermes config migrate` is pending. False whenever either version is
  /// unknown (an older gateway must never show a migration banner).
  bool get configMigrationNeeded {
    final current = configVersion;
    final latest = latestConfigVersion;
    if (current == null || latest == null) {
      return false;
    }
    return current < latest;
  }

  /// Whether a search-index rebuild is in progress — search results are
  /// incomplete and slower until it finishes.
  bool get ftsRebuildPending => ftsRebuild != null;

  /// Profiles served by a live gateway, from [gateways]. Empty when the field
  /// was withheld (gated mode / older gateway) as well as when nothing is
  /// running, so never read "no gateway is up" out of it — check
  /// `gateways == null` for that.
  Set<String> get liveGatewayProfiles {
    final entries = gateways;
    if (entries == null) {
      return const <String>{};
    }
    return <String>{
      for (final entry in entries) ...<String>[
        entry.profile,
        // A multiplexing gateway serves profiles that have no gateway entry
        // of their own; they are still live.
        ...entry.servedProfiles,
      ],
    }..removeWhere((name) => name.isEmpty);
  }

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
        _nullableListEquals(other.gateways, gateways) &&
        other.configVersion == configVersion &&
        other.latestConfigVersion == latestConfigVersion &&
        other.canUpdateHermes == canUpdateHermes &&
        other.gatewayDrainable == gatewayDrainable &&
        other.restartDrainTimeout == restartDrainTimeout &&
        other.ftsRebuild == ftsRebuild &&
        other.hermesHome == hermesHome &&
        other.configPath == configPath &&
        other.envPath == envPath &&
        other.gatewayPid == gatewayPid &&
        other.gatewayHealthUrl == gatewayHealthUrl;
  }

  // Object.hash tops out at 20 positional args, which this outgrew — hashAll
  // over a list is the same contract without the arity ceiling.
  @override
  int get hashCode => Object.hashAll(<Object?>[
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
    gateways == null ? null : Object.hashAll(gateways!),
    configVersion,
    latestConfigVersion,
    canUpdateHermes,
    gatewayDrainable,
    restartDrainTimeout,
    ftsRebuild,
    hermesHome,
    configPath,
    envPath,
    gatewayPid,
    gatewayHealthUrl,
  ]);

  @override
  String toString() {
    return 'GatewayStatus(version: $version, releaseDate: $releaseDate, '
        'gatewayRunning: $gatewayRunning, gatewayState: $gatewayState, '
        'gatewayBusy: $gatewayBusy, activeSessions: $activeSessions, '
        'activeAgents: $activeAgents, authRequired: $authRequired, '
        'authProviders: $authProviders, authFlows: $authFlows, '
        'profiles: $profiles, gatewayMode: $gatewayMode, '
        'gateways: $gateways, configVersion: $configVersion, '
        'latestConfigVersion: $latestConfigVersion, '
        'canUpdateHermes: $canUpdateHermes, '
        'gatewayDrainable: $gatewayDrainable, '
        'restartDrainTimeout: $restartDrainTimeout, '
        'ftsRebuild: $ftsRebuild, '
        'hermesHome: $hermesHome, configPath: $configPath, envPath: $envPath, '
        'gatewayPid: $gatewayPid, gatewayHealthUrl: $gatewayHealthUrl)';
  }
}

/// One live gateway process and the profiles it serves, from
/// `GET /api/status` `gateways[]` (loopback mode only).
final class GatewayTopologyEntry {
  const GatewayTopologyEntry({
    required this.profile,
    this.ports = const <String, int>{},
    this.servedProfiles = const <String>[],
  });

  /// The profile this gateway belongs to, e.g. `default`.
  final String profile;

  /// `platform -> host TCP port` for the port-binding platforms it has up.
  /// Display-only: env-var port overrides are not resolved server-side.
  final Map<String, int> ports;

  /// Every profile this one gateway serves — non-empty only when it
  /// multiplexes beyond [profile].
  final List<String> servedProfiles;

  @override
  bool operator ==(Object other) {
    return other is GatewayTopologyEntry &&
        other.profile == profile &&
        shallowMapEquals(other.ports, ports) &&
        _stringListEquals(other.servedProfiles, servedProfiles);
  }

  @override
  int get hashCode => Object.hash(
    profile,
    Object.hashAll(<Object?>[
      for (final key in ports.keys.toList()..sort()) ...<Object?>[
        key,
        ports[key],
      ],
    ]),
    Object.hashAll(servedProfiles),
  );

  @override
  String toString() {
    return 'GatewayTopologyEntry(profile: $profile, ports: $ports, '
        'servedProfiles: $servedProfiles)';
  }
}

/// Search-index (FTS) rebuild progress. Only ever constructed while a rebuild
/// is pending — the gateway omits the block otherwise.
final class FtsRebuild {
  const FtsRebuild({
    required this.total,
    required this.indexed,
    required this.percent,
  });

  /// Rows to index in total.
  final int total;

  /// Rows indexed so far.
  final int indexed;

  /// Server-computed completion, `0..100`.
  final int percent;

  /// [percent] as a `0.0..1.0` fraction for a progress indicator.
  double get fraction => (percent.clamp(0, 100)) / 100;

  @override
  bool operator ==(Object other) {
    return other is FtsRebuild &&
        other.total == total &&
        other.indexed == indexed &&
        other.percent == percent;
  }

  @override
  int get hashCode => Object.hash(total, indexed, percent);

  @override
  String toString() =>
      'FtsRebuild(indexed: $indexed/$total, percent: $percent)';
}

bool _nullableListEquals<T>(List<T>? a, List<T>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return deepListEquals(a, b);
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
