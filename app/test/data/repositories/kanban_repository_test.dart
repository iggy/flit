// P1-15 acceptance: KanbanRepositoryImpl against a fake Dio
// HttpClientAdapter — no live gateway. Asserts the EXACT paths/verbs from
// docs/reference/06-kanban-rest.md (MVP scope) and the sanctioned defensive
// task-field parsing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/kanban_repository.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flit/domain/models/kanban.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('board (GET /api/plugins/kanban/board)', () {
    test('parses a two-column board with one task each', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _cannedBoard);
      });

      final board = await repository.board();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/board');
      expect(requests.single.uri.query, isEmpty);

      // Envelope (pinned by 06-kanban-rest.md).
      expect(board.columns, hasLength(2));
      expect(board.tenants, <String>['acme']);
      expect(board.assignees, <String>['default', 'research']);
      expect(board.latestEventId, 4211);
      expect(
        board.now,
        DateTime.fromMillisecondsSinceEpoch(1783200000 * 1000, isUtc: true),
      );

      // Column order preserved as sent.
      expect(board.columns[0].name, 'triage');
      expect(board.columns[1].name, 'todo');

      final first = board.columns[0].tasks.single;
      // String-or-num id stringified (sanctioned defensive parsing).
      expect(first.id, '7');
      expect(first.title, 'Fix the parser');
      expect(first.status, 'triage');
      expect(first.assignee, 'default');
      expect(first.priority, 'high');
      expect(first.tenant, 'acme');
      expect(first.age, '2h');
      // Documented derived fields.
      expect(first.latestSummary, 'Investigating the crash');
      expect(first.linkCounts, const KanbanLinkCounts(parents: 1, children: 2));
      expect(first.commentCount, 3);
      expect(first.progress, const KanbanProgress(done: 1, total: 4));

      // Missing optional fields parse to null/empty — never crash.
      final second = board.columns[1].tasks.single;
      expect(second.id, '8');
      expect(second.title, 'Write docs');
      expect(second.status, 'todo');
      expect(second.body, isNull);
      expect(second.assignee, isNull);
      expect(second.priority, isNull);
      expect(second.tenant, isNull);
      expect(second.age, isNull);
      expect(second.latestSummary, isNull);
      expect(second.linkCounts, isNull);
      expect(second.commentCount, isNull);
      expect(second.progress, isNull);
    });

    test('forwards ?board= when a slug is given', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _cannedBoard);
      });

      await repository.board(board: 'ops');

      expect(requests.single.uri.queryParameters['board'], 'ops');
    });

    test('a task missing EVERYTHING still parses (tolerant)', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'columns': <Object?>[
            <String, Object?>{
              'name': 'triage',
              'tasks': <Object?>[<String, Object?>{}],
            },
          ],
        });
      });

      final board = await repository.board();

      final task = board.columns.single.tasks.single;
      expect(task.id, '');
      expect(task.title, '');
      expect(task.status, isNull);
    });

    test('maps HTTP 401 to GatewayAuthException (passthrough)', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(401, <String, Object?>{'detail': 'unauthorized'});
      });

      await expectLater(
        repository.board(),
        throwsA(isA<GatewayAuthException>()),
      );
    });
  });

  group('task (GET /api/plugins/kanban/tasks/{id})', () {
    test('parses task + comments + raw extras', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{
            'id': '7',
            'title': 'Fix the parser',
            'status': 'triage',
            'body': 'Full body text',
          },
          'comments': <Object?>[
            <String, Object?>{'author': 'iggy', 'body': 'Looks good'},
          ],
          // Unpinned extras stay raw.
          'events': <Object?>[
            <String, Object?>{'id': 1},
          ],
          'links': <Object?>[],
        });
      });

      final detail = await repository.task('7');

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7');
      expect(detail.task.id, '7');
      expect(detail.task.title, 'Fix the parser');
      expect(detail.task.body, 'Full body text');
      expect(detail.comments, hasLength(1));
      expect(detail.comments.single['body'], 'Looks good');
      expect(detail.extras.keys, containsAll(<String>['events', 'links']));
      expect(detail.extras.containsKey('task'), isFalse);
      expect(detail.extras.containsKey('comments'), isFalse);
    });

    test('tolerates a flattened detail envelope (no task key)', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'id': 7,
          'title': 'Fix the parser',
          'status': 'todo',
        });
      });

      final detail = await repository.task('7');

      expect(detail.task.id, '7');
      expect(detail.task.status, 'todo');
      expect(detail.comments, isEmpty);
    });
  });

  group('updateTaskStatus (PATCH /api/plugins/kanban/tasks/{id})', () {
    test("sends {'status': 'done'} to the task path", () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.updateTaskStatus('7', 'done');

      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7');
      expect(requests.single.data, <String, dynamic>{'status': 'done'});
    });

    test('maps HTTP 403 to GatewayAuthException (passthrough)', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(403, <String, Object?>{'detail': 'forbidden'});
      });

      await expectLater(
        repository.updateTaskStatus('7', 'done'),
        throwsA(isA<GatewayAuthException>()),
      );
    });
  });
}

/// Canned `GET /board` body (envelope pinned by 06-kanban-rest.md; task
/// identity fields per the ticket's sanctioned defensive list).
const _cannedBoard = <String, Object?>{
  'columns': <Object?>[
    <String, Object?>{
      'name': 'triage',
      'tasks': <Object?>[
        <String, Object?>{
          'id': 7, // num id — stringified
          'title': 'Fix the parser',
          'status': 'triage',
          'assignee': 'default',
          'priority': 'high',
          'tenant': 'acme',
          'age': '2h',
          'latest_summary': 'Investigating the crash',
          'link_counts': <String, Object?>{'parents': 1, 'children': 2},
          'comment_count': 3,
          'progress': <String, Object?>{'done': 1, 'total': 4},
        },
      ],
    },
    <String, Object?>{
      'name': 'todo',
      'tasks': <Object?>[
        <String, Object?>{'id': '8', 'title': 'Write docs', 'status': 'todo'},
      ],
    },
  ],
  'tenants': <String>['acme'],
  'assignees': <String>['default', 'research'],
  'latest_event_id': 4211,
  'now': 1783200000,
};

KanbanRepositoryImpl _repositoryWith(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
  final client = GatewayRestClient(
    ConnectionConfig(baseUrl: 'http://127.0.0.1:8765', token: 'test-token'),
    dio: dio,
  );
  return KanbanRepositoryImpl(client);
}

ResponseBody _jsonResponse(int statusCode, Map<String, Object?> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

/// Hand-written fake adapter (mirrors gateway_rest_client_test.dart).
final class _FakeAdapter implements HttpClientAdapter {
  const _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
