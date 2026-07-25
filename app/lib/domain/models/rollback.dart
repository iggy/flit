import 'package:flit/domain/models/deep_equals.dart';

/// A single git checkpoint from the gateway's checkpoint manager.
final class Checkpoint {
  const Checkpoint({
    required this.hash,
    required this.timestamp,
    required this.message,
  });

  /// Full 40-character git hash.
  final String hash;

  /// ISO 8601 timestamp when the checkpoint was created.
  final String timestamp;

  /// Human-readable reason for this checkpoint.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is Checkpoint &&
        other.hash == hash &&
        other.timestamp == timestamp &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(hash, timestamp, message);

  @override
  String toString() {
    return 'Checkpoint(hash: $hash, timestamp: $timestamp, message: $message)';
  }
}

/// Result from `rollback.list`: the enabled flag and the checkpoint list.
final class CheckpointList {
  const CheckpointList({
    required this.enabled,
    required this.checkpoints,
  });

  /// Whether checkpointing is enabled for this session.
  final bool enabled;

  /// List of checkpoints, most recent first.
  final List<Checkpoint> checkpoints;

  @override
  bool operator ==(Object other) {
    return other is CheckpointList &&
        other.enabled == enabled &&
        deepListEquals(other.checkpoints, checkpoints);
  }

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(checkpoints));

  @override
  String toString() {
    return 'CheckpointList(enabled: $enabled, checkpoints: $checkpoints)';
  }
}

/// Result from `rollback.diff`: git diff statistics and content.
final class CheckpointDiff {
  const CheckpointDiff({
    required this.stat,
    required this.diff,
  });

  /// Git diff --stat summary line.
  final String stat;

  /// Raw unified diff content (truncated to 4000 chars on server).
  final String diff;

  @override
  bool operator ==(Object other) {
    return other is CheckpointDiff &&
        other.stat == stat &&
        other.diff == diff;
  }

  @override
  int get hashCode => Object.hash(stat, diff);

  @override
  String toString() {
    return 'CheckpointDiff(stat: $stat, diff: ${diff.substring(0, diff.length > 50 ? 50 : diff.length)}...)';
  }
}

/// Result from `rollback.restore`: whether the restore succeeded and metadata.
final class RestoreResult {
  const RestoreResult({
    required this.success,
    this.restoredTo,
    this.reason,
    this.directory,
    this.file,
    this.historyRemoved,
    this.error,
  });

  /// Whether the restore succeeded.
  final bool success;

  /// Short hash of the checkpoint that was restored to (full restore only).
  final String? restoredTo;

  /// Human-readable reason for the checkpoint (full restore only).
  final String? reason;

  /// Working directory path (full restore only).
  final String? directory;

  /// File path (file-scoped restore only).
  final String? file;

  /// Number of chat turns dropped (full restore only).
  final int? historyRemoved;

  /// Human-readable error message when success is false.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is RestoreResult &&
        other.success == success &&
        other.restoredTo == restoredTo &&
        other.reason == reason &&
        other.directory == directory &&
        other.file == file &&
        other.historyRemoved == historyRemoved &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        success,
        restoredTo,
        reason,
        directory,
        file,
        historyRemoved,
        error,
      );

  @override
  String toString() {
    return 'RestoreResult(success: $success, restoredTo: $restoredTo, '
        'reason: $reason, directory: $directory, file: $file, '
        'historyRemoved: $historyRemoved, error: $error)';
  }
}
