// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetupStatusDto _$SetupStatusDtoFromJson(Map<String, dynamic> json) =>
    SetupStatusDto(providerConfigured: json['provider_configured'] as bool?);

Map<String, dynamic> _$SetupStatusDtoToJson(SetupStatusDto instance) =>
    <String, dynamic>{'provider_configured': instance.providerConfigured};

RuntimeCheckDto _$RuntimeCheckDtoFromJson(Map<String, dynamic> json) =>
    RuntimeCheckDto(
      ok: json['ok'] as bool?,
      provider: json['provider'] as String?,
      model: json['model'] as String?,
      source: json['source'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$RuntimeCheckDtoToJson(RuntimeCheckDto instance) =>
    <String, dynamic>{
      'ok': instance.ok,
      'provider': instance.provider,
      'model': instance.model,
      'source': instance.source,
      'error': instance.error,
    };
