/// Riverpod wiring for skills management (ticket P5-09).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/data/repositories/skills_repository.dart';
import 'package:flit/domain/models/skill_catalog.dart';
import 'package:flit/domain/repositories/skills_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The skills repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final skillsRepositoryProvider = Provider<SkillsRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return SkillsRepositoryImpl(client);
});

/// Skill catalog from `skills.manage {action:'list'}` (P5-09);
/// empty when disconnected.
final skillCatalogProvider = FutureProvider<SkillCatalog>((ref) async {
  final repository = ref.watch(skillsRepositoryProvider);
  if (repository == null) {
    return const SkillCatalog(groups: <SkillGroup>[]);
  }
  return repository.list();
});

/// Interaction state for skills reload (P5-09).
final class SkillsReloadState {
  const SkillsReloadState({this.busy = false, this.error, this.lastResult});

  /// A reload call is in flight.
  final bool busy;

  /// Human-readable failure, or null.
  final String? error;

  /// The last reload result (so UI can surface added/removed/total).
  final SkillReloadResult? lastResult;

  @override
  bool operator ==(Object other) {
    return other is SkillsReloadState &&
        other.busy == busy &&
        other.error == error &&
        other.lastResult == lastResult;
  }

  @override
  int get hashCode => Object.hash(busy, error, lastResult);

  @override
  String toString() {
    return 'SkillsReloadState(busy: $busy, error: $error, '
        'lastResult: $lastResult)';
  }
}

/// Controller for skills reload (P5-09).
final skillsReloadControllerProvider =
    NotifierProvider<SkillsReloadController, SkillsReloadState>(
      SkillsReloadController.new,
    );

class SkillsReloadController extends Notifier<SkillsReloadState> {
  @override
  SkillsReloadState build() => const SkillsReloadState();

  /// Reload skills. NEVER throws — failures land in [SkillsReloadState.error].
  Future<void> reload() async {
    if (state.busy) {
      return;
    }
    final repository = ref.read(skillsRepositoryProvider);
    if (repository == null) {
      state = const SkillsReloadState(error: 'Not connected to a gateway.');
      return;
    }
    state = const SkillsReloadState(busy: true);
    try {
      final result = await repository.reload();
      state = SkillsReloadState(lastResult: result);
      ref.invalidate(skillCatalogProvider);
    } on GatewayException catch (error) {
      state = SkillsReloadState(error: error.message);
    } on Object catch (error) {
      state = SkillsReloadState(error: error.toString());
    }
  }

  void clearError() {
    state = SkillsReloadState(busy: state.busy, lastResult: state.lastResult);
  }
}
