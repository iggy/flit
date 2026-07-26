import 'package:flit/data/dto/process_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/background_process.dart';
import 'package:flit/domain/repositories/process_repository.dart';

/// [ProcessRepository] over [GatewayRpcClient.request] (ticket P5-03).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
final class ProcessRepositoryImpl implements ProcessRepository {
  const ProcessRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<List<BackgroundProcess>> list({String? sessionId}) async {
    final params = <String, dynamic>{'session_id': ?sessionId};
    final result = await _client.request('process.list', params);
    final dto = ProcessListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ProcessKillResult> kill(String processId, {String? sessionId}) async {
    final params = <String, dynamic>{
      'session_id': ?sessionId,
      'process_id': processId,
    };
    final result = await _client.request('process.kill', params);
    final dto = ProcessKillResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<int> stopAll() async {
    final result = await _client.request('process.stop');
    final dto = ProcessStopResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ShellExecResult> exec(String command) async {
    final params = <String, dynamic>{'command': command};
    final result = await _client.request('shell.exec', params);
    final dto = ShellExecResultDto.fromJson(result);
    return dto.toDomain();
  }
}
