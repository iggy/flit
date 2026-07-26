// Provider tests for command palette aggregation (P9-04).

import 'package:flit/application/models/model_providers.dart';
import 'package:flit/application/palette/palette_providers.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('paletteCommandsProvider', () {
    test('includes navigation commands even when disconnected', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async => <SessionSummary>[]),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final commands = container.read(paletteCommandsProvider);
      // At least the navigation commands are present.
      expect(commands.where((c) => c.section == 'Navigation'), isNotEmpty);
      expect(
        commands.any((c) => c is PaletteNavigate && c.route == '/chat'),
        true,
      );
    });

    test('includes sessions when available', () async {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async {
            return <SessionSummary>[
              const SessionSummary(
                durableId: 's1',
                title: 'Test Session',
                preview: 'Test preview',
                messageCount: 5,
              ),
            ];
          }),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future provider to complete.
      await container.read(sessionListProvider.future);

      final commands = container.read(paletteCommandsProvider);
      final sessionCommands = commands.whereType<PaletteSwitchSession>();
      expect(sessionCommands, hasLength(1));
      expect(sessionCommands.first.label, 'Test Session');
      expect(sessionCommands.first.durableId, 's1');
    });

    test('includes models when available', () async {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async => <SessionSummary>[]),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: <ModelProvider>[
                const ModelProvider(
                  name: 'Test Provider',
                  slug: 'test',
                  authenticated: true,
                  isCurrent: true,
                  models: <String>['model-a', 'model-b'],
                ),
              ],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future provider to complete.
      await container.read(modelOptionsProvider.future);

      final commands = container.read(paletteCommandsProvider);
      final modelCommands = commands.whereType<PaletteSelectModel>();
      expect(modelCommands, hasLength(2));
      expect(
        modelCommands.any(
          (c) => c.model == 'model-a' && c.providerSlug == 'test',
        ),
        true,
      );
      expect(
        modelCommands.any(
          (c) => c.model == 'model-b' && c.providerSlug == 'test',
        ),
        true,
      );
    });

    test('includes slash commands when available', () async {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async => <SessionSummary>[]),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async {
            return const SlashCatalog(
              allCommands: <SlashCommand>[
                SlashCommand(
                  command: '/test',
                  description: 'Test command',
                  category: 'Test',
                ),
              ],
              categories: <SlashCategory>[],
              canon: <String, String>{},
              skillCount: 0,
              warning: '',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      // Wait for the future provider to complete.
      await container.read(slashCatalogProvider.future);

      final commands = container.read(paletteCommandsProvider);
      final slashCommands = commands.whereType<PalettePrefillSlash>();
      expect(slashCommands, hasLength(1));
      expect(slashCommands.first.command, '/test');
      expect(slashCommands.first.subtitle, 'Test command');
    });

    test('handles loading state without error', () {
      final container = ProviderContainer(
        overrides: [
          // sessionListProvider in loading state (no override → default behavior)
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Should not throw; navigation commands are still present.
      final commands = container.read(paletteCommandsProvider);
      expect(commands.where((c) => c.section == 'Navigation'), isNotEmpty);
    });

    test('handles error state in a source provider without failing', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async {
            throw Exception('Session fetch failed');
          }),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Should not throw; navigation commands are still present.
      final commands = container.read(paletteCommandsProvider);
      expect(commands.where((c) => c.section == 'Navigation'), isNotEmpty);
    });
  });

  group('paletteQueryProvider', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(paletteQueryProvider), '');
    });

    test('setQuery updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(paletteQueryProvider.notifier).setQuery('test');
      expect(container.read(paletteQueryProvider), 'test');
    });

    test('clear resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(paletteQueryProvider.notifier).setQuery('test');
      container.read(paletteQueryProvider.notifier).clear();
      expect(container.read(paletteQueryProvider), '');
    });
  });

  group('filteredPaletteCommandsProvider', () {
    test('empty query returns all commands', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async => <SessionSummary>[]),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      final all = container.read(paletteCommandsProvider);
      final filtered = container.read(filteredPaletteCommandsProvider);
      expect(filtered.length, all.length);
    });

    test('query filters commands', () {
      final container = ProviderContainer(
        overrides: [
          sessionListProvider.overrideWith((ref) async => <SessionSummary>[]),
          modelOptionsProvider.overrideWith((ref) async {
            return (
              current: const CurrentModel(model: '', provider: ''),
              providers: const <ModelProvider>[],
            );
          }),
          slashCatalogProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      container.read(paletteQueryProvider.notifier).setQuery('chat');
      final filtered = container.read(filteredPaletteCommandsProvider);
      // Should include the "Chat" navigation command.
      expect(filtered.any((c) => c.label.toLowerCase().contains('chat')), true);
      // Should NOT include commands that don't match.
      final allCommands = container.read(paletteCommandsProvider);
      expect(filtered.length, lessThan(allCommands.length));
    });
  });
}
