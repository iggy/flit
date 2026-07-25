import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/cron_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/cron_job.dart';
import 'package:flit/domain/repositories/cron_repository.dart';

/// [CronRepository] over [GatewayRpcClient.request] (ticket P5-01).
///
/// Method names/params come VERBATIM from wire protocol: never invent fields.
final class CronRepositoryImpl implements CronRepository {
  const CronRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<List<CronJob>> list() async {
    final params = <String, dynamic>{
      'action': 'list',
    };
    final result = await _client.request('cron.manage', params);
    final dto = CronManageResultDto.fromJson(result);

    // Check for failure result.
    if (dto.success == false) {
      throw GatewayRpcException(
        -1,
        dto.error ?? 'Cron list failed',
      );
    }

    return dto.toDomainList();
  }

  @override
  Future<void> add({
    required String prompt,
    required String schedule,
    String? name,
  }) async {
    final params = <String, dynamic>{
      'action': 'add',
      'prompt': prompt,
      'schedule': schedule,
      'name': ?name,
    };
    final result = await _client.request('cron.manage', params);
    final dto = CronManageResultDto.fromJson(result);

    // Check for failure result.
    if (dto.success == false) {
      throw GatewayRpcException(
        -1,
        dto.error ?? dto.message ?? 'Cron add failed',
      );
    }
  }

  @override
  Future<void> remove(String jobId) async {
    final params = <String, dynamic>{
      'action': 'remove',
      'name': jobId,
    };
    final result = await _client.request('cron.manage', params);
    final dto = CronManageResultDto.fromJson(result);

    // Check for failure result.
    if (dto.success == false) {
      throw GatewayRpcException(
        -1,
        dto.error ?? dto.message ?? 'Cron remove failed',
      );
    }
  }

  @override
  Future<void> pause(String jobId) async {
    final params = <String, dynamic>{
      'action': 'pause',
      'name': jobId,
    };
    final result = await _client.request('cron.manage', params);
    final dto = CronManageResultDto.fromJson(result);

    // Check for failure result.
    if (dto.success == false) {
      throw GatewayRpcException(
        -1,
        dto.error ?? dto.message ?? 'Cron pause failed',
      );
    }
  }

  @override
  Future<void> resume(String jobId) async {
    final params = <String, dynamic>{
      'action': 'resume',
      'name': jobId,
    };
    final result = await _client.request('cron.manage', params);
    final dto = CronManageResultDto.fromJson(result);

    // Check for failure result.
    if (dto.success == false) {
      throw GatewayRpcException(
        -1,
        dto.error ?? dto.message ?? 'Cron resume failed',
      );
    }
  }
}
