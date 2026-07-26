// P4-07/P4-08 acceptance: ProjectsRepositoryImpl against a fake RPC client.
// Asserts the EXACT method names + params from the wire shapes documented in
// the task description, plus DTO→domain mapping.

import 'package:flit/data/repositories/projects_repository.dart';
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

/// A representative project wire dict.
const projectWire = <String, dynamic>{
  'id': 'proj-123',
  'slug': 'test-project',
  'name': 'Test Project',
  'description': 'A test project',
  'icon': '📁',
  'color': '#FF5733',
  'board_slug': 'kanban',
  'primary_path': '/home/test',
  'archived': false,
  'created_at': 1690000000,
  'folders': <Map<String, dynamic>>[
    <String, dynamic>{
      'path': '/home/test',
      'label': 'Main',
      'is_primary': true,
      'added_at': 1690000000,
    },
    <String, dynamic>{
      'path': '/home/test2',
      'label': null,
      'is_primary': false,
      'added_at': 1690000001,
    },
  ],
};

void main() {
  late FakeGatewayRpcClient client;
  late ProjectsRepositoryImpl repository;

  setUp(() {
    client = FakeGatewayRpcClient();
    repository = ProjectsRepositoryImpl(client);
  });

  group('list (wire projects.list)', () {
    test('sends projects.list with EMPTY params', () async {
      await repository.list();

      expect(client.calls.single.method, 'projects.list');
      expect(client.calls.single.params, isEmpty);
    });

    test('maps projects array and active_id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'projects': <Map<String, dynamic>>[projectWire],
          'active_id': 'proj-123',
        },
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.list();

      expect(result.projects, hasLength(1));
      expect(result.activeId, 'proj-123');
      final project = result.projects.first;
      expect(project.id, 'proj-123');
      expect(project.slug, 'test-project');
      expect(project.name, 'Test Project');
      expect(project.description, 'A test project');
      expect(project.icon, '📁');
      expect(project.color, '#FF5733');
      expect(project.boardSlug, 'kanban');
      expect(project.primaryPath, '/home/test');
      expect(project.archived, isFalse);
      expect(project.createdAt, 1690000000);
      expect(project.folders, hasLength(2));
      expect(project.folders[0].path, '/home/test');
      expect(project.folders[0].label, 'Main');
      expect(project.folders[0].isPrimary, isTrue);
      expect(project.folders[0].addedAt, 1690000000);
      expect(project.folders[1].path, '/home/test2');
      expect(project.folders[1].label, isNull);
      expect(project.folders[1].isPrimary, isFalse);
    });
  });

  group('get (wire projects.get)', () {
    test('sends projects.get with id', () async {
      await repository.get('proj-123');

      expect(client.calls.single.method, 'projects.get');
      expect(client.calls.single.params, <String, dynamic>{'id': 'proj-123'});
    });

    test('returns null when project not found', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': null},
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.get('proj-999');

      expect(result, isNull);
    });
  });

  group('setActive (wire projects.set_active)', () {
    test('sends projects.set_active with id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'active_id': 'proj-123'},
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.setActive('proj-123');

      expect(client.calls.single.method, 'projects.set_active');
      expect(client.calls.single.params, <String, dynamic>{'id': 'proj-123'});
      expect(result, 'proj-123');
    });

    test('sends null id to clear active project', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'active_id': null},
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.setActive(null);

      expect(client.calls.single.method, 'projects.set_active');
      expect(client.calls.single.params, <String, dynamic>{'id': null});
      expect(result, isNull);
    });
  });

  group('forCwd (wire projects.for_cwd)', () {
    test('sends projects.for_cwd with EMPTY params when cwd omitted', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'project': projectWire,
          'cwd': '/home/test',
          'branch': 'main',
        },
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.forCwd();

      expect(client.calls.single.method, 'projects.for_cwd');
      expect(client.calls.single.params, isEmpty);
      expect(result.project?.id, 'proj-123');
      expect(result.cwd, '/home/test');
      expect(result.branch, 'main');
    });

    test('sends cwd when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'project': null,
          'cwd': '/other/path',
          'branch': null,
        },
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.forCwd(cwd: '/other/path');

      expect(client.calls.single.method, 'projects.for_cwd');
      expect(client.calls.single.params, <String, dynamic>{
        'cwd': '/other/path',
      });
      expect(result.project, isNull);
      expect(result.cwd, '/other/path');
      expect(result.branch, isNull);
    });
  });

  group('create (wire projects.create)', () {
    test('sends projects.create with only required name', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.create(name: 'New Project');

      expect(client.calls.single.method, 'projects.create');
      expect(client.calls.single.params, <String, dynamic>{
        'name': 'New Project',
      });
    });

    test('includes only non-null optional params', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.create(
        name: 'New Project',
        slug: 'new-project',
        folders: <String>['/path/one', '/path/two'],
        primaryPath: '/path/one',
        description: 'A new project',
        icon: '🚀',
        color: '#0000FF',
        boardSlug: 'board',
        use: true,
      );

      expect(client.calls.single.method, 'projects.create');
      expect(client.calls.single.params, <String, dynamic>{
        'name': 'New Project',
        'slug': 'new-project',
        'folders': <String>['/path/one', '/path/two'],
        'primary_path': '/path/one',
        'description': 'A new project',
        'icon': '🚀',
        'color': '#0000FF',
        'board_slug': 'board',
        'use': true,
      });
    });
  });

  group('update (wire projects.update)', () {
    test('sends projects.update with id and only non-null params', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.update('proj-123', name: 'Updated Name');

      expect(client.calls.single.method, 'projects.update');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'name': 'Updated Name',
      });
    });

    test('includes all optional params when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.update(
        'proj-123',
        name: 'Updated',
        description: 'New desc',
        icon: '⭐',
        color: '#00FF00',
        boardSlug: 'new-board',
      );

      expect(client.calls.single.method, 'projects.update');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'name': 'Updated',
        'description': 'New desc',
        'icon': '⭐',
        'color': '#00FF00',
        'board_slug': 'new-board',
      });
    });
  });

  group('addFolder (wire projects.add_folder)', () {
    test('sends projects.add_folder with id and path', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.addFolder('proj-123', '/new/path');

      expect(client.calls.single.method, 'projects.add_folder');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'path': '/new/path',
      });
    });

    test('includes label and is_primary when provided', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.addFolder(
        'proj-123',
        '/new/path',
        label: 'New Folder',
        isPrimary: true,
      );

      expect(client.calls.single.method, 'projects.add_folder');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'path': '/new/path',
        'label': 'New Folder',
        'is_primary': true,
      });
    });
  });

  group('removeFolder (wire projects.remove_folder)', () {
    test('sends projects.remove_folder with id and path', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.removeFolder('proj-123', '/old/path');

      expect(client.calls.single.method, 'projects.remove_folder');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'path': '/old/path',
      });
    });
  });

  group('setPrimary (wire projects.set_primary)', () {
    test('sends projects.set_primary with id and path', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{'project': projectWire},
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.setPrimary('proj-123', '/primary/path');

      expect(client.calls.single.method, 'projects.set_primary');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'path': '/primary/path',
      });
    });
  });

  group('archive (wire projects.archive)', () {
    test('sends projects.archive with id only', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'projects': <Map<String, dynamic>>[projectWire],
          'active_id': null,
        },
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.archive('proj-123');

      expect(client.calls.single.method, 'projects.archive');
      expect(client.calls.single.params, <String, dynamic>{'id': 'proj-123'});
    });

    test('includes restore:true when restoring', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'projects': <Map<String, dynamic>>[projectWire],
          'active_id': 'proj-123',
        },
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.archive('proj-123', restore: true);

      expect(client.calls.single.method, 'projects.archive');
      expect(client.calls.single.params, <String, dynamic>{
        'id': 'proj-123',
        'restore': true,
      });
    });
  });

  group('delete (wire projects.delete)', () {
    test('sends projects.delete with id', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'projects': <Map<String, dynamic>>[],
          'active_id': null,
        },
      );
      repository = ProjectsRepositoryImpl(client);

      await repository.delete('proj-123');

      expect(client.calls.single.method, 'projects.delete');
      expect(client.calls.single.params, <String, dynamic>{'id': 'proj-123'});
    });
  });

  group('discoverRepos (wire projects.discover_repos)', () {
    test('sends projects.discover_repos with EMPTY params', () async {
      client = FakeGatewayRpcClient(
        handler: (_, _) => <String, dynamic>{
          'repos': <Map<String, dynamic>>[
            <String, dynamic>{
              'root': '/home/user/repo1',
              'label': 'Repo 1',
              'sessions': 5,
              'last_active': 1690000000,
            },
          ],
        },
      );
      repository = ProjectsRepositoryImpl(client);

      final result = await repository.discoverRepos();

      expect(client.calls.single.method, 'projects.discover_repos');
      expect(client.calls.single.params, isEmpty);
      expect(result, hasLength(1));
      expect(result.first.root, '/home/user/repo1');
      expect(result.first.label, 'Repo 1');
      expect(result.first.sessions, 5);
      expect(result.first.lastActive, 1690000000);
    });
  });
}
