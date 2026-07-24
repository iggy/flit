import 'package:hermes/domain/models/plugin_info.dart';

/// Intent-level plugin operations (ticket P1-14).
abstract interface class PluginRepository {
  /// `plugins.list` (wire §13) → every plugin with name, version (`'?'`
  /// fallback), and enabled flag.
  Future<List<PluginInfo>> list();
}
