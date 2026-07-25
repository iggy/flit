/// Riverpod wiring for model selection (ticket P1-11): the repository
/// provider, the refreshable `model.options` fetch, the picker's
/// interaction controller, and the merged current-model tracker.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/repositories/model_repository.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/repositories/model_repository.dart';

/// The model repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect) — mirroring the nullable
/// [sessionRepositoryProvider] pattern. Callers must handle null (the UI
/// only offers model actions while connected).
final modelRepositoryProvider = Provider<ModelRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ModelRepositoryImpl(client);
});

/// `model.options` for the picker (wire §8). Re-fetches on client swap
/// (reconnect); refresh after a change with
/// `ref.invalidate(modelOptionsProvider)` — [ModelPickerController] does
/// this automatically after a successful switch.
final modelOptionsProvider = FutureProvider<ModelOptions>((ref) async {
  final repository = ref.watch(modelRepositoryProvider);
  if (repository == null) {
    // Disconnected: an empty picker.
    return (
      current: const CurrentModel(model: '', provider: ''),
      providers: const <ModelProvider>[],
    );
  }
  return repository.options();
});

/// The latest known current model, exposed for compact surfaces (the app
/// bar button) that should not re-run `model.options`.
///
/// Merge of two sources, latest write wins:
/// 1. [modelOptionsProvider] results (seed on load; refresh after a
///    switch) — carries model AND provider.
/// 2. `session.info` events (wire §6/§9): after a successful switch the
///    gateway pushes one whose payload reflects the new model. Only
///    `payload.model` is pinned by the docs, so the provider slug is kept
///    from the previous state.
final currentModelProvider =
    NotifierProvider<CurrentModelNotifier, CurrentModel?>(
      CurrentModelNotifier.new,
    );

class CurrentModelNotifier extends Notifier<CurrentModel?> {
  @override
  CurrentModel? build() {
    ref.listen(modelOptionsProvider, (previous, next) {
      // SEED ONLY: once any truth source has set the state (an explicit
      // switch via [set], or a session.info push), a model.options
      // refetch must never regress it. The gateway's model.options
      // endpoint is not guaranteed to be immediately consistent right
      // after config.set — docs/reference/03-mvp-wire-shapes.md §9 pins
      // session.info (not a re-fetch) as the freshness signal for a
      // switch. Without this guard, invalidating modelOptionsProvider
      // after a switch can bounce the UI back to the stale model if the
      // gateway's refetch still reports the old value.
      if (state != null) {
        return;
      }
      final current = next.value?.current;
      if (current != null && current.model.isNotEmpty) {
        state = current;
      }
    });
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final model = event.info['model'];
        if (model is String && model.isNotEmpty) {
          state = CurrentModel(model: model, provider: state?.provider ?? '');
        }
      }
    });
    return null;
  }

  /// Set the current model directly (ticket P1-12 fix): called right after
  /// a successful `config.set{key:"model"}` apply so the UI reflects the
  /// switch immediately, without waiting on a `model.options` refetch
  /// (which may not be immediately consistent) or a `session.info` push
  /// (which requires an active session).
  void set(CurrentModel model) {
    state = model;
  }
}

/// Interaction state of the model picker.
final class ModelPickerState {
  const ModelPickerState({
    this.switching = false,
    this.needsConfirm,
    this.error,
  });

  /// A `config.set` call is in flight.
  final bool switching;

  /// The gateway's expensive-model confirm message (wire §9), or null.
  /// The UI shows the confirm dialog while non-null.
  final String? needsConfirm;

  /// Human-readable failure (token-redacted), or null. The controller
  /// NEVER throws — failures land here so the UI can show them inline.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is ModelPickerState &&
        other.switching == switching &&
        other.needsConfirm == needsConfirm &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(switching, needsConfirm, error);

  @override
  String toString() {
    return 'ModelPickerState(switching: $switching, '
        'needsConfirm: $needsConfirm, error: $error)';
  }
}

/// The picker's controller: select → `config.set`; expensive models →
/// confirm state; [confirmExpensive] re-sends with
/// `confirm_expensive_model:true` (wire §9).
final modelPickerControllerProvider =
    NotifierProvider<ModelPickerController, ModelPickerState>(
      ModelPickerController.new,
    );

class ModelPickerController extends Notifier<ModelPickerState> {
  @override
  ModelPickerState build() => const ModelPickerState();

  /// The option awaiting an expensive-model confirmation, so
  /// [confirmExpensive] can re-send the SAME model/provider.
  ModelOption? _pending;

  /// Switch to [option]. On [ModelSetNeedsConfirm] the message is stored
  /// in [ModelPickerState.needsConfirm] and nothing is applied yet.
  /// NEVER throws — failures land in [ModelPickerState.error].
  Future<void> select(ModelOption option) async {
    if (state.switching) {
      return;
    }
    final repository = ref.read(modelRepositoryProvider);
    if (repository == null) {
      state = const ModelPickerState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ModelPickerState(switching: true);
    try {
      final outcome = await repository.setModel(
        model: option.model,
        providerSlug: option.providerSlug,
      );
      _applyOutcome(outcome, option);
    } on GatewayException catch (error) {
      state = ModelPickerState(error: error.message);
    } on Object catch (error) {
      state = ModelPickerState(error: error.toString());
    }
  }

  /// Re-send the pending selection with `confirm_expensive_model:true`
  /// (wire §9) after the user confirmed the expensive-model dialog.
  Future<void> confirmExpensive() async {
    final option = _pending;
    final repository = ref.read(modelRepositoryProvider);
    if (option == null) {
      // Nothing pending (already applied or cancelled) — just clear.
      state = const ModelPickerState();
      return;
    }
    if (repository == null) {
      _pending = null;
      state = const ModelPickerState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ModelPickerState(switching: true);
    try {
      final outcome = await repository.setModelConfirmed(
        model: option.model,
        providerSlug: option.providerSlug,
      );
      _applyOutcome(outcome, option);
    } on GatewayException catch (error) {
      state = ModelPickerState(error: error.message);
    } on Object catch (error) {
      state = ModelPickerState(error: error.toString());
    }
  }

  /// Dismiss the expensive-model confirmation WITHOUT confirming (the
  /// dialog's Cancel path).
  void cancelConfirm() {
    _pending = null;
    state = const ModelPickerState();
  }

  /// Clear the inline error (the error banner's dismiss action).
  void clearError() {
    state = ModelPickerState(
      switching: state.switching,
      needsConfirm: state.needsConfirm,
    );
  }

  void _applyOutcome(ModelSetOutcome outcome, ModelOption option) {
    switch (outcome) {
      case ModelSetApplied(:final value):
        _pending = null;
        state = const ModelPickerState();
        // Update the UI's current-model tracker immediately: don't rely
        // solely on a model.options refetch (may not be immediately
        // consistent server-side) or a session.info push (requires an
        // active session) — both still happen and will keep it fresh.
        ref
            .read(currentModelProvider.notifier)
            .set(
              CurrentModel(
                model: value.isNotEmpty ? value : option.model,
                provider: option.providerSlug,
              ),
            );
        // Refresh the picker's badges/current markers.
        ref.invalidate(modelOptionsProvider);
      case ModelSetNeedsConfirm(:final message):
        // Defensive: a confirm AFTER confirm_expensive_model:true would
        // re-enter here (docs pin only the single-confirm flow) — the
        // dialog simply stays open with the new message.
        _pending = option;
        state = ModelPickerState(needsConfirm: message);
    }
  }
}
