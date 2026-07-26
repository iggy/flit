/// Riverpod wiring for billing (tickets P8-04, P8-05): repository provider,
/// state fetch, and step-up verification event stream.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/billing_repository_impl.dart';
import 'package:flit/domain/models/billing_state.dart';
import 'package:flit/domain/repositories/billing_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The billing repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final billingRepositoryProvider = Provider<BillingRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return BillingRepositoryImpl(client);
});

/// `billing.state` for the current connection. Returns null when disconnected
/// (no repository). Re-fetches on client swap (reconnect); refresh with
/// `ref.invalidate(billingStateProvider)`.
final billingStateProvider = FutureProvider<BillingState?>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.state();
});

/// Step-up verification data: URL and user code from
/// `billing.step_up.verification` events. Cleared on new verification or when
/// the step-up completes.
final class StepUpVerification {
  const StepUpVerification({
    required this.verificationUrl,
    required this.userCode,
  });

  final String verificationUrl;
  final String userCode;

  @override
  bool operator ==(Object other) {
    return other is StepUpVerification &&
        other.verificationUrl == verificationUrl &&
        other.userCode == userCode;
  }

  @override
  int get hashCode => Object.hash(verificationUrl, userCode);

  @override
  String toString() =>
      'StepUpVerification(url: $verificationUrl, code: $userCode)';
}

/// Latest step-up verification data from the gateway. Updated when the
/// gateway sends a `billing.step_up.verification` event during a step-up call.
/// Cleared when consumed or when a new step-up starts.
final stepUpVerificationProvider =
    NotifierProvider<StepUpVerificationNotifier, StepUpVerification?>(
      StepUpVerificationNotifier.new,
    );

class StepUpVerificationNotifier extends Notifier<StepUpVerification?> {
  @override
  StepUpVerification? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final event = next.value;
      if (event == null) {
        return;
      }
      if (event.type == 'billing.step_up.verification') {
        final url = event.payload['verification_url'] as String?;
        final code = event.payload['user_code'] as String?;
        if (url != null && code != null) {
          state = StepUpVerification(verificationUrl: url, userCode: code);
        }
      }
    });
    return null;
  }

  void clear() {
    state = null;
  }
}
