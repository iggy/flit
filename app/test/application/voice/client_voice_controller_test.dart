// P7-05 rework acceptance: ClientVoiceController against fakes.
// Covers start/stop/transcribe flow, silence handling, error capture,
// cancel, and the composer prefill hand-off.

import 'dart:typed_data';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/voice/client_voice_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/repositories/audio_repository.dart';
import 'package:flit/domain/services/local_mic_recorder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeMicRecorder implements LocalMicRecorder {
  FakeMicRecorder({this.startError, this.stopResult, this.stopError});

  MicCaptureException? startError;
  MicCaptureException? stopError;
  LocalRecording? stopResult;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> start() async {
    startCalls += 1;
    final error = startError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<LocalRecording?> stop() async {
    stopCalls += 1;
    final error = stopError;
    if (error != null) {
      throw error;
    }
    return stopResult;
  }
}

final class FakeAudioRepository implements AudioRepository {
  FakeAudioRepository({this.transcript = '', this.routesAvailable = true});

  String transcript;
  bool routesAvailable;
  String? lastDataUrl;
  List<String> spokenTexts = <String>[];

  @override
  Future<AudioTranscription> transcribe({
    required String dataUrl,
    String? mimeType,
  }) async {
    lastDataUrl = dataUrl;
    return AudioTranscription(transcript: transcript, provider: 'fake');
  }

  @override
  Future<SpeechAudio> speak(String text) async {
    spokenTexts.add(text);
    throw const GatewayNetworkException('no audio output in tests');
  }

  @override
  Future<bool> audioRoutesAvailable() async => routesAvailable;
}

ClientVoiceContainer _container({
  FakeMicRecorder? mic,
  AudioRepository? audio,
}) {
  final container = ProviderContainer(
    overrides: [
      localMicRecorderProvider.overrideWithValue(
      mic ?? FakeMicRecorder(stopResult: _stubRecording()),
      ),
      audioRepositoryProvider.overrideWithValue(audio ?? FakeAudioRepository()),
      restClientProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  return ClientVoiceContainer(container);
}

/// Wrapper keeping the dispose teardown tidy without leaking ProviderContainer
/// into every test body.
class ClientVoiceContainer {
  ClientVoiceContainer(this.container);

  final ProviderContainer container;

  ClientVoiceState get state => container.read(clientVoiceControllerProvider);
  ClientVoiceController get controller =>
      container.read(clientVoiceControllerProvider.notifier);
  String? get prefilledTranscript =>
      container.read(composerPrefillFromVoiceProvider);
}

LocalRecording _stubRecording() => LocalRecording(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'audio/wav',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start → stopAndTranscribe delivers the transcript to the composer',
      () async {
    final audio = FakeAudioRepository(transcript: 'hello world');
    final voice = _container(audio: audio);

    await voice.controller.start();
    expect(voice.state.recording, isTrue);

    await voice.controller.stopAndTranscribe();

    expect(voice.state.phase, ClientVoicePhase.idle);
    expect(voice.prefilledTranscript, 'hello world');
    expect(audio.lastDataUrl, startsWith('data:audio/wav;base64,'));
  });

  test('silence resets to idle with no composer insert', () async {
    final voice = _container(audio: FakeAudioRepository(transcript: ''));

    await voice.controller.start();
    await voice.controller.stopAndTranscribe();

    expect(voice.state.phase, ClientVoicePhase.idle);
    expect(voice.prefilledTranscript, isNull);
  });

  test('mic permission failure lands in state.error', () async {
    final voice = _container(
      mic: FakeMicRecorder(
        startError: const MicCaptureException(
          MicCaptureFailure.permissionDenied,
          'Microphone permission was denied.',
        ),
      ),
    );

    await voice.controller.start();

    expect(voice.state.phase, ClientVoicePhase.idle);
    expect(voice.state.error, contains('permission'));
  });

  test('transcription failure keeps the error and clears the phase', () async {
    final failing = _FailingAudioRepository();
    final voice = _container(audio: failing);

    await voice.controller.start();
    await voice.controller.stopAndTranscribe();

    expect(voice.state.phase, ClientVoicePhase.idle);
    expect(voice.state.error, isNotNull);
  });

  test('cancel stops without transcribing', () async {
    final mic = FakeMicRecorder(stopResult: _stubRecording());
    final voice = _container(mic: mic);

    await voice.controller.start();
    await voice.controller.cancel();

    expect(mic.stopCalls, 1);
    expect(voice.state.phase, ClientVoicePhase.idle);
    expect(voice.prefilledTranscript, isNull);
  });

  test('start is a no-op while not idle', () async {
    final mic = FakeMicRecorder();
    final voice = _container(mic: mic);

    await voice.controller.start();
    await voice.controller.start();

    expect(mic.startCalls, 1);
  });
}

final class _FailingAudioRepository implements AudioRepository {
  @override
  Future<AudioTranscription> transcribe({
    required String dataUrl,
    String? mimeType,
  }) async {
    throw const GatewayTimeoutException('timed out');
  }

  @override
  Future<SpeechAudio> speak(String text) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> audioRoutesAvailable() async => true;
}
