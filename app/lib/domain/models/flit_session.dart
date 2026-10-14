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
  });

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
        other.updatedAt == updatedAt;
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
  );

  @override
  String toString() =>
      'FlitSession(id: $id, title: $title, state: ${state.name}, '
      'model: $provider/$model, lastSeq: $lastSeq)';
}
