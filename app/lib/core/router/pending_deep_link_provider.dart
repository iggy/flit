/// Pending deep-link state (ticket P9-02): when a deep link arrives before
/// the user has connected to a gateway, the router redirects to `/connect`
/// and stores the original location here so the connect flow can resume it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The pending deep-link location (path + query), or null when there's no
/// pending link. Set by the router's redirect guard; consumed by the connect
/// flow after a successful connection.
final pendingDeepLinkProvider =
    NotifierProvider<PendingDeepLinkNotifier, String?>(
      PendingDeepLinkNotifier.new,
    );

class PendingDeepLinkNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Store a pending deep-link location (called by the router's redirect).
  void setPending(String location) {
    state = location;
  }

  /// Consume the pending location (returns and clears it).
  String? consumePending() {
    final pending = state;
    state = null;
    return pending;
  }

  /// Clear the pending location without consuming it.
  void clear() {
    state = null;
  }
}
