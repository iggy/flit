/// Domain models for voice control (ticket P7-05).
///
/// Wire shapes from gateway protocol (voice.toggle, voice.record, voice.tts).
library;

/// Result of `voice.toggle` — polymorphic based on action.
///
/// The "status" action returns all fields including [available], [audioAvailable],
/// [sttAvailable], and [details]. Other actions (on/off/tts) return only
/// [enabled], [recordKey], and [tts].
final class VoiceToggleResult {
  const VoiceToggleResult({
    required this.enabled,
    required this.recordKey,
    required this.tts,
    this.available,
    this.audioAvailable,
    this.sttAvailable,
    this.details,
  });

  /// Wire `enabled` — whether voice mode is on.
  final bool enabled;

  /// Wire `record_key` — the keyboard shortcut for voice recording.
  final String recordKey;

  /// Wire `tts` — whether text-to-speech is enabled.
  final bool tts;

  /// Wire `available` — whether voice is available (status action only).
  final bool? available;

  /// Wire `audio_available` — whether audio is available (status action only).
  final bool? audioAvailable;

  /// Wire `stt_available` — whether STT is available (status action only).
  final bool? sttAvailable;

  /// Wire `details` — additional status details (status action only).
  final String? details;

  @override
  bool operator ==(Object other) {
    return other is VoiceToggleResult &&
        other.enabled == enabled &&
        other.recordKey == recordKey &&
        other.tts == tts &&
        other.available == available &&
        other.audioAvailable == audioAvailable &&
        other.sttAvailable == sttAvailable &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        recordKey,
        tts,
        available,
        audioAvailable,
        sttAvailable,
        details,
      );

  @override
  String toString() {
    return 'VoiceToggleResult(enabled: $enabled, recordKey: $recordKey, '
        'tts: $tts, available: $available, audioAvailable: $audioAvailable, '
        'sttAvailable: $sttAvailable, details: $details)';
  }
}

/// Result of `voice.record` — reports the recording status.
final class VoiceRecordResult {
  const VoiceRecordResult({
    required this.status,
  });

  /// Wire `status` — "recording", "stopped", or "busy".
  final String status;

  @override
  bool operator ==(Object other) {
    return other is VoiceRecordResult && other.status == status;
  }

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() {
    return 'VoiceRecordResult(status: $status)';
  }
}

/// Result of `voice.tts` — reports the TTS status.
final class VoiceTtsResult {
  const VoiceTtsResult({
    required this.status,
  });

  /// Wire `status` — e.g. "speaking".
  final String status;

  @override
  bool operator ==(Object other) {
    return other is VoiceTtsResult && other.status == status;
  }

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() {
    return 'VoiceTtsResult(status: $status)';
  }
}
