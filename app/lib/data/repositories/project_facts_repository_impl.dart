import 'package:flit/data/dto/project_facts_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/project_facts.dart';
import 'package:flit/domain/repositories/project_facts_repository.dart';

/// [ProjectFactsRepository] over [GatewayRpcClient.request] (ticket P6-04).
///
/// Method name/result shape come VERBATIM from the wire protocol —
/// never invent protocol.
final class ProjectFactsRepositoryImpl implements ProjectFactsRepository {
  const ProjectFactsRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<ProjectFacts?> facts({String? cwd}) async {
    // P6-04: `project.facts {cwd?}` → `{facts: {...}}` or `{facts: null}`.
    final params = <String, dynamic>{};
    if (cwd != null) {
      params['cwd'] = cwd;
    }
    final result = await _client.request('project.facts', params);
    return ProjectFactsResultDto.fromJson(result).toDomain();
  }
}
