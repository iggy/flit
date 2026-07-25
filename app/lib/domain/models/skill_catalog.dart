import 'package:flit/domain/models/deep_equals.dart';

/// Skill catalog from `skills.manage {action:'list'}` (P5-09).
/// Wire returns `{skills: {category: [name-str]}}` — a map of category to
/// skill names.
final class SkillCatalog {
  const SkillCatalog({required this.groups});

  /// Skill groups, each holding a category and skill names within it.
  final List<SkillGroup> groups;

  @override
  bool operator ==(Object other) {
    return other is SkillCatalog && deepListEquals(other.groups, groups);
  }

  @override
  int get hashCode => Object.hashAll(groups);

  @override
  String toString() => 'SkillCatalog(groups: $groups)';
}

/// One category of skills.
final class SkillGroup {
  const SkillGroup({required this.category, required this.names});

  /// Category name, e.g. "built-in" or "project".
  final String category;

  /// Skill names within this category.
  final List<String> names;

  @override
  bool operator ==(Object other) {
    return other is SkillGroup &&
        other.category == category &&
        deepListEquals(other.names, names);
  }

  @override
  int get hashCode => Object.hash(category, Object.hashAll(names));

  @override
  String toString() => 'SkillGroup(category: $category, names: $names)';
}

/// One item from `skills.manage {action:'browse'}` (P5-09).
final class SkillBrowseItem {
  const SkillBrowseItem({
    required this.name,
    required this.description,
    required this.source,
    required this.trust,
    required this.identifier,
  });

  final String name;
  final String description;
  final String source;
  final String trust;
  final String identifier;

  @override
  bool operator ==(Object other) {
    return other is SkillBrowseItem &&
        other.name == name &&
        other.description == description &&
        other.source == source &&
        other.trust == trust &&
        other.identifier == identifier;
  }

  @override
  int get hashCode => Object.hash(name, description, source, trust, identifier);

  @override
  String toString() {
    return 'SkillBrowseItem(name: $name, description: $description, '
        'source: $source, trust: $trust, identifier: $identifier)';
  }
}

/// Result from `skills.manage {action:'browse'}` (P5-09).
final class SkillBrowseResult {
  const SkillBrowseResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<SkillBrowseItem> items;
  final int page;
  final int totalPages;
  final int total;

  @override
  bool operator ==(Object other) {
    return other is SkillBrowseResult &&
        deepListEquals(other.items, items) &&
        other.page == page &&
        other.totalPages == totalPages &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), page, totalPages, total);

  @override
  String toString() {
    return 'SkillBrowseResult(items: $items, page: $page, '
        'totalPages: $totalPages, total: $total)';
  }
}

/// One skill change from `skills.reload` (P5-09).
final class SkillChange {
  const SkillChange({required this.name, required this.description});

  final String name;
  final String description;

  @override
  bool operator ==(Object other) {
    return other is SkillChange &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() => 'SkillChange(name: $name, description: $description)';
}

/// Result from `skills.reload` (P5-09).
final class SkillReloadResult {
  const SkillReloadResult({
    required this.output,
    required this.added,
    required this.removed,
    required this.unchanged,
    required this.total,
    required this.commands,
  });

  final String output;
  final List<SkillChange> added;
  final List<SkillChange> removed;
  final List<String> unchanged;
  final int total;
  final int commands;

  @override
  bool operator ==(Object other) {
    return other is SkillReloadResult &&
        other.output == output &&
        deepListEquals(other.added, added) &&
        deepListEquals(other.removed, removed) &&
        deepListEquals(other.unchanged, unchanged) &&
        other.total == total &&
        other.commands == commands;
  }

  @override
  int get hashCode => Object.hash(
    output,
    Object.hashAll(added),
    Object.hashAll(removed),
    Object.hashAll(unchanged),
    total,
    commands,
  );

  @override
  String toString() {
    return 'SkillReloadResult(output: $output, added: $added, '
        'removed: $removed, unchanged: $unchanged, total: $total, '
        'commands: $commands)';
  }
}
