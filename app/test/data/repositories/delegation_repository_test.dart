// P3-05 acceptance: DelegationRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names from docs/reference/08-agent-transparency-wire-shapes.md
// and the DTO→domain mapping.

import 'package:flit/data/repositories/delegation_repository.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call
/// and answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  /// Every (method, params) call, in order.
  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const <String, dynamic>{},
  ]) async {
    calls.add((method: method, params: params));
    final answer = handler;
    return answer == null ? const <String, dynamic>{} : answer(method, params);
  }
}

void main() {
  group('DelegationRepositoryImpl.status (wire §delegation.status)', () {
    test(
      'sends delegation.status and parses active subagents + limits',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'active': <Map<String, dynamic>>[
              <String, dynamic>{
                'subagent_id': 'abc123',
                'parent_id': null,
                'depth': 0,
                'goal': 'Write a test',
                'model': 'sonnet',
                'started_at': 1690000000.0,
                'status': 'running',
                'tool_count': 3,
                'last_tool': 'Read',
              },
              <String, dynamic>{
                'subagent_id': 'def456',
                'parent_id': 'abc123',
                'depth': 1,
                'goal': 'Execute subtask',
                'started_at': 1690000010.5,
                'status': 'thinking',
                'tool_count': 1,
              },
            ],
            'paused': false,
            'max_spawn_depth': 3,
            'max_concurrent_children': 4,
          },
        );
        final repository = DelegationRepositoryImpl(client);

        final status = await repository.status();

        expect(client.calls.single.method, 'delegation.status');
        expect(client.calls.single.params, isEmpty);
        expect(status.active.length, 2);
        expect(status.active[0].id, 'abc123');
        expect(status.active[0].parentId, null);
        expect(status.active[0].depth, 0);
        expect(status.active[0].goal, 'Write a test');
        expect(status.active[0].model, 'sonnet');
        expect(status.active[0].startedAt, 1690000000.0);
        expect(status.active[0].status, 'running');
        expect(status.active[0].toolCount, 3);
        expect(status.active[0].lastTool, 'Read');
        expect(status.active[1].id, 'def456');
        expect(status.active[1].parentId, 'abc123');
        expect(status.active[1].lastTool, null);
        expect(status.paused, false);
        expect(status.maxSpawnDepth, 3);
        expect(status.maxConcurrentChildren, 4);
      },
    );

    test('absent fields fall back to safe defaults', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      final status = await repository.status();

      expect(status.active, isEmpty);
      expect(status.paused, false);
      expect(status.maxSpawnDepth, 0);
      expect(status.maxConcurrentChildren, 0);
    });
  });

  group('DelegationRepositoryImpl.setPaused (wire §delegation.pause)', () {
    test(
      'sends delegation.pause with paused=true and returns new state',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{'paused': true},
        );
        final repository = DelegationRepositoryImpl(client);

        final paused = await repository.setPaused(true);

        expect(client.calls.single.method, 'delegation.pause');
        expect(client.calls.single.params, <String, dynamic>{'paused': true});
        expect(paused, true);
      },
    );

    test('sends delegation.pause with paused=false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'paused': false},
      );
      final repository = DelegationRepositoryImpl(client);

      final paused = await repository.setPaused(false);

      expect(client.calls.single.params, <String, dynamic>{'paused': false});
      expect(paused, false);
    });

    test('absent result paused field falls back to requested value', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.setPaused(true), true);
      expect(await repository.setPaused(false), false);
    });
  });

  group('DelegationRepositoryImpl.interrupt (wire §subagent.interrupt)', () {
    test(
      'sends subagent.interrupt with subagent_id and returns found',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'found': true,
            'subagent_id': 'abc123',
          },
        );
        final repository = DelegationRepositoryImpl(client);

        final found = await repository.interrupt('abc123');

        expect(client.calls.single.method, 'subagent.interrupt');
        expect(client.calls.single.params, <String, dynamic>{
          'subagent_id': 'abc123',
        });
        expect(found, true);
      },
    );

    test('not found returns false', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'found': false},
      );
      final repository = DelegationRepositoryImpl(client);

      expect(await repository.interrupt('unknown'), false);
    });

    test('absent found field falls back to false', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.interrupt('xyz'), false);
    });
  });

  group('DelegationRepositoryImpl.agents (wire §agents.list)', () {
    test('sends agents.list and parses processes', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'processes': <Map<String, dynamic>>[
            <String, dynamic>{
              'session_id': 'sess_abc',
              'command': '/new write a test',
              'status': 'running',
              'uptime': 123.45,
            },
            <String, dynamic>{
              'session_id': 'sess_def',
              'command': '/help',
              'status': 'completed',
              'uptime': 5.0,
            },
          ],
        },
      );
      final repository = DelegationRepositoryImpl(client);

      final processes = await repository.agents();

      expect(client.calls.single.method, 'agents.list');
      expect(client.calls.single.params, isEmpty);
      expect(processes.length, 2);
      expect(processes[0].sessionId, 'sess_abc');
      expect(processes[0].command, '/new write a test');
      expect(processes[0].status, 'running');
      expect(processes[0].uptime, 123.45);
      expect(processes[1].sessionId, 'sess_def');
    });

    test('absent processes key yields an empty list', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.agents(), isEmpty);
    });
  });

  group('DelegationRepositoryImpl.listSnapshots (wire §spawn_tree.list)', () {
    test(
      'sends spawn_tree.list with session_id, limit, cross_session and parses entries',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'entries': <Map<String, dynamic>>[
              <String, dynamic>{
                'path': '/snapshots/snap1.json',
                'session_id': 'sess_abc',
                'finished_at': 1690000000.0,
                'started_at': 1689999900.0,
                'label': 'Snapshot 1',
                'count': 3,
              },
              <String, dynamic>{
                'path': '/snapshots/snap2.json',
                'session_id': 'sess_abc',
                'finished_at': 1690000100.0,
                'label': 'Snapshot 2',
                'count': 5,
              },
            ],
          },
        );
        final repository = DelegationRepositoryImpl(client);

        final entries = await repository.listSnapshots(
          'sess_abc',
          limit: 10,
          crossSession: true,
        );

        expect(client.calls.single.method, 'spawn_tree.list');
        expect(client.calls.single.params, <String, dynamic>{
          'session_id': 'sess_abc',
          'limit': 10,
          'cross_session': true,
        });
        expect(entries.length, 2);
        expect(entries[0].path, '/snapshots/snap1.json');
        expect(entries[0].sessionId, 'sess_abc');
        expect(entries[0].finishedAt, 1690000000.0);
        expect(entries[0].startedAt, 1689999900.0);
        expect(entries[0].label, 'Snapshot 1');
        expect(entries[0].count, 3);
        expect(entries[1].path, '/snapshots/snap2.json');
        expect(entries[1].startedAt, null);
        expect(entries[1].count, 5);
      },
    );

    test('defaults limit and cross_session when not provided', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'entries': <Map<String, dynamic>>[],
        },
      );
      final repository = DelegationRepositoryImpl(client);

      await repository.listSnapshots('sess_xyz');

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_xyz',
        'limit': 50,
        'cross_session': false,
      });
    });

    test('absent entries key yields an empty list', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      expect(await repository.listSnapshots('sess_any'), isEmpty);
    });
  });

  group('DelegationRepositoryImpl.loadSnapshot (wire §spawn_tree.load)', () {
    test(
      'sends spawn_tree.load with path and parses the snapshot including opaque subagents',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => <String, dynamic>{
            'session_id': 'sess_abc',
            'started_at': 1689999900.0,
            'finished_at': 1690000000.0,
            'label': 'Test snapshot',
            'subagents': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'sub1', 'goal': 'task 1'},
              <String, dynamic>{'id': 'sub2', 'goal': 'task 2'},
            ],
          },
        );
        final repository = DelegationRepositoryImpl(client);

        final snapshot = await repository.loadSnapshot('/snapshots/test.json');

        expect(client.calls.single.method, 'spawn_tree.load');
        expect(client.calls.single.params, <String, dynamic>{
          'path': '/snapshots/test.json',
        });
        expect(snapshot.sessionId, 'sess_abc');
        expect(snapshot.startedAt, 1689999900.0);
        expect(snapshot.finishedAt, 1690000000.0);
        expect(snapshot.label, 'Test snapshot');
        expect(snapshot.subagents.length, 2);
      },
    );

    test('parses snapshot with null started_at', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'session_id': 'sess_def',
          'finished_at': 1690000000.0,
          'label': 'No start time',
          'subagents': <Map<String, dynamic>>[],
        },
      );
      final repository = DelegationRepositoryImpl(client);

      final snapshot = await repository.loadSnapshot('/path/to/snap');

      expect(snapshot.startedAt, null);
      expect(snapshot.subagents, isEmpty);
    });
  });

  group('DelegationRepositoryImpl.saveSnapshot (wire §spawn_tree.save)', () {
    test(
      'sends spawn_tree.save with all params including started_at and returns path',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'path': '/snapshots/saved.json',
            'session_id': 'sess_abc',
          },
        );
        final repository = DelegationRepositoryImpl(client);

        final path = await repository.saveSnapshot(
          sessionId: 'sess_abc',
          subagents: <Map<String, dynamic>>[
            <String, dynamic>{'id': 'sub1', 'goal': 'test task'},
          ],
          startedAt: 1689999900.0,
          finishedAt: 1690000000.0,
          label: 'My snapshot',
        );

        expect(client.calls.single.method, 'spawn_tree.save');
        expect(client.calls.single.params, <String, dynamic>{
          'session_id': 'sess_abc',
          'subagents': <Map<String, dynamic>>[
            <String, dynamic>{'id': 'sub1', 'goal': 'test task'},
          ],
          'started_at': 1689999900.0,
          'finished_at': 1690000000.0,
          'label': 'My snapshot',
        });
        expect(path, '/snapshots/saved.json');
      },
    );

    test('omits started_at when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'path': '/snap.json'},
      );
      final repository = DelegationRepositoryImpl(client);

      await repository.saveSnapshot(
        sessionId: 'sess_xyz',
        subagents: <Map<String, dynamic>>[
          <String, dynamic>{'id': 'x'},
        ],
        startedAt: null,
        finishedAt: 1690000000.0,
        label: 'No start',
      );

      expect(client.calls.single.params.containsKey('started_at'), false);
      expect(client.calls.single.params['session_id'], 'sess_xyz');
      expect(client.calls.single.params['finished_at'], 1690000000.0);
      expect(client.calls.single.params['label'], 'No start');
    });

    test('absent path field falls back to empty string', () async {
      final repository = DelegationRepositoryImpl(FakeGatewayRpcClient());

      final path = await repository.saveSnapshot(
        sessionId: 's',
        subagents: <Map<String, dynamic>>[<String, dynamic>{}],
        finishedAt: 0.0,
        label: 'test',
      );

      expect(path, '');
    });
  });
}
