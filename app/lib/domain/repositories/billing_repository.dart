import 'package:flit/domain/models/billing_state.dart';

/// Intent-level billing & credits operations (tickets P8-04, P8-05).
abstract interface class BillingRepository {
  /// `billing.state` → current balance, card, caps, auto-reload.
  Future<BillingState> state();

  /// `billing.charge {amount_usd, idempotency_key?}` → initiate a top-up.
  Future<BillingChargeResult> charge({
    required String amountUsd,
    String? idempotencyKey,
  });

  /// `billing.charge_status {charge_id}` → poll charge progress.
  Future<BillingChargeStatus> chargeStatus(String chargeId);

  /// `billing.auto_reload {enabled, threshold, top_up_amount}` → configure.
  Future<BillingMutationResult> autoReload({
    required bool enabled,
    required num threshold,
    required num topUpAmount,
  });

  /// `billing.step_up {session_id}` → long-running device flow for granting
  /// charge permission. Gateway emits a `billing.step_up.verification` event
  /// with URL + code during the call.
  Future<BillingMutationResult> stepUp({required String sessionId});
}
