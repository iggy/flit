import 'package:flit/data/dto/plugin_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/plugin_info.dart';
import 'package:flit/domain/repositories/plugin_repository.dart';

/// [PluginRepository] over [GatewayRpcClient.request] (ticket P1-14, P5-08).
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

  @override
  Future<List<PluginDetail>> manageList() async {
    // P5-08: `plugins.manage {action:'list'}`.
    final result = await _client.request('plugins.manage', <String, dynamic>{
      'action': 'list',
    });
    return PluginsManageResultDto.fromJson(result).toDomain();
  }

  @override
  Future<PluginDetail?> toggle(String name, bool enable) async {
    // P5-08: `plugins.manage {action:'toggle', name, enable}`.
    // Wire field is `enable`, NOT `enabled`.
    final result = await _client.request('plugins.manage', <String, dynamic>{
      'action': 'toggle',
      'name': name,
      'enable': enable,
    });
    return PluginToggleResultDto.fromJson(result).toDomain();
  }
}
