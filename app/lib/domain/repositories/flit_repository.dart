import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';

/// Operations on a flit server's sessions (flit.v1 `SessionService`).
///
/// Implementations throw [GatewayException] subclasses on failure, never a
/// transport error.
abstract interface class FlitRepository {
  /// All sessions, most recently updated first.
  Future<List<FlitSession>> listSessions();

  /// Start a new session working in [workingDir] (an absolute path on the
  /// server). Empty [provider]/[model] mean the server's defaults.
  Future<FlitSession> createSession({
    required String workingDir,
    String title = '',
    String provider = '',
    String model = '',
  });

  Future<FlitSession> getSession(String id);

  /// The session's events with seq >= [fromSeq], then live ones. The stream
  /// ends (or errors) when the connection drops; resume by attaching again
  /// from the last seq seen + 1.
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq});

  /// Send a user message, starting a turn.
  Future<void> send(String sessionId, String text);

  /// Stop the running turn. Returns whether one was running.
  Future<bool> interrupt(String sessionId);

  /// Answer a pending prompt. [client] names this device in the session log.
  Future<void> answerPrompt(
    String sessionId,
    String promptId, {
    required bool allow,
    String client = '',
  });

  /// Change the session's provider and model.
  Future<FlitSession> setModel(
    String sessionId, {
    required String provider,
    required String model,
  });
}
