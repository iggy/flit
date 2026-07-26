import 'package:flit/data/dto/tools_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/tool_catalog.dart';
import 'package:flit/domain/repositories/tools_repository.dart';

/// [ToolsRepository] over [GatewayRpcClient.request] (tickets P4-03, P4-04).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
final class ToolsRepositoryImpl implements ToolsRepository {
  const ToolsRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<List<Toolset>> listTools({String? sessionId}) async {
    final params = <String, dynamic>{'session_id': ?sessionId};
    final result = await _client.request('tools.list', params);
    final dto = ToolsListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<List<Toolset>> listToolsets({String? sessionId}) async {
    final params = <String, dynamic>{'session_id': ?sessionId};
    final result = await _client.request('toolsets.list', params);
    final dto = ToolsListResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ToolsShow> showTools({String? sessionId}) async {
    final params = <String, dynamic>{'session_id': ?sessionId};
    final result = await _client.request('tools.show', params);
    final dto = ToolsShowResultDto.fromJson(result);
    return dto.toDomain();
  }

  @override
  Future<ToolsConfigureResult> configure({
    required String action,
    required List<String> names,
    String? sessionId,
  }) async {
    final params = <String, dynamic>{
      'action': action,
      'names': names,
      'session_id': ?sessionId,
    };
    final result = await _client.request('tools.configure', params);
    final dto = ToolsConfigureResultDto.fromJson(result);
    return dto.toDomain();
  }
}
