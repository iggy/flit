// P6-01/P6-02 acceptance: LearningRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire shapes documented in
// 09-memory-learning-wire-shapes.md, plus DTO→domain mapping.

import 'package:flit/data/repositories/learning_repository_impl.dart';
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

/// A representative learning.frames wire result.
const framesWire = <String, dynamic>{
  'frames': <String>[], // IGNORED by Flutter client
  'legend': <Map<String, dynamic>>[
    <String, dynamic>{'glyph': '●', 'style': 'skill', 'label': 'skills (12)'},
    <String, dynamic>{'glyph': '◆', 'style': 'memory', 'label': 'memories (4)'},
  ],
  'categories': <Map<String, dynamic>>[
    <String, dynamic>{'glyph': '●', 'color': '#FF5733', 'label': 'coding (5)'},
  ],
  'buckets': <Map<String, dynamic>>[
    <String, dynamic>{
      'index': 0,
      'label': 'Jul 2026',
      'date': '3 Jul 2026',
      'skills': 3,
      'memories': 1,
      'total': 4,
      'category': 'coding',
      'color': '#FF5733',
      'nodes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'refactor-helper',
          'glyph': '●',
          'label': 'refactor-helper',
          'fullLabel': 'refactor-helper',
          'meta': 'agent · 3 Jul 2026',
          'body': '',
          'style': 'skill',
        },
        <String, dynamic>{
          'id': 'memory:session:0',
          'glyph': '◆',
          'label': 'Context about X',
          'fullLabel': 'Context about X',
          'meta': 'session · 3 Jul 2026',
          'body': 'Some memory content here',
          'style': 'memory',
        },
      ],
    },
  ],
  'summary': <String>[
    '12 learned skills · 4 memories · 6 skill links',
    '2 memory↔skill links · busiest day 3 Jul 2026 · 4 learned',
  ],
  'axis': <String, dynamic>{'start': 'oldest', 'end': 'now'},
  'count': 16,
};

void main() {
  late FakeGatewayRpcClient client;
  late LearningRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = LearningRepositoryImpl(client);
  });

  group('frames (wire learning.frames)', () {
    test('sends learning.frames with frames:2', () async {
      await repository.frames();

      expect(client.calls.single.method, 'learning.frames');
      expect(client.calls.single.params, <String, dynamic>{'frames': 2});
    });

    test('maps buckets, summary, legend, categories, axis, count', () async {
      client = FakeGatewayRpcClient(handler: (_, _) => framesWire);
      repository = LearningRepositoryImpl(client);

      final result = await repository.frames();

      expect(result.count, 16);
      expect(result.summary, hasLength(2));
      expect(
        result.summary.first,
        '12 learned skills · 4 memories · 6 skill links',
      );
      expect(result.legend, hasLength(2));
      expect(result.legend[0].glyph, '●');
      expect(result.legend[0].style, 'skill');
      expect(result.legend[0].label, 'skills (12)');
      expect(result.legend[1].glyph, '◆');
      expect(result.legend[1].style, 'memory');
      expect(result.categories, hasLength(1));
      expect(result.categories[0].glyph, '●');
      expect(result.categories[0].color, '#FF5733');
      expect(result.categories[0].label, 'coding (5)');
      expect(result.axis.start, 'oldest');
      expect(result.axis.end, 'now');
      expect(result.buckets, hasLength(1));
      final bucket = result.buckets.first;
      expect(bucket.index, 0);
      expect(bucket.label, 'Jul 2026');
      expect(bucket.date, '3 Jul 2026');
      expect(bucket.skills, 3);
      expect(bucket.memories, 1);
      expect(bucket.total, 4);
      expect(bucket.category, 'coding');
      expect(bucket.color, '#FF5733');
      expect(bucket.nodes, hasLength(2));
      final node0 = bucket.nodes[0];
      expect(node0.id, 'refactor-helper');
      expect(node0.glyph, '●');
      expect(node0.label, 'refactor-helper');
      expect(node0.fullLabel, 'refactor-helper');
      expect(node0.meta, 'agent · 3 Jul 2026');
      expect(node0.body, '');
      expect(node0.style, 'skill');
      final node1 = bucket.nodes[1];
      expect(node1.id, 'memory:session:0');
      expect(node1.glyph, '◆');
      expect(node1.label, 'Context about X');
      expect(node1.fullLabel, 'Context about X');
      expect(node1.meta, 'session · 3 Jul 2026');
      expect(node1.body, 'Some memory content here');
      expect(node1.style, 'memory');
    });

    test('handles empty journey', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'buckets': <Map<String, dynamic>>[],
          'summary': <String>[],
          'legend': <Map<String, dynamic>>[],
          'categories': <Map<String, dynamic>>[],
          'axis': <String, dynamic>{'start': '', 'end': ''},
          'count': 0,
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.frames();

      expect(result.count, 0);
      expect(result.buckets, isEmpty);
      expect(result.summary, isEmpty);
    });
  });

  group('detail (wire learning.detail)', () {
    test('sends learning.detail with id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'kind': 'skill',
          'id': 'refactor-helper',
          'label': 'refactor-helper',
          'content': 'Full SKILL.md content here',
        },
      );
      repository = LearningRepositoryImpl(client);

      await repository.detail('refactor-helper');

      expect(client.calls.single.method, 'learning.detail');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'refactor-helper',
      });
    });

    test('maps success result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'kind': 'skill',
          'id': 'refactor-helper',
          'label': 'refactor-helper',
          'content': 'Full SKILL.md content here',
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.detail('refactor-helper');

      expect(result.ok, isTrue);
      expect(result.kind, 'skill');
      expect(result.id, 'refactor-helper');
      expect(result.label, 'refactor-helper');
      expect(result.content, 'Full SKILL.md content here');
      expect(result.message, isNull);
    });

    test('maps failure result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': false,
          'message': "skill 'x' not found",
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.detail('x');

      expect(result.ok, isFalse);
      expect(result.message, "skill 'x' not found");
    });
  });

  group('edit (wire learning.edit)', () {
    test('sends learning.edit with id and content', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'message': "updated 'refactor-helper'",
        },
      );
      repository = LearningRepositoryImpl(client);

      await repository.edit('refactor-helper', 'New content here');

      expect(client.calls.single.method, 'learning.edit');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'refactor-helper',
        'content': 'New content here',
      });
    });

    test('maps success result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'message': "updated 'refactor-helper'",
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.edit('refactor-helper', 'New content');

      expect(result.ok, isTrue);
      expect(result.message, "updated 'refactor-helper'");
    });

    test('maps failure result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': false,
          'message': 'edit failed',
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.edit('x', 'content');

      expect(result.ok, isFalse);
      expect(result.message, 'edit failed');
    });
  });

  group('delete (wire learning.delete)', () {
    test('sends learning.delete with id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'message': "archived 'x' — restore with: hermes curator restore x",
        },
      );
      repository = LearningRepositoryImpl(client);

      await repository.delete('x');

      expect(client.calls.single.method, 'learning.delete');
      expect(client.calls.single.params, <String, dynamic>{'id': 'x'});
    });

    test('maps success result', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': true,
          'message': "archived 'x' — restore with: hermes curator restore x",
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.delete('x');

      expect(result.ok, isTrue);
      expect(
        result.message,
        "archived 'x' — restore with: hermes curator restore x",
      );
    });

    test('maps failure result (pinned)', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'ok': false,
          'message': "'x' is pinned — unpin it first (...)",
        },
      );
      repository = LearningRepositoryImpl(client);

      final result = await repository.delete('x');

      expect(result.ok, isFalse);
      expect(result.message, "'x' is pinned — unpin it first (...)");
    });
  });
}
