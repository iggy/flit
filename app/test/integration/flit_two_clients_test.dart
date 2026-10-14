// Two devices on one flit session, against a real `flit serve`.
//
// Skipped unless these are set (run "flit pair" twice for the codes):
//   FLIT_E2E_URL      server URL, e.g. http://127.0.0.1:7433
//   FLIT_E2E_CODE_A   pairing code for client A (the app's own chat state)
//   FLIT_E2E_CODE_B   pairing code for client B (a second device)
//   FLIT_E2E_WORKDIR  working directory on the server
// The server needs a provider/model that can call tools, and shell rules
// that ask before running `echo` (the default).
//
//   flutter test test/integration/flit_two_clients_test.dart
@Tags(<String>['e2e'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flit/application/flit/flit_chat_notifier.dart';
import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/data/flit/flit_pairing.dart';
import 'package:flit/data/flit/flit_repository_impl.dart';
import 'package:flit/data/flit/flit_transport.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final env = Platform.environment;
  final url = env['FLIT_E2E_URL'];
  final skip = url == null
      ? 'set FLIT_E2E_URL, FLIT_E2E_CODE_A, FLIT_E2E_CODE_B, FLIT_E2E_WORKDIR'
      : null;

  test(
    'a prompt raised in one client is answered from another; both converge',
    () async {
      final a = await pairWithServer(
        serverUrl: url!,
        code: env['FLIT_E2E_CODE_A']!,
        deviceName: 'e2e desktop',
      );
      final b = await pairWithServer(
        serverUrl: url,
        code: env['FLIT_E2E_CODE_B']!,
        deviceName: 'e2e phone',
      );
      final repoA = FlitRepositoryImpl(
        createFlitTransport(baseUrl: url, token: a.token),
      );
      final repoB = FlitRepositoryImpl(
        createFlitTransport(baseUrl: url, token: b.token),
      );

      final session = await repoA.createSession(
        workingDir: env['FLIT_E2E_WORKDIR']!,
      );

      // Client A: the app's real chat notifier.
      final container = ProviderContainer(
        overrides: [
          flitRepositoryProvider.overrideWithValue(repoA),
          flitDeviceNameProvider.overrideWithValue(a.deviceName),
        ],
      );
      addTearDown(container.dispose);
      final states = <FlitChatState>[];
      final sub = container.listen(
        flitChatProvider(session.id),
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Client B: raw event stream, answering the prompt when it shows up.
      final bEvents = <FlitEvent>[];
      final answered = Completer<String>();
      final bSub = repoB.attach(session.id, fromSeq: 1).listen((event) {
        bEvents.add(event);
        if (event is FlitPromptRequested && !answered.isCompleted) {
          answered.complete(event.promptId);
          unawaited(
            repoB.answerPrompt(
              session.id,
              event.promptId,
              allow: true,
              client: b.deviceName,
            ),
          );
        }
      });
      addTearDown(bSub.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      final sendError = await container
          .read(flitChatProvider(session.id).notifier)
          .send(
            'Use the shell tool to run exactly this command: echo flit-two-clients. '
            'Then reply with the word done.',
          );
      expect(sendError, isNull);

      // Client A sees the prompt before B answers it…
      await _until(
        () => states.any((s) => s.fold.prompts.isNotEmpty),
        'client A to see the prompt',
      );
      final promptId = await answered.future.timeout(
        const Duration(minutes: 3),
      );
      // …and sees it go away once B's answer is logged.
      await _until(
        () => container.read(flitChatProvider(session.id)).fold.prompts.isEmpty,
        'client A to see the prompt resolved',
      );
      await _until(
        () {
          final st = container
              .read(flitChatProvider(session.id))
              .fold
              .taskState;
          return st == FlitTaskState.done || st == FlitTaskState.stuck;
        },
        'the turn to end',
        timeout: const Duration(minutes: 5),
      );

      final fold = container.read(flitChatProvider(session.id)).fold;
      expect(fold.taskState, FlitTaskState.done);
      final resolved = bEvents.whereType<FlitPromptResolved>().single;
      expect(resolved.promptId, promptId);
      expect(resolved.client, 'e2e phone');
      final tool = fold.messages
          .expand((m) => m.toolCalls)
          .firstWhere((t) => t.name == 'shell');
      expect('${tool.result}', contains('flit-two-clients'));
      expect(fold.messages.first.role, MessageRole.user);

      // Both clients folded the same log to the same view.
      final foldB = foldFlitEvents(const FlitFoldState(), bEvents);
      expect(foldB.lastSeq, fold.lastSeq);
      expect(foldB.messages, fold.messages);

      // A third look from scratch (a reconnecting phone) matches too.
      final replay = await repoB
          .attach(session.id, fromSeq: 1)
          .take(fold.lastSeq)
          .toList();
      expect(foldFlitEvents(const FlitFoldState(), replay), foldB);

      // ignore: avoid_print
      print(
        'two-client check: session ${session.id}, ${fold.lastSeq} events, '
        'prompt answered by "${resolved.client}", '
        'tool output: ${'${tool.result}'.trim().split('\n').first}',
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

Future<void> _until(
  bool Function() done,
  String what, {
  Duration timeout = const Duration(minutes: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
