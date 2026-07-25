import 'package:flit/data/dto/delegation_dtos.dart';
import 'package:flit/data/dto/spawn_tree_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/agent_process.dart';
import 'package:flit/domain/models/delegation_status.dart';
import 'package:flit/domain/models/spawn_tree_snapshot.dart';
import 'package:flit/domain/repositories/delegation_repository.dart';

/// [DelegationRepository] over [GatewayRpcClient.request] (ticket P3-05, P3-06).
///
/// Method name/result shape come VERBATIM from
/// docs/reference/08-agent-transparency-wire-shapes.md — never invent protocol.
final class DelegationRepositoryImpl implements DelegationRepository {
  const DelegationRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<DelegationStatus> status() async {
    final result = await _client.request('delegation.status');
    return DelegationStatusResultDto.fromJson(result).toDomain();
  }

  @override
  Future<bool> setPaused(bool paused) async {
    final result = await _client.request('delegation.pause', {'paused': paused});
    final dto = DelegationPauseResultDto.fromJson(result);
    return dto.paused ?? paused;
  }

  @override
  Future<bool> interrupt(String subagentId) async {
    final result =
        await _client.request('subagent.interrupt', {'subagent_id': subagentId});
    final dto = SubagentInterruptResultDto.fromJson(result);
    return dto.found ?? false;
  }

  @override
  Future<List<AgentProcess>> agents() async {
    final result = await _client.request('agents.list');
    return AgentsListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<List<SpawnTreeSnapshotEntry>> listSnapshots(
    String sessionId, {
    int limit = 50,
    bool crossSession = false,
  }) async {
    final result = await _client.request('spawn_tree.list', <String, dynamic>{
      'session_id': sessionId,
      'limit': limit,
      'cross_session': crossSession,
    });
    return SpawnTreeListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<SpawnTreeSnapshot> loadSnapshot(String path) async {
    final result = await _client.request('spawn_tree.load', <String, dynamic>{
      'path': path,
    });
    return SpawnTreeLoadResultDto.fromJson(result).toDomain();
  }

  @override
  Future<String> saveSnapshot({
    required String sessionId,
    required List<dynamic> subagents,
    double? startedAt,
    required double finishedAt,
    required String label,
  }) async {
    final params = <String, dynamic>{
      'session_id': sessionId,
      'subagents': subagents,
      'finished_at': finishedAt,
      'label': label,
      'started_at': ?startedAt,
    };
    final result = await _client.request('spawn_tree.save', params);
    final dto = SpawnTreeSaveResultDto.fromJson(result);
    return dto.path ?? '';
  }
}
