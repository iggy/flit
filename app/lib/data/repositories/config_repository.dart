import 'package:flit/data/dto/config_set_result_dto.dart';
import 'package:flit/data/dto/config_show_dto.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/config_view.dart';
import 'package:flit/domain/repositories/config_repository.dart';

final class ConfigRepositoryImpl implements ConfigRepository {
  const ConfigRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<String?> getReasoning() async {
    final result = await _client.request('config.get', <String, dynamic>{
      'key': 'reasoning',
    });
    final value = result['value'];
    return value is String ? value : null;
  }

  @override
  Future<ReasoningSetOutcome> setReasoning(String value) async {
    final result = await _client.request('config.set', <String, dynamic>{
      'key': 'reasoning',
      'value': value,
    });
    return switch (ConfigSetResultDto.fromJson(result).toDomain()) {
      ConfigSetApplied(:final value) => ReasoningSetApplied(
        value: value is String ? value : '',
      ),
      ConfigSetConfirmRequired(:final message) => ReasoningSetNeedsConfirm(
        message: message,
      ),
    };
  }

  @override
  Future<bool> getFast() async {
    final result = await _client.request('config.get', <String, dynamic>{
      'key': 'fast',
    });
    final value = result['value'];
    return value is String && value == 'fast';
  }

  @override
  Future<void> setFast(bool value) async {
    await _client.request('config.set', <String, dynamic>{
      'key': 'fast',
      'value': value ? 'fast' : 'normal',
    });
  }

  @override
  Future<String?> getPersonality() async {
    final result = await _client.request('config.get', <String, dynamic>{
      'key': 'personality',
    });
    final value = result['value'];
    return value is String ? value : null;
  }

  @override
  Future<void> setPersonality(String value) async {
    await _client.request('config.set', <String, dynamic>{
      'key': 'personality',
      'value': value,
    });
  }

  @override
  Future<String?> getPrompt() async {
    final result = await _client.request('config.get', <String, dynamic>{
      'key': 'prompt',
    });
    final prompt = result['prompt'];
    return prompt is String ? prompt : null;
  }

  @override
  Future<void> setPrompt(String value) async {
    await _client.request('config.set', <String, dynamic>{
      'key': 'prompt',
      'value': value.isEmpty ? 'clear' : value,
    });
  }

  @override
  Future<List<ConfigSection>> showConfig() async {
    final result = await _client.request('config.show', <String, dynamic>{});
    return ConfigShowResultDto.fromJson(result).toDomain();
  }

  @override
  Future<Map<String, dynamic>> getKey(String key, {String? sessionId}) async {
    final params = <String, dynamic>{'key': key};
    if (sessionId != null) {
      params['session_id'] = sessionId;
    }
    return _client.request('config.get', params);
  }

  @override
  Future<ConfigSetOutcome> setKey(
    String key,
    dynamic value, {
    String? sessionId,
    bool confirmExpensive = false,
  }) async {
    final params = <String, dynamic>{'key': key, 'value': value};
    if (sessionId != null) {
      params['session_id'] = sessionId;
    }
    if (confirmExpensive) {
      params['confirm_expensive_model'] = true;
    }
    final result = await _client.request('config.set', params);
    return switch (ConfigSetResultDto.fromJson(result).toDomain()) {
      ConfigSetApplied(:final value, :final warning) => ConfigKeyApplied(
        value: value,
        warning: warning,
      ),
      ConfigSetConfirmRequired(:final message) => ConfigKeyNeedsConfirm(
        message,
      ),
    };
  }
}
