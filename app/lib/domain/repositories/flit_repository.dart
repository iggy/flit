import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flit/domain/models/flit_learning.dart';
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
  /// Sends a user message as [client]. While a turn runs it is queued and
  /// delivered at the turn's next step; with empty [text] it just delivers
  /// what's queued.
  Future<void> send(String sessionId, String text, {String client = ''});

  /// Changes or withdraws a message still in the queue.
  Future<void> editQueuedMessage(String sessionId, String queueId, String text);
  Future<void> cancelQueuedMessage(String sessionId, String queueId);

  /// Stop the running turn. Returns whether one was running.
  Future<bool> interrupt(String sessionId);

  /// Give up on the model call in progress and send it again. Only works
  /// while none of the reply has arrived.
  Future<void> retryModelCall(String sessionId);

  /// Asks the model to stop thinking and answer now (llama.cpp).
  Future<void> endReasoning(String sessionId, {String client = ''});

  /// Summarizes the older part of the conversation to free up context: now
  /// if the session is idle, else at the running turn's next step (then it
  /// returns true). [instructions] are extra asks for the summary.
  Future<bool> compact(
    String sessionId, {
    String instructions = '',
    String client = '',
  });

  /// Start a new branch that keeps user message [messageId] and answers it
  /// again. Only while idle with nothing queued.
  Future<void> retryFromMessage(
    String sessionId,
    String messageId, {
    String client = '',
  });

  /// Start a new branch with [text] in place of user message [messageId].
  Future<void> editMessage(
    String sessionId,
    String messageId,
    String text, {
    String client = '',
  });

  /// Make another branch the active one ('' is the root branch).
  Future<void> switchBranch(
    String sessionId,
    String branchId, {
    String client = '',
  });

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

  /// Stars or unstars a model (for every device).
  Future<void> setFavorite(
    String provider,
    String model, {
    required bool favorite,
  });

  /// Loads or unloads a llama.cpp router model ([FlitModel.canLoad]) and
  /// returns it once it has settled.
  Future<FlitModel> setModelLoaded(
    String provider,
    String model, {
    required bool load,
  });

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

  /// The session's git repository and the files changed since its base
  /// commit; [FlitGitStatus.none] outside git.
  Future<FlitGitStatus> gitStatus(String sessionId);

  /// The unified diff of the session's changes, optionally for one [path]
  /// (relative to the repository root).
  Future<FlitGitDiff> gitDiff(String sessionId, {String path = ''});

  /// Runs the learning pass on a session (the server's learning model):
  /// its proposals replace the session's earlier pending ones. Can take a
  /// while with a local model. An empty list is a normal answer.
  Future<FlitLearnResult> learn(String sessionId);

  /// Pending proposals, the session's ('' = every session's); decided ones
  /// too with [includeDecided].
  Future<List<FlitLearnProposal>> listLearnProposals({
    String sessionId = '',
    bool includeDecided = false,
  });

  /// Writes a pending proposal, with [text] in place of its proposed text
  /// when given.
  Future<FlitLearnProposal> acceptLearnProposal(String id, {String? text});

  /// Rejects a pending proposal; nothing is written.
  Future<FlitLearnProposal> rejectLearnProposal(String id);
}
