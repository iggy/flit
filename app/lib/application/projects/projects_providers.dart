/// Riverpod wiring for project management (tickets P4-07, P4-08): the
/// repository provider, the refreshable `projects.list` fetch, and the
/// controller for mutation operations.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/projects_repository.dart';
import 'package:flit/domain/models/project.dart';
import 'package:flit/domain/repositories/projects_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The projects repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect) — mirroring the nullable
/// [modelRepositoryProvider] pattern. Callers must handle null (the UI only
/// offers project actions while connected).
final projectsRepositoryProvider = Provider<ProjectsRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return ProjectsRepositoryImpl(client);
});

/// `projects.list` for the projects screen (wire shape). Re-fetches on client
/// swap (reconnect); refresh after a change with
/// `ref.invalidate(projectsListProvider)` — [ProjectsController] does this
/// automatically after mutations.
final projectsListProvider = FutureProvider<ProjectsList>((ref) async {
  final repository = ref.watch(projectsRepositoryProvider);
  if (repository == null) {
    // Disconnected: empty list, no active project.
    return (projects: const <Project>[], activeId: null);
  }
  return repository.list();
});

/// Interaction state for project mutations.
final class ProjectsControllerState {
  const ProjectsControllerState({this.busy = false, this.error});

  /// A mutating operation is in flight.
  final bool busy;

  /// Human-readable failure (token-redacted), or null. The controller NEVER
  /// throws — failures land here so the UI can show them inline.
  final String? error;

  @override
  bool operator ==(Object other) {
    return other is ProjectsControllerState &&
        other.busy == busy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(busy, error);

  @override
  String toString() => 'ProjectsControllerState(busy: $busy, error: $error)';
}

/// Controller for project mutations: setActive, create, update, addFolder,
/// removeFolder, setPrimary, archive, delete. NEVER throws; failures land in
/// [ProjectsControllerState.error].
final projectsControllerProvider =
    NotifierProvider<ProjectsController, ProjectsControllerState>(
      ProjectsController.new,
    );

class ProjectsController extends Notifier<ProjectsControllerState> {
  @override
  ProjectsControllerState build() => const ProjectsControllerState();

  Future<void> setActive(String? id) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.setActive(id);
    });
  }

  Future<void> create({
    required String name,
    String? slug,
    List<String>? folders,
    String? primaryPath,
    String? description,
    String? icon,
    String? color,
    String? boardSlug,
    bool use = false,
  }) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.create(
        name: name,
        slug: slug,
        folders: folders,
        primaryPath: primaryPath,
        description: description,
        icon: icon,
        color: color,
        boardSlug: boardSlug,
        use: use,
      );
    });
  }

  Future<void> update(
    String id, {
    String? name,
    String? description,
    String? icon,
    String? color,
    String? boardSlug,
  }) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.update(
        id,
        name: name,
        description: description,
        icon: icon,
        color: color,
        boardSlug: boardSlug,
      );
    });
  }

  Future<void> addFolder(
    String id,
    String path, {
    String? label,
    bool isPrimary = false,
  }) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.addFolder(id, path, label: label, isPrimary: isPrimary);
    });
  }

  Future<void> removeFolder(String id, String path) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.removeFolder(id, path);
    });
  }

  Future<void> setPrimary(String id, String path) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.setPrimary(id, path);
    });
  }

  Future<void> archive(String id, {bool restore = false}) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.archive(id, restore: restore);
    });
  }

  Future<void> delete(String id) async {
    await _mutate(() async {
      final repository = ref.read(projectsRepositoryProvider);
      if (repository == null) {
        throw Exception('Not connected to a gateway.');
      }
      await repository.delete(id);
    });
  }

  void clearError() {
    state = ProjectsControllerState(busy: state.busy);
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (state.busy) {
      return;
    }
    state = const ProjectsControllerState(busy: true);
    try {
      await action();
      state = const ProjectsControllerState();
      ref.invalidate(projectsListProvider);
    } on GatewayException catch (error) {
      state = ProjectsControllerState(error: error.message);
    } on Object catch (error) {
      state = ProjectsControllerState(error: error.toString());
    }
  }
}
