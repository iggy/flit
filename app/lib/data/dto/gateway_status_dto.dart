import 'package:flit/domain/models/gateway_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gateway_status_dto.g.dart';

/// Wire DTO for `GET /api/status` (docs/reference/01-gateway-protocol.md §1).
///
/// Field names come straight from the protocol doc — snake_case absorbed via
/// `@JsonKey` (05-conventions.md). Never exposed above the data layer; fold
/// into the domain model with [GatewayStatusDto.toDomain].
///
/// Always present: [version], [gatewayRunning], [gatewayState] (nullable),
/// [gatewayBusy], [activeSessions], [activeAgents], [authRequired],
/// [authProviders]. The host recon fields ([hermesHome], [configPath],
/// [envPath], [gatewayPid], [gatewayHealthUrl]) are returned **only when
/// `auth_required == false`** and stay null in OAuth mode.
///
/// [authFlows], [profiles], [gatewayMode], [configVersion],
/// [latestConfigVersion], [canUpdateHermes], [gatewayDrainable],
/// [restartDrainTimeout], [ftsRebuild], and [gateways] arrived in gateway 0.20
/// and stay null against older gateways.
@JsonSerializable()
class GatewayStatusDto {
  const GatewayStatusDto({
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

  factory GatewayStatusDto.fromJson(Map<String, dynamic> json) =>
      _$GatewayStatusDtoFromJson(json);

  final String version;

  @JsonKey(name: 'release_date')
  final String? releaseDate;

  @JsonKey(name: 'gateway_running')
  final bool gatewayRunning;

  @JsonKey(name: 'gateway_state')
  final String? gatewayState;

  @JsonKey(name: 'gateway_busy')
  final bool gatewayBusy;

  @JsonKey(name: 'active_sessions')
  final int activeSessions;

  @JsonKey(name: 'active_agents')
  final int activeAgents;

  @JsonKey(name: 'auth_required')
  final bool authRequired;

  @JsonKey(name: 'auth_providers')
  final List<String> authProviders;

  /// Auth capability flags, e.g. `["cookie", "native_pkce"]` (gateway 0.20;
  /// `web_server.py:3190-3204`). Empty in loopback mode, absent on older
  /// gateways. `native_pkce` means the RFC 8252 loopback flow is brokerable.
  @JsonKey(name: 'auth_flows')
  final List<String>? authFlows;

  /// Profile names on the host (gateway 0.20).
  final List<String>? profiles;

  /// Gateway topology: `multiplex` | `single` | `multiple` | `none` |
  /// `unknown` (gateway 0.20).
  @JsonKey(name: 'gateway_mode')
  final String? gatewayMode;

  /// Per-gateway detail — one entry per profile with a LIVE gateway process
  /// (`web_server.py:2888` `_collect_profile_gateway_topology`). Carries host
  /// ports, so the gateway sends it **only in loopback mode** alongside the
  /// other recon fields; null in gated mode AND on older gateways.
  final List<GatewayTopologyEntryDto>? gateways;

  /// On-disk config schema version (gateway 0.20). `0` means a legacy config
  /// with no `_config_version` key at all (`config.py:1783`).
  @JsonKey(name: 'config_version')
  final int? configVersion;

  /// The schema version this gateway build ships (gateway 0.20). Below
  /// [configVersion] the user's config wants `hermes config migrate`.
  @JsonKey(name: 'latest_config_version')
  final int? latestConfigVersion;

  /// Whether this host's Hermes install can update itself (gateway 0.20);
  /// false when an outer launcher/image owns updates (`web_server.py:2122`).
  @JsonKey(name: 'can_update_hermes')
  final bool? canUpdateHermes;

  /// Whether the gateway can accept a begin-drain right now — live and in the
  /// `running` state (gateway 0.20; `gateway/status.py:1140`).
  @JsonKey(name: 'gateway_drainable')
  final bool? gatewayDrainable;

  /// Seconds a restart waits for in-flight turns to drain (gateway 0.20).
  /// Wire sends a float, so parse as [num] and narrow in [toDomain].
  @JsonKey(name: 'restart_drain_timeout')
  final num? restartDrainTimeout;

  /// Search-index rebuild progress — present **only while a rebuild is
  /// pending** (gateway 0.20; `hermes_state_search.py:83`). Absence is the
  /// common case and means "no rebuild", not "unknown".
  @JsonKey(name: 'fts_rebuild')
  final FtsRebuildDto? ftsRebuild;

  @JsonKey(name: 'hermes_home')
  final String? hermesHome;

  @JsonKey(name: 'config_path')
  final String? configPath;

  @JsonKey(name: 'env_path')
  final String? envPath;

  @JsonKey(name: 'gateway_pid')
  final int? gatewayPid;

  @JsonKey(name: 'gateway_health_url')
  final String? gatewayHealthUrl;

  Map<String, dynamic> toJson() => _$GatewayStatusDtoToJson(this);

  /// Fold into the clean domain model (no wire quirks above the data layer).
  GatewayStatus toDomain() {
    return GatewayStatus(
      version: version,
      releaseDate: releaseDate,
      gatewayRunning: gatewayRunning,
      gatewayState: gatewayState,
      gatewayBusy: gatewayBusy,
      activeSessions: activeSessions,
      activeAgents: activeAgents,
      authRequired: authRequired,
      authProviders: List<String>.unmodifiable(authProviders),
      authFlows: authFlows == null
          ? null
          : List<String>.unmodifiable(authFlows!),
      profiles: profiles == null ? null : List<String>.unmodifiable(profiles!),
      gatewayMode: gatewayMode,
      gateways: gateways == null
          ? null
          : List<GatewayTopologyEntry>.unmodifiable(
              gateways!.map((entry) => entry.toDomain()),
            ),
      configVersion: configVersion,
      latestConfigVersion: latestConfigVersion,
      canUpdateHermes: canUpdateHermes,
      gatewayDrainable: gatewayDrainable,
      restartDrainTimeout: restartDrainTimeout?.toDouble(),
      ftsRebuild: ftsRebuild?.toDomain(),
      hermesHome: hermesHome,
      configPath: configPath,
      envPath: envPath,
      gatewayPid: gatewayPid,
      gatewayHealthUrl: gatewayHealthUrl,
    );
  }
}

/// Wire DTO for one `gateways[]` entry of `GET /api/status`
/// (`web_server.py:2888`), loopback mode only.
@JsonSerializable()
class GatewayTopologyEntryDto {
  const GatewayTopologyEntryDto({
    this.profile,
    this.ports,
    this.servedProfiles,
  });

  factory GatewayTopologyEntryDto.fromJson(Map<String, dynamic> json) =>
      _$GatewayTopologyEntryDtoFromJson(json);

  /// The profile whose gateway this is, e.g. `default`.
  final String? profile;

  /// `platform -> host TCP port` for the port-binding platforms this gateway
  /// has up. Absent platforms simply aren't listed; `{}` is normal.
  final Map<String, int>? ports;

  /// The profiles this one gateway serves — present only when it multiplexes
  /// more than its own (`served_profiles`).
  @JsonKey(name: 'served_profiles')
  final List<String>? servedProfiles;

  Map<String, dynamic> toJson() => _$GatewayTopologyEntryDtoToJson(this);

  GatewayTopologyEntry toDomain() {
    return GatewayTopologyEntry(
      profile: profile ?? '',
      ports: Map<String, int>.unmodifiable(ports ?? const <String, int>{}),
      servedProfiles: List<String>.unmodifiable(
        servedProfiles ?? const <String>[],
      ),
    );
  }
}

/// Wire DTO for the `fts_rebuild` block of `GET /api/status`
/// (`hermes_state_search.py:83`).
@JsonSerializable()
class FtsRebuildDto {
  const FtsRebuildDto({this.pending, this.total, this.indexed, this.percent});

  factory FtsRebuildDto.fromJson(Map<String, dynamic> json) =>
      _$FtsRebuildDtoFromJson(json);

  /// Always `true` on the wire — the gateway omits the whole block when no
  /// rebuild is pending rather than sending `pending: false`.
  final bool? pending;

  /// Rows to index (the high-water mark captured when the index was dropped).
  final int? total;

  /// Rows backfilled so far.
  final int? indexed;

  /// Server-computed `0..100`.
  final int? percent;

  Map<String, dynamic> toJson() => _$FtsRebuildDtoToJson(this);

  FtsRebuild toDomain() {
    return FtsRebuild(
      total: total ?? 0,
      indexed: indexed ?? 0,
      percent: percent ?? 0,
    );
  }
}
