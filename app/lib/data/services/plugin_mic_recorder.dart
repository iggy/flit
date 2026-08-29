import 'dart:io';
import 'dart:typed_data';

import 'package:flit/core/debug/voice_debug.dart';
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
    voiceDebug('pluginRecorder.start begin recording=$_recording');
    if (_recording) {
      voiceDebug('pluginRecorder.start ignored already recording');
      return;
    }
    try {
      final permission = await _recorder.hasPermission();
      voiceDebug('pluginRecorder.permission=$permission');
      if (!permission) {
        throw const MicCaptureException(
          MicCaptureFailure.permissionDenied,
          'Microphone permission was denied.',
        );
      }
      final path =
          '${(await getTemporaryDirectory()).path}/flit-voice-${DateTime.now().microsecondsSinceEpoch}.wav';
      voiceDebug('pluginRecorder.starting recorder path=$path');
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
      voiceDebug('pluginRecorder.started');
    } on MicCaptureException {
      rethrow;
    } on Object catch (error) {
      voiceDebug('pluginRecorder.start error=$error');
      throw MicCaptureException(
        MicCaptureFailure.unknown,
        'Could not start the microphone: $error',
      );
    }
  }

  @override
  Future<LocalRecording?> stop() async {
    voiceDebug('pluginRecorder.stop begin recording=$_recording path=$_activePath');
    if (!_recording) {
      voiceDebug('pluginRecorder.stop skipped not recording');
      return null;
    }
    try {
      final path = await _recorder.stop();
      final activePath = path?.isNotEmpty == true ? path : _activePath;
      _activePath = null;
      voiceDebug(
        'pluginRecorder.stopped pluginPath=$path activePath=$activePath',
      );
      if (activePath == null || activePath.isEmpty) {
        voiceDebug('pluginRecorder.stop no active path');
        return null;
      }
      final bytes = await _readFile(activePath);
      voiceDebug('pluginRecorder.fileBytes=${bytes.length}');
      if (bytes.isEmpty) {
        voiceDebug('pluginRecorder.stop empty file');
        return null;
      }
      return LocalRecording(bytes: bytes, mimeType: 'audio/wav');
    } on MicCaptureException {
      rethrow;
    } on Object catch (error) {
      voiceDebug('pluginRecorder.stop error=$error');
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
