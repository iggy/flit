/// Audio playback abstraction (P7-06 rework).
library;

/// Plays synthesized audio bytes through the device speakers.
abstract interface class AudioPlayback {
  /// Play [bytes] (encoded per [mimeType]); resolves when playback finishes.
  ///
  /// A second call stops the previous playback first. Throws when no audio
  /// output is available.
  Future<void> play({required List<int> bytes, required String mimeType});

  /// Stop any in-flight playback immediately. Safe when idle.
  void stop();
}
