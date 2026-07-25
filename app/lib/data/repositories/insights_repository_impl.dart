import 'package:flit/data/dto/insights_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/insights.dart';
import 'package:flit/domain/repositories/insights_repository.dart';

/// [InsightsRepository] over [GatewayRpcClient.request] (ticket P6-03).
///
/// Method name/result shape come VERBATIM from the wire protocol —
/// never invent protocol.
final class InsightsRepositoryImpl implements InsightsRepository {
  const InsightsRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<Insights> get({int days = 30}) async {
    // P6-03: `insights.get {days}` → `{days, sessions, messages}`.
    final result = await _client.request('insights.get', <String, dynamic>{
      'days': days,
    });
    return InsightsResultDto.fromJson(result).toDomain();
  }
}
