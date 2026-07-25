// P1-04 acceptance: SessionRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from
// docs/reference/03-mvp-wire-shapes.md §2–§5, §12 and the DTO→domain result
// mapping (esp. the two session ids, protocol §9).

import 'package:flit/data/repositories/session_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call
/// and answers from [handler].
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({this.handler});

  /// Answers a request; defaults to an empty result map.
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
  late FakeGatewayRpcClient client;
  late SessionRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = SessionRepositoryImpl(client);
  });

  group('create (wire §2)', () {
    test('sends session.create with EMPTY params when no optionals', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'session_id': 'a1b2c3d4',
          'stored_session_id': '2026-uuid',
          'session_key': '2026-uuid',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.create();

      expect(client.calls.single.method, 'session.create');
      expect(client.calls.single.params, isEmpty);
      // Two ids mapped (protocol §9): live + durable.
      expect(result.liveId, 'a1b2c3d4');
      expect(result.durableId, '2026-uuid');
    });

    test('sends only the non-null optionals', () async {
      await repository.create(profile: 'research', model: 'hermes-4-70b');

      expect(client.calls.single.method, 'session.create');
      expect(client.calls.single.params, <String, dynamic>{
        'profile': 'research',
        'model': 'hermes-4-70b',
      });
    });

    test(
      'durableId falls back to session_key without stored_session_id',
      () async {
        client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'session_id': 'a1b2c3d4',
            'session_key': 'key-only-uuid',
          },
        );
        repository = SessionRepositoryImpl(client);

        final result = await repository.create();

        expect(result.liveId, 'a1b2c3d4');
        expect(result.durableId, 'key-only-uuid');
      },
    );
  });

  group('list (wire §3)', () {
    test('sends session.list and maps durable summaries', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'sessions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '2026-uuid',
              'title': 'Fix the parser',
              'preview': 'last message…',
              'message_count': 12,
              'started_at': 1783200000,
              'source': 'cli',
            },
          ],
        },
      );
      repository = SessionRepositoryImpl(client);

      final sessions = await repository.list();

      expect(client.calls.single.method, 'session.list');
      expect(client.calls.single.params, isEmpty);
      expect(sessions, hasLength(1));
      expect(sessions.single.durableId, '2026-uuid');
      expect(sessions.single.title, 'Fix the parser');
      expect(sessions.single.messageCount, 12);
      expect(sessions.single.source, 'cli');
      expect(
        sessions.single.startedAt,
        DateTime.fromMillisecondsSinceEpoch(1783200000 * 1000, isUtc: true),
      );
    });
  });

  group('activeList (wire §4)', () {
    test('OMITS current_session_id when null', () async {
      await repository.activeList();

      expect(client.calls.single.method, 'session.active_list');
      expect(client.calls.single.params, isEmpty);
    });

    test('sends current_session_id when non-null; parses status', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'sessions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a1b2c3d4',
              'status': 'working',
              'current': true,
              'model': 'hermes-4-405b',
              'title': 'Fix the parser',
            },
            <String, dynamic>{'id': 'e5f6a7b8', 'status': 'idle'},
            // Unknown status strings parse tolerantly → working.
            <String, dynamic>{'id': 'ffffffff', 'status': 'mystery'},
          ],
        },
      );
      repository = SessionRepositoryImpl(client);

      final sessions = await repository.activeList(currentLiveId: 'a1b2c3d4');

      expect(client.calls.single.method, 'session.active_list');
      expect(client.calls.single.params, <String, dynamic>{
        'current_session_id': 'a1b2c3d4',
      });
      expect(sessions, hasLength(3));
      expect(sessions[0].liveId, 'a1b2c3d4');
      expect(sessions[0].status, SessionStatus.working);
      expect(sessions[0].isCurrent, isTrue);
      expect(sessions[0].model, 'hermes-4-405b');
      expect(sessions[1].status, SessionStatus.idle);
      expect(sessions[2].status, SessionStatus.working);
    });
  });

  group('resume (wire §5)', () {
    test(
      'sends the DURABLE id; maps new live id + messages + status',
      () async {
        client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{
            'session_id': 'e5f6a7b8',
            'resumed': '2026-uuid',
            'session_key': '2026-uuid',
            'messages': <Map<String, dynamic>>[
              <String, dynamic>{'role': 'user', 'text': 'hi'},
              <String, dynamic>{'role': 'assistant', 'text': 'hello'},
            ],
            'message_count': 12,
            'running': false,
            'status': 'idle',
          },
        );
        repository = SessionRepositoryImpl(client);

        final result = await repository.resume('2026-uuid');

        expect(client.calls.single.method, 'session.resume');
        // The DURABLE id goes in as session_id (protocol §9).
        expect(client.calls.single.params, <String, dynamic>{
          'session_id': '2026-uuid',
        });
        // A NEW short live id comes back; the durable id is echoed.
        expect(result.liveId, 'e5f6a7b8');
        expect(result.durableId, '2026-uuid');
        expect(result.messageCount, 12);
        expect(result.running, isFalse);
        expect(result.status, SessionStatus.idle);
        expect(result.messages, <ChatMessage>[
          const ChatMessage(role: MessageRole.user, text: 'hi'),
          const ChatMessage(role: MessageRole.assistant, text: 'hello'),
        ]);
      },
    );

    test('durableId falls back to resumed without session_key', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'session_id': 'e5f6a7b8',
          'resumed': '2026-uuid',
          'status': 'working',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.resume('2026-uuid');

      expect(result.liveId, 'e5f6a7b8');
      expect(result.durableId, '2026-uuid');
      expect(result.status, SessionStatus.working);
      expect(result.messages, isEmpty);
    });
  });

  group('interrupt (wire §12)', () {
    test('sends the LIVE id; succeeds on {status: interrupted}', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'interrupted'},
      );
      repository = SessionRepositoryImpl(client);

      await repository.interrupt('a1b2c3d4');

      expect(client.calls.single.method, 'session.interrupt');
      // The LIVE id — NOT the durable id (protocol §9).
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
    });
  });

  group('mostRecent (Phase 2, §session.most_recent)', () {
    test('sends session.most_recent with NO session id; maps found', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'session_id': '2026-uuid',
          'title': 'Fix the parser',
          'started_at': 1783200000,
          'source': 'cli',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.mostRecent();

      expect(client.calls.single.method, 'session.most_recent');
      expect(client.calls.single.params, isEmpty);
      expect(result, isNotNull);
      expect(result!.durableId, '2026-uuid');
      expect(result.title, 'Fix the parser');
      expect(result.source, 'cli');
      expect(
        result.startedAt,
        DateTime.fromMillisecondsSinceEpoch(1783200000 * 1000, isUtc: true),
      );
    });

    test('sends profile when provided', () async {
      await repository.mostRecent(profile: 'research');

      expect(client.calls.single.method, 'session.most_recent');
      expect(client.calls.single.params, <String, dynamic>{
        'profile': 'research',
      });
    });

    test('returns null when session_id is null (not found)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'session_id': null},
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.mostRecent();

      expect(result, isNull);
    });
  });

  group('setTitle (Phase 2, §session.title SET)', () {
    test('sends LIVE id + title; returns resulting title', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'title': 'New name',
          'pending': false,
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.setTitle('a1b2c3d4', 'New name');

      expect(client.calls.single.method, 'session.title');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'title': 'New name',
      });
      expect(result, 'New name');
    });

    test('falls back to passed title when result missing', () async {
      final result = await repository.setTitle('a1b2c3d4', 'Fallback');

      expect(result, 'Fallback');
    });
  });

  group('delete (Phase 2, §session.delete)', () {
    test('sends DURABLE id to session.delete', () async {
      await repository.delete('2026-uuid');

      expect(client.calls.single.method, 'session.delete');
      // DURABLE id — NOT the live id (protocol §9).
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': '2026-uuid',
      });
    });

    test('sends profile when provided', () async {
      await repository.delete('2026-uuid', profile: 'research');

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': '2026-uuid',
        'profile': 'research',
      });
    });
  });

  group('usage (Phase 2, §session.usage)', () {
    test('sends LIVE id; maps usage stats with conditional fields', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'model': 'hermes-4-405b',
          'input': 1200,
          'output': 420,
          'total': 1620,
          'calls': 3,
          'reasoning': 0,
          'context_used': 48000,
          'context_max': 128000,
          'context_percent': 38,
          'compressions': 0,
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.usage('a1b2c3d4');

      expect(client.calls.single.method, 'session.usage');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      expect(result.model, 'hermes-4-405b');
      expect(result.input, 1200);
      expect(result.output, 420);
      expect(result.total, 1620);
      expect(result.calls, 3);
      expect(result.reasoning, 0);
      expect(result.contextUsed, 48000);
      expect(result.contextMax, 128000);
      expect(result.contextPercent, 38);
      expect(result.compressions, 0);
    });

    test('maps usage without conditional context fields', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'model': 'hermes-4-70b',
          'input': 100,
          'output': 50,
          'total': 150,
          'calls': 1,
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.usage('a1b2c3d4');

      expect(result.model, 'hermes-4-70b');
      expect(result.calls, 1);
      expect(result.contextUsed, isNull);
      expect(result.contextMax, isNull);
      expect(result.contextPercent, isNull);
      expect(result.compressions, isNull);
    });
  });

  group('contextBreakdown (Phase 2, §session.context_breakdown)', () {
    test('sends LIVE id; maps breakdown with categories', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'categories': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'system_prompt',
              'label': 'System prompt',
              'tokens': 2400,
              'color': 'var(--context-usage-system)',
            },
            <String, dynamic>{
              'id': 'conversation',
              'label': 'Conversation',
              'tokens': 45600,
              'color': 'var(--context-usage-conversation)',
            },
          ],
          'context_max': 128000,
          'context_percent': 38,
          'context_used': 48000,
          'estimated_total': 48000,
          'model': 'hermes-4-405b',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.contextBreakdown('a1b2c3d4');

      expect(client.calls.single.method, 'session.context_breakdown');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      expect(result.categories, hasLength(2));
      expect(result.categories[0].id, 'system_prompt');
      expect(result.categories[0].tokens, 2400);
      expect(result.categories[1].id, 'conversation');
      expect(result.categories[1].tokens, 45600);
      expect(result.contextMax, 128000);
      expect(result.contextPercent, 38);
      expect(result.contextUsed, 48000);
      expect(result.estimatedTotal, 48000);
      expect(result.model, 'hermes-4-405b');
    });
  });

  group('compress (Phase 2, §session.compress)', () {
    test('sends LIVE id; maps local-success result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'compressed',
          'removed': 8,
          'before_messages': 24,
          'after_messages': 16,
          'before_tokens': 90000,
          'after_tokens': 42000,
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.compress('a1b2c3d4');

      expect(client.calls.single.method, 'session.compress');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      expect(result.status, 'compressed');
      expect(result.removed, 8);
      expect(result.beforeMessages, 24);
      expect(result.afterMessages, 16);
      expect(result.beforeTokens, 90000);
      expect(result.afterTokens, 42000);
      expect(result.lockHeld, isFalse);
    });

    test('sends focus_topic when provided', () async {
      await repository.compress('a1b2c3d4', focusTopic: 'parser bugs');

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'focus_topic': 'parser bugs',
      });
    });

    test('maps lock-held variant', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'compressed': false,
          'lock_held': true,
          'message': 'session busy',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.compress('a1b2c3d4');

      expect(result.lockHeld, isTrue);
      expect(result.message, 'session busy');
    });
  });

  group('undo (Phase 2, §session.undo)', () {
    test('sends LIVE id; returns removed count', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'removed': 2},
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.undo('a1b2c3d4');

      expect(client.calls.single.method, 'session.undo');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      expect(result, 2);
    });

    test('returns 0 when removed absent', () async {
      final result = await repository.undo('a1b2c3d4');

      expect(result, 0);
    });
  });

  group('save (Phase 2, §session.save)', () {
    test('sends LIVE id; returns file path', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'file': '/home/iggy/hermes_conversation_1783200000.json',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.save('a1b2c3d4');

      expect(client.calls.single.method, 'session.save');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      expect(result, '/home/iggy/hermes_conversation_1783200000.json');
    });

    test('returns empty string when file absent', () async {
      final result = await repository.save('a1b2c3d4');

      expect(result, '');
    });
  });

  group('branch (Phase 2, §session.branch)', () {
    test('sends LIVE id (parent); maps NEW live id + parent durable', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'session_id': 'c9d0e1f2',
          'title': 'Fix the parser (branch)',
          'parent': '2026-uuid',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.branch('a1b2c3d4');

      expect(client.calls.single.method, 'session.branch');
      // LIVE id of the parent (protocol §9).
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
      });
      // Result has the NEW live id for the branch.
      expect(result.liveId, 'c9d0e1f2');
      expect(result.title, 'Fix the parser (branch)');
      expect(result.parentDurableId, '2026-uuid');
    });

    test('sends name when provided', () async {
      await repository.branch('a1b2c3d4', name: 'Custom branch');

      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'name': 'Custom branch',
      });
    });
  });

  group('setCwd (Phase 2, §session.cwd.set)', () {
    test('sends LIVE id + cwd', () async {
      await repository.setCwd('a1b2c3d4', '/home/iggy/project');

      expect(client.calls.single.method, 'session.cwd.set');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'cwd': '/home/iggy/project',
      });
    });
  });

  group('steer (P3-07, §session.steer)', () {
    test('sends LIVE id + text; maps status "queued" to SteerOutcome.queued', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'queued',
          'text': 'Focus on error handling',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.steer('a1b2c3d4', 'Focus on error handling');

      expect(client.calls.single.method, 'session.steer');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'a1b2c3d4',
        'text': 'Focus on error handling',
      });
      expect(result, SteerOutcome.queued);
    });

    test('maps status "rejected" to SteerOutcome.rejected', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'status': 'rejected',
          'text': 'Cannot steer now',
        },
      );
      repository = SessionRepositoryImpl(client);

      final result = await repository.steer('a1b2c3d4', 'Try this approach');

      expect(result, SteerOutcome.rejected);
    });
  });
}
