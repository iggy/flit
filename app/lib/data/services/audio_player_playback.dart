import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'package:flit/domain/services/audio_playback.dart';
import 'package:path_provider/path_provider.dart';

/// Writes bytes to a short-lived cache file and plays it via audioplayers.
///
/// Synthesized speech is transient: the temp file is deleted when the next
/// clip starts or playback is stopped, so nothing accumulates on disk.
final class AudioPlayerPlayback implements AudioPlayback {
  AudioPlayerPlayback({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _tempPath;
  StreamSubscription<void>? _completionSub;

  @override
  Future<void> play({
    required List<int> bytes,
    required String mimeType,
  }) async {
    await _player.stop();
    _cleanupTemp();
    final file = await _writeTemp(Uint8List.fromList(bytes), mimeType);
    _tempPath = file.path;
    // Fire-and-forget completion cleanup; play() resolves at start, not end.
    unawaited(_completionSub?.cancel());
    _completionSub = _player.onPlayerComplete.listen((_) => _cleanupTemp());
    await _player.play(DeviceFileSource(file.path));
  }

  @override
  void stop() {
    unawaited(_player.stop());
    _cleanupTemp();
    unawaited(_completionSub?.cancel());
    _completionSub = null;
  }

  Future<File> _writeTemp(Uint8List bytes, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/flit-tts-${DateTime.now().microsecondsSinceEpoch}.${_extensionFor(mimeType)}',
    );
    await file.writeAsBytes(bytes, flush: false);
    return file;
  }

  void _cleanupTemp() {
    final path = _tempPath;
    _tempPath = null;
    if (path == null) {
      return;
    }
    File(path).delete().catchError((_) => File(path));
  }
}

String _extensionFor(String mimeType) => switch (mimeType) {
  'audio/wav' || 'audio/x-wav' => 'wav',
  'audio/ogg' || 'audio/opus' => 'ogg',
  'audio/flac' => 'flac',
  _ => 'mp3',
};
