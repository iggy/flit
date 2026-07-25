import 'package:flit/data/dto/learning_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/learning_journey.dart';
import 'package:flit/domain/repositories/learning_repository.dart';

/// [LearningRepository] over [GatewayRpcClient.request] (tickets P6-01, P6-02).
///
/// Method name/result shape come VERBATIM from the wire protocol —
/// never invent protocol.
final class LearningRepositoryImpl implements LearningRepository {
  const LearningRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<LearningJourney> frames() async {
    // P6-01: `learning.frames {frames:2}`.
    final result = await _client.request('learning.frames', <String, dynamic>{
      'frames': 2,
    });
    return LearningFramesResultDto.fromJson(result).toDomain();
  }

  @override
  Future<LearningNodeDetail> detail(String id) async {
    // P6-02: `learning.detail {id}`.
    final result = await _client.request('learning.detail', <String, dynamic>{
      'id': id,
    });
    return LearningDetailResultDto.fromJson(result).toDomain();
  }

  @override
  Future<LearningMutationResult> edit(String id, String content) async {
    // P6-02: `learning.edit {id, content}`.
    final result = await _client.request('learning.edit', <String, dynamic>{
      'id': id,
      'content': content,
    });
    return LearningMutationResultDto.fromJson(result).toDomain();
  }

  @override
  Future<LearningMutationResult> delete(String id) async {
    // P6-02: `learning.delete {id}`.
    final result = await _client.request('learning.delete', <String, dynamic>{
      'id': id,
    });
    return LearningMutationResultDto.fromJson(result).toDomain();
  }
}
