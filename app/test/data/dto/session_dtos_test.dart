// P1-02 acceptance: decode the §2/§3/§4/§5 example JSONs from
// docs/reference/03-mvp-wire-shapes.md and assert the mapped domain fields —
// especially the liveId vs durableId absorption (protocol §9) and the
// epoch-seconds → DateTime translation.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flit/data/dto/session_dtos.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/chat_message.dart';

Map<String, dynamic> _resultOf(String frame) {
  final decoded = jsonDecode(frame) as Map<String, dynamic>;
  return decoded['result'] as Map<String, dynamic>;
}

void main() {
  group('session.create result (§2)', () {
    // Verbatim §2 example values.
    const frame = '''
{
  "jsonrpc":"2.0","id":"r1",
  "result":{
    "session_id":"a1b2c3d4",
    "stored_session_id":"2026...-uuid",
    "session_key":"2026...-uuid",
    "info":{"model":"...","provider":"...","lazy":true}
  }
}''';

    test('maps liveId from session_id, durableId from stored_session_id', () {
      final result = SessionCreateResultDto.fromJson(
        _resultOf(frame),
      ).toDomain();

      expect(result.liveId, 'a1b2c3d4');
      expect(result.durableId, '2026...-uuid');
      expect(result.info, isNotNull);
      expect(result.info!['lazy'], true);
      expect(result.info!['model'], '...');
    });

    test('durableId falls back to session_key', () {
      final result = const SessionCreateResultDto(
        sessionId: 'a1b2c3d4',
        sessionKey: '2026...-uuid',
      ).toDomain();

      expect(result.durableId, '2026...-uuid');
    });
  });

  group('session.list result (§3)', () {
    // Verbatim §3 example values.
    const frame = '''
{
  "jsonrpc":"2.0","id":"r2",
  "result":{
    "sessions":[
      {"id":"2026..-uuid","title":"Fix the parser","preview":"last message…",
       "message_count":12,"started_at":1783200000,"source":"cli"}
    ]
  }
}''';

    test('maps durable id + epoch seconds → DateTime', () {
      final summaries = SessionListResultDto.fromJson(
        _resultOf(frame),
      ).toDomain();

      expect(summaries, hasLength(1));
      final s = summaries.single;
      expect(s.durableId, '2026..-uuid');
      expect(s.title, 'Fix the parser');
      expect(s.preview, 'last message…');
      expect(s.messageCount, 12);
      expect(
        s.startedAt,
        DateTime.fromMillisecondsSinceEpoch(1783200000 * 1000, isUtc: true),
      );
      expect(s.startedAt!.isUtc, isTrue);
      expect(s.source, 'cli');
    });

    test('tolerates missing optional fields', () {
      final summaries = SessionListResultDto.fromJson(const {
        'sessions': [
          {'id': 'x'},
        ],
      }).toDomain();

      final s = summaries.single;
      expect(s.durableId, 'x');
      expect(s.title, '');
      expect(s.preview, '');
      expect(s.messageCount, 0);
      expect(s.startedAt, isNull);
      expect(s.source, isNull);
    });
  });

  group('session.active_list result (§4)', () {
    // Verbatim §4 example values.
    const frame = '''
{
  "jsonrpc":"2.0","id":"r3",
  "result":{"sessions":[
    {"id":"a1b2c3d4","status":"working","current":true,"model":"...",
     "title":"…","preview":"…","last_active":1783200500,"message_count":12}
  ]}
}''';

    test('maps short live id, status, current flag, epoch seconds', () {
      final sessions = ActiveSessionListResultDto.fromJson(
        _resultOf(frame),
      ).toDomain();

      expect(sessions, hasLength(1));
      final s = sessions.single;
      expect(s.liveId, 'a1b2c3d4');
      expect(s.status, SessionStatus.working);
      expect(s.isCurrent, isTrue);
      expect(s.model, '...');
      expect(s.title, '…');
      expect(s.preview, '…');
      expect(
        s.lastActive,
        DateTime.fromMillisecondsSinceEpoch(1783200500 * 1000, isUtc: true),
      );
      expect(s.messageCount, 12);
    });

    test('unknown status string → working (open question #4)', () {
      final sessions = ActiveSessionListResultDto.fromJson(const {
        'sessions': [
          {'id': 'a1b2c3d4', 'status': 'quantum-entangled'},
        ],
      }).toDomain();

      expect(sessions.single.status, SessionStatus.working);
      expect(sessions.single.isCurrent, isFalse);
    });
  });

  group('session.resume result (§5)', () {
    // Verbatim §5 example values.
    const frame = '''
{
  "jsonrpc":"2.0","id":"r4",
  "result":{
    "session_id":"e5f6a7b8",
    "resumed":"2026..-uuid",
    "session_key":"2026..-uuid",
    "messages":[ {"role":"user","text":"…"}, {"role":"assistant","text":"…"} ],
    "message_count":12,
    "running":false,
    "status":"idle",
    "info":{}
  }
}''';

    test('maps NEW liveId, durableId, replayed messages, status', () {
      final result = SessionResumeResultDto.fromJson(
        _resultOf(frame),
      ).toDomain();

      expect(result.liveId, 'e5f6a7b8');
      expect(result.durableId, '2026..-uuid');
      expect(result.messages, hasLength(2));
      expect(result.messages[0].role, MessageRole.user);
      expect(result.messages[0].text, '…');
      expect(result.messages[1].role, MessageRole.assistant);
      expect(result.messages[1].text, '…');
      expect(result.messageCount, 12);
      expect(result.running, isFalse);
      expect(result.status, SessionStatus.idle);
      expect(result.info, isNotNull);
    });

    test('durableId falls back to resumed', () {
      final result = const SessionResumeResultDto(
        sessionId: 'e5f6a7b8',
        resumed: '2026..-uuid',
      ).toDomain();

      expect(result.durableId, '2026..-uuid');
      expect(result.messageCount, 0);
      expect(result.messages, isEmpty);
    });

    test('messageCount defaults to messages length when absent', () {
      final result = SessionResumeResultDto.fromJson(const {
        'session_id': 'e5f6a7b8',
        'session_key': '2026..-uuid',
        'messages': [
          {'role': 'user', 'text': 'hi'},
        ],
      }).toDomain();

      expect(result.messageCount, 1);
    });

    test('maps inflight when present (P2-02)', () {
      final result = SessionResumeResultDto.fromJson(const {
        'session_id': 'e5f6a7b8',
        'session_key': '2026..-uuid',
        'inflight': {
          'user': 'hi',
          'assistant': 'partial response...',
          'streaming': true,
        },
      }).toDomain();

      expect(result.inflight, isNotNull);
      expect(result.inflight!.user, 'hi');
      expect(result.inflight!.assistant, 'partial response...');
      expect(result.inflight!.streaming, isTrue);
    });

    test('treats null inflight as no inflight turn (P2-02)', () {
      final result = SessionResumeResultDto.fromJson(const {
        'session_id': 'e5f6a7b8',
        'session_key': '2026..-uuid',
        'inflight': null,
      }).toDomain();

      expect(result.inflight, isNull);
    });

    test('treats missing inflight as no inflight turn (P2-02)', () {
      final result = SessionResumeResultDto.fromJson(const {
        'session_id': 'e5f6a7b8',
        'session_key': '2026..-uuid',
      }).toDomain();

      expect(result.inflight, isNull);
    });
  });
}
