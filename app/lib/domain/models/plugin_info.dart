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
