/// Riverpod wiring for voice control (ticket P7-05).
library;

import 'dart:async';

import 'package:flit/application/chat/composer_prefill.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/data/repositories/voice_repository_impl.dart';
import 'package:flit/domain/repositories/voice_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The voice repository for the current connection, or null when there is no
/// RPC client (disconnected / pre-connect).
final voiceRepositoryProvider = Provider<VoiceRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return VoiceRepositoryImpl(client);
});

/// Voice UI state: mode/tts enablement, record key, mic state, recording flag,
/// and error.
final class VoiceUiState {
  const VoiceUiState({
    this.modeEnabled = false,
    this.ttsEnabled = false,
    this.recordKey = 'Ctrl+B',
    this.micState = 'idle',
    this.recording = false,
    this.error,
  });

  /// Whether voice mode is enabled.
  final bool modeEnabled;

  /// Whether TTS is enabled.
  final bool ttsEnabled;

  /// The keyboard shortcut for voice recording (wire `record_key`).
  final String recordKey;

  /// The last voice.status state ∈ idle|listening|transcribing.
  final String micState;

  /// Whether a voice.record start is active.
  final bool recording;

  /// Human-readable failure (token-redacted), or null.
  final String? error;

  VoiceUiState copyWith({
    bool? modeEnabled,
    bool? ttsEnabled,
    String? recordKey,
    String? micState,
    bool? recording,
    String? error,
  }) {
    return VoiceUiState(
      modeEnabled: modeEnabled ?? this.modeEnabled,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      recordKey: recordKey ?? this.recordKey,
      micState: micState ?? this.micState,
      recording: recording ?? this.recording,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VoiceUiState &&
        other.modeEnabled == modeEnabled &&
        other.ttsEnabled == ttsEnabled &&
        other.recordKey == recordKey &&
        other.micState == micState &&
        other.recording == recording &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        modeEnabled,
        ttsEnabled,
        recordKey,
        micState,
        recording,
        error,
      );

  @override
  String toString() {
    return 'VoiceUiState(modeEnabled: $modeEnabled, ttsEnabled: $ttsEnabled, '
        'recordKey: $recordKey, micState: $micState, recording: $recording, '
        'error: $error)';
  }
}

/// Controller for voice actions: refresh status, enable/disable mode, toggle
/// TTS, start/stop recording, and speak text.
final voiceControllerProvider =
    NotifierProvider<VoiceController, VoiceUiState>(
  VoiceController.new,
);

class VoiceController extends Notifier<VoiceUiState> {
  StreamSubscription<TypedGatewayEvent>? _eventSubscription;

  @override
  VoiceUiState build() {
    final client = ref.watch(rpcClientProvider);
    if (client != null) {
      _eventSubscription = client.events
          .map(parseGatewayEvent)
          .listen(_onEvent);
      ref.onDispose(() {
        _eventSubscription?.cancel();
        _eventSubscription = null;
      });
    }
    return const VoiceUiState();
  }

  void _onEvent(TypedGatewayEvent event) {
    switch (event) {
      case VoiceStatusEvent(:final state):
        this.state = this.state.copyWith(micState: state, error: null);
      case VoiceTranscriptEvent(:final text, :final noSpeechLimit):
        if (noSpeechLimit) {
          // Three silent captures — stop recording and reset mic state.
          state = state.copyWith(
            recording: false,
            micState: 'idle',
            error: null,
          );
        } else if (text != null && text.isNotEmpty) {
          // A finished transcript — drop it into the composer.
          ref.read(composerPrefillProvider.notifier).prefill(text);
          state = state.copyWith(error: null);
        }
      case _:
      // Ignore other event types.
    }
  }

  /// Query current voice status (calls `voice.toggle` with action="status").
  /// Updates [modeEnabled], [ttsEnabled], and [recordKey] from the result.
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> refreshStatus() async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      final result = await repository.toggle('status');
      state = state.copyWith(
        modeEnabled: result.enabled,
        ttsEnabled: result.tts,
        recordKey: result.recordKey,
        error: null,
      );
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Enable voice mode (calls `voice.toggle` with action="on").
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> enableMode() async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      final result = await repository.toggle('on');
      state = state.copyWith(
        modeEnabled: result.enabled,
        ttsEnabled: result.tts,
        recordKey: result.recordKey,
        error: null,
      );
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Disable voice mode (calls `voice.toggle` with action="off").
  /// Also resets recording and mic state.
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> disableMode() async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      final result = await repository.toggle('off');
      state = state.copyWith(
        modeEnabled: result.enabled,
        ttsEnabled: result.tts,
        recordKey: result.recordKey,
        recording: false,
        micState: 'idle',
        error: null,
      );
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Toggle TTS on/off (calls `voice.toggle` with action="tts").
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> toggleTts() async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      final result = await repository.toggle('tts');
      state = state.copyWith(
        modeEnabled: result.enabled,
        ttsEnabled: result.tts,
        recordKey: result.recordKey,
        error: null,
      );
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Start server-side recording (calls `voice.record` with action="start").
  /// Sets [recording] to true if the result status is "recording".
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> startRecording(String? sessionId) async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      final result = await repository.record('start', sessionId: sessionId);
      if (result.status == 'recording') {
        state = state.copyWith(recording: true, error: null);
      } else if (result.status == 'busy') {
        // Server is busy — leave recording as-is, but note the status.
        state = state.copyWith(error: 'Server is busy recording');
      } else {
        state = state.copyWith(error: null);
      }
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Stop server-side recording (calls `voice.record` with action="stop").
  /// Sets [recording] to false.
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> stopRecording(String? sessionId) async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      await repository.record('stop', sessionId: sessionId);
      state = state.copyWith(recording: false, error: null);
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Request the gateway to speak text via TTS (calls `voice.tts`).
  /// NEVER throws — failures land in [VoiceUiState.error].
  Future<void> speak(String text) async {
    final repository = ref.read(voiceRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(error: 'Not connected to a gateway.');
      return;
    }
    try {
      await repository.tts(text);
      state = state.copyWith(error: null);
    } on GatewayException catch (error) {
      state = state.copyWith(error: error.message);
    } on Object catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  /// Clear the error message.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
