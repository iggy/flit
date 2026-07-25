import 'package:flit/data/dto/rollback_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/rollback.dart';
import 'package:flit/domain/repositories/rollback_repository.dart';

/// [RollbackRepository] over [GatewayRpcClient.request] (tickets P6-05, P6-06).
///
/// Method name/result shape come VERBATIM from the wire protocol —
/// never invent protocol.
final class RollbackRepositoryImpl implements RollbackRepository {
  const RollbackRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<CheckpointList> list(String sessionId) async {
    // P6-05: `rollback.list {session_id}`.
    final result = await _client.request('rollback.list', <String, dynamic>{
      'session_id': sessionId,
    });
    return RollbackListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<CheckpointDiff> diff(String sessionId, String hash) async {
    // P6-05: `rollback.diff {session_id, hash}`.
    final result = await _client.request('rollback.diff', <String, dynamic>{
      'session_id': sessionId,
      'hash': hash,
    });
    return RollbackDiffResultDto.fromJson(result).toDomain();
  }

  @override
  Future<RestoreResult> restore(
    String sessionId,
    String hash, {
    String? filePath,
  }) async {
    // P6-06: `rollback.restore {session_id, hash, file_path?}`.
    final params = <String, dynamic>{
      'session_id': sessionId,
      'hash': hash,
    };
    if (filePath != null) {
      params['file_path'] = filePath;
    }
    final result = await _client.request('rollback.restore', params);
    return RollbackRestoreResultDto.fromJson(result).toDomain();
  }
}
