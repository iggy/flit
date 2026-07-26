library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/repositories/config_repository.dart';
import 'package:flit/domain/models/config_view.dart';
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
    NotifierProvider<CurrentReasoningNotifier, String?>(
      CurrentReasoningNotifier.new,
    );

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
  const ReasoningPickerState({this.switching = false, this.error});

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
  String toString() =>
      'ReasoningPickerState(switching: $switching, error: $error)';
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
    state = ReasoningPickerState(switching: state.switching);
  }
}

/// Current "fast" setting (ticket P4-02).
final currentFastProvider = NotifierProvider<CurrentFastNotifier, bool?>(
  CurrentFastNotifier.new,
);

class CurrentFastNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final fast = event.info['fast'];
        if (fast is String) {
          state = fast == 'fast';
        } else if (fast is bool) {
          state = fast;
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
      final fast = await repository.getFast();
      if (state == null) {
        state = fast;
      }
    } on Object {
      // Ignore fetch failures; session.info will populate if connection is live
    }
  }

  void set(bool value) {
    state = value;
  }
}

/// Current personality setting (ticket P4-02).
final currentPersonalityProvider =
    NotifierProvider<CurrentPersonalityNotifier, String?>(
      CurrentPersonalityNotifier.new,
    );

class CurrentPersonalityNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final personality = event.info['personality'];
        if (personality is String && personality.isNotEmpty) {
          state = personality;
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
      final personality = await repository.getPersonality();
      if (personality != null && personality.isNotEmpty && state == null) {
        state = personality;
      }
    } on Object {
      // Ignore fetch failures; session.info will populate if connection is live
    }
  }

  void set(String value) {
    state = value;
  }
}

/// Current system prompt setting (ticket P4-02).
final currentPromptProvider = NotifierProvider<CurrentPromptNotifier, String?>(
  CurrentPromptNotifier.new,
);

class CurrentPromptNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        final prompt = event.info['prompt'];
        if (prompt is String) {
          state = prompt;
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
      final prompt = await repository.getPrompt();
      if (state == null) {
        state = prompt;
      }
    } on Object {
      // Ignore fetch failures; session.info will populate if connection is live
    }
  }

  void set(String value) {
    state = value;
  }
}

/// Interaction state for agent settings (ticket P4-02).
final class AgentSettingsState {
  const AgentSettingsState({this.busy = false, this.error});

  final bool busy;
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is AgentSettingsState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() => 'AgentSettingsState(busy: $busy, error: $error)';
}

/// Controller for agent settings: fast, personality, prompt. NEVER throws;
/// failures land in [AgentSettingsState.error].
final agentSettingsControllerProvider =
    NotifierProvider<AgentSettingsController, AgentSettingsState>(
      AgentSettingsController.new,
    );

class AgentSettingsController extends Notifier<AgentSettingsState> {
  @override
  AgentSettingsState build() => const AgentSettingsState();

  Future<void> setFast(bool value) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const AgentSettingsState(error: 'Not connected to a gateway.');
      return;
    }
    state = const AgentSettingsState(busy: true);
    try {
      await repository.setFast(value);
      state = const AgentSettingsState();
      ref.read(currentFastProvider.notifier).set(value);
    } on GatewayException catch (error) {
      state = AgentSettingsState(error: error.message);
    } on Object catch (error) {
      state = AgentSettingsState(error: error.toString());
    }
  }

  Future<void> setPersonality(String value) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const AgentSettingsState(error: 'Not connected to a gateway.');
      return;
    }
    state = const AgentSettingsState(busy: true);
    try {
      await repository.setPersonality(value);
      state = const AgentSettingsState();
      ref.read(currentPersonalityProvider.notifier).set(value);
    } on GatewayException catch (error) {
      state = AgentSettingsState(error: error.message);
    } on Object catch (error) {
      state = AgentSettingsState(error: error.toString());
    }
  }

  Future<void> setPrompt(String value) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const AgentSettingsState(error: 'Not connected to a gateway.');
      return;
    }
    state = const AgentSettingsState(busy: true);
    try {
      await repository.setPrompt(value);
      state = const AgentSettingsState();
      ref.read(currentPromptProvider.notifier).set(value);
    } on GatewayException catch (error) {
      state = AgentSettingsState(error: error.message);
    } on Object catch (error) {
      state = AgentSettingsState(error: error.toString());
    }
  }

  void clearError() {
    state = AgentSettingsState(busy: state.busy);
  }
}

/// Config show provider (ticket P4-06) — list all config sections.
final configShowProvider = FutureProvider<List<ConfigSection>>((ref) async {
  final repository = ref.watch(configRepositoryProvider);
  if (repository == null) {
    return const <ConfigSection>[];
  }
  return repository.showConfig();
});

/// Config editor controller state (ticket P4-06).
final class ConfigEditorState {
  const ConfigEditorState({
    this.busy = false,
    this.error,
    this.warning,
    this.confirmMessage,
    this.pendingKey,
    this.pendingValue,
  });

  final bool busy;
  final String? error;
  final String? warning;
  final String? confirmMessage;
  final String? pendingKey;
  final dynamic pendingValue;

  @override
  bool operator ==(Object other) {
    return other is ConfigEditorState &&
        other.busy == busy &&
        other.error == error &&
        other.warning == warning &&
        other.confirmMessage == confirmMessage &&
        other.pendingKey == pendingKey &&
        other.pendingValue == pendingValue;
  }

  @override
  int get hashCode => Object.hash(
    busy,
    error,
    warning,
    confirmMessage,
    pendingKey,
    pendingValue,
  );

  @override
  String toString() {
    return 'ConfigEditorState(busy: $busy, error: $error, warning: $warning, '
        'confirmMessage: $confirmMessage, pendingKey: $pendingKey, '
        'pendingValue: $pendingValue)';
  }
}

/// Config editor controller (ticket P4-06). NEVER throws; errors land in
/// [ConfigEditorState.error].
final configEditorControllerProvider =
    NotifierProvider<ConfigEditorController, ConfigEditorState>(
      ConfigEditorController.new,
    );

class ConfigEditorController extends Notifier<ConfigEditorState> {
  @override
  ConfigEditorState build() => const ConfigEditorState();

  Future<void> setKey(String key, String value) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const ConfigEditorState(error: 'Not connected to a gateway.');
      return;
    }
    final liveId = ref.read(activeSessionProvider).liveId;
    state = const ConfigEditorState(busy: true);
    try {
      final outcome = await repository.setKey(key, value, sessionId: liveId);
      switch (outcome) {
        case ConfigKeyApplied(:final warning):
          state = ConfigEditorState(
            warning: warning != null && warning.isNotEmpty ? warning : null,
          );
          ref.invalidate(configShowProvider);
        case ConfigKeyNeedsConfirm(:final message):
          state = ConfigEditorState(
            confirmMessage: message,
            pendingKey: key,
            pendingValue: value,
          );
      }
    } on GatewayException catch (error) {
      state = ConfigEditorState(error: error.message);
    } on Object catch (error) {
      state = ConfigEditorState(error: error.toString());
    }
  }

  Future<void> confirmSet(String key, String value) async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(configRepositoryProvider);
    if (repository == null) {
      state = const ConfigEditorState(error: 'Not connected to a gateway.');
      return;
    }
    final liveId = ref.read(activeSessionProvider).liveId;
    state = const ConfigEditorState(busy: true);
    try {
      final outcome = await repository.setKey(
        key,
        value,
        sessionId: liveId,
        confirmExpensive: true,
      );
      switch (outcome) {
        case ConfigKeyApplied(:final warning):
          state = ConfigEditorState(
            warning: warning != null && warning.isNotEmpty ? warning : null,
          );
          ref.invalidate(configShowProvider);
        case ConfigKeyNeedsConfirm():
          // Should not happen after confirm, but treat as error
          state = const ConfigEditorState(error: 'Confirmation failed.');
      }
    } on GatewayException catch (error) {
      state = ConfigEditorState(error: error.message);
    } on Object catch (error) {
      state = ConfigEditorState(error: error.toString());
    }
  }

  void cancelConfirm() {
    state = ConfigEditorState(
      busy: state.busy,
      error: state.error,
      warning: state.warning,
    );
  }

  void clearError() {
    state = ConfigEditorState(
      busy: state.busy,
      warning: state.warning,
      confirmMessage: state.confirmMessage,
      pendingKey: state.pendingKey,
      pendingValue: state.pendingValue,
    );
  }

  void clearWarning() {
    state = ConfigEditorState(
      busy: state.busy,
      error: state.error,
      confirmMessage: state.confirmMessage,
      pendingKey: state.pendingKey,
      pendingValue: state.pendingValue,
    );
  }
}
