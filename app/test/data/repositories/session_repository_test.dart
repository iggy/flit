// P1-04 acceptance: SessionRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from
// docs/reference/03-mvp-wire-shapes.md §2–§5, §12 and the DTO→domain result
// mapping (esp. the two session ids, protocol §9).

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/data/repositories/session_repository_impl.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/chat_message.dart';

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
}
