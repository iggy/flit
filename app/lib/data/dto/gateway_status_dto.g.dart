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
      'hermes_home': instance.hermesHome,
      'config_path': instance.configPath,
      'env_path': instance.envPath,
      'gateway_pid': instance.gatewayPid,
      'gateway_health_url': instance.gatewayHealthUrl,
    };
