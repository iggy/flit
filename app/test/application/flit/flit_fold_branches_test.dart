import 'package:flit/application/flit/flit_branches.dart';
import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// A whole message: started, one delta, done (3 seqs from [seq]).
List<FlitEvent> message(
  int seq,
  String id,
  String text, {
  FlitRole role = FlitRole.assistant,
  String branch = '',
}) => <FlitEvent>[
  FlitMessageStarted(seq: seq, messageId: id, role: role, branchId: branch),
  FlitTextDelta(seq: seq + 1, messageId: id, text: text, branchId: branch),
  FlitMessageDone(
    seq: seq + 2,
    messageId: id,
    text: text,
    reasoning: '',
    finishReason: 'stop',
    branchId: branch,
  ),
];

List<FlitEvent> user(int seq, String id, String text, {String branch = ''}) =>
    message(seq, id, text, role: FlitRole.user, branch: branch);

FlitEvent done(int seq, {String branch = ''}) => FlitTaskStateChanged(
  seq: seq,
  state: FlitTaskState.done,
  reason: '',
  branchId: branch,
);

List<String> texts(FlitFoldState s) => s.messages.map((m) => m.text).toList();

void main() {
  // root: u1 a1 u2 a2. b1 retries u2 (forks after u2's done, seq 9).
  final root = <FlitEvent>[
    ...user(1, 'u1', 'hi'),
    ...message(4, 'a1', 'hello'),
    ...user(7, 'u2', 'more'),
    ...message(10, 'a2', 'first answer'),
    done(13),
  ];
  final retry = <FlitEvent>[
    const FlitBranchCreated(
      seq: 14,
      newBranchId: 'b1',
      parentBranchId: '',
      forkSeq: 9,
      kind: FlitBranchKind.retry,
      messageId: 'u2',
    ),
    const FlitBranchSwitched(seq: 15, newBranchId: 'b1', branchId: 'b1'),
    ...message(16, 'a2b', 'second answer', branch: 'b1'),
    done(19, branch: 'b1'),
  ];

  test('a retry shows the new branch with a switch on its reply', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      ...root,
      ...retry,
    ]);
    expect(s.activeBranch, 'b1');
    expect(texts(s), <String>['hi', 'hello', 'more', 'second answer']);
    expect(s.branchChoices, <String, FlitBranchChoice>{
      'a2b': const FlitBranchChoice(index: 1, targets: <String>['', 'b1']),
    });
  });

  test('switching back re-folds the other branch, deltas and all', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      ...root,
      ...retry,
      const FlitBranchSwitched(seq: 20, newBranchId: ''),
    ]);
    expect(s.activeBranch, '');
    expect(texts(s), <String>['hi', 'hello', 'more', 'first answer']);
    expect(s.branchChoices['a2'], isNotNull);
    expect(s.branchChoices['a2']!.index, 0);
    expect(s.lastSeq, 20);
    expect(s.taskState, FlitTaskState.done);
  });

  test('an edit forks before the message; its switch sits on it', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      ...root,
      ...retry,
      const FlitBranchSwitched(seq: 20, newBranchId: ''),
      // Edit u1 (forks before its MessageStarted at seq 1).
      const FlitBranchCreated(
        seq: 21,
        newBranchId: 'b2',
        parentBranchId: '',
        forkSeq: 0,
        kind: FlitBranchKind.edit,
        messageId: 'u1',
      ),
      const FlitBranchSwitched(seq: 22, newBranchId: 'b2', branchId: 'b2'),
      ...user(23, 'u1b', 'hey', branch: 'b2'),
      ...message(26, 'a1b', 'hey there', branch: 'b2'),
      done(29, branch: 'b2'),
    ]);
    expect(texts(s), <String>['hey', 'hey there']);
    // The root (used more recently than b1) is the other alternative.
    expect(
      s.branchChoices['u1b'],
      const FlitBranchChoice(index: 1, targets: <String>['', 'b2']),
    );
    expect(s.branchChoices.length, 1);

    // Going back to the root's side opens where it was last used.
    final back = foldFlitEvent(
      s,
      const FlitBranchSwitched(seq: 30, newBranchId: ''),
    );
    expect(texts(back), <String>['hi', 'hello', 'more', 'first answer']);
    expect(
      back.branchChoices['u1'],
      const FlitBranchChoice(index: 0, targets: <String>['', 'b2']),
    );
  });

  test('every client converges: replay equals live, twice is a no-op', () {
    final log = <FlitEvent>[
      ...root,
      ...retry,
      const FlitBranchSwitched(seq: 20, newBranchId: ''),
      ...user(21, 'u3', 'and', branch: ''),
    ];
    var live = const FlitFoldState();
    for (final e in log) {
      live = foldFlitEvent(live, e);
    }
    final replay = foldFlitEvents(const FlitFoldState(), log);
    expect(replay, live);
    expect(foldFlitEvents(live, log), live);
    expect(texts(live).last, 'and');
  });

  test('events on another branch leave the chat alone', () {
    final s = foldFlitEvents(const FlitFoldState(), <FlitEvent>[
      ...root,
      ...retry,
      const FlitBranchSwitched(seq: 20, newBranchId: ''),
      // Shouldn't happen (turns run on the active branch), but stays put.
      ...message(21, 'x', 'stray', branch: 'b1'),
    ]);
    expect(texts(s), <String>['hi', 'hello', 'more', 'first answer']);
    expect(s.lastSeq, 23);
  });

  test('a compaction shows only on its branch', () {
    final compacted = <FlitEvent>[
      ...root,
      ...retry,
      const FlitCompactionDone(
        seq: 20,
        compactionId: 'c1',
        summary: 'Goal: b1',
        coveredSeq: 12,
        branchId: 'b1',
      ),
    ];
    final s = foldFlitEvents(const FlitFoldState(), compacted);
    expect(s.compactions.map((c) => c.summary), <String>['Goal: b1']);
    expect(s.summarized(0), isTrue);

    final root0 = foldFlitEvent(
      s,
      const FlitBranchSwitched(seq: 21, newBranchId: ''),
    );
    expect(root0.compactions, isEmpty);
    expect(root0.summarized(0), isFalse);

    final back = foldFlitEvent(
      root0,
      const FlitBranchSwitched(seq: 22, newBranchId: 'b1', branchId: 'b1'),
    );
    expect(back.compactions.map((c) => c.summary), <String>['Goal: b1']);
  });
}
