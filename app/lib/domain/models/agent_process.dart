/// Domain model for agent process info (ticket P3-05).
///
/// Wire shape from docs/reference/08-agent-transparency-wire-shapes.md
/// (section `agents.list`).
library;

/// One agent process from `agents.list` (wire §agents.list) — background
/// agent processes (detached sessions).
final class AgentProcess {
  const AgentProcess({
    required this.sessionId,
    required this.command,
    required this.status,
    required this.uptime,
  });

  /// Wire `session_id` — the durable session id.
  final String sessionId;

  /// Wire `command` — truncated command line (<=80 chars).
  final String command;

  /// Wire `status` — lifecycle string (e.g. `running`, `completed`).
  final String status;

  /// Wire `uptime` — seconds since start.
  final double uptime;

  @override
  bool operator ==(Object other) {
    return other is AgentProcess &&
        other.sessionId == sessionId &&
        other.command == command &&
        other.status == status &&
        other.uptime == uptime;
  }

  @override
  int get hashCode => Object.hash(sessionId, command, status, uptime);

  @override
  String toString() {
    return 'AgentProcess(sessionId: $sessionId, command: $command, '
        'status: $status, uptime: $uptime)';
  }
}
