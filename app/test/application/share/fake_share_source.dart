import 'dart:async';

import 'package:flit/domain/models/shared_content.dart';
import 'package:flit/domain/repositories/share_source.dart';

/// A share sheet under the test's control: [waiting] is the share that
/// launched the app; [share] is one arriving while it runs.
final class FakeShareSource implements ShareSource {
  FakeShareSource([this.waiting]);

  SharedContent? waiting;
  final StreamController<void> _arrivals = StreamController<void>.broadcast();

  @override
  Future<SharedContent?> take() async {
    final content = waiting;
    waiting = null;
    return content;
  }

  @override
  Stream<void> get arrivals => _arrivals.stream;

  void share(SharedContent content) {
    waiting = content;
    _arrivals.add(null);
  }
}
