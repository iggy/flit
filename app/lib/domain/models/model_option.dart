import 'package:hermes/domain/models/deep_equals.dart';

/// One provider entry of `model.options` (wire §8) — a model source with
/// its auth state and the models it offers.
final class ModelProvider {
  const ModelProvider({
    required this.name,
    required this.slug,
    required this.authenticated,
    required this.isCurrent,
    this.authType,
    this.keyEnv,
    this.models = const <String>[],
    this.totalModels,
    this.warning,
  });

  /// Display name, e.g. `Nous Portal`.
  final String name;

  /// Provider slug, e.g. `nous` — used in
  /// `config.set{key:"model", value:"<model> --provider <slug>"}` (wire §9).
  final String slug;

  /// Whether the gateway has credentials for this provider.
  final bool authenticated;

  /// Whether this provider serves the current model.
  final bool isCurrent;

  /// Auth mechanism, e.g. `oauth` (wire `auth_type`).
  final String? authType;

  /// Env var holding the API key, e.g. `NOUS_API_KEY` (wire `key_env`).
  final String? keyEnv;

  /// Models this provider offers.
  final List<String> models;

  /// Total model count (wire `total_models`), when reported.
  final int? totalModels;

  /// Problem hint, e.g. `no key`.
  final String? warning;

  @override
  bool operator ==(Object other) {
    return other is ModelProvider &&
        other.name == name &&
        other.slug == slug &&
        other.authenticated == authenticated &&
        other.isCurrent == isCurrent &&
        other.authType == authType &&
        other.keyEnv == keyEnv &&
        deepListEquals(other.models, models) &&
        other.totalModels == totalModels &&
        other.warning == warning;
  }

  @override
  int get hashCode => Object.hash(
    name,
    slug,
    authenticated,
    isCurrent,
    authType,
    keyEnv,
    Object.hashAll(models),
    totalModels,
    warning,
  );

  @override
  String toString() {
    return 'ModelProvider(name: $name, slug: $slug, '
        'authenticated: $authenticated, isCurrent: $isCurrent, '
        'authType: $authType, keyEnv: $keyEnv, models: $models, '
        'totalModels: $totalModels, warning: $warning)';
  }
}

/// A flattened pickable entry: one model offered by one provider. Built by
/// flattening [ModelProvider.models] across providers for the picker.
final class ModelOption {
  const ModelOption({required this.providerSlug, required this.model});

  /// Slug of the provider offering [model].
  final String providerSlug;

  /// Model name, e.g. `hermes-4-70b`.
  final String model;

  @override
  bool operator ==(Object other) {
    return other is ModelOption &&
        other.providerSlug == providerSlug &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(providerSlug, model);

  @override
  String toString() =>
      'ModelOption(providerSlug: $providerSlug, model: $model)';
}

/// The currently active model (wire §8 top-level `model` + `provider`).
final class CurrentModel {
  const CurrentModel({required this.model, required this.provider});

  /// Current model name, e.g. `hermes-4-405b`.
  final String model;

  /// Slug of the provider serving it, e.g. `nous`.
  final String provider;

  @override
  bool operator ==(Object other) {
    return other is CurrentModel &&
        other.model == model &&
        other.provider == provider;
  }

  @override
  int get hashCode => Object.hash(model, provider);

  @override
  String toString() => 'CurrentModel(model: $model, provider: $provider)';
}
