import 'package:flit/data/dto/reload_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/repositories/reload_repository.dart';

/// [ReloadRepository] over [GatewayRpcClient.request] (ticket P4-05).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
final class ReloadRepositoryImpl implements ReloadRepository {
  const ReloadRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<ReloadMcpOutcome> reloadMcp({
    String? sessionId,
    bool confirm = false,
  }) async {
    final params = <String, dynamic>{
      'session_id': ?sessionId,
      if (confirm) 'confirm': true,
    };
    final result = await _client.request('reload.mcp', params);
    final dto = ReloadMcpResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<int> reloadEnv() async {
    final result = await _client.request('reload.env');
    return result['updated'] as int? ?? 0;
  }
}
