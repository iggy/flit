import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';

/// Operations on a flit server's sessions (flit.v1 `SessionService`).
///
/// Implementations throw [GatewayException] subclasses on failure, never a
/// transport error.
abstract interface class FlitRepository {
  /// Sessions, most recently updated first; only [projectId]'s when set.
  Future<List<FlitSession>> listSessions({String? projectId});

  /// Start a new session working in [workingDir] (an absolute path on the
  /// server). Empty [provider]/[model] mean the server's defaults.
  Future<FlitSession> createSession({
    required String workingDir,
    String title = '',
    String provider = '',
    String model = '',
    String effort = '',
    String role = '',
    String projectId = '',
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

  /// Give up on the model call in progress and send it again. Only works
  /// while none of the reply has arrived.
  Future<void> retryModelCall(String sessionId);

  /// Answer a pending prompt. [client] names this device in the session log.
  /// [forSession] also allows the prompt's session patterns from now on.
  Future<void> answerPrompt(
    String sessionId,
    String promptId, {
    required bool allow,
    bool forSession = false,
    String client = '',
  });

  /// Change the session's provider and model.
  Future<FlitSession> setModel(
    String sessionId, {
    required String provider,
    required String model,
  });

  /// Change the session's reasoning effort ('' = the model's default).
  Future<FlitSession> setEffort(String sessionId, String effort);

  /// Turn yolo mode on or off: every shell command runs unless a deny rule
  /// matches.
  Future<FlitSession> setYolo(String sessionId, {required bool yolo});

  /// The models the server discovered, all providers.
  Future<List<FlitModel>> listModels();

  /// Re-run model discovery on the server, then list the models.
  Future<List<FlitModel>> refreshModels();

  /// The roles sessions can be created with.
  Future<List<FlitAgentRole>> listRoles();

  /// Projects: Scratch first, then by name.
  Future<List<FlitProject>> listProjects();

  /// Add a project for an existing [directory] on the server.
  Future<FlitProject> createProject({required String directory, String name});

  /// Move a session to another project.
  Future<FlitSession> moveSession(String sessionId, String projectId);

  /// Mark a turn result (with [messageId]) or the model as good or bad.
  Future<void> rate(
    String sessionId, {
    required FlitRatingTarget target,
    required bool good,
    String messageId = '',
    String note = '',
  });

  /// The configured MCP servers and whether each is on for the session.
  Future<List<FlitMcpServer>> listMcpServers(String sessionId);

  /// The skills the session's agent can load.
  Future<List<FlitSkill>> listSkills(String sessionId);

  /// Include or exclude a project from `flit export`.
  Future<FlitProject> setProjectExport(
    String projectId, {
    required bool enabled,
  });

  /// Turn an MCP server on or off for the session.
  Future<FlitSession> setMcpServer(
    String sessionId,
    String server, {
    required bool enabled,
  });
}
