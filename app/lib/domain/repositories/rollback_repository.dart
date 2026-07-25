import 'package:flit/domain/models/rollback.dart';

/// Intent-level rollback / checkpoint operations (P6-05, P6-06).
///
/// All methods are SESSION-SCOPED: pass the active live session id from
/// `activeSessionProvider.liveId` — the gateway derives cwd + checkpoint store
/// from the session.
abstract interface class RollbackRepository {
  /// `rollback.list {session_id}` → checkpoint list + enabled flag.
  Future<CheckpointList> list(String sessionId);

  /// `rollback.diff {session_id, hash}` → git diff stat + content.
  Future<CheckpointDiff> diff(String sessionId, String hash);

  /// `rollback.restore {session_id, hash, file_path?}` → restore result.
  ///
  /// When `filePath` is omitted: full restore (rewrites working tree AND drops
  /// chat history since the checkpoint). Requires an idle session (error 4009
  /// when a turn is running). When `filePath` is provided: file-scoped restore
  /// (no history drop, allowed during a turn).
  Future<RestoreResult> restore(
    String sessionId,
    String hash, {
    String? filePath,
  });
}
