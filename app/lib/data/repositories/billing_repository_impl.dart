import 'package:flit/data/dto/billing_dtos.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/billing_state.dart';
import 'package:flit/domain/repositories/billing_repository.dart';

/// [BillingRepository] over [GatewayRpcClient.request] (tickets P8-04, P8-05).
///
/// Method names/result shapes come VERBATIM from the wire protocol.
/// CRITICAL: billing handlers return structured envelopes even on failure
/// (the RPC itself succeeds) — `ok:false` with an `error` string is a normal
/// result we render, NOT a thrown exception.
final class BillingRepositoryImpl implements BillingRepository {
  const BillingRepositoryImpl(this._client);

  final GatewayRpcClient _client;

  @override
  Future<BillingState> state() async {
    final result = await _client.request('billing.state');
    return BillingStateDto.fromJson(result).toDomain();
  }

  @override
  Future<BillingChargeResult> charge({
    required String amountUsd,
    String? idempotencyKey,
  }) async {
    final params = <String, dynamic>{'amount_usd': amountUsd};
    if (idempotencyKey != null) {
      params['idempotency_key'] = idempotencyKey;
    }
    final result = await _client.request('billing.charge', params);
    return BillingChargeResultDto.fromJson(result).toDomain();
  }

  @override
  Future<BillingChargeStatus> chargeStatus(String chargeId) async {
    final result = await _client.request(
      'billing.charge_status',
      <String, dynamic>{'charge_id': chargeId},
    );
    return BillingChargeStatusDto.fromJson(result).toDomain();
  }

  @override
  Future<BillingMutationResult> autoReload({
    required bool enabled,
    required num threshold,
    required num topUpAmount,
  }) async {
    final result = await _client.request(
      'billing.auto_reload',
      <String, dynamic>{
        'enabled': enabled,
        'threshold': threshold,
        'top_up_amount': topUpAmount,
      },
    );
    return BillingMutationResultDto.fromJson(result).toDomain();
  }

  @override
  Future<BillingMutationResult> stepUp({required String sessionId}) async {
    final result = await _client.request('billing.step_up', <String, dynamic>{
      'session_id': sessionId,
    });
    return BillingMutationResultDto.fromJson(result).toDomain();
  }
}
