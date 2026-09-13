import 'package:flit/domain/models/model_option.dart';
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

/// Per-model capability metadata added by newer gateways.
@JsonSerializable()
class ModelCapabilitiesDto {
  const ModelCapabilitiesDto({
    this.contextWindow,
    this.maxOutputTokens,
    this.reasoning = false,
    this.tools = false,
    this.vision = false,
    this.audio = false,
    this.inputModalities = const <String>[],
    this.outputModalities = const <String>[],
    this.reasoningLevels = const <String>[],
    this.canDisableReasoning,
  });

  factory ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilitiesDtoFromJson(json);

  @JsonKey(name: 'context_window')
  final int? contextWindow;
  @JsonKey(name: 'max_output_tokens')
  final int? maxOutputTokens;
  final bool reasoning;
  final bool tools;
  final bool vision;
  final bool audio;
  @JsonKey(name: 'input_modalities')
  final List<String> inputModalities;
  @JsonKey(name: 'output_modalities')
  final List<String> outputModalities;
  @JsonKey(name: 'reasoning_levels')
  final List<String> reasoningLevels;
  @JsonKey(name: 'can_disable_reasoning')
  final bool? canDisableReasoning;

  Map<String, dynamic> toJson() => _$ModelCapabilitiesDtoToJson(this);

  ModelDetails toDomain() => ModelDetails(
    contextWindow: contextWindow,
    maxOutputTokens: maxOutputTokens,
    reasoning: reasoning,
    tools: tools,
    vision: vision,
    audio: audio,
    inputModalities: inputModalities,
    outputModalities: outputModalities,
    reasoningLevels: reasoningLevels,
    canDisableReasoning: canDisableReasoning,
  );
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
    this.capabilities = const <String, ModelCapabilitiesDto>{},
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

  @JsonKey(name: 'capabilities')
  final Map<String, ModelCapabilitiesDto> capabilities;

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
      modelDetails: capabilities.map(
        (model, details) => MapEntry(model, details.toDomain()),
      ),
    );
  }
}
