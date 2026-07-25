// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reload_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReloadMcpResultDto _$ReloadMcpResultDtoFromJson(Map<String, dynamic> json) =>
    ReloadMcpResultDto(
      status: json['status'] as String?,
      message: json['message'] as String?,
      coalesced: json['coalesced'] as bool?,
    );

Map<String, dynamic> _$ReloadMcpResultDtoToJson(ReloadMcpResultDto instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'coalesced': instance.coalesced,
    };
