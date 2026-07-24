import 'package:hermes/data/dto/plugin_dtos.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/plugin_info.dart';
import 'package:hermes/domain/repositories/plugin_repository.dart';

/// [PluginRepository] over [GatewayRpcClient.request] (ticket P1-14).
///
/// Method name/result shape come VERBATIM from
/// docs/reference/03-mvp-wire-shapes.md §13 — never invent protocol.
/// Wire quirks (missing `version` → `'?'`) are absorbed by the DTO.
final class PluginRepositoryImpl implements PluginRepository {
  const PluginRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<List<PluginInfo>> list() async {
    // Wire §13: `plugins.list` with empty params.
    final result = await _client.request('plugins.list');
    return PluginsListResultDto.fromJson(result).toDomain();
  }
}
