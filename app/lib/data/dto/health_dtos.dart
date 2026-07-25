import 'package:flit/domain/models/health_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'health_dtos.g.dart';

/// Wire DTO for `setup.status` result (ticket P4-06).
@JsonSerializable()
class SetupStatusDto {
  const SetupStatusDto({this.providerConfigured});

  factory SetupStatusDto.fromJson(Map<String, dynamic> json) =>
      _$SetupStatusDtoFromJson(json);

  @JsonKey(name: 'provider_configured')
  final bool? providerConfigured;

  Map<String, dynamic> toJson() => _$SetupStatusDtoToJson(this);

  bool toDomain() => providerConfigured ?? false;
}

/// Wire DTO for `setup.runtime_check` result (ticket P4-06).
@JsonSerializable()
class RuntimeCheckDto {
  const RuntimeCheckDto({
    this.ok,
    this.provider,
    this.model,
    this.source,
    this.error,
  });

  factory RuntimeCheckDto.fromJson(Map<String, dynamic> json) =>
      _$RuntimeCheckDtoFromJson(json);

  @JsonKey(name: 'ok')
  final bool? ok;

  @JsonKey(name: 'provider')
  final String? provider;

  @JsonKey(name: 'model')
  final String? model;

  @JsonKey(name: 'source')
  final String? source;

  @JsonKey(name: 'error')
  final String? error;

  Map<String, dynamic> toJson() => _$RuntimeCheckDtoToJson(this);

  RuntimeCheck toDomain() {
    return RuntimeCheck(
      ok: ok ?? false,
      provider: provider ?? '',
      model: model ?? '',
      source: source ?? '',
      error: error,
    );
  }
}
