/// A session on a flit server (flit.v1 `Session`), as the app sees it.
library;

/// What a flit session's agent is doing (flit.v1 `TaskState`).
enum FlitTaskState {
  /// Created; no turn has run yet.
  idle,

  /// A turn is running.
  working,

  /// The turn waits for someone to answer a prompt.
  waiting,

  /// The turn stopped on an error it could not get past.
  stuck,

  /// The turn finished (or was interrupted).
  done,

  /// A state this app version doesn't know.
  unknown,
}

/// One flit session.
final class FlitSession {
  const FlitSession({
    required this.id,
    required this.title,
    required this.workingDir,
    required this.provider,
    required this.model,
    required this.state,
    required this.lastSeq,
    this.teamId = '',
    this.projectId = '',
    this.createdAt,
    this.updatedAt,
    this.effort = '',
    this.role = '',
    this.contextTokens = 0,
    this.contextLength = 0,
    this.mcpServers = const <String>[],
    this.yolo = false,
    this.cronJob = '',
    this.sourceDir = '',
    this.worktreePath = '',
    this.worktreeBranch = '',
    this.worktreeRemoved = false,
  });

  /// The worktree was removed; the session can't run turns any more, and
  /// [worktreeBranch] may still hold its commits.
  final bool worktreeRemoved;

  /// With its own git worktree: the directory the session was started in,
  /// the worktree and its branch ([workingDir] is inside the worktree).
  /// All empty otherwise.
  final String sourceDir;
  final String worktreePath;
  final String worktreeBranch;

  /// Whether the session works in its own git worktree.
  bool get hasWorktree => worktreePath.isNotEmpty;

  /// The cron job this session is a run of; empty for ordinary sessions.
  final String cronJob;

  /// Whether this session is a cron job's run.
  bool get isCronRun => cronJob.isNotEmpty;

  /// MCP servers enabled for the session.
  final List<String> mcpServers;

  /// Yolo mode: every shell command runs unless a deny rule matches.
  final bool yolo;

  /// Reasoning effort; empty means the model's default.
  final String effort;

  /// The role the session was created with; empty for none.
  final String role;

  /// Context use after the last model call, and the model's window (0 if
  /// unknown).
  final int contextTokens;
  final int contextLength;

  final String id;
  final String title;

  /// Absolute path on the server the agent works in.
  final String workingDir;

  /// Configured provider name and model on it; empty when unset.
  final String provider;
  final String model;

  final FlitTaskState state;

  /// Sequence number of the newest event (0 = none).
  final int lastSeq;

  final String teamId;
  final String projectId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The title, or a placeholder for an untitled session.
  String get displayTitle => title.isEmpty ? 'New session' : title;

  @override
  bool operator ==(Object other) {
    return other is FlitSession &&
        other.id == id &&
        other.title == title &&
        other.workingDir == workingDir &&
        other.provider == provider &&
        other.model == model &&
        other.state == state &&
        other.lastSeq == lastSeq &&
        other.teamId == teamId &&
        other.projectId == projectId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.effort == effort &&
        other.role == role &&
        other.contextTokens == contextTokens &&
        other.contextLength == contextLength &&
        other.yolo == yolo &&
        other.worktreePath == worktreePath &&
        other.worktreeBranch == worktreeBranch &&
        other.sourceDir == sourceDir &&
        other.worktreeRemoved == worktreeRemoved;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    workingDir,
    provider,
    model,
    state,
    lastSeq,
    teamId,
    projectId,
    createdAt,
    updatedAt,
    effort,
    role,
    contextTokens,
    contextLength,
    yolo,
    worktreePath,
    worktreeBranch,
  );

  @override
  String toString() =>
      'FlitSession(id: $id, title: $title, state: ${state.name}, '
      'model: $provider/$model, lastSeq: $lastSeq)';
}

/// A llama.cpp router model's state; [none] for other servers.
enum FlitModelState { none, unloaded, loading, loaded, sleeping, failed }

/// A model a flit server can use, as discovered from its provider.
final class FlitModel {
  const FlitModel({
    required this.provider,
    required this.id,
    this.displayName = '',
    this.contextLength = 0,
    this.supportsTools = false,
    this.supportsReasoning = false,
    this.supportsVision = false,
    this.efforts = const <String>[],
    this.loaded = false,
    this.favorite = false,
    this.lastUsed,
    this.state = FlitModelState.none,
    this.canEndReasoning = false,
  });

  /// Whether "answer now" may work: a llama.cpp model not yet seen
  /// ignoring it.
  final bool canEndReasoning;

  final String provider;
  final String id;
  final String displayName;

  /// Starred; favorites are kept on the server, shared by every device.
  final bool favorite;

  /// When a session last used it; null if never.
  final DateTime? lastUsed;

  /// llama.cpp router state. Only routers report one, and only their
  /// models can be loaded and unloaded ([canLoad]).
  final FlitModelState state;

  bool get canLoad => state != FlitModelState.none;

  /// Context window in tokens; 0 if unknown.
  final int contextLength;
  final bool supportsTools;
  final bool supportsReasoning;
  final bool supportsVision;

  /// Reasoning effort levels it accepts.
  final List<String> efforts;

  /// llama.cpp router: loaded right now (no load delay).
  final bool loaded;

  String get label => displayName.isEmpty ? id : displayName;

  @override
  bool operator ==(Object other) =>
      other is FlitModel && other.provider == provider && other.id == id;

  @override
  int get hashCode => Object.hash(provider, id);

  @override
  String toString() => 'FlitModel($provider/$id)';
}

/// A role a session can be created with.
final class FlitAgentRole {
  const FlitAgentRole({
    required this.name,
    this.description = '',
    this.provider = '',
    this.model = '',
    this.effort = '',
    this.error = '',
    this.builtin = false,
  });

  final String name;
  final String description;
  final String provider;
  final String model;
  final String effort;

  /// Why the role file couldn't be read; such roles can't be picked.
  final String error;

  /// Ships with flit; a role file with the same name replaces it.
  final bool builtin;

  @override
  bool operator ==(Object other) =>
      other is FlitAgentRole && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// A project: a group of sessions, usually for one directory on the server.
final class FlitProject {
  const FlitProject({
    required this.id,
    required this.name,
    this.directory = '',
    this.sessionCount = 0,
    this.exportEnabled = true,
    this.worktrees = false,
  });

  /// Whether `flit export` includes this project's sessions.
  final bool exportEnabled;

  /// Whether new sessions get their own git worktree (the project's choice,
  /// or the server's default).
  final bool worktrees;

  final String id;
  final String name;

  /// Absolute directory on the server; empty for Scratch.
  final String directory;
  final int sessionCount;

  @override
  bool operator ==(Object other) =>
      other is FlitProject &&
      other.id == id &&
      other.name == name &&
      other.directory == directory &&
      other.sessionCount == sessionCount &&
      other.exportEnabled == exportEnabled &&
      other.worktrees == worktrees;

  @override
  int get hashCode =>
      Object.hash(id, name, directory, sessionCount, exportEnabled, worktrees);

  @override
  String toString() => 'FlitProject($id, $name)';
}

/// An MCP server as one session sees it.
final class FlitMcpServer {
  const FlitMcpServer({
    required this.name,
    required this.enabled,
    this.running = false,
    this.toolCount = 0,
    this.error = '',
  });

  final String name;
  final bool enabled;
  final bool running;
  final int toolCount;
  final String error;
}

/// What a rating is about.
enum FlitRatingTarget { turn, model }

/// A skill the agent can load, and where it was found ("repo
/// .agents/skills", "global", ...).
final class FlitSkill {
  const FlitSkill({
    required this.name,
    required this.description,
    required this.source,
  });

  final String name;
  final String description;
  final String source;
}
