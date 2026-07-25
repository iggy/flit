/// Repository interface for process control (ticket P5-03).
library;

import 'package:flit/domain/models/background_process.dart';

/// Process control repository — list, kill, stop, and execute shell commands.
abstract interface class ProcessRepository {
  /// List background processes (wire `process.list`).
  ///
  /// Requires a session_id when provided; returns all processes for that
  /// session.
  Future<List<BackgroundProcess>> list({String? sessionId});

  /// Kill a specific background process (wire `process.kill`).
  ///
  /// [processId] is the process's session_id field from the list result.
  /// Requires a session_id when provided.
  Future<ProcessKillResult> kill(String processId, {String? sessionId});

  /// Stop all background processes (wire `process.stop`).
  ///
  /// Returns the count of killed processes. No session_id needed.
  Future<int> stopAll();

  /// Execute a shell command (wire `shell.exec`).
  ///
  /// [command] is the shell command to execute. No cwd/timeout params exist.
  Future<ShellExecResult> exec(String command);
}
