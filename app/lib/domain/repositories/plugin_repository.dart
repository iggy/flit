import 'package:flit/domain/models/plugin_info.dart';

/// Intent-level plugin operations (ticket P1-14, P5-08).
abstract interface class PluginRepository {
  /// `plugins.list` (wire §13) → every plugin with name, version (`'?'`
  /// fallback), and enabled flag.
  Future<List<PluginInfo>> list();

  /// `plugins.manage {action:'list'}` (P5-08) → rich plugin details with
  /// description, source, and status.
  Future<List<PluginDetail>> manageList();

  /// `plugins.manage {action:'toggle', name, enable}` (P5-08) → the refreshed
  /// plugin detail row, or null if the plugin was not found.
  Future<PluginDetail?> toggle(String name, bool enable);
}
