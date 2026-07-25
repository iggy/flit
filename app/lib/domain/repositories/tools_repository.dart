import 'package:flit/domain/models/tool_catalog.dart';

/// Tool catalog and configuration operations (tickets P4-03, P4-04).
///
/// Methods follow the wire protocol exactly: `tools.list`, `toolsets.list`,
/// `tools.show`, `tools.configure`.
abstract interface class ToolsRepository {
  /// `tools.list` — list all toolsets with their tools.
  Future<List<Toolset>> listTools({String? sessionId});

  /// `toolsets.list` — list toolsets without tool details.
  Future<List<Toolset>> listToolsets({String? sessionId});

  /// `tools.show` — show all tools grouped by section.
  Future<ToolsShow> showTools({String? sessionId});

  /// `tools.configure` — enable or disable toolsets by name.
  ///
  /// The [action] must be `"enable"` or `"disable"`.
  /// The [names] list contains the toolset names to configure.
  Future<ToolsConfigureResult> configure({
    required String action,
    required List<String> names,
    String? sessionId,
  });
}
