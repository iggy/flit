import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> sent = <String>[];
  final List<StreamController<FlitEvent>> streams =
      <StreamController<FlitEvent>>[];

  @override
  Future<FlitSession> getSession(String id) async => FlitSession(
    id: id,
    title: 'Session $id',
    workingDir: '/src/app',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
  );

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) {
    final c = StreamController<FlitEvent>();
    streams.add(c);
    return c.stream;
  }

  @override
  Future<void> send(String sessionId, String text, {String client = ''}) async {
    sent.add('$sessionId: $text');
  }
}

void main() {
  testWidgets('unsent text survives switching sessions; sending clears it', (
    tester,
  ) async {
    final repo = _Repo();
    addTearDown(() async {
      for (final c in repo.streams) {
        await c.close();
      }
    });
    final container = ProviderContainer(
      overrides: [flitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    // Each open builds a fresh screen, like the router does.
    Future<void> open(String id) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FlitChatScreen(key: ValueKey<String>(id), sessionId: id),
          ),
        ),
      );
      await tester.pump();
    }

    String composerText() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    // A new session: type, go to another one, come back.
    await open('new');
    await tester.enterText(find.byType(TextField), 'fix the bug in');
    await open('other');
    expect(composerText(), isEmpty);
    await tester.enterText(find.byType(TextField), 'something else');
    await open('new');
    expect(composerText(), 'fix the bug in');

    // The other session kept its own draft.
    await open('other');
    expect(composerText(), 'something else');

    // Sending clears the draft, so it doesn't come back.
    await open('new');
    await tester.enterText(find.byType(TextField), 'fix the bug in main.go');
    await tester.tap(find.byKey(flitSendKey));
    await tester.pumpAndSettle();
    expect(repo.sent, <String>['new: fix the bug in main.go']);
    expect(composerText(), isEmpty);
    await open('other');
    await open('new');
    expect(composerText(), isEmpty);
  });
}
