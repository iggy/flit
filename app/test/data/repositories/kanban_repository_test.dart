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

    test('parses the 0.20 execution block', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'columns': <Object?>[
            <String, Object?>{
              'name': 'running',
              'tasks': <Object?>[
                <String, Object?>{
                  'id': '11',
                  'title': 'Long job',
                  'project_id': 'proj-1',
                  'session_id': 'sess-9',
                  'block_kind': 'needs_input',
                  'block_recurrences': 2,
                  'consecutive_failures': 3,
                  'model_override': 'claude-opus-5',
                  'provider_override': 'anthropic',
                  'reasoning_effort': 'high',
                  'goal_mode': true,
                  'goal_max_turns': 12,
                  'skills': <String>['research'],
                  'workflow_template_id': 'wf-2',
                  'current_step_key': 'implement',
                  'max_retries': 4,
                  'max_runtime_seconds': 1800,
                  'current_run_id': 55,
                  'claim_lock': 'lock-abc',
                  'claim_expires': 1783200600,
                  'last_failure_error': 'worker crashed',
                  'last_heartbeat_at': 1783200000,
                  'worker_pid': 4242,
                },
              ],
            },
          ],
        });
      });

      final task = (await repository.board()).columns.single.tasks.single;

      expect(task.projectId, 'proj-1');
      expect(task.sessionId, 'sess-9');
      expect(task.blockKind, 'needs_input');
      expect(task.blockRecurrences, 2);
      expect(task.consecutiveFailures, 3);
      expect(task.modelOverride, 'claude-opus-5');
      expect(task.providerOverride, 'anthropic');
      expect(task.reasoningEffort, 'high');
      expect(task.goalMode, isTrue);
      expect(task.goalMaxTurns, 12);
      expect(task.skills, <String>['research']);
      expect(task.workflowTemplateId, 'wf-2');
      expect(task.currentStepKey, 'implement');
      expect(task.maxRetries, 4);
      expect(task.maxRuntimeSeconds, 1800);
      expect(task.currentRunId, 55);
      expect(task.claimLock, 'lock-abc');
      expect(
        task.claimExpires,
        DateTime.fromMillisecondsSinceEpoch(1783200600 * 1000, isUtc: true),
      );
      expect(task.lastFailureError, 'worker crashed');
      expect(
        task.lastHeartbeatAt,
        DateTime.fromMillisecondsSinceEpoch(1783200000 * 1000, isUtc: true),
      );
      expect(task.workerPid, 4242);
    });

    test(
      'an older gateway omitting the execution block reads as unset',
      () async {
        final repository = _repositoryWith((options) async {
          return _jsonResponse(200, _cannedBoard);
        });

        final task = (await repository.board()).columns.first.tasks.single;

        expect(task.projectId, isNull);
        expect(task.modelOverride, isNull);
        expect(task.reasoningEffort, isNull);
        expect(task.goalMode, isFalse);
        expect(task.blockKind, isNull);
        expect(task.blockRecurrences, 0);
        expect(task.consecutiveFailures, 0);
        // `null` (profile defaults) and `[]` (no extra skills) are different
        // values, so a missing key must NOT become an empty list.
        expect(task.skills, isNull);
      },
    );

    test('an explicitly empty skills list stays empty, not null', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'columns': <Object?>[
            <String, Object?>{
              'name': 'todo',
              'tasks': <Object?>[
                <String, Object?>{
                  'id': '12',
                  'title': 'No skills',
                  'skills': <String>[],
                },
              ],
            },
          ],
        });
      });

      final task = (await repository.board()).columns.single.tasks.single;

      expect(task.skills, isEmpty);
      expect(task.skills, isNotNull);
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

  group('createTask (POST /api/plugins/kanban/tasks)', () {
    test('sends only non-null fields and parses task response', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{
            'id': '42',
            'title': 'New task',
            'status': 'triage',
          },
        });
      });

      final task = await repository.createTask(
        title: 'New task',
        body: 'Task body',
        priority: 2,
        triage: true,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks');
      expect(requests.single.data, <String, dynamic>{
        'title': 'New task',
        'body': 'Task body',
        'priority': 2,
        'triage': true,
      });
      expect(requests.single.data, isNot(contains('assignee')));
      expect(requests.single.data, isNot(contains('tenant')));
      expect(task?.id, '42');
      expect(task?.title, 'New task');
    });

    test('forwards ?board= when a slug is given', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '1', 'title': 'Test'},
        });
      });

      await repository.createTask(title: 'Test', board: 'ops');

      expect(requests.single.uri.queryParameters['board'], 'ops');
    });

    test('returns null when task field is missing', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      final task = await repository.createTask(title: 'Test');

      expect(task, isNull);
    });

    test('sends the execution overrides when set', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '9', 'title': 'Deep task'},
        });
      });

      await repository.createTask(
        title: 'Deep task',
        modelOverride: 'claude-opus-5',
        providerOverride: 'anthropic',
        reasoningEffort: 'ultra',
        goalMode: true,
        goalMaxTurns: 8,
        maxRuntimeSeconds: 900,
        projectId: 'proj-1',
      );

      expect(requests.single.data, <String, dynamic>{
        'title': 'Deep task',
        'model_override': 'claude-opus-5',
        'provider_override': 'anthropic',
        'reasoning_effort': 'ultra',
        'goal_mode': true,
        'goal_max_turns': 8,
        'max_runtime_seconds': 900,
        'project_id': 'proj-1',
      });
    });

    test('omits every override when none are set', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '9', 'title': 'Plain'},
        });
      });

      await repository.createTask(title: 'Plain');

      expect(requests.single.data, <String, dynamic>{'title': 'Plain'});
    });
  });

  group('editTask (PATCH /api/plugins/kanban/tasks/{id})', () {
    test('sends only non-null fields', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '7', 'title': 'Updated'},
        });
      });

      await repository.editTask('7', title: 'Updated', priority: 1);

      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7');
      expect(requests.single.data, <String, dynamic>{
        'title': 'Updated',
        'priority': 1,
      });
      expect(requests.single.data, isNot(contains('status')));
      expect(requests.single.data, isNot(contains('body')));
    });

    test('threads board query', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{},
        });
      });

      await repository.editTask('7', title: 'Test', board: 'ops');

      expect(requests.single.uri.queryParameters['board'], 'ops');
    });

    test('sends the execution overrides', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '7', 'title': 'Updated'},
        });
      });

      await repository.editTask(
        '7',
        modelOverride: 'claude-opus-5',
        providerOverride: 'anthropic',
        reasoningEffort: 'high',
      );

      expect(requests.single.data, <String, dynamic>{
        'model_override': 'claude-opus-5',
        'provider_override': 'anthropic',
        'reasoning_effort': 'high',
      });
      expect(requests.single.data, isNot(contains('clear_model_override')));
      expect(requests.single.data, isNot(contains('clear_reasoning_effort')));
    });

    test(
      'clearing needs the flags — an omitted field means unchanged',
      () async {
        final requests = <RequestOptions>[];
        final repository = _repositoryWith((options) async {
          requests.add(options);
          return _jsonResponse(200, <String, Object?>{
            'task': <String, Object?>{'id': '7', 'title': 'Updated'},
          });
        });

        await repository.editTask(
          '7',
          clearModelOverride: true,
          clearReasoningEffort: true,
        );

        expect(requests.single.data, <String, dynamic>{
          'clear_model_override': true,
          'clear_reasoning_effort': true,
        });
      },
    );

    test('reasoning_effort "none" is a value, not a clear', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'task': <String, Object?>{'id': '7', 'title': 'Updated'},
        });
      });

      await repository.editTask('7', reasoningEffort: 'none');

      expect(requests.single.data, <String, dynamic>{
        'reasoning_effort': 'none',
      });
    });
  });

  group('deleteTask (DELETE /api/plugins/kanban/tasks/{id})', () {
    test('sends DELETE to the task path', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'deleted': true});
      });

      await repository.deleteTask('7');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7');
    });

    test('threads board query', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{});
      });

      await repository.deleteTask('7', board: 'ops');

      expect(requests.single.uri.queryParameters['board'], 'ops');
    });
  });

  group('bulkUpdate (POST /api/plugins/kanban/tasks/bulk)', () {
    test('sends ids and non-null fields, parses results', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'results': <Object?>[
            <String, Object?>{'id': '1', 'ok': true},
            <String, Object?>{'id': '2', 'ok': false, 'error': 'not found'},
          ],
        });
      });

      final result = await repository.bulkUpdate(
        ids: <String>['1', '2'],
        status: 'done',
        priority: 3,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/bulk');
      expect(requests.single.data, <String, dynamic>{
        'ids': <String>['1', '2'],
        'status': 'done',
        'priority': 3,
      });
      expect(requests.single.data, isNot(contains('assignee')));
      expect(result.results, hasLength(2));
      expect(result.results[0].id, '1');
      expect(result.results[0].ok, isTrue);
      expect(result.results[0].error, isNull);
      expect(result.results[1].id, '2');
      expect(result.results[1].ok, isFalse);
      expect(result.results[1].error, 'not found');
    });
  });

  group('addComment (POST /api/plugins/kanban/tasks/{id}/comments)', () {
    test('sends body and optional author', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.addComment('7', body: 'Nice work', author: 'iggy');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/comments');
      expect(requests.single.data, <String, dynamic>{
        'body': 'Nice work',
        'author': 'iggy',
      });
    });

    test('omits author when null', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.addComment('7', body: 'Test');

      expect(requests.single.data, <String, dynamic>{'body': 'Test'});
      expect(requests.single.data, isNot(contains('author')));
    });
  });

  group('specify (POST /api/plugins/kanban/tasks/{id}/specify)', () {
    test('parses specify result', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'task_id': '7',
          'reason': 'Task fleshed out',
          'new_title': 'Expanded title',
        });
      });

      final result = await repository.specify('7');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/specify');
      expect(result.ok, isTrue);
      expect(result.taskId, '7');
      expect(result.reason, 'Task fleshed out');
      expect(result.newTitle, 'Expanded title');
    });

    test('sends author when provided', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'task_id': '7',
        });
      });

      await repository.specify('7', author: 'iggy');

      expect(requests.single.data, <String, dynamic>{'author': 'iggy'});
    });
  });

  group('decompose (POST /api/plugins/kanban/tasks/{id}/decompose)', () {
    test('parses decompose result with child ids', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'task_id': '7',
          'fanout': true,
          'child_ids': <String>['8', '9', '10'],
          'new_title': 'Parent task',
        });
      });

      final result = await repository.decompose('7');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/decompose');
      expect(result.ok, isTrue);
      expect(result.taskId, '7');
      expect(result.fanout, isTrue);
      expect(result.childIds, <String>['8', '9', '10']);
      expect(result.newTitle, 'Parent task');
    });
  });

  group('estimateTask (POST /api/plugins/kanban/tasks/{id}/estimate)', () {
    test('parses an ok estimate', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'est_tokens': 48000,
          'complexity': 'M',
          'rationale': 'Multi-file change with tests.',
          'model': 'hermes-4-405b',
        });
      });

      final estimate = await repository.estimateTask('7');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/estimate');
      expect(requests.single.uri.query, isEmpty);
      expect(estimate.ok, isTrue);
      expect(estimate.estTokens, 48000);
      expect(estimate.complexity, 'M');
      expect(estimate.rationale, 'Multi-file change with tests.');
      expect(estimate.model, 'hermes-4-405b');
      expect(estimate.reason, isNull);
    });

    test('a refusal is a 200 with ok:false, not a throw', () async {
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'ok': false,
          'reason': 'auxiliary client unavailable',
        });
      });

      final estimate = await repository.estimateTask('7');

      expect(estimate.ok, isFalse);
      expect(estimate.reason, 'auxiliary client unavailable');
      expect(estimate.estTokens, isNull);
      expect(estimate.complexity, isNull);
    });

    test('tolerates a null complexity / rationale / model on an ok', () async {
      // The server nulls a complexity band it doesn't recognise, and only
      // knows the model when the provider echoed one back.
      final repository = _repositoryWith((options) async {
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'est_tokens': 12000,
          'complexity': null,
          'rationale': null,
          'model': null,
        });
      });

      final estimate = await repository.estimateTask('7');

      expect(estimate.ok, isTrue);
      expect(estimate.estTokens, 12000);
      expect(estimate.complexity, isNull);
      expect(estimate.rationale, isNull);
      expect(estimate.model, isNull);
    });

    test('sends the board as a query param', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.estimateTask('7', board: 'infra');

      expect(requests.single.uri.queryParameters['board'], 'infra');
    });
  });

  group('reassign (POST /api/plugins/kanban/tasks/{id}/reassign)', () {
    test('sends profile, reclaim_first, and reason', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{
          'ok': true,
          'task_id': '7',
        });
      });

      await repository.reassign(
        '7',
        profile: 'research',
        reclaimFirst: true,
        reason: 'Better fit',
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/reassign');
      expect(requests.single.data, <String, dynamic>{
        'profile': 'research',
        'reclaim_first': true,
        'reason': 'Better fit',
      });
    });

    test('reclaim_first defaults to false', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.reassign('7');

      expect((requests.single.data as Map)['reclaim_first'], isFalse);
    });
  });

  group('reclaim (POST /api/plugins/kanban/tasks/{id}/reclaim)', () {
    test('sends optional reason', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.reclaim('7', reason: 'Stuck');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/tasks/7/reclaim');
      expect(requests.single.data, <String, dynamic>{'reason': 'Stuck'});
    });
  });

  group('addLink (POST /api/plugins/kanban/links)', () {
    test('sends parent_id and child_id', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.addLink(parentId: '1', childId: '2');

      expect(requests.single.method, 'POST');
      expect(requests.single.path, '/api/plugins/kanban/links');
      expect(requests.single.data, <String, dynamic>{
        'parent_id': '1',
        'child_id': '2',
      });
    });
  });

  group('removeLink (DELETE /api/plugins/kanban/links)', () {
    test('sends parent_id and child_id as query params', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{'ok': true});
      });

      await repository.removeLink(parentId: '1', childId: '2');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/api/plugins/kanban/links');
      expect(requests.single.uri.queryParameters['parent_id'], '1');
      expect(requests.single.uri.queryParameters['child_id'], '2');
    });

    test('threads board query', () async {
      final requests = <RequestOptions>[];
      final repository = _repositoryWith((options) async {
        requests.add(options);
        return _jsonResponse(200, <String, Object?>{});
      });

      await repository.removeLink(parentId: '1', childId: '2', board: 'ops');

      expect(requests.single.uri.queryParameters['board'], 'ops');
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
