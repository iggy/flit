/// Shares from other apps ("Share via… flit"): the one waiting to be turned
/// into a new flit session, and what to do with it given the connection.
library;

import 'dart:async';

import 'package:flit/core/platform/share_intake.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/shared_content.dart';
import 'package:flit/domain/repositories/share_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform's share source. Override with a fake in tests.
final shareSourceProvider = Provider<ShareSource>(
  (ref) => MethodChannelShareSource(),
);

/// The share waiting to become a new session, or null. Fed by
/// [shareSourceProvider]: picks up the share that launched the app, and
/// any that arrive later (a newer share replaces an unhandled one).
final pendingShareProvider =
    NotifierProvider<PendingShareNotifier, SharedContent?>(
      PendingShareNotifier.new,
    );

class PendingShareNotifier extends Notifier<SharedContent?> {
  @override
  SharedContent? build() {
    final source = ref.watch(shareSourceProvider);
    final sub = source.arrivals.listen((_) => unawaited(_take(source)));
    ref.onDispose(sub.cancel);
    unawaited(_take(source));
    return null;
  }

  Future<void> _take(ShareSource source) async {
    final content = await source.take();
    if (content != null && ref.mounted) {
      state = content;
    }
  }

  /// Hands over the waiting share (null if none) and clears it.
  SharedContent? consume() {
    final content = state;
    state = null;
    return content;
  }
}

/// What to do with a waiting share.
enum ShareRoute {
  /// Nothing waiting.
  none,

  /// No connection (yet): keep it until one is made. The stored connection
  /// may still be loading, and pairing with a flit server picks it up.
  wait,

  /// Connected to flit: open the flit screens, which start a session.
  flit,

  /// Connected to Hermes, which this doesn't support: tell the user.
  unsupported,
}

/// The pure routing decision for [pending] given the connection [config].
ShareRoute shareRouteFor(SharedContent? pending, ConnectionConfig? config) {
  if (pending == null) {
    return ShareRoute.none;
  }
  if (config == null) {
    return ShareRoute.wait;
  }
  return config.backend == BackendKind.flit
      ? ShareRoute.flit
      : ShareRoute.unsupported;
}
