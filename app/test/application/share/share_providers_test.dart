import 'package:flit/application/share/share_providers.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/shared_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_share_source.dart';

void main() {
  const paper = SharedContent(text: 'https://arxiv.org/abs/1706.03762');

  ProviderContainer containerWith(FakeShareSource source) {
    final c = ProviderContainer(
      overrides: [shareSourceProvider.overrideWithValue(source)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('picks up the share that launched the app', () async {
    final source = FakeShareSource(paper);
    final c = containerWith(source);
    final sub = c.listen(pendingShareProvider, (_, _) {});
    addTearDown(sub.close);
    expect(c.read(pendingShareProvider), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(pendingShareProvider), paper);
    expect(source.waiting, isNull, reason: 'taken from the platform');
  });

  test('picks up shares arriving later; consume clears', () async {
    final source = FakeShareSource();
    final c = containerWith(source);
    final sub = c.listen(pendingShareProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(pendingShareProvider), isNull);

    source.share(paper);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(pendingShareProvider), paper);

    expect(c.read(pendingShareProvider.notifier).consume(), paper);
    expect(c.read(pendingShareProvider), isNull);
    expect(c.read(pendingShareProvider.notifier).consume(), isNull);
  });

  test('routing depends on the connection', () {
    final flit = ConnectionConfig(
      baseUrl: 'https://flit.example.com',
      token: 't',
      backend: BackendKind.flit,
    );
    final hermes = ConnectionConfig(baseUrl: 'http://127.0.0.1:9119');
    expect(shareRouteFor(null, flit), ShareRoute.none);
    expect(shareRouteFor(paper, null), ShareRoute.wait);
    expect(shareRouteFor(paper, flit), ShareRoute.flit);
    expect(shareRouteFor(paper, hermes), ShareRoute.unsupported);
  });
}
