// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gateway_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GatewayStatusDto _$GatewayStatusDtoFromJson(Map<String, dynamic> json) =>
    GatewayStatusDto(
      version: json['version'] as String,
      gatewayRunning: json['gateway_running'] as bool,
      gatewayState: json['gateway_state'] as String?,
      gatewayBusy: json['gateway_busy'] as bool,
      activeSessions: (json['active_sessions'] as num).toInt(),
      activeAgents: (json['active_agents'] as num).toInt(),
      authRequired: json['auth_required'] as bool,
      authProviders: (json['auth_providers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      releaseDate: json['release_date'] as String?,
      authFlows: (json['auth_flows'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      profiles: (json['profiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gatewayMode: json['gateway_mode'] as String?,
      gateways: (json['gateways'] as List<dynamic>?)
          ?.map(
            (e) => GatewayTopologyEntryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      configVersion: (json['config_version'] as num?)?.toInt(),
      latestConfigVersion: (json['latest_config_version'] as num?)?.toInt(),
      canUpdateHermes: json['can_update_hermes'] as bool?,
      gatewayDrainable: json['gateway_drainable'] as bool?,
      restartDrainTimeout: json['restart_drain_timeout'] as num?,
      ftsRebuild: json['fts_rebuild'] == null
          ? null
          : FtsRebuildDto.fromJson(json['fts_rebuild'] as Map<String, dynamic>),
      hermesHome: json['hermes_home'] as String?,
      configPath: json['config_path'] as String?,
      envPath: json['env_path'] as String?,
      gatewayPid: (json['gateway_pid'] as num?)?.toInt(),
      gatewayHealthUrl: json['gateway_health_url'] as String?,
    );

Map<String, dynamic> _$GatewayStatusDtoToJson(GatewayStatusDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'release_date': instance.releaseDate,
      'gateway_running': instance.gatewayRunning,
      'gateway_state': instance.gatewayState,
      'gateway_busy': instance.gatewayBusy,
      'active_sessions': instance.activeSessions,
      'active_agents': instance.activeAgents,
      'auth_required': instance.authRequired,
      'auth_providers': instance.authProviders,
      'auth_flows': instance.authFlows,
      'profiles': instance.profiles,
      'gateway_mode': instance.gatewayMode,
      'gateways': instance.gateways,
      'config_version': instance.configVersion,
      'latest_config_version': instance.latestConfigVersion,
      'can_update_hermes': instance.canUpdateHermes,
      'gateway_drainable': instance.gatewayDrainable,
      'restart_drain_timeout': instance.restartDrainTimeout,
      'fts_rebuild': instance.ftsRebuild,
      'hermes_home': instance.hermesHome,
      'config_path': instance.configPath,
      'env_path': instance.envPath,
      'gateway_pid': instance.gatewayPid,
      'gateway_health_url': instance.gatewayHealthUrl,
    };

GatewayTopologyEntryDto _$GatewayTopologyEntryDtoFromJson(
  Map<String, dynamic> json,
) => GatewayTopologyEntryDto(
  profile: json['profile'] as String?,
  ports: (json['ports'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
  servedProfiles: (json['served_profiles'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$GatewayTopologyEntryDtoToJson(
  GatewayTopologyEntryDto instance,
) => <String, dynamic>{
  'profile': instance.profile,
  'ports': instance.ports,
  'served_profiles': instance.servedProfiles,
};

FtsRebuildDto _$FtsRebuildDtoFromJson(Map<String, dynamic> json) =>
    FtsRebuildDto(
      pending: json['pending'] as bool?,
      total: (json['total'] as num?)?.toInt(),
      indexed: (json['indexed'] as num?)?.toInt(),
      percent: (json['percent'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FtsRebuildDtoToJson(FtsRebuildDto instance) =>
    <String, dynamic>{
      'pending': instance.pending,
      'total': instance.total,
      'indexed': instance.indexed,
      'percent': instance.percent,
    };
