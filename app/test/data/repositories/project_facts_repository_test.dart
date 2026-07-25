// P6-04 acceptance: ProjectFactsRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire shapes documented in
// the task description, plus DTO→domain mapping.

import 'package:flit/data/repositories/project_facts_repository_impl.dart';
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

/// A representative project facts wire dict.
const projectFactsWire = <String, dynamic>{
  'facts': <String, dynamic>{
    'root': '/home/test/repo',
    'manifests': <String>['pubspec.yaml', 'package.json'],
    'packageManagers': <String>['dart', 'npm'],
    'verifyCommands': <String>['flutter analyze', 'flutter test'],
    'contextFiles': <String>['CLAUDE.md', 'AGENTS.md'],
  },
};

void main() {
  late FakeGatewayRpcClient client;
  late ProjectFactsRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = ProjectFactsRepositoryImpl(client);
  });

  group('facts (wire project.facts)', () {
    test('sends project.facts with cwd param', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => projectFactsWire,
      );
      repository = ProjectFactsRepositoryImpl(client);

      await repository.facts(cwd: '/x');

      expect(client.calls.single.method, 'project.facts');
      expect(client.calls.single.params, <String, dynamic>{'cwd': '/x'});
    });

    test('sends EMPTY params when cwd is null', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => projectFactsWire,
      );
      repository = ProjectFactsRepositoryImpl(client);

      await repository.facts();

      expect(client.calls.single.method, 'project.facts');
      expect(client.calls.single.params, isEmpty);
    });

    test('maps result correctly', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => projectFactsWire,
      );
      repository = ProjectFactsRepositoryImpl(client);

      final result = await repository.facts(cwd: '/home/test/repo');

      expect(result, isNotNull);
      expect(result!.root, '/home/test/repo');
      expect(result.manifests, <String>['pubspec.yaml', 'package.json']);
      expect(result.packageManagers, <String>['dart', 'npm']);
      expect(
        result.verifyCommands,
        <String>['flutter analyze', 'flutter test'],
      );
      expect(result.contextFiles, <String>['CLAUDE.md', 'AGENTS.md']);
    });

    test('returns null when facts is null (not a code workspace)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'facts': null,
        },
      );
      repository = ProjectFactsRepositoryImpl(client);

      final result = await repository.facts(cwd: '/home/empty');

      expect(result, isNull);
    });

    test('defaults missing lists to empty', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'facts': <String, dynamic>{
            'root': '/home/minimal',
          },
        },
      );
      repository = ProjectFactsRepositoryImpl(client);

      final result = await repository.facts();

      expect(result, isNotNull);
      expect(result!.root, '/home/minimal');
      expect(result.manifests, isEmpty);
      expect(result.packageManagers, isEmpty);
      expect(result.verifyCommands, isEmpty);
      expect(result.contextFiles, isEmpty);
    });
  });
}
