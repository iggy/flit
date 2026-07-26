/// Domain models for process control (ticket P5-03).
///
/// Wire shapes from gateway protocol (process.list, process.kill,
/// process.stop, shell.exec).
library;

/// One background process entry from `process.list`.
final class BackgroundProcess {
  const BackgroundProcess({
    required this.processId,
    this.command,
    this.cwd,
    this.pid,
    this.startedAt,
    this.uptimeSeconds,
    this.status,
    this.outputTail,
    this.outputPreview,
    this.exitCode,
  });

  /// Wire `session_id` (the process id, NOT the session) — used by
  /// process.kill. Renamed to processId to avoid confusion with session ids.
  final String processId;

  /// Wire `command` — the command that was executed.
  final String? command;

  /// Wire `cwd` — the working directory.
  final String? cwd;

  /// Wire `pid` — the OS process id (nullable).
  final int? pid;

  /// Wire `started_at` — ISO timestamp string.
  final String? startedAt;

  /// Wire `uptime_seconds` — seconds since process started.
  final int? uptimeSeconds;

  /// Wire `status` — "running" or "exited".
  final String? status;

  /// Wire `output_tail` — last N lines of output (may be large).
  final String? outputTail;

  /// Wire `output_preview` — short preview of output.
  final String? outputPreview;

  /// Wire `exit_code` — exit code if process has exited.
  final int? exitCode;

  @override
  bool operator ==(Object other) {
    return other is BackgroundProcess &&
        other.processId == processId &&
        other.command == command &&
        other.cwd == cwd &&
        other.pid == pid &&
        other.startedAt == startedAt &&
        other.uptimeSeconds == uptimeSeconds &&
        other.status == status &&
        other.outputTail == outputTail &&
        other.outputPreview == outputPreview &&
        other.exitCode == exitCode;
  }

  @override
  int get hashCode => Object.hash(
    processId,
    command,
    cwd,
    pid,
    startedAt,
    uptimeSeconds,
    status,
    outputTail,
    outputPreview,
    exitCode,
  );

  @override
  String toString() {
    return 'BackgroundProcess(processId: $processId, command: $command, '
        'cwd: $cwd, pid: $pid, startedAt: $startedAt, '
        'uptimeSeconds: $uptimeSeconds, status: $status, '
        'outputTail: $outputTail, outputPreview: $outputPreview, '
        'exitCode: $exitCode)';
  }
}

/// Result of `process.kill` — polymorphic keyed by status.
final class ProcessKillResult {
  const ProcessKillResult({required this.status, this.output, this.error});

  /// Wire `status` — "killed", "already_exited", "not_found", or "error".
  final String status;

  /// Wire `output` — output message (nullable).
  final String? output;

  /// Wire `error` — error message (nullable).
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is ProcessKillResult &&
        other.status == status &&
        other.output == output &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, output, error);

  @override
  String toString() {
    return 'ProcessKillResult(status: $status, output: $output, '
        'error: $error)';
  }
}

/// Result of `shell.exec`.
final class ShellExecResult {
  const ShellExecResult({
    required this.stdout,
    required this.stderr,
    required this.code,
  });

  /// Wire `stdout` — standard output.
  final String stdout;

  /// Wire `stderr` — standard error.
  final String stderr;

  /// Wire `code` — exit code.
  final int code;

  @override
  bool operator ==(Object other) {
    return other is ShellExecResult &&
        other.stdout == stdout &&
        other.stderr == stderr &&
        other.code == code;
  }

  @override
  int get hashCode => Object.hash(stdout, stderr, code);

  @override
  String toString() {
    return 'ShellExecResult(stdout: $stdout, stderr: $stderr, code: $code)';
  }
}
