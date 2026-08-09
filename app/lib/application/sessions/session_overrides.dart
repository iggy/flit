/// Per-session overrides carried into `session.create` (wire §2, desktop
/// contract v4).
///
/// The gateway inherits any override that is NOT sent from the profile, so a
/// new chat used to silently reset the model/effort/fast picks the user made
/// in the current one. [sessionCreateOverridesProvider] snapshots those picks
/// so `session.create` can carry them forward.
library;

import 'package:flit/application/config/config_providers.dart';
import 'package:flit/application/models/model_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The model/effort/fast picks to send with `session.create`. A null field
/// means "not sent" — inherit the profile default. For [fast] that is
/// deliberately distinct from `false`, which PINS the normal tier.
final class SessionOverrides {
  const SessionOverrides({
    this.model,
    this.provider,
    this.reasoningEffort,
    this.fast,
  });

  /// Wire `model` — the current model name, or null when unknown.
  final String? model;

  /// Wire `provider` — slug serving [model]. Only meaningful with a model.
  final String? provider;

  /// Wire `reasoning_effort` — `high|medium|low`, parsed gateway-side by
  /// `parse_reasoning_effort`.
  final String? reasoningEffort;

  /// Wire `fast` — true pins the priority tier, false pins normal, null
  /// inherits the profile.
  final bool? fast;

  @override
  bool operator ==(Object other) {
    return other is SessionOverrides &&
        other.model == model &&
        other.provider == provider &&
        other.reasoningEffort == reasoningEffort &&
        other.fast == fast;
  }

  @override
  int get hashCode => Object.hash(model, provider, reasoningEffort, fast);

  @override
  String toString() {
    return 'SessionOverrides(model: $model, provider: $provider, '
        'reasoningEffort: $reasoningEffort, fast: $fast)';
  }
}

/// The current sticky picks, assembled from the model picker
/// ([currentModelProvider]) and the agent-settings trackers
/// ([currentReasoningProvider], [currentFastProvider]). Anything still
/// unknown is left null so the gateway falls back to the profile.
final sessionCreateOverridesProvider = Provider<SessionOverrides>((ref) {
  final model = ref.watch(currentModelProvider);
  final reasoning = ref.watch(currentReasoningProvider);
  final fast = ref.watch(currentFastProvider);
  final hasModel = model != null && model.model.isNotEmpty;
  return SessionOverrides(
    model: hasModel ? model.model : null,
    // The provider slug is only sent alongside a model — on its own it would
    // tell the gateway to serve an unspecified model from that provider.
    provider: hasModel && model.provider.isNotEmpty ? model.provider : null,
    reasoningEffort: (reasoning != null && reasoning.isNotEmpty)
        ? reasoning
        : null,
    fast: fast,
  );
});
