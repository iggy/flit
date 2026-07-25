import 'package:flit/data/dto/config_set_result_dto.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
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
}
