/// Command dispatch models
/// (docs/reference/08-agent-transparency-wire-shapes.md
/// §command.dispatch, §slash.exec).
library;

/// Discriminated union result of `command.dispatch` (wire type field).
sealed class CommandDispatchResult {
  const CommandDispatchResult();
}

/// `{type: "exec", output}` OR `{type: "plugin", output}` — rendered text.
/// We merge exec+plugin into one class; both carry only `output`.
final class DispatchExec extends CommandDispatchResult {
  const DispatchExec(this.output, {this.isPlugin = false});

  /// Rendered command output.
  final String output;

  /// True if type was "plugin", false if "exec".
  final bool isPlugin;

  @override
  String toString() => 'DispatchExec(output: $output, isPlugin: $isPlugin)';
}

/// `{type: "alias", target}` — command is an alias for another command.
final class DispatchAlias extends CommandDispatchResult {
  const DispatchAlias(this.target);

  /// The target command (e.g. "/model" for alias "/m").
  final String target;

  @override
  String toString() => 'DispatchAlias(target: $target)';
}

/// `{type: "skill", message, name}` — skill invocation result.
final class DispatchSkill extends CommandDispatchResult {
  const DispatchSkill({required this.message, required this.name});

  /// Rendered message text.
  final String message;

  /// Skill name.
  final String name;

  @override
  String toString() => 'DispatchSkill(message: $message, name: $name)';
}

/// `{type: "send", message, notice?}` — submit message as a user turn.
final class DispatchSend extends CommandDispatchResult {
  const DispatchSend({required this.message, this.notice});

  /// Message to submit.
  final String message;

  /// Optional system notice to show first.
  final String? notice;

  @override
  String toString() => 'DispatchSend(message: $message, notice: $notice)';
}

/// `{type: "prefill", message, notice}` — populate composer with message.
final class DispatchPrefill extends CommandDispatchResult {
  const DispatchPrefill({required this.message, required this.notice});

  /// Message to prefill.
  final String message;

  /// System notice to show.
  final String notice;

  @override
  String toString() => 'DispatchPrefill(message: $message, notice: $notice)';
}

/// Defensive fallback for unknown type values.
final class DispatchUnknown extends CommandDispatchResult {
  const DispatchUnknown(this.rawType);

  /// The unrecognized type value.
  final String rawType;

  @override
  String toString() => 'DispatchUnknown(rawType: $rawType)';
}

/// Result of `slash.exec`: either rendered output OR a re-routed dispatch.
sealed class SlashExecResult {
  const SlashExecResult();
}

/// Normal `slash.exec` result: `{output, warning?}`.
final class SlashExecOutput extends SlashExecResult {
  const SlashExecOutput({required this.output, this.warning});

  /// Rendered output text.
  final String output;

  /// Optional warning message.
  final String? warning;

  @override
  String toString() => 'SlashExecOutput(output: $output, warning: $warning)';
}

/// Re-routed `slash.exec` result (pending-input/bundle commands):
/// internally dispatched, result is a [CommandDispatchResult].
final class SlashExecDispatch extends SlashExecResult {
  const SlashExecDispatch(this.dispatch);

  /// The dispatched command result.
  final CommandDispatchResult dispatch;

  @override
  String toString() => 'SlashExecDispatch(dispatch: $dispatch)';
}
