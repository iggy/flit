/// Domain models for tool catalog and configuration (tickets P4-03, P4-04).
///
/// Wire shapes from gateway protocol (tools.list, toolsets.list, tools.show,
/// tools.configure).
library;

import 'package:flit/domain/models/deep_equals.dart';

/// One toolset entry from `tools.list` or `toolsets.list`.
final class Toolset {
  const Toolset({
    required this.name,
    required this.description,
    required this.toolCount,
    required this.enabled,
    required this.tools,
  });

  /// Wire `name` — toolset name (e.g. `mcp:filesystem`).
  final String name;

  /// Wire `description` — human-readable description.
  final String description;

  /// Wire `tool_count` — number of tools in this toolset.
  final int toolCount;

  /// Wire `enabled` — whether this toolset is currently enabled.
  final bool enabled;

  /// Wire `tools` — list of tool names (present in `tools.list`, absent in
  /// `toolsets.list`). Empty list when absent.
  final List<String> tools;

  @override
  bool operator ==(Object other) {
    return other is Toolset &&
        other.name == name &&
        other.description == description &&
        other.toolCount == toolCount &&
        other.enabled == enabled &&
        deepListEquals(other.tools, tools);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        toolCount,
        enabled,
        Object.hashAll(tools),
      );

  @override
  String toString() {
    return 'Toolset(name: $name, description: $description, '
        'toolCount: $toolCount, enabled: $enabled, tools: $tools)';
  }
}

/// Result of `tools.show` — tools grouped by section.
final class ToolsShow {
  const ToolsShow({
    required this.sections,
    required this.total,
  });

  /// Wire `sections` — list of tool sections.
  final List<ToolSection> sections;

  /// Wire `total` — total tool count across all sections.
  final int total;

  @override
  bool operator ==(Object other) {
    return other is ToolsShow &&
        deepListEquals(other.sections, sections) &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(sections),
        total,
      );

  @override
  String toString() {
    return 'ToolsShow(sections: $sections, total: $total)';
  }
}

/// One section entry from `tools.show`.
final class ToolSection {
  const ToolSection({
    required this.name,
    required this.tools,
  });

  /// Wire `name` — section name.
  final String name;

  /// Wire `tools` — list of tools in this section.
  final List<ToolInfo> tools;

  @override
  bool operator ==(Object other) {
    return other is ToolSection &&
        other.name == name &&
        deepListEquals(other.tools, tools);
  }

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAll(tools),
      );

  @override
  String toString() {
    return 'ToolSection(name: $name, tools: $tools)';
  }
}

/// One tool entry from `tools.show`.
final class ToolInfo {
  const ToolInfo({
    required this.name,
    required this.description,
  });

  /// Wire `name` — tool name.
  final String name;

  /// Wire `description` — tool description.
  final String description;

  @override
  bool operator ==(Object other) {
    return other is ToolInfo &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() {
    return 'ToolInfo(name: $name, description: $description)';
  }
}

/// Result of `tools.configure` — which toolsets changed.
final class ToolsConfigureResult {
  const ToolsConfigureResult({
    required this.changed,
    required this.enabledToolsets,
    required this.missingServers,
    required this.reset,
    required this.unknown,
  });

  /// Wire `changed` — list of toolset names that were changed.
  final List<String> changed;

  /// Wire `enabled_toolsets` — list of currently enabled toolset names.
  final List<String> enabledToolsets;

  /// Wire `missing_servers` — list of servers that are not running.
  final List<String> missingServers;

  /// Wire `reset` — whether the configuration was reset.
  final bool reset;

  /// Wire `unknown` — list of unknown toolset names that were requested.
  final List<String> unknown;

  @override
  bool operator ==(Object other) {
    return other is ToolsConfigureResult &&
        deepListEquals(other.changed, changed) &&
        deepListEquals(other.enabledToolsets, enabledToolsets) &&
        deepListEquals(other.missingServers, missingServers) &&
        other.reset == reset &&
        deepListEquals(other.unknown, unknown);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(changed),
        Object.hashAll(enabledToolsets),
        Object.hashAll(missingServers),
        reset,
        Object.hashAll(unknown),
      );

  @override
  String toString() {
    return 'ToolsConfigureResult(changed: $changed, '
        'enabledToolsets: $enabledToolsets, '
        'missingServers: $missingServers, '
        'reset: $reset, unknown: $unknown)';
  }
}
