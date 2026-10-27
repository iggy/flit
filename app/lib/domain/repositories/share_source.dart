import 'package:flit/domain/models/shared_content.dart';

/// Where shares from other apps come in (the platform's share sheet).
///
/// Pull-based so nothing is lost while the app is still starting: [take]
/// hands over the waiting share, if any, and [arrivals] only says that
/// another one is waiting.
abstract interface class ShareSource {
  /// The share waiting to be handled, or null. Taking it clears it.
  Future<SharedContent?> take();

  /// Fires each time a new share arrives while the app is running.
  Stream<void> get arrivals;
}
