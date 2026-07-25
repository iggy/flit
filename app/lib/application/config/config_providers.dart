library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/repositories/config_repository.dart';
import 'package:flit/domain/models/reasoning_option.dart';
import 'package:flit/domain/repositories/config_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final configRepositoryProvider = Provider<ConfigRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ConfigRepositoryImpl(client);
});

final reasoningOptionsProvider = Provider<List<ReasoningOption>>((ref) {
  return ReasoningOption.defaults;
});

final currentReasoningProvider =
    NotifierProvider<CurrentReasoningNotifier, String?>(CurrentReasoningNotifier.new);

class CurrentReasoningNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final reasoning = event.info['reasoning'];
        if (reasoning is String && reasoning.isNotEmpty) {
          state = reasoning;
        }
      }
    });
    return null;
  }

  Future<void> fetchInitial() async {
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      return;
    }
    if (state != null) {
      return;
    }
    try {
      final reasoning = await repository.getReasoning();
      if (reasoning != null && reasoning.isNotEmpty && state == null) {
        state = reasoning;
      }
    } on Object {
      // Ignore fetch failures; session.info will populate if connection is live
    }
  }

  void set(String value) {
    state = value;
  }
}

final class ReasoningPickerState {
  const ReasoningPickerState({
    this.switching = false,
    this.error,
  });

  final bool switching;
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is ReasoningPickerState &&
        other.switching == switching &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(switching, error);

  @override
  String toString() => 'ReasoningPickerState(switching: $switching, error: $error)';
}

final reasoningPickerControllerProvider =
    NotifierProvider<ReasoningPickerController, ReasoningPickerState>(
      ReasoningPickerController.new,
    );

class ReasoningPickerController extends Notifier<ReasoningPickerState> {
  @override
  ReasoningPickerState build() => const ReasoningPickerState();

  Future<void> select(String value) async {
    if (state.switching) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const ReasoningPickerState(error: 'Not connected to a gateway.');
      return;
    }
    state = const ReasoningPickerState(switching: true);
    try {
      final outcome = await repository.setReasoning(value);
      switch (outcome) {
        case ReasoningSetApplied(:final value):
          state = const ReasoningPickerState();
          ref.read(currentReasoningProvider.notifier).set(value);
        case ReasoningSetNeedsConfirm():
          state = const ReasoningPickerState();
          ref.read(currentReasoningProvider.notifier).set(value);
      }
    } on GatewayException catch (error) {
      state = ReasoningPickerState(error: error.message);
    } on Object catch (error) {
      state = ReasoningPickerState(error: error.toString());
    }
  }

  void clearError() {
    state = ReasoningPickerState(
      switching: state.switching,
    );
  }
}
