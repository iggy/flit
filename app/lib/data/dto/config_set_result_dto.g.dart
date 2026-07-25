// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_set_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigSetResultDto _$ConfigSetResultDtoFromJson(Map<String, dynamic> json) =>
    ConfigSetResultDto(
      value: json['value'],
      info: json['info'] as Map<String, dynamic>?,
      confirmRequired: json['confirm_required'] as bool?,
      confirmMessage: json['confirm_message'] as String?,
      warning: json['warning'] as String?,
    );

Map<String, dynamic> _$ConfigSetResultDtoToJson(ConfigSetResultDto instance) =>
    <String, dynamic>{
      'value': instance.value,
      'info': instance.info,
      'confirm_required': instance.confirmRequired,
      'confirm_message': instance.confirmMessage,
      'warning': instance.warning,
    };
