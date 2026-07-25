import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flit/domain/models/slash_completion.dart';

/// Slash command operations (tickets P3-01/P3-02/P3-03).
///
/// Method names/params come VERBATIM from
/// docs/reference/08-agent-transparency-wire-shapes.md
/// §commands.catalog, §command.resolve, §complete.slash, §complete.path,
/// §command.dispatch, §slash.exec — never invent protocol.
abstract interface class SlashRepository {
  /// `commands.catalog` (P3-01) → full catalog with pairs, categories,
  /// aliases, skill count, and discovery warning.
  Future<SlashCatalog> catalog();

  /// `command.resolve` (P3-01) → canonical command, description, category.
  /// Unknown command → JSON-RPC error 4011.
  Future<CommandResolution> resolve(String name);

  /// `complete.slash` (P3-02) → completion items + replace_from index.
  /// Cursor assumed at end of [text].
  Future<SlashCompletionResult> completeSlash(String text);

  /// `complete.path` (P3-02) → completion items for @-tokens/paths.
  /// NOTE: no replace_from (unlike completeSlash).
  Future<List<CompletionItem>> completePath(String word);

  /// `command.dispatch` (P3-03) → discriminated union result.
  /// Not-a-quick/plugin/bundle/skill command → JSON-RPC error 4018.
  Future<CommandDispatchResult> dispatch({
    required String name,
    required String arg,
    required String sessionId,
  });

  /// `slash.exec` (P3-03) → rendered output OR re-routed dispatch result.
  /// LONG handler (≥120s timeout). Empty command → error 4004.
  /// Pending-input/bundle commands may internally re-route to
  /// command.dispatch, so result may be [SlashExecDispatch].
  Future<SlashExecResult> exec({
    required String command,
    required String sessionId,
  });
}
