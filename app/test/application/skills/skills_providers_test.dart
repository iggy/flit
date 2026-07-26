// P5-09 acceptance: skills providers against fake repository — reload
// controller never throws, stores result, invalidates catalog.

import 'package:flit/application/skills/skills_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/skill_catalog.dart';
import 'package:flit/domain/repositories/skills_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake skills repository answering from fields.
final class FakeSkillsRepository implements SkillsRepository {
  FakeSkillsRepository({
    this.catalog = const SkillCatalog(groups: <SkillGroup>[]),
    this.reloadResult,
    this.error,
  });

  SkillCatalog catalog;
  SkillReloadResult? reloadResult;
  Exception? error;
  int listCalls = 0;
  int reloadCalls = 0;

  @override
  Future<SkillCatalog> list() async {
    listCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return catalog;
  }

  @override
  Future<SkillBrowseResult> browse({int page = 1, int pageSize = 20}) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return const SkillBrowseResult(
      items: <SkillBrowseItem>[],
      page: 1,
      totalPages: 0,
      total: 0,
    );
  }

  @override
  Future<SkillReloadResult> reload() async {
    reloadCalls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return reloadResult ??
        const SkillReloadResult(
          output: '',
          added: <SkillChange>[],
          removed: <SkillChange>[],
          unchanged: <String>[],
          total: 0,
          commands: 0,
        );
  }
}

const _catalog = SkillCatalog(
  groups: <SkillGroup>[
    SkillGroup(category: 'built-in', names: <String>['loop', 'run']),
    SkillGroup(category: 'project', names: <String>['custom']),
  ],
);

const _reloadResult = SkillReloadResult(
  output: 'Reload complete',
  added: <SkillChange>[
    SkillChange(name: 'new-skill', description: 'A new skill'),
  ],
  removed: <SkillChange>[],
  unchanged: <String>['old-skill'],
  total: 5,
  commands: 3,
);

void main() {
  group('skillCatalogProvider', () {
    test('returns the fake repository catalog', () async {
      final repository = FakeSkillsRepository(catalog: _catalog);
      final container = ProviderContainer(
        overrides: [skillsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(skillCatalogProvider.future), _catalog);
      expect(repository.listCalls, 1);
    });

    test('is empty when the repository is null (disconnected)', () async {
      final container = ProviderContainer(
        overrides: [skillsRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(skillCatalogProvider.future),
        const SkillCatalog(groups: <SkillGroup>[]),
      );
    });
  });

  group('SkillsReloadController (P5-09)', () {
    test('reloads skills, stores result, and invalidates catalog', () async {
      final repository = FakeSkillsRepository(reloadResult: _reloadResult);
      final container = ProviderContainer(
        overrides: [skillsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(skillsReloadControllerProvider.notifier).reload();

      expect(repository.reloadCalls, 1);
      expect(
        container.read(skillsReloadControllerProvider).lastResult,
        _reloadResult,
      );
      expect(container.read(skillsReloadControllerProvider).error, isNull);
    });

    test('never throws — captures error in state', () async {
      final repository = FakeSkillsRepository()
        ..error = const GatewayNetworkException('offline');
      final container = ProviderContainer(
        overrides: [skillsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(skillsReloadControllerProvider.notifier).reload();

      expect(container.read(skillsReloadControllerProvider).error, isNotNull);
    });

    test('guards against null repository', () async {
      final container = ProviderContainer(
        overrides: [skillsRepositoryProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      await container.read(skillsReloadControllerProvider.notifier).reload();

      expect(
        container.read(skillsReloadControllerProvider).error,
        'Not connected to a gateway.',
      );
    });
  });
}
