/// Repository interface for voice control (ticket P7-05).
library;

import 'package:flit/domain/models/voice_state.dart';

/// Voice control repository — toggle mode/tts, record audio, and speak text.
///
/// IMPORTANT: Voice is SERVER-SIDE. The gateway host records from its microphone
/// and speaks through its speakers. This client merely triggers actions and
/// consumes events — no local audio recording or playback.
abstract interface class VoiceRepository {
  /// Toggle voice mode or TTS (wire `voice.toggle`).
  ///
  /// [action] ∈ "status" | "on" | "off" | "tts".
  /// - "status": query current state, returns all fields including availability.
  /// - "on" / "off": enable/disable voice mode.
  /// - "tts": toggle text-to-speech on/off.
  ///
  /// Errors (e.g. code 4014 "enable voice mode first" when toggling TTS while off)
  /// come back as GatewayRpcException.
  Future<VoiceToggleResult> toggle(String action);

  /// Start or stop server-side audio recording (wire `voice.record`).
  ///
  /// [action] ∈ "start" | "stop".
  /// [sessionId] is optional but should always be provided so events target this
  /// session.
  ///
  /// Returns status ∈ "recording" | "stopped" | "busy".
  Future<VoiceRecordResult> record(String action, {String? sessionId});

  /// Request the gateway to speak text via TTS (wire `voice.tts`).
  ///
  /// [text] is the text to speak. Returns status (e.g. "speaking").
  Future<VoiceTtsResult> tts(String text);
}
