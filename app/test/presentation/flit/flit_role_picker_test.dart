import 'dart:async';

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flit/presentation/flit/flit_chat_screen.dart';
import 'package:flit/presentation/flit/flit_role_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends Fake implements FlitRepository {
  final List<String> calls = <String>[];
  final StreamController<FlitEvent> events = StreamController<FlitEvent>();
  String role = 'planner';

  FlitSession get _session => FlitSession(
    id: 's1',
    title: 'Session',
    workingDir: '/src/app',
    provider: 'local',
    model: 'qwen',
    state: FlitTaskState.idle,
    lastSeq: 0,
    role: role,
  );

  @override
  Future<FlitSession> getSession(String id) async => _session;

  @override
  Stream<FlitEvent> attach(String sessionId, {required int fromSeq}) =>
      events.stream;

  @override
  Future<List<FlitAgentRole>> listRoles() async => const <FlitAgentRole>[
    FlitAgentRole(name: 'implementer', description: 'Builds it'),
    FlitAgentRole(name: 'planner', description: 'Plans it'),
    FlitAgentRole(name: 'broken', error: 'bad frontmatter'),
  ];

  @override
  Future<FlitSession> setRole(String sessionId, String role) async {
    calls.add('role:$role');
    this.role = role;
    return _session;
  }

  @override
  Future<List<FlitSkill>> listSkills(String sessionId) async =>
      const <FlitSkill>[];
}

void main() {
  test('flitRoleCommandArg', () {
    expect(flitRoleCommandArg('/role'), '');
    expect(flitRoleCommandArg(' /role qa '), 'qa');
    expect(flitRoleCommandArg('/roles'), isNull);
    expect(flitRoleCommandArg('/role a b'), isNull);
    expect(flitRoleCommandArg('hello'), isNull);
  });

  testWidgets('role picker switches the role; the log shows a divider', (
    tester,
  ) async {
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
    expect(
      find.descendant(
        of: find.byKey(flitRoleButtonKey),
        matching: find.text('planner'),
      ),
      findsOneWidget,
    );

    // A broken role can't be picked.
    await tester.tap(find.byKey(flitRoleButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('bad frontmatter'), findsOneWidget);
    await tester.tap(find.byKey(const Key('${flitRoleItemKeyPrefix}broken')));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    await tester.tap(
      find.byKey(const Key('${flitRoleItemKeyPrefix}implementer')),
    );
    await tester.pumpAndSettle();
    expect(repo.calls, <String>['role:implementer']);

    // The switch shows up from the log, as the current role and a divider.
    repo.events
      ..add(
        const FlitMessageStarted(seq: 1, messageId: 'u1', role: FlitRole.user),
      )
      ..add(
        const FlitRoleChanged(
          seq: 2,
          role: 'implementer',
          previousRole: 'planner',
        ),
      );
    await tester.pump();
    await tester.pump();
    expect(find.text('Switched role to implementer'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(flitRoleButtonKey),
        matching: find.text('implementer'),
      ),
      findsOneWidget,
    );

    // /role name from the composer.
    await tester.enterText(find.byType(TextField), '/role qa');
    await tester.tap(find.byKey(flitSendKey));
    await tester.pumpAndSettle();
    expect(repo.calls, <String>['role:implementer', 'role:qa']);
  });
}
