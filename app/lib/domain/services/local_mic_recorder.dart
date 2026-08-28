/// Client-side microphone capture abstraction (P7-05 rework).
library;

import 'dart:typed_data';

/// One finished local recording, ready to upload.
final class LocalRecording {
  const LocalRecording({required this.bytes, required this.mimeType});

  /// Raw encoded audio bytes (WAV/PCM16 for this client's captures).
  final Uint8List bytes;

  /// IANA mime type matching [bytes] (e.g. `audio/wav`).
  final String mimeType;
}

/// Records from the device microphone.
///
/// Implementations exist for mobile/desktop via the `record` plugin
/// ([LocalMicRecorder]) and for tests (in-memory fake). The gateway never
/// sees the device path — only the finished bytes.
abstract interface class LocalMicRecorder {
  /// Begin capturing from the default input device.
  ///
  /// Throws a typed [MicCaptureException] when the mic is unavailable
  /// (permission denied, no device, busy). Idempotent: starting twice is a
  /// no-op.
  Future<void> start();

  /// Finish the active capture and return its encoded bytes.
  ///
  /// Returns null when nothing was recording. The recorder is idle again
  /// after this call.
  Future<LocalRecording?> stop();
}

/// Typed failure for [LocalMicRecorder] so UI copy can branch without
/// string matching.
enum MicCaptureFailure { permissionDenied, noDevice, inUse, unknown }

class MicCaptureException implements Exception {
  const MicCaptureException(this.failure, this.message);

  final MicCaptureFailure failure;
  final String message;

  @override
  String toString() => message;
}
