// P0-06 acceptance tests for GatewayRpcClient against a fake WS channel.
// Frame examples follow docs/reference/03-mvp-wire-shapes.md §1/§7.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes/core/errors/gateway_error.dart';
import 'package:hermes/data/transport/gateway_rpc_client.dart';
import 'package:stream_channel/stream_channel.dart';

/// A fake server end of the WS transport. The client reads from
/// [_toClient] and writes to [_toServer].
class FakeGatewayChannel {
  FakeGatewayChannel() {
    channel = StreamChannel<String>(_toClient.stream, _toServer.sink);
    _toServer.stream.listen(sentByClient.add);
  }

  final StreamController<String> _toClient = StreamController<String>();
  final StreamController<String> _toServer = StreamController<String>();

  late final StreamChannel<String> channel;

  /// Raw strings the client sent (each ends with '\n').
  final List<String> sentByClient = <String>[];

  /// Server → client. [frames] may contain several newline-delimited
  /// frames in ONE WS message (protocol §3 gotcha).
  void serverSends(String frames) {
    _toClient.add(frames.endsWith('\n') ? frames : '$frames\n');
  }

  Future<void> serverCloses() => _toClient.close();
}

const String _readyFrame =
    '{"jsonrpc":"2.0","method":"event","params":{"type":"gateway.ready",'
    '"payload":{"name":"hermes","colors":{},"branding":{}}}}\n';

Map<String, dynamic> _lastRequestFrame(FakeGatewayChannel fake) {
  final line = fake.sentByClient.last.trim();
  return jsonDecode(line) as Map<String, dynamic>;
}

void main() {
  late FakeGatewayChannel fake;
  late GatewayRpcClient client;

  GatewayRpcClient buildClient({Duration? requestTimeout}) {
    fake = FakeGatewayChannel();
    return GatewayRpcClient(
      requestTimeout: requestTimeout ?? const Duration(seconds: 5),
      handshakeTimeout: const Duration(seconds: 5),
      channelFactory: (_) => fake.channel,
    );
  }

  Future<void> connectAndReady(GatewayRpcClient c) async {
    final future = c.connect(Uri.parse('ws://gateway.test/api/ws?token=x'));
    await pumpEventQueue();
    fake.serverSends(_readyFrame);
    await future;
  }

  tearDown(() async {
    await client.close();
  });

  test('reaches ready only after gateway.ready, not before', () async {
    client = buildClient();
    final states = <GatewayConnectionState>[];
    final sub = client.connection.listen(states.add);

    final future = client.connect(
      Uri.parse('ws://gateway.test/api/ws?token=x'),
    );
    await pumpEventQueue();

    expect(client.state, GatewayConnectionState.connecting);
    // Requests before ready are rejected (protocol §4: requests only after
    // gateway.ready).
    await expectLater(
      client.request('session.list'),
      throwsA(isA<GatewayClosedException>()),
    );

    fake.serverSends(_readyFrame);
    await future;

    expect(client.state, GatewayConnectionState.ready);
    expect(client.skin, isNotNull);
    expect(client.skin!['name'], 'hermes');
    expect(
      states,
      containsAllInOrder(<GatewayConnectionState>[
        GatewayConnectionState.connecting,
        GatewayConnectionState.ready,
      ]),
    );
    await sub.cancel();
  });

  test('resolves a request when a matching-id response arrives', () async {
    client = buildClient();
    await connectAndReady(client);

    final future = client.request('session.create');
    await pumpEventQueue();
    expect(_lastRequestFrame(fake)['method'], 'session.create');
    expect(_lastRequestFrame(fake)['id'], 'r1');

    fake.serverSends(
      '{"jsonrpc":"2.0","id":"r1","result":{"session_id":"a1b2c3d4",'
      '"stored_session_id":"2026-uuid","session_key":"2026-uuid"}}\n',
    );
    final result = await future;
    expect(result['session_id'], 'a1b2c3d4');
    expect(result['session_key'], '2026-uuid');
  });

  test('handles TWO frames in ONE WS message (event + response)', () async {
    client = buildClient();
    final events = <GatewayEvent>[];
    final sub = client.events.listen(events.add);
    await connectAndReady(client);

    final future = client.request('session.list');
    await pumpEventQueue();

    // One WS message, two newline-delimited frames (protocol §3 gotcha).
    fake.serverSends(
      '{"jsonrpc":"2.0","method":"event","params":{"type":"message.delta",'
      '"session_id":"a1b2c3d4","payload":{"text":"Hel"}}}\n'
      '{"jsonrpc":"2.0","id":"r1","result":{"sessions":[]}}\n',
    );

    final result = await future;
    expect(result['sessions'], isEmpty);
    final deltas = events.where((e) => e.type == 'message.delta');
    expect(deltas, hasLength(1));
    expect(deltas.single.payload['text'], 'Hel');
    expect(deltas.single.sessionId, 'a1b2c3d4');
    await sub.cancel();
  });

  test('dispatches an event that arrives BEFORE a pending response', () async {
    client = buildClient();
    final events = <GatewayEvent>[];
    final sub = client.events.listen(events.add);
    await connectAndReady(client);

    final future = client.request('prompt.submit', <String, dynamic>{
      'session_id': 'a1b2c3d4',
      'text': 'hi',
    });
    await pumpEventQueue();

    // Event first, response later, in separate messages.
    fake.serverSends(
      '{"jsonrpc":"2.0","method":"event","params":{"type":"message.start",'
      '"session_id":"a1b2c3d4"}}\n',
    );
    await pumpEventQueue();
    expect(events.where((e) => e.type == 'message.start'), hasLength(1));

    fake.serverSends(
      '{"jsonrpc":"2.0","id":"r1","result":{"status":"streaming"}}\n',
    );
    final result = await future;
    expect(result['status'], 'streaming'); // §6: NOT {ok:true}
    await sub.cancel();
  });

  test('surfaces an error frame as a rejected request', () async {
    client = buildClient();
    await connectAndReady(client);

    final future = client.request('clarify.respond', <String, dynamic>{
      'request_id': '9f3a1c2b',
      'answer': 'staging',
    });
    await pumpEventQueue();

    fake.serverSends(
      '{"jsonrpc":"2.0","id":"r1","error":{"code":4009,'
      '"message":"no pending answer request"}}\n',
    );
    await expectLater(
      future,
      throwsA(
        isA<GatewayRpcException>()
            .having((e) => e.code, 'code', 4009)
            .having((e) => e.message, 'message', 'no pending answer request'),
      ),
    );
  });

  test('times out a request with no response', () async {
    client = buildClient(requestTimeout: const Duration(milliseconds: 80));
    await connectAndReady(client);

    final future = client.request('session.compress');
    await expectLater(future, throwsA(isA<GatewayTimeoutException>()));
  });

  test(
    'transport drop rejects in-flight requests and goes reconnecting',
    () async {
      client = buildClient();
      final states = <GatewayConnectionState>[];
      final sub = client.connection.listen(states.add);
      await connectAndReady(client);

      final future = client.request('session.list');
      await pumpEventQueue();

      final expectation = expectLater(
        future,
        throwsA(isA<GatewayClosedException>()),
      );
      await fake.serverCloses();
      await pumpEventQueue();
      await expectation;
      expect(client.state, GatewayConnectionState.reconnecting);
      expect(states, contains(GatewayConnectionState.reconnecting));
      await sub.cancel();
    },
  );

  test('a stray response id is dropped without breaking the client', () async {
    client = buildClient();
    await connectAndReady(client);

    fake.serverSends('{"jsonrpc":"2.0","id":"r999","result":{}}\n');
    await pumpEventQueue();

    // Client still functional.
    final future = client.request('plugins.list');
    await pumpEventQueue();
    expect(_lastRequestFrame(fake)['id'], 'r1');
    fake.serverSends('{"jsonrpc":"2.0","id":"r1","result":{"plugins":[]}}\n');
    expect((await future)['plugins'], isEmpty);
  });
}
