// P6-03 acceptance: InsightsRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire shapes documented in
// the task description, plus DTO→domain mapping.

import 'package:flit/data/repositories/insights_repository_impl.dart';
import 'package:flit/data/transport/gateway_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-written fake: subclasses [GatewayRpcClient] and overrides ONLY
/// `request` — the single surface the repository uses. Records every call and
/// answers from [handler].
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
  late InsightsRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = InsightsRepositoryImpl(client);
  });

  group('get (wire insights.get)', () {
    test('sends insights.get with days param', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'days': 7,
          'sessions': 3,
          'messages': 20,
        },
      );
      repository = InsightsRepositoryImpl(client);

      await repository.get(days: 7);

      expect(client.calls.single.method, 'insights.get');
      expect(client.calls.single.params, <String, dynamic>{'days': 7});
    });

    test('defaults to 30 days when not specified', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'days': 30,
          'sessions': 10,
          'messages': 100,
        },
      );
      repository = InsightsRepositoryImpl(client);

      await repository.get();

      expect(client.calls.single.method, 'insights.get');
      expect(client.calls.single.params, <String, dynamic>{'days': 30});
    });

    test('maps result correctly', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'days': 7,
          'sessions': 3,
          'messages': 20,
        },
      );
      repository = InsightsRepositoryImpl(client);

      final result = await repository.get(days: 7);

      expect(result.days, 7);
      expect(result.sessions, 3);
      expect(result.messages, 20);
    });

    test('defaults null fields to 0', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'days': null,
          'sessions': null,
          'messages': null,
        },
      );
      repository = InsightsRepositoryImpl(client);

      final result = await repository.get();

      expect(result.days, 0);
      expect(result.sessions, 0);
      expect(result.messages, 0);
    });
  });
}
