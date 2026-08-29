/// Client-side voice capture wiring (P7-05/P7-06 rework).
///
/// Voice is DEVICE-captured on Android/Linux: the mic records locally, the
/// clip is uploaded to the gateway's `/api/audio/transcribe`, and the
/// transcript drops into the composer. TTS goes through `/api/audio/speak`
/// and plays through the device speakers. The legacy server-side
/// `voice.record` RPC path remains for gateways without the audio routes.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/debug/voice_debug.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/audio_repository_impl.dart';
import 'package:flit/data/services/audio_player_playback.dart';
import 'package:flit/data/services/plugin_mic_recorder.dart';
import 'package:flit/domain/repositories/audio_repository.dart';
import 'package:flit/domain/services/audio_playback.dart';
import 'package:flit/domain/services/local_mic_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The audio repository for the current connection, or null when there is no
/// REST client (disconnected / pre-connect).
final audioRepositoryProvider = Provider<AudioRepository?>((ref) {
  final rest = ref.watch(restClientProvider);
  voiceDebug('audioRepository restClient=${rest == null ? 'null' : 'present'}');
  if (rest == null) {
    return null;
  }
  return RestAudioRepository(rest);
});

/// Device mic capture (record plugin). Created lazily; tests inject a fake.
final localMicRecorderProvider =
    Provider<LocalMicRecorder>((ref) => PluginMicRecorder());

/// Device audio output (audioplayers over /api/audio/speak bytes).
final audioPlaybackProvider = Provider<AudioPlayback>(
  (ref) => AudioPlayerPlayback(),
);

/// Whether the connected gateway exposes `/api/audio/*` routes.
///
/// Probed once per connection; null until the first probe resolves. Older
/// gateways answer 404 → false, keeping the client-side path hidden.
final audioRoutesProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(audioRepositoryProvider);
  if (repository == null) {
    return false;
  }
  return repository.audioRoutesAvailable();
});

/// Whether the client-side capture path should drive voice UI on this
/// platform + connection.
///
/// True when the gateway has the audio routes and this build can record
/// (Android/Linux desktop via the `record` plugin). Web and unsupported
/// desktops keep the legacy server-side flow.
final clientVoiceCaptureSupportedProvider = Provider<bool>((ref) {
  if (kIsWeb) {
    voiceDebug('clientVoiceSupported=false web');
    return false;
  }
  final routes = ref.watch(audioRoutesProvider);
  final supported =
      routes.value == true &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.linux);
  voiceDebug(
    'clientVoiceSupported=$supported '
    'platform=$defaultTargetPlatform routesState=${routes.runtimeType} '
    'routesValue=${routes.value}',
  );
  return supported;
});

/// Controller for device-side push-to-talk: start → stop → transcribe →
/// prefill the composer. Failures land in state.error; nothing throws.
class ClientVoiceController extends Notifier<ClientVoiceState> {
  @override
  ClientVoiceState build() => const ClientVoiceState();

  LocalMicRecorder get _mic => ref.read(localMicRecorderProvider);

  /// Begin capturing from the device microphone.
  ///
  /// The platform gate is advisory-only in the controller: the composer only
  /// routes here when [clientVoiceCaptureSupportedProvider] is true, so a
  /// direct call (tests, future surfaces) still works on any platform.
  Future<void> start() async {
    voiceDebug('controller.start phase=${state.phase.name}');
    if (state.phase != ClientVoicePhase.idle) {
      voiceDebug('controller.start ignored non-idle');
      return;
    }
    try {
      await _mic.start();
      state = const ClientVoiceState(phase: ClientVoicePhase.recording);
      voiceDebug('controller.start recording');
    } on MicCaptureException catch (error) {
      voiceDebug('controller.start mic error=${error.message}');
      state = ClientVoiceState(error: error.message);
    } on Object catch (error) {
      voiceDebug('controller.start error=$error');
      state = ClientVoiceState(error: error.toString());
    }
  }

  /// Stop capturing and transcribe through the gateway; a non-empty
  /// transcript lands in the composer prefill slot.
  Future<void> stopAndTranscribe() async {
    voiceDebug('controller.stopAndTranscribe phase=${state.phase.name}');
    if (state.phase != ClientVoicePhase.recording) {
      voiceDebug('controller.stopAndTranscribe ignored non-recording');
      return;
    }
    state = const ClientVoiceState(phase: ClientVoicePhase.transcribing);
    try {
      final recording = await _mic.stop();
      voiceDebug(
        'controller.micStop result=${recording?.bytes.length ?? 'null'}',
      );
      if (recording == null) {
        voiceDebug('controller.stopAndTranscribe no recording => idle');
        state = const ClientVoiceState();
        return;
      }
      final repository = ref.read(audioRepositoryProvider);
      if (repository == null) {
        voiceDebug('controller.stopAndTranscribe no repository');
        state = const ClientVoiceState(error: 'Not connected to a gateway.');
        return;
      }
      final result = await repository.transcribe(
        dataUrl:
            'data:${recording.mimeType};base64,${base64Encode(recording.bytes)}',
        mimeType: recording.mimeType,
      );
      voiceDebug(
        'controller.transcribe resultLength=${result.transcript.length} '
        'provider=${result.provider}',
      );
      if (result.transcript.isEmpty) {
        // Silence — back to idle with nothing to insert.
        voiceDebug('controller.stopAndTranscribe empty transcript => idle');
        state = const ClientVoiceState();
        return;
      }
      state = const ClientVoiceState();
      ref.read(composerPrefillFromVoiceProvider.notifier).prefill(result.transcript);
      voiceDebug('controller.stopAndTranscribe prefilled composer');
    } on GatewayException catch (error) {
      voiceDebug('controller.stopAndTranscribe gateway error=${error.message}');
      state = ClientVoiceState(error: error.message);
    } on Object catch (error) {
      voiceDebug('controller.stopAndTranscribe error=$error');
      state = ClientVoiceState(error: error.toString());
    }
  }

  /// Cancel an active capture without transcribing.
  Future<void> cancel() async {
    if (state.phase == ClientVoicePhase.idle) {
      return;
    }
    try {
      await _mic.stop();
    } on Object {
      // Cancel is best-effort; never surface an error from it.
    }
    state = const ClientVoiceState();
  }

  /// Speak [text] through the gateway TTS chain and play it locally.
  Future<void> speak(String text) async {
    if (!ref.read(clientVoiceCaptureSupportedProvider)) {
      return;
    }
    try {
      final repository = ref.read(audioRepositoryProvider);
      if (repository == null) {
        throw const GatewayNetworkException('Not connected to a gateway.');
      }
      final audio = await repository.speak(text);
      state = state.copyWith(speaking: true);
      await ref
          .read(audioPlaybackProvider)
          .play(bytes: audio.bytes, mimeType: audio.mimeType);
      state = state.copyWith(speaking: false);
    } on GatewayException catch (error) {
      state = state.copyWith(speaking: false, error: error.message);
    } on Object catch (error) {
      state = state.copyWith(speaking: false, error: error.toString());
    }
  }

  /// Stop in-flight speech playback (barge-in / Stop button).
  void stopSpeaking() {
    ref.read(audioPlaybackProvider).stop();
    if (state.speaking) {
      state = state.copyWith(speaking: false);
    }
  }

  /// Clear the error message.
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// One-shot composer insertion channel fed by [ClientVoiceController].
/// Kept separate from the slash launcher's prefill so a voice transcript can
/// append instead of overwrite an in-progress draft at the UI layer.
final composerPrefillFromVoiceProvider =
    NotifierProvider<ComposerPrefillFromVoiceNotifier, String?>(
      ComposerPrefillFromVoiceNotifier.new,
    );

final class ComposerPrefillFromVoiceNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void prefill(String text) => state = text;

  void clear() => state = null;
}

enum ClientVoicePhase { idle, recording, transcribing }

/// Controller provider for the device-side voice path.
final clientVoiceControllerProvider =
    NotifierProvider<ClientVoiceController, ClientVoiceState>(
      ClientVoiceController.new,
    );

/// UI state for the device-side voice path.
final class ClientVoiceState {
  const ClientVoiceState({
    this.phase = ClientVoicePhase.idle,
    this.speaking = false,
    this.error,
  });

  final ClientVoicePhase phase;

  /// Whether synthesized speech is playing locally.
  final bool speaking;

  /// Human-readable failure, or null.
  final String? error;

  bool get recording => phase == ClientVoicePhase.recording;
  bool get transcribing => phase == ClientVoicePhase.transcribing;

  ClientVoiceState copyWith({ClientVoicePhase? phase, bool? speaking, String? error}) {
    return ClientVoiceState(
      phase: phase ?? this.phase,
      speaking: speaking ?? this.speaking,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClientVoiceState &&
        other.phase == phase &&
        other.speaking == speaking &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(phase, speaking, error);
}

/// Convenience view combining both voice paths for the composer: which one
/// owns the mic button, plus the merged display state.
final composerVoiceModeProvider = Provider<ComposerVoiceMode>((ref) {
  final mode = ref.watch(clientVoiceCaptureSupportedProvider)
      ? ComposerVoiceMode.clientCapture
      : ComposerVoiceMode.serverCapture;
  voiceDebug('composerVoiceMode=${mode.name}');
  return mode;
});

enum ComposerVoiceMode { clientCapture, serverCapture }
