// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_options_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelOptionsResultDto _$ModelOptionsResultDtoFromJson(
  Map<String, dynamic> json,
) => ModelOptionsResultDto(
  model: json['model'] as String?,
  provider: json['provider'] as String?,
  providers:
      (json['providers'] as List<dynamic>?)
          ?.map((e) => ModelProviderDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ModelProviderDto>[],
);

Map<String, dynamic> _$ModelOptionsResultDtoToJson(
  ModelOptionsResultDto instance,
) => <String, dynamic>{
  'model': instance.model,
  'provider': instance.provider,
  'providers': instance.providers,
};

ModelProviderDto _$ModelProviderDtoFromJson(Map<String, dynamic> json) =>
    ModelProviderDto(
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      authenticated: json['authenticated'] as bool?,
      isCurrent: json['is_current'] as bool?,
      authType: json['auth_type'] as String?,
      keyEnv: json['key_env'] as String?,
      models:
          (json['models'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      totalModels: (json['total_models'] as num?)?.toInt(),
      warning: json['warning'] as String?,
    );

Map<String, dynamic> _$ModelProviderDtoToJson(ModelProviderDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'slug': instance.slug,
      'authenticated': instance.authenticated,
      'is_current': instance.isCurrent,
      'auth_type': instance.authType,
      'key_env': instance.keyEnv,
      'models': instance.models,
      'total_models': instance.totalModels,
      'warning': instance.warning,
    };
