import 'package:flit/data/dto/config_set_result_dto.dart';
import 'package:flit/data/dto/model_options_dto.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/repositories/model_repository.dart';

/// [ModelRepository] over [GatewayRpcClient.request] (ticket P1-11).
///
/// Method names/params come VERBATIM from
/// docs/reference/03-mvp-wire-shapes.md §8–§9 — never invent protocol.
/// Setting the model is NOT a `model.*` RPC (02-rpc-index.md "Models &
/// providers"): it is `config.set{key:"model"}`.
final class ModelRepositoryImpl implements ModelRepository {
  const ModelRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<ModelOptions> options() async {
    // Wire §8: no params.
    final result = await _client.request('model.options');
    final dto = ModelOptionsResultDto.fromJson(result);
    return (current: dto.toCurrentModel(), providers: dto.toProviders());
  }

  @override
  Future<ModelSetOutcome> setModel({
    required String model,
    required String providerSlug,
  }) {
    return _setModel(model: model, providerSlug: providerSlug, confirm: false);
  }

  @override
  Future<ModelSetOutcome> setModelConfirmed({
    required String model,
    required String providerSlug,
  }) {
    return _setModel(model: model, providerSlug: providerSlug, confirm: true);
  }

  /// Wire §9: `config.set{key:"model", value:"<model> --provider <slug>"}`;
  /// the confirm re-send adds `confirm_expensive_model:true`.
  Future<ModelSetOutcome> _setModel({
    required String model,
    required String providerSlug,
    required bool confirm,
  }) async {
    final result = await _client.request('config.set', <String, dynamic>{
      'key': 'model',
      'value': '$model --provider $providerSlug',
      if (confirm) 'confirm_expensive_model': true,
    });
    return switch (ConfigSetResultDto.fromJson(result).toDomain()) {
      // `value` is the applied model name for key:"model" (wire §9);
      // defensive '' for anything non-string.
      ConfigSetApplied(:final value) => ModelSetApplied(
        value: value is String ? value : '',
      ),
      ConfigSetConfirmRequired(:final message) => ModelSetNeedsConfirm(
        message: message,
      ),
    };
  }

  @override
  Future<ModelProvider> saveKey({
    required String slug,
    required String apiKey,
  }) async {
    final result = await _client.request('model.save_key', <String, dynamic>{
      'slug': slug,
      'api_key': apiKey,
    });
    final providerMap = result['provider'] as Map<String, dynamic>;
    final dto = ModelProviderDto.fromJson(providerMap);
    return dto.toDomain();
  }

  @override
  Future<void> disconnectProvider({required String slug}) async {
    await _client.request('model.disconnect', <String, dynamic>{'slug': slug});
  }
}
