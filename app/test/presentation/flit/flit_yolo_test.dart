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
  final List<String> calls = <String>[];
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();
  bool yolo = false;

  FlitSession get _session => FlitSession(
    id: 's1',
    title: 'Session',
    workingDir: '/src/app',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
    yolo: yolo,
  );

  @override
  Future<FlitSession> getSession(String id) async => _session;

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      events.stream;

  @override
  Future<FlitSession> setYolo(String sessionId, {required bool yolo}) async {
    calls.add('yolo:$yolo');
    this.yolo = yolo;
    return _session;
  }
}

void main() {
  testWidgets('yolo toggle confirms before turning on', (tester) async {
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

    IconButton button() =>
        tester.widget<IconButton>(find.byKey(flitYoloButtonKey));
    expect(button().isSelected, isFalse);

    // Cancelling the dialog changes nothing.
    await tester.tap(find.byKey(flitYoloButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Turn on yolo mode?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);

    await tester.tap(find.byKey(flitYoloButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(flitYoloConfirmKey));
    await tester.pumpAndSettle();
    expect(repo.calls, <String>['yolo:true']);
    expect(button().isSelected, isTrue);

    // Another client turning it off shows up from the log.
    repo.events.add(const FlitYoloChanged(seq: 1, yolo: false));
    await tester.pump();
    await tester.pump();
    expect(button().isSelected, isFalse);

    // Turning it off doesn't ask.
    repo.events.add(const FlitYoloChanged(seq: 2, yolo: true));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(flitYoloButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Turn on yolo mode?'), findsNothing);
    expect(repo.calls, <String>['yolo:true', 'yolo:false']);
  });
}
