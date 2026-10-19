import 'package:fixnum/fixnum.dart';
import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/data/flit/flit_pairing.dart';
import 'package:flit/data/storage/connection_store.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

final class _MemoryStore implements KeyValueStore {
  final Map<String, String> data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  group('parsePairingUri', () {
    test('reads what flit pair puts in the QR code', () {
      final info = parsePairingUri(
        'flit://pair?code=K7QM-4XPZ&server=https%3A%2F%2Fflit.example.com%3A8443',
      );
      expect(
        info,
        const PairingInfo(
          serverUrl: 'https://flit.example.com:8443',
          code: 'K7QM-4XPZ',
        ),
      );
      expect(info.toString(), isNot(contains('K7QM')));
    });

    test('rejects anything else', () {
      for (final raw in <String>[
        'https://example.com',
        'flit://pair?code=X',
        'flit://pair?server=https://x',
        'flit://other?server=https://x&code=Y',
        '',
      ]) {
        expect(parsePairingUri(raw), isNull, reason: raw);
      }
    });
  });

  group('ConnectionStore', () {
    test('round-trips a flit connection', () async {
      final store = ConnectionStore(_MemoryStore());
      final config = ConnectionConfig(
        baseUrl: 'https://flit.example.com/',
        token: 'flitd_secret',
        backend: BackendKind.flit,
        deviceName: 'phone',
      );
      await store.save(config);
      expect(await store.load(), config);
      expect(config.toString(), isNot(contains('flitd_secret')));
    });

    test('configs saved before flit support load as Hermes', () async {
      final kv = _MemoryStore()
        ..data[ConnectionStore.baseUrlKey] = 'http://127.0.0.1:9119'
        ..data[ConnectionStore.tokenKey] = 't';
      final loaded = await ConnectionStore(kv).load();
      expect(loaded?.backend, BackendKind.hermes);
      expect(loaded?.deviceName, isNull);
    });

    test('forget removes the flit keys too', () async {
      final kv = _MemoryStore();
      final store = ConnectionStore(kv);
      await store.save(
        ConnectionConfig(
          baseUrl: 'https://x',
          token: 'flitd_t',
          backend: BackendKind.flit,
          deviceName: 'd',
        ),
      );
      await store.forget();
      expect(kv.data, isEmpty);
    });
  });

  group('mappers', () {
    test('session', () {
      final s = sessionFromProto(
        pb.Session(
          id: 'ses_1',
          title: 't',
          workingDir: '/w',
          provider: 'local',
          model: 'm',
          state: pb.TaskState.TASK_STATE_WAITING,
          lastSeq: Int64(42),
        ),
      );
      expect(s.state, FlitTaskState.waiting);
      expect(s.lastSeq, 42);
      expect(s.createdAt, isNull);
    });

    test('model call events', () {
      FlitEvent map(pb.Event e) => eventFromProto(e..seq = Int64(3));
      final started = map(
        pb.Event(
          modelCallStarted: pb.ModelCallStarted(messageId: 'm', attempt: 2),
        ),
      );
      expect(started, isA<FlitModelCallStarted>());
      expect((started as FlitModelCallStarted).attempt, 2);
      final progress = map(
        pb.Event(
          promptProgress: pb.PromptProgress(
            messageId: 'm',
            processed: Int64(10),
            total: Int64(40),
            cached: Int64(5),
          ),
        ),
      );
      expect(progress, isA<FlitPromptProgress>());
      expect((progress as FlitPromptProgress).total, 40);
      expect(progress.cached, 5);
      final ended = map(
        pb.Event(
          modelCallEnded: pb.ModelCallEnded(
            messageId: 'm',
            attempt: 1,
            outcome: pb.ModelCallOutcome.MODEL_CALL_OUTCOME_STALLED,
            phase: 'streaming',
            willRetry: true,
          ),
        ),
      );
      expect(ended, isA<FlitModelCallEnded>());
      expect((ended as FlitModelCallEnded).outcome, FlitCallOutcome.stalled);
      expect(ended.phase, 'streaming');
      expect(ended.willRetry, isTrue);
    });

    test('events', () {
      FlitEvent map(pb.Event e) => eventFromProto(e..seq = Int64(7));
      final resolved = map(
        pb.Event(
          promptResolved: pb.PromptResolved(
            promptId: 'p',
            decision: pb.PromptDecision.PROMPT_DECISION_ALLOW,
            client: 'laptop',
          ),
        ),
      );
      expect(resolved, isA<FlitPromptResolved>());
      expect((resolved as FlitPromptResolved).allowed, isTrue);
      expect(resolved.client, 'laptop');
      expect(resolved.seq, 7);

      final started = map(
        pb.Event(
          messageStarted: pb.MessageStarted(
            messageId: 'm',
            role: pb.Role.ROLE_USER,
          ),
        ),
      );
      expect((started as FlitMessageStarted).role, FlitRole.user);

      final err = map(
        pb.Event(error: pb.TurnError(message: 'x', turnCanContinue: true)),
      );
      expect((err as FlitTurnError).canContinue, isTrue);

      expect(map(pb.Event()), isA<FlitUnknownEvent>());
    });
  });
}
