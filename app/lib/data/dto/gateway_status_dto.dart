import 'package:hermes/domain/models/gateway_status.dart';
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
      hermesHome: hermesHome,
      configPath: configPath,
      envPath: envPath,
      gatewayPid: gatewayPid,
      gatewayHealthUrl: gatewayHealthUrl,
    );
  }
}
