/// Wire DTOs for slash command RPCs
/// (docs/reference/08-agent-transparency-wire-shapes.md §commands.catalog,
/// §command.resolve, §complete.slash, §complete.path, §command.dispatch,
/// §slash.exec).
///
/// Hand-written fromJson due to awkward shapes (pairs as 2-element arrays,
/// discriminated unions). No @JsonSerializable, no .g.dart.
library;

import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flit/domain/models/slash_completion.dart';

/// `commands.catalog` result DTO (P3-01).
class CommandsCatalogDto {
  const CommandsCatalogDto({
    this.pairs = const <List<String>>[],
    this.sub = const <String, List<String>>{},
    this.canon = const <String, String>{},
    this.categories = const <Map<String, dynamic>>[],
    this.skillCount = 0,
    this.warning = '',
  });

  factory CommandsCatalogDto.fromJson(Map<String, dynamic> json) {
    final pairs = _asPairs(json['pairs']);
    final sub = _asStringMapOfStringList(json['sub']);
    final canon = _asStringMap(json['canon']);
    final categories = _asMaps(json['categories']);
    final skillCount = _asInt(json['skill_count']);
    final warning = _asString(json['warning']);
    return CommandsCatalogDto(
      pairs: pairs,
      sub: sub,
      canon: canon,
      categories: categories,
      skillCount: skillCount,
      warning: warning,
    );
  }

  final List<List<String>> pairs;
  final Map<String, List<String>> sub;
  final Map<String, String> canon;
  final List<Map<String, dynamic>> categories;
  final int skillCount;
  final String warning;

  SlashCatalog toDomain() {
    // Build all commands from pairs.
    final allCommands = <SlashCommand>[];
    for (final p in pairs) {
      if (p.length >= 2) {
        allCommands.add(SlashCommand(command: p[0], description: p[1]));
      }
    }

    // Build categorized commands.
    final cats = <SlashCategory>[];
    for (final cat in categories) {
      final name = _asString(cat['name']);
      final catPairs = _asPairs(cat['pairs']);
      final commands = <SlashCommand>[];
      for (final p in catPairs) {
        if (p.length >= 2) {
          commands.add(
            SlashCommand(command: p[0], description: p[1], category: name),
          );
        }
      }
      cats.add(SlashCategory(name: name, commands: commands));
    }

    return SlashCatalog(
      allCommands: allCommands,
      categories: cats,
      canon: canon,
      skillCount: skillCount,
      warning: warning,
    );
  }
}

/// `command.resolve` result DTO (P3-01).
class CommandResolveDto {
  const CommandResolveDto({
    this.canonical = '',
    this.description = '',
    this.category = '',
  });

  factory CommandResolveDto.fromJson(Map<String, dynamic> json) {
    return CommandResolveDto(
      canonical: _asString(json['canonical']),
      description: _asString(json['description']),
      category: _asString(json['category']),
    );
  }

  final String canonical;
  final String description;
  final String category;

  CommandResolution toDomain() {
    return CommandResolution(
      canonical: canonical,
      description: description,
      category: category,
    );
  }
}

/// `complete.slash` result DTO (P3-02).
class CompleteSlashDto {
  const CompleteSlashDto({
    this.items = const <Map<String, dynamic>>[],
    this.replaceFrom = 0,
  });

  factory CompleteSlashDto.fromJson(Map<String, dynamic> json) {
    return CompleteSlashDto(
      items: _asMaps(json['items']),
      replaceFrom: _asInt(json['replace_from']),
    );
  }

  final List<Map<String, dynamic>> items;
  final int replaceFrom;

  SlashCompletionResult toDomain() {
    final completionItems = items.map((item) {
      return CompletionItem(
        text: _asString(item['text']),
        display: _asString(item['display']),
        meta: _asString(item['meta']),
      );
    }).toList();
    return SlashCompletionResult(
      items: completionItems,
      replaceFrom: replaceFrom,
    );
  }
}

/// `complete.path` result DTO (P3-02).
class CompletePathDto {
  const CompletePathDto({this.items = const <Map<String, dynamic>>[]});

  factory CompletePathDto.fromJson(Map<String, dynamic> json) {
    return CompletePathDto(items: _asMaps(json['items']));
  }

  final List<Map<String, dynamic>> items;

  List<CompletionItem> toDomain() {
    return items.map((item) {
      return CompletionItem(
        text: _asString(item['text']),
        display: _asString(item['display']),
        meta: _asString(item['meta']),
      );
    }).toList();
  }
}

/// `command.dispatch` result DTO (P3-03) — discriminated union on `type`.
class CommandDispatchDto {
  const CommandDispatchDto(this.json);

  factory CommandDispatchDto.fromJson(Map<String, dynamic> json) {
    return CommandDispatchDto(json);
  }

  final Map<String, dynamic> json;

  CommandDispatchResult toDomain() {
    final type = _asString(json['type']);
    switch (type) {
      case 'exec':
        return DispatchExec(_asString(json['output']));
      case 'plugin':
        return DispatchExec(_asString(json['output']), isPlugin: true);
      case 'alias':
        return DispatchAlias(_asString(json['target']));
      case 'skill':
        return DispatchSkill(
          message: _asString(json['message']),
          name: _asString(json['name']),
        );
      case 'send':
        return DispatchSend(
          message: _asString(json['message']),
          notice: json['notice'] as String?,
        );
      case 'prefill':
        return DispatchPrefill(
          message: _asString(json['message']),
          notice: _asString(json['notice']),
        );
      default:
        return DispatchUnknown(type);
    }
  }
}

/// `slash.exec` result DTO (P3-03) — either {output, warning?} OR a
/// re-routed command.dispatch union.
class SlashExecDto {
  const SlashExecDto(this.json);

  factory SlashExecDto.fromJson(Map<String, dynamic> json) {
    return SlashExecDto(json);
  }

  final Map<String, dynamic> json;

  SlashExecResult toDomain() {
    // If there's a 'type' field, it's a re-routed dispatch.
    if (json.containsKey('type')) {
      final dispatch = CommandDispatchDto(json).toDomain();
      return SlashExecDispatch(dispatch);
    }
    // Otherwise normal output result.
    return SlashExecOutput(
      output: _asString(json['output']),
      warning: json['warning'] as String?,
    );
  }
}

// --- Defensive parsing helpers ---

String _asString(dynamic value) => value is String ? value : '';

int _asInt(dynamic value) => value is int ? value : 0;

List<List<String>> _asPairs(dynamic value) {
  if (value is! List) {
    return const <List<String>>[];
  }
  final result = <List<String>>[];
  for (final item in value) {
    if (item is List && item.length >= 2) {
      final pair = <String>[];
      for (final element in item) {
        if (element is String) {
          pair.add(element);
        }
      }
      if (pair.length >= 2) {
        result.add(pair);
      }
    }
  }
  return result;
}

Map<String, String> _asStringMap(dynamic value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key is String && entry.value is String) {
      result[entry.key as String] = entry.value as String;
    }
  }
  return result;
}

Map<String, List<String>> _asStringMapOfStringList(dynamic value) {
  if (value is! Map) {
    return const <String, List<String>>{};
  }
  final result = <String, List<String>>{};
  for (final entry in value.entries) {
    if (entry.key is String && entry.value is List) {
      final strings = <String>[];
      for (final item in entry.value as List) {
        if (item is String) {
          strings.add(item);
        }
      }
      result[entry.key as String] = strings;
    }
  }
  return result;
}

List<Map<String, dynamic>> _asMaps(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  final result = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      result.add(item);
    }
  }
  return result;
}
