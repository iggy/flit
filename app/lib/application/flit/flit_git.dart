/// A flit session's git status and diffs. The status refreshes on its own
/// when a tool that may change files finishes or a turn ends, debounced so a
/// burst of events (a replay, several tools in a row) costs one request.
library;

import 'dart:async';

import 'package:flit/application/flit/flit_chat_notifier.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the status waits after the last trigger before refreshing.
/// Overridden in tests.
final flitGitRefreshDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 500),
);

/// A session's git status, keyed by session id. [FlitGitStatus.none] when
/// the session isn't in a repository (or there is no flit connection).
final flitGitStatusProvider =
    AsyncNotifierProvider.family<FlitGitStatusNotifier, FlitGitStatus, String>(
      FlitGitStatusNotifier.new,
    );

class FlitGitStatusNotifier extends AsyncNotifier<FlitGitStatus> {
  FlitGitStatusNotifier(this.sessionId);

  final String sessionId;
  Timer? _debounce;

  @override
  Future<FlitGitStatus> build() async {
    final repository = ref.watch(flitRepositoryProvider);
    ref
      ..onDispose(() => _debounce?.cancel())
      ..listen(
        flitChatProvider(
          sessionId,
        ).select((s) => (s.fold.fileToolsDone, s.fold.busy)),
        (prev, next) {
          if (prev == null) {
            return;
          }
          final turnEnded = prev.$2 && !next.$2;
          if (next.$1 != prev.$1 || turnEnded) {
            _schedule();
          }
        },
      );
    if (repository == null) {
      return FlitGitStatus.none;
    }
    return repository.gitStatus(sessionId);
  }

  void _schedule() {
    // Failing (e.g. a server without the git RPCs, or no git on it): don't
    // keep asking. A new connection builds the provider again.
    if (state.hasError && !state.hasValue) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(ref.read(flitGitRefreshDelayProvider), () {
      unawaited(refresh());
    });
  }

  /// Fetches the status again. A failure keeps the last good status.
  Future<void> refresh() async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    final next = await AsyncValue.guard(() => repository.gitStatus(sessionId));
    if (!ref.mounted || (next.hasError && state.hasValue)) {
      return;
    }
    state = next;
  }
}

/// A session's diff since its base: (session id, path), path '' for all.
/// Fetched again whenever the session's status refreshes.
final flitGitDiffProvider =
    FutureProvider.family<FlitGitDiff, (String, String)>((ref, key) async {
      final (sessionId, path) = key;
      final repository = ref.watch(flitRepositoryProvider);
      ref.watch(flitGitStatusProvider(sessionId).select((s) => s.value));
      if (repository == null) {
        return const FlitGitDiff(isRepo: false, text: '');
      }
      return repository.gitDiff(sessionId, path: path);
    });
