/// A background shell job: a command that runs on while the agent's turn
/// goes on (flit's shell with background, or one that ran long).
library;

enum BackgroundJobStatus { running, exited, failed, timedOut, cancelled, lost }

final class BackgroundJob {
  const BackgroundJob({
    required this.id,
    this.command = '',
    this.detached = false,
    this.status = BackgroundJobStatus.running,
    this.exitCode = 0,
    this.error = '',
    this.output = '',
    this.duration,
    this.cancelledBy = '',
    this.startedAt,
  });

  /// The session's id for it, e.g. `job_1`.
  final String id;
  final String command;

  /// Whether it ran in the foreground first and moved to the background
  /// because it ran long.
  final bool detached;
  final BackgroundJobStatus status;

  /// For [BackgroundJobStatus.exited].
  final int exitCode;
  final String error;

  /// Its output as it arrives (the end of it, when long); once it ended
  /// without live output, the last part of it.
  final String output;

  /// How long it ran, once it ended.
  final Duration? duration;

  /// Who cancelled it: a client name, or empty for the agent.
  final String cancelledBy;
  final DateTime? startedAt;

  bool get running => status == BackgroundJobStatus.running;

  /// Ended badly: a non-zero exit, a failure or a timeout.
  bool get failed => switch (status) {
    BackgroundJobStatus.exited => exitCode != 0,
    BackgroundJobStatus.failed || BackgroundJobStatus.timedOut => true,
    _ => false,
  };

  BackgroundJob copyWith({
    BackgroundJobStatus? status,
    int? exitCode,
    String? error,
    String? output,
    Duration? duration,
    String? cancelledBy,
  }) {
    return BackgroundJob(
      id: id,
      command: command,
      detached: detached,
      status: status ?? this.status,
      exitCode: exitCode ?? this.exitCode,
      error: error ?? this.error,
      output: output ?? this.output,
      duration: duration ?? this.duration,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      startedAt: startedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BackgroundJob &&
        other.id == id &&
        other.command == command &&
        other.detached == detached &&
        other.status == status &&
        other.exitCode == exitCode &&
        other.error == error &&
        other.output == output &&
        other.duration == duration &&
        other.cancelledBy == cancelledBy &&
        other.startedAt == startedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    command,
    detached,
    status,
    exitCode,
    error,
    output,
    duration,
    cancelledBy,
    startedAt,
  );
}
