import 'package:flit/data/dto/health_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/health_status.dart';
import 'package:flit/domain/repositories/health_repository.dart';

final class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<bool> setupStatus() async {
    final result = await _client.request('setup.status', <String, dynamic>{});
    return SetupStatusDto.fromJson(result).toDomain();
  }

  @override
  Future<RuntimeCheck> runtimeCheck({String? provider}) async {
    final params = <String, dynamic>{};
    if (provider != null) {
      params['provider'] = provider;
    }
    final result = await _client.request('setup.runtime_check', params);
    return RuntimeCheckDto.fromJson(result).toDomain();
  }

  @override
  Future<String> verificationStatus({
    String? sessionId,
    String? cwd,
  }) async {
    final params = <String, dynamic>{};
    if (sessionId != null) {
      params['session_id'] = sessionId;
    }
    if (cwd != null) {
      params['cwd'] = cwd;
    }
    final result = await _client.request('verification.status', params);
    // Result is nested under 'verification' key
    final verification = result['verification'];
    if (verification is Map<String, dynamic>) {
      final status = verification['status'];
      return status is String ? status : 'unknown';
    }
    return 'unknown';
  }
}
