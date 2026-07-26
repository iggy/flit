// P7-05 acceptance: VoiceRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping.

import 'package:flit/data/repositories/voice_repository_impl.dart';
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
  group('VoiceRepositoryImpl.toggle (wire voice.toggle)', () {
    test('sends voice.toggle with action param', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'enabled': true,
          'record_key': 'Ctrl+B',
          'tts': false,
        },
      );
      final repository = VoiceRepositoryImpl(client);

      final result = await repository.toggle('on');

      expect(client.calls.single.method, 'voice.toggle');
      expect(client.calls.single.params, <String, dynamic>{'action': 'on'});
      expect(result.enabled, true);
      expect(result.recordKey, 'Ctrl+B');
      expect(result.tts, false);
    });

    test('action="status" returns all fields including availability', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'enabled': true,
          'record_key': 'Ctrl+Shift+B',
          'tts': true,
          'available': true,
          'audio_available': true,
          'stt_available': true,
          'details': 'All systems operational',
        },
      );
      final repository = VoiceRepositoryImpl(client);

      final result = await repository.toggle('status');

      expect(client.calls.single.params, <String, dynamic>{'action': 'status'});
      expect(result.enabled, true);
      expect(result.recordKey, 'Ctrl+Shift+B');
      expect(result.tts, true);
      expect(result.available, true);
      expect(result.audioAvailable, true);
      expect(result.sttAvailable, true);
      expect(result.details, 'All systems operational');
    });

    test('action="on|off|tts" omits availability fields', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{
          'enabled': false,
          'record_key': 'Ctrl+B',
          'tts': false,
        },
      );
      final repository = VoiceRepositoryImpl(client);

      final result = await repository.toggle('off');

      expect(result.enabled, false);
      expect(result.tts, false);
      expect(result.available, isNull);
      expect(result.audioAvailable, isNull);
      expect(result.sttAvailable, isNull);
      expect(result.details, isNull);
    });

    test('absent fields fall back to safe defaults', () async {
      final repository = VoiceRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.toggle('status');

      expect(result.enabled, false);
      expect(result.recordKey, '');
      expect(result.tts, false);
      expect(result.available, isNull);
    });
  });

  group('VoiceRepositoryImpl.record (wire voice.record)', () {
    test(
      'sends voice.record with action and session_id when provided',
      () async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => const <String, dynamic>{'status': 'recording'},
        );
        final repository = VoiceRepositoryImpl(client);

        final result = await repository.record('start', sessionId: 'sess_abc');

        expect(client.calls.single.method, 'voice.record');
        expect(client.calls.single.params, <String, dynamic>{
          'action': 'start',
          'session_id': 'sess_abc',
        });
        expect(result.status, 'recording');
      },
    );

    test('omits session_id when null', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'stopped'},
      );
      final repository = VoiceRepositoryImpl(client);

      await repository.record('stop');

      expect(client.calls.single.params, <String, dynamic>{'action': 'stop'});
    });

    test('parses status: recording|stopped|busy', () async {
      Future<void> expectStatus(String wireStatus) async {
        final client = FakeGatewayRpcClient(
          handler: (_, _) => <String, dynamic>{'status': wireStatus},
        );
        final repository = VoiceRepositoryImpl(client);

        final result = await repository.record('start');

        expect(result.status, wireStatus);
      }

      await expectStatus('recording');
      await expectStatus('stopped');
      await expectStatus('busy');
    });

    test('absent status field falls back to empty string', () async {
      final repository = VoiceRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.record('start');

      expect(result.status, '');
    });
  });

  group('VoiceRepositoryImpl.tts (wire voice.tts)', () {
    test('sends voice.tts with text param', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'status': 'speaking'},
      );
      final repository = VoiceRepositoryImpl(client);

      final result = await repository.tts('Hello world');

      expect(client.calls.single.method, 'voice.tts');
      expect(client.calls.single.params, <String, dynamic>{
        'text': 'Hello world',
      });
      expect(result.status, 'speaking');
    });

    test('absent status field falls back to empty string', () async {
      final repository = VoiceRepositoryImpl(FakeGatewayRpcClient());

      final result = await repository.tts('Test');

      expect(result.status, '');
    });
  });
}
