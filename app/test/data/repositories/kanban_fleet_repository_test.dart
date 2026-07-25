// P5-06/P5-07 acceptance: KanbanFleetRepositoryImpl against a fake Dio
// HttpClientAdapter — no live gateway. Asserts the EXACT paths/verbs/query/body
// from docs/phases/phase-5-wire-shapes.md and defensive parsing.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/kanban_fleet_repository.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/data/transport/gateway_rest_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listBoards (GET /api/plugins/kanban/boards)', () {
    test('parses boards list with current board', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _cannedBoards);
      });

      final boardList = await repository.listBoards();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/boards');
      expect(requests.single.uri.query, isEmpty);
      expect(boardList.boards, hasLength(2));
      expect(boardList.current, 'main');
      expect(boardList.boards[0].slug, 'main');
      expect(boardList.boards[0].name, 'Main Board');
      expect(boardList.boards[0].isCurrent, isTrue);
      expect(boardList.boards[0].total, 42);
      expect(boardList.boards[0].archived, isFalse);
    });

    test('forwards includeArchived query param', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, _cannedBoards);
      });

      await repository.listBoards(includeArchived: true);

      expect(requests.single.uri.queryParameters['include_archived'], 'true');
    });
  });

  group('createBoard (POST /api/plugins/kanban/boards)', () {
    test('sends only non-null fields', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'board': <String, Object?>{
            'slug': 'new-board',
            'name': 'New Board',
            'total': 0,
            'is_current': false,
            'archived': false,
            'db_path': '/path',
            'default_workspace_kind': 'scratch',
            'counts': <String, Object?>{},
          },
        });
      });

      await repository.createBoard(
        slug: 'new-board',
        name: 'New Board',
        switchTo: true,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/boards');
      expect(requests.single.data, <String, dynamic>{
        'slug': 'new-board',
        'name': 'New Board',
        'switch': true,
      });
      expect(requests.single.data, isNot(contains('description')));
    });
  });

  group('updateBoard (PATCH /api/plugins/kanban/boards/{slug})', () {
    test('sends only non-null fields', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'board': <String, Object?>{
            'slug': 'main',
            'name': 'Updated',
            'total': 0,
            'is_current': true,
            'archived': false,
            'db_path': '/path',
            'default_workspace_kind': 'scratch',
            'counts': <String, Object?>{},
          },
        });
      });

      await repository.updateBoard('main', name: 'Updated');

      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/api/plugins/kanban/boards/main');
      expect(requests.single.data, <String, dynamic>{'name': 'Updated'});
    });
  });

  group('deleteBoard (DELETE /api/plugins/kanban/boards/{slug})', () {
    test('sends delete query param when true', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'result': <String, Object?>{
            'slug': 'old',
            'action': 'deleted',
          },
        });
      });

      await repository.deleteBoard('old', delete: true);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/api/plugins/kanban/boards/old');
      expect(requests.single.uri.queryParameters['delete'], 'true');
    });
  });

  group('switchBoard (POST /api/plugins/kanban/boards/{slug}/switch)', () {
    test('returns new current board', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'current': 'ops'});
      });

      final current = await repository.switchBoard('ops');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/boards/ops/switch');
      expect(current, 'ops');
    });
  });

  group('stats (GET /api/plugins/kanban/stats)', () {
    test('parses stats with by_status and by_assignee', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'by_status': <String, Object?>{'ready': 5, 'running': 3},
          'by_assignee': <String, Object?>{
            'default': <String, Object?>{'ready': 2, 'running': 1},
          },
          'oldest_ready_age_seconds': 3600,
          'now': 1700000000,
        });
      });

      final stats = await repository.stats();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/stats');
      expect(stats.byStatus['ready'], 5);
      expect(stats.byAssignee['default']?['ready'], 2);
      expect(stats.oldestReadyAgeSeconds, 3600);
    });
  });

  group('activeWorkers (GET /api/plugins/kanban/workers/active)', () {
    test('parses workers list', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'workers': <Object?>[
            <String, Object?>{
              'run_id': 101,
              'task_id': 'task-1',
              'task_title': 'Working on it',
              'task_status': 'running',
              'worker_pid': 1234,
              'started_at': 1700000000,
            },
          ],
          'count': 1,
          'checked_at': 1700000100,
        });
      });

      final workers = await repository.activeWorkers();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/workers/active');
      expect(workers, hasLength(1));
      expect(workers[0].runId, 101);
      expect(workers[0].taskTitle, 'Working on it');
    });
  });

  group('diagnostics (GET /api/plugins/kanban/diagnostics)', () {
    test('parses diagnostic groups', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'diagnostics': <Object?>[
            <String, Object?>{
              'task_id': 'task-1',
              'diagnostics': <Object?>[
                <String, Object?>{
                  'kind': 'crash',
                  'severity': 'error',
                  'title': 'Worker crashed',
                  'detail': 'Out of memory',
                  'first_seen_at': 1700000000,
                  'last_seen_at': 1700000100,
                  'count': 3,
                },
              ],
            },
          ],
          'count': 1,
        });
      });

      final groups = await repository.diagnostics();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/diagnostics');
      expect(groups, hasLength(1));
      expect(groups[0].taskId, 'task-1');
      expect(groups[0].diagnostics, hasLength(1));
      expect(groups[0].diagnostics[0].severity, 'error');
    });

    test('forwards severity query param', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'diagnostics': <Object?>[],
          'count': 0,
        });
      });

      await repository.diagnostics(severity: 'critical');

      expect(requests.single.uri.queryParameters['severity'], 'critical');
    });
  });

  group('dispatch (POST /api/plugins/kanban/dispatch)', () {
    test('parses dispatch result', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'reclaimed': 2,
          'promoted': 1,
          'spawned': <Object?>[
            <Object?>['task-1', 'default', '/tmp/ws'],
            <Object?>['task-2', 'research', '/tmp/ws2'],
          ],
          'skipped_unassigned': <String>['task-3'],
        });
      });

      final result = await repository.dispatch();

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/dispatch');
      expect(result.reclaimed, 2);
      expect(result.promoted, 1);
      expect(result.spawnedCount, 2);
      expect(result.skippedUnassigned, <String>['task-3']);
    });

    test('forwards dry_run and max query params', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'reclaimed': 0,
          'promoted': 0,
          'spawned': <Object?>[],
        });
      });

      await repository.dispatch(dryRun: true, max: 5);

      expect(requests.single.uri.queryParameters['dry_run'], 'true');
      expect(requests.single.uri.queryParameters['max'], '5');
    });
  });

  group('terminateRun (POST /api/plugins/kanban/runs/{id}/terminate)', () {
    test('sends reason in body', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'run_id': 101,
          'task_id': 'task-1',
        });
      });

      await repository.terminateRun(101, reason: 'Stuck');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/runs/101/terminate');
      expect(requests.single.data, <String, dynamic>{'reason': 'Stuck'});
    });
  });

  group('listAssignees (GET /api/plugins/kanban/assignees)', () {
    test('parses assignees list', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'assignees': <Object?>[
            <String, Object?>{
              'name': 'default',
              'on_disk': true,
              'counts': <String, Object?>{'ready': 3, 'running': 1},
            },
          ],
        });
      });

      final assignees = await repository.listAssignees();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/assignees');
      expect(assignees, hasLength(1));
      expect(assignees[0].name, 'default');
      expect(assignees[0].onDisk, isTrue);
      expect(assignees[0].counts['ready'], 3);
    });
  });

  group('listProfiles (GET /api/plugins/kanban/profiles)', () {
    test('parses profiles list', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'profiles': <Object?>[
            <String, Object?>{
              'name': 'default',
              'is_default': true,
              'model': 'claude-3',
              'provider': 'anthropic',
              'description': 'Default profile',
              'description_auto': false,
              'skill_count': 5,
            },
          ],
        });
      });

      final profiles = await repository.listProfiles();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/profiles');
      expect(profiles, hasLength(1));
      expect(profiles[0].name, 'default');
      expect(profiles[0].isDefault, isTrue);
      expect(profiles[0].model, 'claude-3');
    });
  });

  group('setProfileDescription (PATCH /api/plugins/kanban/profiles/{name})', () {
    test('sends description in body', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'profile': 'default',
          'description': 'Updated',
        });
      });

      await repository.setProfileDescription('default', 'Updated');

      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/api/plugins/kanban/profiles/default');
      expect(requests.single.data, <String, dynamic>{'description': 'Updated'});
    });
  });

  group('orchestration (GET /api/plugins/kanban/orchestration)', () {
    test('parses orchestration settings', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'orchestrator_profile': 'orchestrator',
          'default_assignee': 'default',
          'auto_decompose': true,
          'auto_promote_children': false,
          'resolved_orchestrator_profile': 'orchestrator',
          'resolved_default_assignee': 'default',
          'active_profile': 'orchestrator',
        });
      });

      final orch = await repository.orchestration();

      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/api/plugins/kanban/orchestration');
      expect(orch.orchestratorProfile, 'orchestrator');
      expect(orch.autoDecompose, isTrue);
      expect(orch.autoPromoteChildren, isFalse);
    });
  });

  group('setOrchestration (PUT /api/plugins/kanban/orchestration)', () {
    test('sends only non-null fields', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'orchestrator_profile': 'new-orch',
          'default_assignee': 'default',
          'auto_decompose': true,
          'auto_promote_children': false,
          'resolved_orchestrator_profile': 'new-orch',
          'resolved_default_assignee': 'default',
          'active_profile': 'new-orch',
        });
      });

      await repository.setOrchestration(
        orchestratorProfile: 'new-orch',
        autoDecompose: true,
      );

      expect(requests.single.method, 'PUT');
      expect(requests.single.path, '/api/plugins/kanban/orchestration');
      expect(requests.single.data, <String, dynamic>{
        'orchestrator_profile': 'new-orch',
        'auto_decompose': true,
      });
      expect(requests.single.data, isNot(contains('default_assignee')));
    });
  });

  group('error handling', () {
    test('maps HTTP 401 to GatewayAuthException', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(401, <String, Object?>{'detail': 'unauthorized'});
      });

      await expectLater(
        repository.listBoards(),
        throwsA(isA<GatewayAuthException>()),
      );
    });
  });
}

const _cannedBoards = <String, Object?>{
  'boards': <Object?>[
    <String, Object?>{
      'slug': 'main',
      'name': 'Main Board',
      'description': 'Default board',
      'icon': 'star',
      'color': 'blue',
      'archived': false,
      'db_path': '/data/main.db',
      'is_current': true,
      'counts': <String, Object?>{'ready': 10, 'running': 5},
      'total': 42,
      'default_workspace_kind': 'scratch',
      'created_at': 1700000000,
    },
    <String, Object?>{
      'slug': 'ops',
      'name': 'Ops Board',
      'description': '',
      'icon': '',
      'color': '',
      'archived': false,
      'db_path': '/data/ops.db',
      'is_current': false,
      'counts': <String, Object?>{},
      'total': 0,
      'default_workspace_kind': 'scratch',
    },
  ],
  'current': 'main',
};

KanbanFleetRepositoryImpl _repositoryWith(
  Future<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
  final client = GatewayRestClient(
    ConnectionConfig(baseUrl: 'http://127.0.0.1:8765', token: 'test-token'),
    dio: dio,
  );
  return KanbanFleetRepositoryImpl(client);
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
