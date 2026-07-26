import 'package:flit/domain/models/model_option.dart';

/// The picker's source data (wire §8): the currently active model plus the
/// provider list with auth state.
typedef ModelOptions = ({CurrentModel current, List<ModelProvider> providers});

/// Intent-level model operations (ticket P1-11).
///
/// Setting the active model is NOT a `model.*` RPC — it goes through
/// `config.set{key:"model", value:"<model> --provider <slug>"}`
/// (docs/reference/03-mvp-wire-shapes.md §9, 02-rpc-index.md "Models &
/// providers"). The value-string format is assembled BELOW this interface:
/// callers pass the model and provider slug separately.
abstract interface class ModelRepository {
  /// `model.options` (wire §8) → the current model + provider list.
  Future<ModelOptions> options();

  /// `config.set{key:"model", value:"<model> --provider <slug>"}` (wire §9).
  ///
  /// Returns [ModelSetNeedsConfirm] when the gateway flags the model as
  /// expensive (`confirm_required:true`) — re-send via [setModelConfirmed]
  /// to proceed.
  Future<ModelSetOutcome> setModel({
    required String model,
    required String providerSlug,
  });

  /// The confirm re-send (wire §9): same params as [setModel] plus
  /// `confirm_expensive_model:true`.
  Future<ModelSetOutcome> setModelConfirmed({
    required String model,
    required String providerSlug,
  });

  /// `model.save_key` — save a provider API key (ticket P4-01).
  ///
  /// Returns the refreshed provider entry (same shape as one
  /// `model.options` provider).
  Future<ModelProvider> saveKey({required String slug, required String apiKey});

  /// `model.disconnect` — clear provider credentials (ticket P4-01).
  Future<void> disconnectProvider({required String slug});
}

/// Domain-facing outcome of a `config.set{key:"model"}` call (wire §9).
sealed class ModelSetOutcome {
  const ModelSetOutcome();
}

/// The model was applied (wire `{value, info?}`).
final class ModelSetApplied extends ModelSetOutcome {
  const ModelSetApplied({required this.value});

  /// The applied model name (wire `value`).
  final String value;

  @override
  bool operator ==(Object other) {
    return other is ModelSetApplied && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ModelSetApplied(value: $value)';
}

/// The gateway demands confirmation before applying (wire
/// `{confirm_required:true, confirm_message}`) — re-send with
/// `confirm_expensive_model:true` via [ModelRepository.setModelConfirmed].
final class ModelSetNeedsConfirm extends ModelSetOutcome {
  const ModelSetNeedsConfirm({required this.message});

  /// The confirmation prompt to show, e.g.
  /// `This model is $X/Mtok. Continue?`.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is ModelSetNeedsConfirm && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ModelSetNeedsConfirm(message: $message)';
}
