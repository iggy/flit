/// One entry of `plugins.list` (wire §13).
final class PluginInfo {
  const PluginInfo({
    required this.name,
    required this.version,
    required this.enabled,
  });

  /// Plugin name, e.g. `kanban`.
  final String name;

  /// Version string; `'?'` when the plugin doesn't report one (wire §13).
  final String version;

  /// Whether the plugin is enabled.
  final bool enabled;

  @override
  bool operator ==(Object other) {
    return other is PluginInfo &&
        other.name == name &&
        other.version == version &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(name, version, enabled);

  @override
  String toString() =>
      'PluginInfo(name: $name, version: $version, enabled: $enabled)';
}

/// Rich plugin detail from `plugins.manage {action:'list'}` (ticket P5-08).
/// Wire returns `status` as a string ("disabled"/"enabled"/"not enabled");
/// activation is derived via [isEnabled].
final class PluginDetail {
  const PluginDetail({
    required this.name,
    required this.version,
    required this.description,
    required this.source,
    required this.status,
  });

  /// Plugin name, e.g. `kanban`.
  final String name;

  /// Version string.
  final String version;

  /// Human-readable description.
  final String description;

  /// Source: "bundled", "user", or "entrypoint".
  final String source;

  /// Activation status: "disabled", "enabled", or "not enabled".
  final String status;

  /// Whether the plugin is enabled (derived from [status]).
  bool get isEnabled => status == 'enabled';

  @override
  bool operator ==(Object other) {
    return other is PluginDetail &&
        other.name == name &&
        other.version == version &&
        other.description == description &&
        other.source == source &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(name, version, description, source, status);

  @override
  String toString() {
    return 'PluginDetail(name: $name, version: $version, '
        'description: $description, source: $source, status: $status)';
  }
}
