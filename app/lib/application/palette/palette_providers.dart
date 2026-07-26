/// Command palette providers (P9-04): command aggregation, filtering, and
/// action intents.
library;

import 'package:flit/application/models/model_providers.dart';
import 'package:flit/application/palette/palette_match.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A command palette entry with its action intent (P9-04).
sealed class PaletteCommand {
  const PaletteCommand({
    required this.id,
    required this.label,
    required this.section,
    this.subtitle,
  });

  /// Unique identifier for this command.
  final String id;

  /// Display label.
  final String label;

  /// Optional subtitle (e.g., session preview or model provider).
  final String? subtitle;

  /// Section header (e.g., "Navigation", "Sessions", "Models", "Commands").
  final String section;

  @override
  bool operator ==(Object other) {
    return other is PaletteCommand &&
        other.id == id &&
        other.label == label &&
        other.subtitle == subtitle &&
        other.section == section;
  }

  @override
  int get hashCode => Object.hash(id, label, subtitle, section);
}

/// Navigate to a route.
final class PaletteNavigate extends PaletteCommand {
  const PaletteNavigate({
    required super.id,
    required super.label,
    required super.section,
    required this.route,
    super.subtitle,
  });

  final String route;

  @override
  bool operator ==(Object other) {
    return other is PaletteNavigate && super == other && other.route == route;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, route);

  @override
  String toString() => 'PaletteNavigate(id: $id, label: $label, route: $route)';
}

/// Switch to a session.
final class PaletteSwitchSession extends PaletteCommand {
  const PaletteSwitchSession({
    required super.id,
    required super.label,
    required super.section,
    required this.durableId,
    super.subtitle,
  });

  final String durableId;

  @override
  bool operator ==(Object other) {
    return other is PaletteSwitchSession &&
        super == other &&
        other.durableId == durableId;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, durableId);

  @override
  String toString() =>
      'PaletteSwitchSession(id: $id, label: $label, durableId: $durableId)';
}

/// Select a model.
final class PaletteSelectModel extends PaletteCommand {
  const PaletteSelectModel({
    required super.id,
    required super.label,
    required super.section,
    required this.providerSlug,
    required this.model,
    super.subtitle,
  });

  final String providerSlug;
  final String model;

  @override
  bool operator ==(Object other) {
    return other is PaletteSelectModel &&
        super == other &&
        other.providerSlug == providerSlug &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, providerSlug, model);

  @override
  String toString() =>
      'PaletteSelectModel(id: $id, label: $label, model: $model)';
}

/// Prefill a slash command.
final class PalettePrefillSlash extends PaletteCommand {
  const PalettePrefillSlash({
    required super.id,
    required super.label,
    required super.section,
    required this.command,
    super.subtitle,
  });

  final String command;

  @override
  bool operator ==(Object other) {
    return other is PalettePrefillSlash &&
        super == other &&
        other.command == command;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, command);

  @override
  String toString() =>
      'PalettePrefillSlash(id: $id, label: $label, command: $command)';
}

/// All command palette entries from all sources (P9-04).
/// Sources that are loading, errored, or disconnected contribute nothing
/// rather than failing the whole list — navigation commands are always
/// available even with no gateway connection.
final paletteCommandsProvider = Provider<List<PaletteCommand>>((ref) {
  final commands = <PaletteCommand>[];

  // Navigation commands (always present)
  commands.addAll(_navigationCommands);

  // Sessions (when available)
  final sessions = ref.watch(sessionListProvider).value;
  if (sessions != null) {
    for (final session in sessions) {
      commands.add(
        PaletteSwitchSession(
          id: 'session-${session.durableId}',
          label: session.title,
          subtitle: session.preview,
          section: 'Sessions',
          durableId: session.durableId,
        ),
      );
    }
  }

  // Models (when available)
  final modelOptions = ref.watch(modelOptionsProvider).value;
  if (modelOptions != null) {
    for (final provider in modelOptions.providers) {
      for (final model in provider.models) {
        commands.add(
          PaletteSelectModel(
            id: 'model-${provider.slug}-$model',
            label: model,
            subtitle: provider.name,
            section: 'Models',
            providerSlug: provider.slug,
            model: model,
          ),
        );
      }
    }
  }

  // Slash commands (when available)
  final catalog = ref.watch(slashCatalogProvider).value;
  if (catalog != null) {
    for (final cmd in catalog.allCommands) {
      commands.add(
        PalettePrefillSlash(
          id: 'slash-${cmd.command}',
          label: cmd.command,
          subtitle: cmd.description,
          section: 'Commands',
          command: cmd.command,
        ),
      );
    }
  }

  return commands;
});

/// Current filter query.
final paletteQueryProvider = NotifierProvider<PaletteQueryNotifier, String>(
  PaletteQueryNotifier.new,
);

final class PaletteQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Filtered and ranked commands based on [paletteQueryProvider].
final filteredPaletteCommandsProvider = Provider<List<PaletteCommand>>((ref) {
  final commands = ref.watch(paletteCommandsProvider);
  final query = ref.watch(paletteQueryProvider);
  return rankCommands<PaletteCommand>(
    commands,
    query,
    (cmd) => '${cmd.label} ${cmd.subtitle ?? ''}'.trim(),
  );
});

/// Static navigation commands (P9-04). Icons are assigned in the presentation layer.
const _navigationCommands = <PaletteNavigate>[
  PaletteNavigate(
    id: 'nav-chat',
    label: 'Chat',
    section: 'Navigation',
    route: '/chat',
  ),
  PaletteNavigate(
    id: 'nav-plugins',
    label: 'Plugins',
    section: 'Navigation',
    route: '/plugins',
  ),
  PaletteNavigate(
    id: 'nav-kanban',
    label: 'Kanban Board',
    section: 'Navigation',
    route: '/plugins/kanban',
  ),
  PaletteNavigate(
    id: 'nav-agents',
    label: 'Agents',
    section: 'Navigation',
    route: '/agents',
  ),
  PaletteNavigate(
    id: 'nav-snapshots',
    label: 'Agent Snapshots',
    section: 'Navigation',
    route: '/agents/snapshots',
  ),
  PaletteNavigate(
    id: 'nav-settings',
    label: 'Settings',
    section: 'Navigation',
    route: '/settings',
  ),
  PaletteNavigate(
    id: 'nav-settings-providers',
    label: 'Settings → Provider Keys',
    section: 'Navigation',
    route: '/settings/providers',
  ),
  PaletteNavigate(
    id: 'nav-settings-agent',
    label: 'Settings → Agent',
    section: 'Navigation',
    route: '/settings/agent',
  ),
  PaletteNavigate(
    id: 'nav-settings-tools',
    label: 'Settings → Tools',
    section: 'Navigation',
    route: '/settings/tools',
  ),
  PaletteNavigate(
    id: 'nav-settings-mcp',
    label: 'Settings → MCP',
    section: 'Navigation',
    route: '/settings/mcp',
  ),
  PaletteNavigate(
    id: 'nav-settings-config',
    label: 'Settings → Config Editor',
    section: 'Navigation',
    route: '/settings/config',
  ),
  PaletteNavigate(
    id: 'nav-settings-health',
    label: 'Settings → Health',
    section: 'Navigation',
    route: '/settings/health',
  ),
  PaletteNavigate(
    id: 'nav-settings-projects',
    label: 'Settings → Projects',
    section: 'Navigation',
    route: '/settings/projects',
  ),
  PaletteNavigate(
    id: 'nav-settings-cron',
    label: 'Settings → Cron',
    section: 'Navigation',
    route: '/settings/cron',
  ),
  PaletteNavigate(
    id: 'nav-settings-background',
    label: 'Settings → Background',
    section: 'Navigation',
    route: '/settings/background',
  ),
  PaletteNavigate(
    id: 'nav-settings-processes',
    label: 'Settings → Processes',
    section: 'Navigation',
    route: '/settings/processes',
  ),
  PaletteNavigate(
    id: 'nav-settings-skills',
    label: 'Settings → Skills',
    section: 'Navigation',
    route: '/settings/skills',
  ),
  PaletteNavigate(
    id: 'nav-settings-boards',
    label: 'Settings → Kanban Boards',
    section: 'Navigation',
    route: '/settings/boards',
  ),
  PaletteNavigate(
    id: 'nav-settings-fleet',
    label: 'Settings → Kanban Fleet',
    section: 'Navigation',
    route: '/settings/fleet',
  ),
  PaletteNavigate(
    id: 'nav-settings-orchestration',
    label: 'Settings → Kanban Orchestration',
    section: 'Navigation',
    route: '/settings/orchestration',
  ),
  PaletteNavigate(
    id: 'nav-settings-journey',
    label: 'Settings → Journey',
    section: 'Navigation',
    route: '/settings/journey',
  ),
  PaletteNavigate(
    id: 'nav-settings-insights',
    label: 'Settings → Insights',
    section: 'Navigation',
    route: '/settings/insights',
  ),
  PaletteNavigate(
    id: 'nav-settings-facts',
    label: 'Settings → Project Facts',
    section: 'Navigation',
    route: '/settings/facts',
  ),
  PaletteNavigate(
    id: 'nav-settings-checkpoints',
    label: 'Settings → Checkpoints',
    section: 'Navigation',
    route: '/settings/checkpoints',
  ),
  PaletteNavigate(
    id: 'nav-settings-billing',
    label: 'Settings → Billing',
    section: 'Navigation',
    route: '/settings/billing',
  ),
];
