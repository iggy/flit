import 'package:flit/data/dto/skills_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/skill_catalog.dart';
import 'package:flit/domain/repositories/skills_repository.dart';

/// [SkillsRepository] over [GatewayRpcClient.request] (ticket P5-09).
///
/// Method name/result shape come VERBATIM from the wire protocol —
/// never invent protocol.
final class SkillsRepositoryImpl implements SkillsRepository {
  const SkillsRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<SkillCatalog> list() async {
    // P5-09: `skills.manage {action:'list'}`.
    final result = await _client.request('skills.manage', <String, dynamic>{
      'action': 'list',
    });
    return SkillsListResultDto.fromJson(result).toDomain();
  }

  @override
  Future<SkillBrowseResult> browse({int page = 1, int pageSize = 20}) async {
    // P5-09: `skills.manage {action:'browse', page, page_size}`.
    final result = await _client.request('skills.manage', <String, dynamic>{
      'action': 'browse',
      'page': page,
      'page_size': pageSize,
    });
    return SkillsBrowseResultDto.fromJson(result).toDomain();
  }

  @override
  Future<SkillReloadResult> reload() async {
    // P5-09: `skills.reload {}`.
    final result = await _client.request('skills.reload');
    return SkillsReloadResultDto.fromJson(result).toDomain();
  }
}
