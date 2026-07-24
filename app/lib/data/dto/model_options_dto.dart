import 'package:hermes/domain/models/model_option.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_options_dto.g.dart';

/// Wire DTO for the `model.options` result
/// (docs/reference/03-mvp-wire-shapes.md §8).
@JsonSerializable()
class ModelOptionsResultDto {
  const ModelOptionsResultDto({
    this.model,
    this.provider,
    this.providers = const <ModelProviderDto>[],
  });

  factory ModelOptionsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ModelOptionsResultDtoFromJson(json);

  /// Current model name.
  @JsonKey(name: 'model')
  final String? model;

  /// Current provider slug.
  @JsonKey(name: 'provider')
  final String? provider;

  @JsonKey(name: 'providers')
  final List<ModelProviderDto> providers;

  Map<String, dynamic> toJson() => _$ModelOptionsResultDtoToJson(this);

  /// The currently active model.
  CurrentModel toCurrentModel() {
    return CurrentModel(model: model ?? '', provider: provider ?? '');
  }

  /// The provider list for the picker.
  List<ModelProvider> toProviders() {
    return providers.map((dto) => dto.toDomain()).toList();
  }

  /// Flattened pickable entries: one [ModelOption] per
  /// (provider, model) pair.
  List<ModelOption> toModelOptions() {
    return toProviders()
        .expand(
          (p) =>
              p.models.map((m) => ModelOption(providerSlug: p.slug, model: m)),
        )
        .toList();
  }
}

/// One provider entry of `model.options` (§8).
@JsonSerializable()
class ModelProviderDto {
  const ModelProviderDto({
    this.name,
    this.slug,
    this.authenticated,
    this.isCurrent,
    this.authType,
    this.keyEnv,
    this.models = const <String>[],
    this.totalModels,
    this.warning,
  });

  factory ModelProviderDto.fromJson(Map<String, dynamic> json) =>
      _$ModelProviderDtoFromJson(json);

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'slug')
  final String? slug;

  @JsonKey(name: 'authenticated')
  final bool? authenticated;

  @JsonKey(name: 'is_current')
  final bool? isCurrent;

  @JsonKey(name: 'auth_type')
  final String? authType;

  @JsonKey(name: 'key_env')
  final String? keyEnv;

  @JsonKey(name: 'models')
  final List<String> models;

  @JsonKey(name: 'total_models')
  final int? totalModels;

  @JsonKey(name: 'warning')
  final String? warning;

  Map<String, dynamic> toJson() => _$ModelProviderDtoToJson(this);

  ModelProvider toDomain() {
    return ModelProvider(
      name: name ?? '',
      slug: slug ?? '',
      authenticated: authenticated ?? false,
      isCurrent: isCurrent ?? false,
      authType: authType,
      keyEnv: keyEnv,
      models: models,
      totalModels: totalModels,
      warning: warning,
    );
  }
}
