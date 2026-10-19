import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();

  @override
  Future<FlitSession> getSession(String id) async => const FlitSession(
    id: 's1',
    title: 'Fix the build',
    workingDir: '/src/app',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
    projectId: 'p1',
  );

  @override
  Future<List<FlitProject>> listProjects() async => const <FlitProject>[
    FlitProject(id: 'p1', name: 'Web'),
  ];

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      events.stream;
}

void main() {
  Future<(_Repo, ProviderContainer)> pump(WidgetTester tester) async {
    final repo = _Repo();
    addTearDown(repo.events.close);
    final container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FlitChatScreen(sessionId: 's1')),
      ),
    );
    await tester.pump();
    return (repo, container);
  }

  var seq = 0;
  Future<void> message(
    WidgetTester tester,
    _Repo repo,
    String id,
    String text, {
    bool done = true,
  }) async {
    repo.events
      ..add(
        FlitMessageStarted(seq: ++seq, messageId: id, role: FlitRole.assistant),
      )
      ..add(FlitTextDelta(seq: ++seq, messageId: id, text: text));
    if (done) {
      repo.events.add(
        FlitMessageDone(
          seq: ++seq,
          messageId: id,
          text: text,
          reasoning: '',
          finishReason: 'stop',
        ),
      );
    }
    await tester.pump();
    await tester.pump();
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('streaming only follows when already at the bottom', (
    tester,
  ) async {
    seq = 0;
    final (repo, _) = await pump(tester);
    for (var i = 0; i < 20; i++) {
      await message(tester, repo, 'm$i', 'Message number $i\n\nwith a body');
    }
    final p = position(tester);
    expect(p.maxScrollExtent, greaterThan(0));
    expect(p.pixels, p.maxScrollExtent);

    // Scroll up to read; new output must not drag the view back down.
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    final readingAt = p.pixels;
    expect(readingAt, lessThan(p.maxScrollExtent - 100));
    await message(tester, repo, 'live', 'streaming…', done: false);
    repo.events.add(
      FlitTextDelta(seq: ++seq, messageId: 'live', text: ' more'),
    );
    await tester.pump();
    await tester.pump();
    expect(p.pixels, readingAt);
    expect(find.byKey(flitJumpToLatestKey), findsOneWidget);

    await tester.tap(find.byKey(flitJumpToLatestKey));
    await tester.pump();
    await tester.pump();
    expect(p.pixels, p.maxScrollExtent);
    expect(find.byKey(flitJumpToLatestKey), findsNothing);

    // Back at the bottom, it follows again.
    await message(tester, repo, 'next', 'one more\n\nmessage\n\nhere');
    expect(p.pixels, p.maxScrollExtent);
    expect(find.byKey(flitJumpToLatestKey), findsNothing);
  });

  testWidgets('narrow windows show Project › Session; project goes back', (
    tester,
  ) async {
    final (_, container) = await pump(tester);
    await tester.pump();
    expect(find.byKey(flitBreadcrumbProjectKey), findsOneWidget);
    expect(find.text('Web'), findsOneWidget);
    expect(find.text('Fix the build'), findsOneWidget);
    await tester.tap(find.byKey(flitBreadcrumbProjectKey));
    await tester.pump();
    expect(container.read(flitSelectedProjectProvider), 'p1');
  });
}
