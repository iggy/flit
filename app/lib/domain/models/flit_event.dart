/// Events from a flit session's event log (flit.v1 `Event`), as the app
/// sees them. Every event carries its per-session sequence number; the log
/// has no gaps, so a client resumes by attaching from `lastSeq + 1`.
library;

import 'package:flit/domain/models/flit_session.dart';

/// One entry in a session's event log.
sealed class FlitEvent {
  const FlitEvent({required this.seq, this.time});

  /// Per-session sequence number, starting at 1.
  final int seq;
  final DateTime? time;
}

/// Who wrote a message.
enum FlitRole { user, assistant, unknown }

/// A message opened; its text follows as [FlitTextDelta]s.
final class FlitMessageStarted extends FlitEvent {
  const FlitMessageStarted({
    required super.seq,
    required this.messageId,
    required this.role,
    this.provider = '',
    this.model = '',
    super.time,
  });

  final String messageId;
  final FlitRole role;

  /// For assistant messages, the model writing it.
  final String provider;
  final String model;
}

final class FlitTextDelta extends FlitEvent {
  const FlitTextDelta({
    required super.seq,
    required this.messageId,
    required this.text,
    super.time,
  });

  final String messageId;
  final String text;
}

final class FlitReasoningDelta extends FlitEvent {
  const FlitReasoningDelta({
    required super.seq,
    required this.messageId,
    required this.text,
    super.time,
  });

  final String messageId;
  final String text;
}

/// A message closed; [text] is its full text.
final class FlitMessageDone extends FlitEvent {
  const FlitMessageDone({
    required super.seq,
    required this.messageId,
    required this.text,
    required this.reasoning,
    required this.finishReason,
    super.time,
  });

  final String messageId;
  final String text;
  final String reasoning;

  /// "stop", "tool_calls", "length", "interrupted", "error", …
  final String finishReason;
}

final class FlitToolCallStarted extends FlitEvent {
  const FlitToolCallStarted({
    required super.seq,
    required this.messageId,
    required this.toolCallId,
    required this.name,
    required this.arguments,
    super.time,
  });

  final String messageId;
  final String toolCallId;
  final String name;

  /// The arguments as the JSON text the model produced.
  final String arguments;
}

/// Live output from a running tool.
final class FlitToolOutput extends FlitEvent {
  const FlitToolOutput({
    required super.seq,
    required this.toolCallId,
    required this.text,
    super.time,
  });

  final String toolCallId;
  final String text;
}

final class FlitToolCallDone extends FlitEvent {
  const FlitToolCallDone({
    required super.seq,
    required this.toolCallId,
    required this.result,
    required this.isError,
    required this.truncated,
    super.time,
  });

  final String toolCallId;

  /// What the model saw, after truncation.
  final String result;
  final bool isError;
  final bool truncated;
}

/// The agent waits for someone to allow or deny something.
final class FlitPromptRequested extends FlitEvent {
  const FlitPromptRequested({
    required super.seq,
    required this.promptId,
    required this.toolCallId,
    required this.title,
    required this.detail,
    this.sessionPatterns = const <String>[],
    this.safetyReason = '',
    super.time,
  });

  final String promptId;
  final String toolCallId;
  final String title;
  final String detail;

  /// What "allow for this session" would allow, e.g. `go test *`; empty
  /// when it isn't offered.
  final List<String> sessionPatterns;

  /// Why the server's safety check wants the user to decide; empty when it
  /// didn't run.
  final String safetyReason;
}

/// A prompt was answered (by [client]) or resolved by the server.
final class FlitPromptResolved extends FlitEvent {
  const FlitPromptResolved({
    required super.seq,
    required this.promptId,
    required this.allowed,
    required this.client,
    required this.reason,
    this.forSession = false,
    super.time,
  });

  final String promptId;
  final bool allowed;

  /// Allowed for the rest of the session, not just this once.
  final bool forSession;

  /// The answering client's name; empty when the server resolved it.
  final String client;
  final String reason;
}

final class FlitTaskStateChanged extends FlitEvent {
  const FlitTaskStateChanged({
    required super.seq,
    required this.state,
    required this.reason,
    super.time,
  });

  final FlitTaskState state;
  final String reason;
}

final class FlitModelChanged extends FlitEvent {
  const FlitModelChanged({
    required super.seq,
    required this.provider,
    required this.model,
    this.effort = '',
    this.contextLength = 0,
    super.time,
  });

  final String provider;
  final String model;

  /// Reasoning effort; empty means the model's default.
  final String effort;

  /// The model's context window; 0 if unknown.
  final int contextLength;
}

/// Token use and speed of one model call.
final class FlitUsage extends FlitEvent {
  const FlitUsage({
    required super.seq,
    required this.messageId,
    required this.inputTokens,
    required this.outputTokens,
    this.contextLength = 0,
    this.timeToFirstTokenMs = 0,
    this.promptTokensPerSecond = 0,
    this.generationTokensPerSecond = 0,
    this.timingSource = '',
    super.time,
  });

  final String messageId;
  final int inputTokens;
  final int outputTokens;

  /// The model's context window; 0 if unknown. Input plus output tokens is
  /// how much of it the call used.
  final int contextLength;
  final int timeToFirstTokenMs;
  final double promptTokensPerSecond;
  final double generationTokensPerSecond;

  /// "llama.cpp" (the server's own timings) or "measured" (timed by flit).
  final String timingSource;
}

enum FlitTodoStatus { pending, inProgress, completed }

/// One entry in the agent's task list.
final class FlitTodo {
  const FlitTodo({required this.content, required this.status});

  final String content;
  final FlitTodoStatus status;

  @override
  bool operator ==(Object other) =>
      other is FlitTodo && other.content == content && other.status == status;

  @override
  int get hashCode => Object.hash(content, status);

  @override
  String toString() => 'FlitTodo(${status.name}: $content)';
}

/// The agent's task list after it changed.
final class FlitTodoUpdated extends FlitEvent {
  const FlitTodoUpdated({required super.seq, required this.items, super.time});

  final List<FlitTodo> items;
}

final class FlitTurnError extends FlitEvent {
  const FlitTurnError({
    required super.seq,
    required this.message,
    required this.canContinue,
    super.time,
  });

  final String message;

  /// True when sending again may work (e.g. a network blip).
  final bool canContinue;
}

/// An event kind this app version doesn't know. Still advances the seq.
final class FlitUnknownEvent extends FlitEvent {
  const FlitUnknownEvent({required super.seq, super.time});
}

/// Someone rated a turn or a model.
final class FlitFeedback extends FlitEvent {
  const FlitFeedback({
    required super.seq,
    required this.target,
    required this.good,
    this.messageId = '',
    this.provider = '',
    this.model = '',
    this.client = '',
    this.note = '',
    super.time,
  });

  final FlitRatingTarget target;
  final bool good;
  final String messageId;
  final String provider;
  final String model;
  final String client;
  final String note;
}

/// The MCP servers enabled for the session changed.
final class FlitMcpServersChanged extends FlitEvent {
  const FlitMcpServersChanged({
    required super.seq,
    required this.enabled,
    super.time,
  });

  final List<String> enabled;
}

/// The session moved to another project.
final class FlitSessionMoved extends FlitEvent {
  const FlitSessionMoved({
    required super.seq,
    required this.projectId,
    super.time,
  });

  final String projectId;
}

/// Yolo mode was turned on or off: every shell command runs unless a deny
/// rule matches.
final class FlitYoloChanged extends FlitEvent {
  const FlitYoloChanged({
    required super.seq,
    required this.yolo,
    this.client = '',
    super.time,
  });

  final bool yolo;
  final String client;
}

/// The safety check's rating of a shell command (flit.v1
/// `PermissionVerdict`).
enum FlitPermissionVerdict {
  /// Runs without asking.
  safe,

  /// The user is asked.
  ask,

  /// Refused.
  block,

  /// The check failed; the user is asked.
  error,
}

/// The server's safety check rated a shell command before it ran.
final class FlitPermissionCheck extends FlitEvent {
  const FlitPermissionCheck({
    required super.seq,
    required this.toolCallId,
    required this.command,
    required this.verdict,
    this.reason = '',
    this.provider = '',
    this.model = '',
    super.time,
  });

  final String toolCallId;
  final String command;
  final FlitPermissionVerdict verdict;
  final String reason;
  final String provider;
  final String model;
}
