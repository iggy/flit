// P9-02 acceptance: the deep-link connection guard.
//
// - Locations that need a gateway are guarded; the connect flow and unknown
//   paths are not.
// - The guard stores the ORIGINAL location (path + query) in
//   pendingDeepLinkProvider so the connect flow can resume it, and
//   consumePending() returns it exactly once.

import 'package:flit/core/router/app_router.dart';
import 'package:flit/core/router/pending_deep_link_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deepLinkNeedsConnection', () {
    test('guards the deep-link routes', () {
      expect(deepLinkNeedsConnection('/session/durable-1'), isTrue);
      expect(deepLinkNeedsConnection('/plugins/kanban/board-a'), isTrue);
      expect(deepLinkNeedsConnection('/plugins/kanban'), isTrue);
      expect(deepLinkNeedsConnection('/plugins'), isTrue);
      expect(deepLinkNeedsConnection('/chat'), isTrue);
      expect(deepLinkNeedsConnection('/agents'), isTrue);
      expect(deepLinkNeedsConnection('/settings/appearance'), isTrue);
    });

    test('never guards /connect (would loop)', () {
      expect(deepLinkNeedsConnection('/connect'), isFalse);
      expect(deepLinkNeedsConnection('/connect?next=/chat'), isFalse);
    });

    test('does not guard the root or an unknown path', () {
      expect(deepLinkNeedsConnection('/'), isFalse);
      expect(deepLinkNeedsConnection('/nope'), isFalse);
    });
  });

  group('pendingDeepLinkProvider', () {
    test('starts null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pendingDeepLinkProvider), isNull);
    });

    test('setPending keeps the full location, consumePending clears it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pendingDeepLinkProvider.notifier);

      notifier.setPending('/session/durable-1?focus=last');

      expect(
        container.read(pendingDeepLinkProvider),
        '/session/durable-1?focus=last',
      );
      expect(notifier.consumePending(), '/session/durable-1?focus=last');
      // Consumed exactly once: a second read finds nothing pending.
      expect(container.read(pendingDeepLinkProvider), isNull);
      expect(notifier.consumePending(), isNull);
    });

    test('clear drops the pending link without consuming it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pendingDeepLinkProvider.notifier);

      notifier.setPending('/plugins/kanban/board-a');
      notifier.clear();

      expect(container.read(pendingDeepLinkProvider), isNull);
    });
  });
}
