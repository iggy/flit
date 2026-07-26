// P5-02 acceptance: BackgroundRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from wire protocol and the
// DTO→domain mapping + event stream filtering.

import 'dart:async';

import 'package:flit/data/repositories/background_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` and `events` — the surfaces the repository uses. Records every
/// call and emits controllable events.
final class FakeGatewayRpcClient extends GatewayRpcClient {
  FakeGatewayRpcClient({
    this.handler,
    StreamController<GatewayEvent>? eventsController,
  }) : _eventsController = eventsController ?? StreamController<GatewayEvent>();

  final Map<String, dynamic> Function(
    String method,
    Map<String, dynamic> params,
  )?
  handler;

  final StreamController<GatewayEvent> _eventsController;

  /// Every (method, params) call, in order.
  final List<({String method, Map<String, dynamic> params})> calls =
      <({String method, Map<String, dynamic> params})>[];

  @override
  Stream<GatewayEvent> get events => _eventsController.stream;

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
  group('BackgroundRepositoryImpl.submit (wire prompt.background)', () {
    test('sends prompt.background with session_id and text', () async {
      final client = FakeGatewayRpcClient(
        handler: (_, _) => const <String, dynamic>{'task_id': 'bg_abc123'},
      );
      final repository = BackgroundRepositoryImpl(client);

      final taskId = await repository.submit('sess_1', 'write a poem');

      expect(client.calls.single.method, 'prompt.background');
      expect(client.calls.single.params, <String, dynamic>{
        'session_id': 'sess_1',
        'text': 'write a poem',
      });
      expect(taskId, 'bg_abc123');
    });

    test('absent task_id yields empty string', () async {
      final repository = BackgroundRepositoryImpl(FakeGatewayRpcClient());

      final taskId = await repository.submit('sess_1', 'test');

      expect(taskId, '');
    });
  });

  group('BackgroundRepositoryImpl.completions (wire background.complete)', () {
    test('yields completion for matching session_id', () async {
      final eventsController = StreamController<GatewayEvent>();
      final client = FakeGatewayRpcClient(eventsController: eventsController);
      final repository = BackgroundRepositoryImpl(client);

      final stream = repository.completions('sess_1');
      final future = stream.first;

      eventsController.add(
        const GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess_1',
          payload: <String, dynamic>{
            'task_id': 'bg_1',
            'text': 'task completed',
          },
        ),
      );

      final completion = await future;
      expect(completion.taskId, 'bg_1');
      expect(completion.text, 'task completed');
    });

    test('filters OUT events for different session_id', () async {
      final eventsController = StreamController<GatewayEvent>();
      final client = FakeGatewayRpcClient(eventsController: eventsController);
      final repository = BackgroundRepositoryImpl(client);

      final stream = repository.completions('sess_1');
      final received = <String>[];
      stream.listen((completion) {
        received.add(completion.taskId);
      });

      // Wrong session_id: should be filtered OUT.
      eventsController.add(
        const GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess_2',
          payload: <String, dynamic>{'task_id': 'bg_wrong', 'text': 'ignore'},
        ),
      );

      // Correct session_id: should come through.
      eventsController.add(
        const GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess_1',
          payload: <String, dynamic>{'task_id': 'bg_right', 'text': 'correct'},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, <String>['bg_right']);
    });

    test('filters OUT non-background events', () async {
      final eventsController = StreamController<GatewayEvent>();
      final client = FakeGatewayRpcClient(eventsController: eventsController);
      final repository = BackgroundRepositoryImpl(client);

      final stream = repository.completions('sess_1');
      final received = <String>[];
      stream.listen((completion) {
        received.add(completion.taskId);
      });

      // Non-background event: should be filtered OUT.
      eventsController.add(
        const GatewayEvent(
          type: 'message.delta',
          sessionId: 'sess_1',
          payload: <String, dynamic>{'text': 'delta'},
        ),
      );

      // Background event: should come through.
      eventsController.add(
        const GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess_1',
          payload: <String, dynamic>{'task_id': 'bg_2', 'text': 'done'},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, <String>['bg_2']);
    });

    test('parses defensively: missing fields become empty strings', () async {
      final eventsController = StreamController<GatewayEvent>();
      final client = FakeGatewayRpcClient(eventsController: eventsController);
      final repository = BackgroundRepositoryImpl(client);

      final stream = repository.completions('sess_1');
      final future = stream.first;

      eventsController.add(
        const GatewayEvent(
          type: 'background.complete',
          sessionId: 'sess_1',
          payload: <String, dynamic>{},
        ),
      );

      final completion = await future;
      expect(completion.taskId, '');
      expect(completion.text, '');
    });
  });
}
