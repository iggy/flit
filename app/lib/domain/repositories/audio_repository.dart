/// Repository interface for gateway-hosted audio (P7-05 rework).
library;

/// Result of `POST /api/audio/transcribe`.
final class AudioTranscription {
  const AudioTranscription({required this.transcript, required this.provider});

  /// Recognized text; empty when no speech was detected (silence).
  final String transcript;

  /// STT provider that handled the clip (e.g. `whisper`), or null.
  final String? provider;
}

/// Result of `POST /api/audio/speak`.
final class SpeechAudio {
  const SpeechAudio({required this.bytes, required this.mimeType});

  /// Decoded audio bytes (mp3/ogg/wav per provider config).
  final List<int> bytes;

  /// IANA mime type of [bytes].
  final String mimeType;
}

/// The gateway's `/api/audio/*` REST surface.
///
/// Voice is client-captured: the app records locally and uploads bytes for
/// transcription, and asks the gateway to synthesize speech text. Both
/// directions ride the authenticated REST transport (same origin/auth as the
/// rest of the API) — no server-side mic is involved.
abstract interface class AudioRepository {
  /// Transcribe a local recording.
  ///
  /// [dataUrl] is a `data:<mime>;base64,<payload>` URL (the wire contract);
  /// [mimeType] is sent alongside as a fallback. An empty transcript means
  /// silence, not failure.
  Future<AudioTranscription> transcribe({
    required String dataUrl,
    String? mimeType,
  });

  /// Synthesize [text] to playable audio via the gateway's TTS chain.
  Future<SpeechAudio> speak(String text);

  /// Whether the connected gateway exposes `/api/audio/*` at all.
  ///
  /// Probed once per connection (404 → false); older gateways without these
  /// routes keep voice controls hidden instead of erroring on every tap.
  Future<bool> audioRoutesAvailable();
}
