/// MCP and environment reload operations (ticket P4-05).
///
/// Methods follow wire protocol: `reload.mcp`, `reload.env`.
library;

/// Outcome of `reload.mcp` — either confirmation required or done.
sealed class ReloadMcpOutcome {
  const ReloadMcpOutcome();
}

/// The gateway requires confirmation before reloading (wire
/// `{status:"confirm_required", message}`). Re-send with `confirm:true`.
final class ReloadMcpConfirmRequired extends ReloadMcpOutcome {
  const ReloadMcpConfirmRequired({required this.message});

  /// The confirmation prompt to show.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is ReloadMcpConfirmRequired && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ReloadMcpConfirmRequired(message: $message)';
}

/// MCP servers were reloaded successfully (wire `{status:"reloaded"}`).
final class ReloadMcpDone extends ReloadMcpOutcome {
  const ReloadMcpDone({required this.coalesced});

  /// Wire `coalesced` — whether the reload was coalesced with another.
  final bool coalesced;

  @override
  bool operator ==(Object other) {
    return other is ReloadMcpDone && other.coalesced == coalesced;
  }

  @override
  int get hashCode => coalesced.hashCode;

  @override
  String toString() => 'ReloadMcpDone(coalesced: $coalesced)';
}

/// MCP and environment reload operations.
abstract interface class ReloadRepository {
  /// `reload.mcp` — reload MCP servers.
  ///
  /// On first call (confirm=false), may return [ReloadMcpConfirmRequired].
  /// Re-call with confirm=true to proceed.
  Future<ReloadMcpOutcome> reloadMcp({
    String? sessionId,
    bool confirm = false,
  });

  /// `reload.env` — reload environment variables.
  ///
  /// Returns the count of updated variables.
  Future<int> reloadEnv();
}
