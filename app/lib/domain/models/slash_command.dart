/// Slash command catalog models
/// (docs/reference/08-agent-transparency-wire-shapes.md §commands.catalog).
library;

/// One slash command entry (e.g. /model, /new).
final class SlashCommand {
  const SlashCommand({
    required this.command,
    required this.description,
    this.category,
  });

  /// Command text, e.g. "/model".
  final String command;

  /// Human-readable description, e.g. "Switch model".
  final String description;

  /// Optional category name, e.g. "Session".
  final String? category;

  @override
  bool operator ==(Object other) {
    return other is SlashCommand &&
        other.command == command &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(command, description, category);

  @override
  String toString() =>
      'SlashCommand(command: $command, description: $description, '
      'category: $category)';
}

/// One category of slash commands (wire §commands.catalog).
final class SlashCategory {
  const SlashCategory({
    required this.name,
    required this.commands,
  });

  /// Category name, e.g. "Session".
  final String name;

  /// Commands in this category.
  final List<SlashCommand> commands;

  @override
  bool operator ==(Object other) {
    return other is SlashCategory &&
        other.name == name &&
        _listEquals(other.commands, commands);
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(commands));

  @override
  String toString() => 'SlashCategory(name: $name, commands: $commands)';
}

/// Full catalog result from `commands.catalog` (P3-01).
final class SlashCatalog {
  const SlashCatalog({
    required this.allCommands,
    required this.categories,
    required this.canon,
    required this.skillCount,
    required this.warning,
  });

  /// All commands, flattened from the wire `pairs` field.
  final List<SlashCommand> allCommands;

  /// Categorized commands (wire `categories`).
  final List<SlashCategory> categories;

  /// Alias→canonical map (wire `canon`, e.g. {"/m": "/model"}).
  final Map<String, String> canon;

  /// Number of discovered skills (wire `skill_count`).
  final int skillCount;

  /// Discovery warning; empty string when no error (wire `warning`).
  final String warning;

  @override
  bool operator ==(Object other) {
    return other is SlashCatalog &&
        _listEquals(other.allCommands, allCommands) &&
        _listEquals(other.categories, categories) &&
        _mapEquals(other.canon, canon) &&
        other.skillCount == skillCount &&
        other.warning == warning;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(allCommands),
    Object.hashAll(categories),
    Object.hashAllUnordered(canon.entries),
    skillCount,
    warning,
  );

  @override
  String toString() => 'SlashCatalog(allCommands: ${allCommands.length}, '
      'categories: ${categories.length}, canon: $canon, '
      'skillCount: $skillCount, warning: $warning)';
}

/// Result of `command.resolve` (P3-01).
final class CommandResolution {
  const CommandResolution({
    required this.canonical,
    required this.description,
    required this.category,
  });

  /// Canonical command name, e.g. "/model".
  final String canonical;

  /// Human-readable description.
  final String description;

  /// Category name.
  final String category;

  @override
  bool operator ==(Object other) {
    return other is CommandResolution &&
        other.canonical == canonical &&
        other.description == description &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(canonical, description, category);

  @override
  String toString() =>
      'CommandResolution(canonical: $canonical, description: $description, '
      'category: $category)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) {
      return false;
    }
  }
  return true;
}
