import 'dart:io';
import 'dart:typed_data';

import 'package:flit/domain/services/local_mic_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Reads recorded bytes off disk; a top-level function so tests can stub it.
typedef RecordedFileReader = Future<Uint8List> Function(String path);

Future<Uint8List> _defaultReadFile(String path) => File(path).readAsBytes();

/// [LocalMicRecorder] over the `record` plugin (Android + Linux desktop;
/// iOS/macOS/windows come with the plugin for free).
///
/// Captures WAV (PCM16, mono, 16 kHz — the rate the gateway's Whisper
/// pipeline prefers) into a per-capture temp file. WAV needs no platform
/// encoder, so the same container works everywhere the plugin does.
final class PluginMicRecorder implements LocalMicRecorder {
  PluginMicRecorder({AudioRecorder? recorder, RecordedFileReader? fileReader})
    : _recorder = recorder ?? AudioRecorder(),
      _readFile = fileReader ?? _defaultReadFile;

  final AudioRecorder _recorder;
  final RecordedFileReader _readFile;
  bool _recording = false;
  String? _activePath;

  @override
  Future<void> start() async {
    if (_recording) {
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        throw const MicCaptureException(
          MicCaptureFailure.permissionDenied,
          'Microphone permission was denied.',
        );
      }
      final path =
          '${(await getTemporaryDirectory()).path}/flit-voice-${DateTime.now().microsecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
      _activePath = path;
      _recording = true;
    } on MicCaptureException {
      rethrow;
    } on Object catch (error) {
      throw MicCaptureException(
        MicCaptureFailure.unknown,
        'Could not start the microphone: $error',
      );
    }
  }

  @override
  Future<LocalRecording?> stop() async {
    if (!_recording) {
      return null;
    }
    try {
      final path = await _recorder.stop();
      final activePath = path?.isNotEmpty == true ? path : _activePath;
      _activePath = null;
      if (activePath == null || activePath.isEmpty) {
        return null;
      }
      final bytes = await _readFile(activePath);
      if (bytes.isEmpty) {
        return null;
      }
      return LocalRecording(bytes: bytes, mimeType: 'audio/wav');
    } on MicCaptureException {
      rethrow;
    } on Object catch (error) {
      throw MicCaptureException(
        MicCaptureFailure.unknown,
        'Could not finish the recording: $error',
      );
    } finally {
      _recording = false;
      _deleteTemp();
    }
  }

  void _deleteTemp() {
    final path = _activePath;
    if (path != null && path.isNotEmpty) {
      File(path).delete().catchError((_) => File(path));
    }
    _activePath = null;
  }
}
