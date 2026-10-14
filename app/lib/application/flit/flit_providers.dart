/// Riverpod wiring for the flit backend (M2). Everything here is null or
/// empty unless the stored connection is a flit one, so Hermes connections
/// never touch it.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/flit/flit_repository_impl.dart';
import 'package:flit/data/flit/flit_transport.dart';
import 'package:flit/data/transport/connection_config.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/repositories/flit_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The flit repository for the current connection, or null when the
/// connection isn't a paired flit server.
final flitRepositoryProvider = Provider<FlitRepository?>((ref) {
  final config = ref.watch(connectionConfigProvider);
  final token = config?.token;
  if (config == null ||
      config.backend != BackendKind.flit ||
      token == null ||
      token.isEmpty) {
    return null;
  }
  return FlitRepositoryImpl(
    createFlitTransport(baseUrl: config.baseUrl, token: token),
  );
});

/// The name this device paired under, used when answering prompts.
final flitDeviceNameProvider = Provider<String>((ref) {
  return ref.watch(connectionConfigProvider)?.deviceName ?? '';
});

/// The project the sessions list shows; null means all projects. Kept for
/// the app's lifetime so switching back to the list keeps the choice.
final flitSelectedProjectProvider =
    NotifierProvider<FlitSelectedProjectNotifier, String?>(
      FlitSelectedProjectNotifier.new,
    );

class FlitSelectedProjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? projectId) => state = projectId;
}

/// Projects on the server: Scratch first, then by name.
final flitProjectsProvider = FutureProvider<List<FlitProject>>((ref) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitProject>[];
  }
  return repository.listProjects();
});

/// Sessions in the selected project (or all), most recently updated first.
final flitSessionsProvider = FutureProvider<List<FlitSession>>((ref) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitSession>[];
  }
  return repository.listSessions(
    projectId: ref.watch(flitSelectedProjectProvider),
  );
});

/// A session's MCP servers and whether each is on.
final flitMcpServersProvider =
    FutureProvider.family<List<FlitMcpServer>, String>((ref, sessionId) async {
      final repository = ref.watch(flitRepositoryProvider);
      if (repository == null) {
        return const <FlitMcpServer>[];
      }
      return repository.listMcpServers(sessionId);
    });

/// One session's metadata (title, working dir, model).
final flitSessionProvider = FutureProvider.family<FlitSession?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return null;
  }
  return repository.getSession(id);
});

/// How long to wait before reattaching after the stream drops, by attempt
/// (0-based). Overridden in tests.
final flitReconnectDelayProvider = Provider<Duration Function(int attempt)>((
  ref,
) {
  return (attempt) {
    const steps = <int>[1, 2, 4, 8, 15, 30];
    return Duration(seconds: steps[attempt.clamp(0, steps.length - 1)]);
  };
});

/// Models the server discovered, all providers. Invalidate to re-list;
/// use [FlitRepository.refreshModels] to re-run discovery.
final flitModelsProvider = FutureProvider<List<FlitModel>>((ref) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitModel>[];
  }
  return repository.listModels();
});

/// Roles sessions can be created with.
final flitRolesProvider = FutureProvider<List<FlitAgentRole>>((ref) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitAgentRole>[];
  }
  return repository.listRoles();
});

/// The skills a session's agent can load, with where each came from.
final flitSkillsProvider = FutureProvider.family<List<FlitSkill>, String>((
  ref,
  sessionId,
) async {
  final repository = ref.watch(flitRepositoryProvider);
  if (repository == null) {
    return const <FlitSkill>[];
  }
  return repository.listSkills(sessionId);
});
