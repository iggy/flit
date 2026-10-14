/// The flit event fold: a PURE reducer from a flit session's event log
/// (flit.v1 `Event`s, as domain [FlitEvent]s) to the app's chat models.
///
/// Unlike the Hermes fold, everything comes from the log — user messages
/// too, whichever client sent them — so every attached client converges on
/// the same view. Events at or below [FlitFoldState.lastSeq] are ignored,
/// which makes replays after a reconnect idempotent.
library;

import 'dart:convert';

import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/domain/models/usage.dart';

/// Live tool output kept per tool call while it runs (the tail is kept).
const int _liveOutputCap = 16 * 1024;

/// A prompt the agent is waiting on. Any attached client may answer it; it
/// disappears from every client when the server records the answer.
final class FlitPendingPrompt {
  const FlitPendingPrompt({
    required this.promptId,
    required this.toolCallId,
    required this.title,
    required this.detail,
  });

  final String promptId;
  final String toolCallId;
  final String title;
  final String detail;

  @override
  bool operator ==(Object other) {
    return other is FlitPendingPrompt &&
        other.promptId == promptId &&
        other.toolCallId == toolCallId &&
        other.title == title &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(promptId, toolCallId, title, detail);

  @override
  String toString() => 'FlitPendingPrompt($promptId, $title: $detail)';
}

/// How fast the last model call was.
final class FlitSpeed {
  const FlitSpeed({
    required this.timeToFirstTokenMs,
    required this.promptTokensPerSecond,
    required this.generationTokensPerSecond,
    required this.source,
  });

  final int timeToFirstTokenMs;
  final double promptTokensPerSecond;
  final double generationTokensPerSecond;

  /// "llama.cpp" or "measured".
  final String source;

  @override
  bool operator ==(Object other) =>
      other is FlitSpeed &&
      other.timeToFirstTokenMs == timeToFirstTokenMs &&
      other.promptTokensPerSecond == promptTokensPerSecond &&
      other.generationTokensPerSecond == generationTokensPerSecond &&
      other.source == source;

  @override
  int get hashCode => Object.hash(
    timeToFirstTokenMs,
    promptTokensPerSecond,
    generationTokensPerSecond,
    source,
  );
}

/// The folded view of one flit session.
final class FlitFoldState {
  const FlitFoldState({
    this.messages = const <ChatMessage>[],
    this.prompts = const <FlitPendingPrompt>[],
    this.taskState = FlitTaskState.idle,
    this.taskReason = '',
    this.provider = '',
    this.model = '',
    this.lastSeq = 0,
    this.messageIndex = const <String, int>{},
    this.toolMessage = const <String, int>{},
    this.effort,
    this.contextTokens = 0,
    this.contextLength = 0,
    this.todos = const <FlitTodo>[],
    this.speed,
  });

  /// The reasoning effort, once a ModelChanged event says so (null until
  /// then: fall back to the session's).
  final String? effort;

  /// Context use after the last model call, and the window (0 if unknown).
  final int contextTokens;
  final int contextLength;

  /// The agent's task list (todo tool), latest version.
  final List<FlitTodo> todos;

  /// Speed of the last model call, if reported.
  final FlitSpeed? speed;

  /// The conversation, in log order.
  final List<ChatMessage> messages;

  /// Prompts still waiting for an answer, in arrival order.
  final List<FlitPendingPrompt> prompts;

  final FlitTaskState taskState;

  /// Why the task state last changed, e.g. "interrupted".
  final String taskReason;

  /// The model, once a ModelChanged event says so. Callers fall back to the
  /// session's own provider/model while these are empty.
  final String provider;
  final String model;

  /// The newest event folded in; resume attaching from lastSeq + 1.
  final int lastSeq;

  /// flit message id → index in [messages].
  final Map<String, int> messageIndex;

  /// tool call id → index in [messages] of the message that made the call.
  final Map<String, int> toolMessage;

  /// Whether a turn is running (including waiting on a prompt).
  bool get busy =>
      taskState == FlitTaskState.working || taskState == FlitTaskState.waiting;

  FlitFoldState copyWith({
    List<ChatMessage>? messages,
    List<FlitPendingPrompt>? prompts,
    FlitTaskState? taskState,
    String? taskReason,
    String? provider,
    String? model,
    int? lastSeq,
    Map<String, int>? messageIndex,
    Map<String, int>? toolMessage,
    String? effort,
    int? contextTokens,
    int? contextLength,
    List<FlitTodo>? todos,
    FlitSpeed? speed,
  }) {
    return FlitFoldState(
      messages: messages ?? this.messages,
      prompts: prompts ?? this.prompts,
      taskState: taskState ?? this.taskState,
      taskReason: taskReason ?? this.taskReason,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      lastSeq: lastSeq ?? this.lastSeq,
      messageIndex: messageIndex ?? this.messageIndex,
      toolMessage: toolMessage ?? this.toolMessage,
      effort: effort ?? this.effort,
      contextTokens: contextTokens ?? this.contextTokens,
      contextLength: contextLength ?? this.contextLength,
      todos: todos ?? this.todos,
      speed: speed ?? this.speed,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlitFoldState &&
        deepListEquals(other.messages, messages) &&
        deepListEquals(other.prompts, prompts) &&
        other.taskState == taskState &&
        other.taskReason == taskReason &&
        other.provider == provider &&
        other.model == model &&
        other.lastSeq == lastSeq &&
        other.effort == effort &&
        other.contextTokens == contextTokens &&
        other.contextLength == contextLength &&
        deepListEquals(other.todos, todos) &&
        other.speed == speed;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(messages),
    Object.hashAll(prompts),
    taskState,
    taskReason,
    provider,
    model,
    lastSeq,
    effort,
    contextTokens,
    contextLength,
    Object.hashAll(todos),
    speed,
  );

  @override
  String toString() =>
      'FlitFoldState(lastSeq: $lastSeq, task: ${taskState.name}, '
      'messages: ${messages.length}, prompts: $prompts)';
}

/// Folds [events] in order.
FlitFoldState foldFlitEvents(FlitFoldState state, Iterable<FlitEvent> events) {
  var next = state;
  for (final event in events) {
    next = foldFlitEvent(next, event);
  }
  return next;
}

/// Folds one event. Never throws. Events already folded (seq <= lastSeq)
/// leave the state unchanged.
FlitFoldState foldFlitEvent(FlitFoldState state, FlitEvent event) {
  if (event.seq <= state.lastSeq) {
    return state;
  }
  final s = state.copyWith(lastSeq: event.seq);
  return switch (event) {
    FlitMessageStarted() => _started(s, event),
    FlitTextDelta() => _updateMessage(
      s,
      event.messageId,
      (m) => m.copyWith(text: m.text + event.text),
    ),
    FlitReasoningDelta() => _updateMessage(
      s,
      event.messageId,
      (m) => m.copyWith(
        reasoning: (m.reasoning ?? '') + event.text,
        reasoningStreaming: true,
      ),
    ),
    FlitMessageDone() => _done(s, event),
    FlitToolCallStarted() => _toolStarted(s, event),
    FlitToolOutput() => _updateTool(s, event.toolCallId, (t) {
      final live =
          '${t.result is String ? t.result as String : ''}${event.text}';
      return t.copyWith(
        result: live.length > _liveOutputCap
            ? live.substring(live.length - _liveOutputCap)
            : live,
      );
    }),
    FlitToolCallDone() => _updateTool(
      s,
      event.toolCallId,
      (t) => ToolCall(
        id: t.id,
        name: t.name,
        context: t.context,
        status: event.isError ? ToolCallStatus.error : ToolCallStatus.done,
        result: event.result,
        summary: event.truncated ? 'output shortened' : null,
      ),
    ),
    FlitPromptRequested() => s.copyWith(
      prompts: <FlitPendingPrompt>[
        ...s.prompts.where((p) => p.promptId != event.promptId),
        FlitPendingPrompt(
          promptId: event.promptId,
          toolCallId: event.toolCallId,
          title: event.title,
          detail: event.detail,
        ),
      ],
    ),
    FlitPromptResolved() => s.copyWith(
      prompts: s.prompts.where((p) => p.promptId != event.promptId).toList(),
    ),
    FlitTaskStateChanged() => s.copyWith(
      taskState: event.state,
      taskReason: event.reason,
      // A finished turn has nothing left to ask.
      prompts:
          event.state == FlitTaskState.working ||
              event.state == FlitTaskState.waiting
          ? s.prompts
          : const <FlitPendingPrompt>[],
    ),
    FlitModelChanged() => s.copyWith(
      provider: event.provider,
      model: event.model,
      effort: event.effort,
      contextLength: event.contextLength,
    ),
    FlitUsage() => _usage(s, event),
    FlitTodoUpdated() => s.copyWith(todos: event.items),
    FlitTurnError() => s.copyWith(
      messages: <ChatMessage>[
        ...s.messages,
        ChatMessage(
          role: MessageRole.system,
          text: event.canContinue
              ? '${event.message}\n\nYou can send another message to try again.'
              : event.message,
          terminalStatus: MessageTerminalStatus.error,
          timestamp: event.time,
        ),
      ],
    ),
    FlitUnknownEvent() => s,
  };
}

FlitFoldState _usage(FlitFoldState s, FlitUsage e) {
  final withUsage = _updateMessage(
    s,
    e.messageId,
    (m) => m.copyWith(
      usage: Usage(input: e.inputTokens, output: e.outputTokens),
    ),
  );
  return withUsage.copyWith(
    contextTokens: e.inputTokens + e.outputTokens,
    contextLength: e.contextLength > 0 ? e.contextLength : s.contextLength,
    speed: e.timingSource.isEmpty
        ? null
        : FlitSpeed(
            timeToFirstTokenMs: e.timeToFirstTokenMs,
            promptTokensPerSecond: e.promptTokensPerSecond,
            generationTokensPerSecond: e.generationTokensPerSecond,
            source: e.timingSource,
          ),
  );
}

FlitFoldState _started(FlitFoldState s, FlitMessageStarted e) {
  final role = switch (e.role) {
    FlitRole.user => MessageRole.user,
    FlitRole.assistant || FlitRole.unknown => MessageRole.assistant,
  };
  return s.copyWith(
    messages: <ChatMessage>[
      ...s.messages,
      ChatMessage(
        role: role,
        text: '',
        streaming: role == MessageRole.assistant,
        timestamp: e.time,
      ),
    ],
    messageIndex: <String, int>{
      ...s.messageIndex,
      e.messageId: s.messages.length,
    },
  );
}

FlitFoldState _done(FlitFoldState s, FlitMessageDone e) {
  return _updateMessage(s, e.messageId, (m) {
    final assistant = m.role == MessageRole.assistant;
    return m.copyWith(
      text: e.text,
      reasoning: e.reasoning.isNotEmpty ? e.reasoning : m.reasoning,
      reasoningStreaming: false,
      streaming: false,
      terminalStatus: !assistant
          ? MessageTerminalStatus.none
          : switch (e.finishReason) {
              'interrupted' => MessageTerminalStatus.interrupted,
              'error' => MessageTerminalStatus.error,
              _ => MessageTerminalStatus.complete,
            },
    );
  });
}

FlitFoldState _toolStarted(FlitFoldState s, FlitToolCallStarted e) {
  final index = s.messageIndex[e.messageId];
  if (index == null) {
    return s;
  }
  final message = s.messages[index];
  final tool = ToolCall(
    id: e.toolCallId,
    name: e.name,
    context: toolContext(e.name, e.arguments),
  );
  final messages = <ChatMessage>[...s.messages];
  messages[index] = message.copyWith(
    toolCalls: <ToolCall>[...message.toolCalls, tool],
  );
  return s.copyWith(
    messages: messages,
    toolMessage: <String, int>{...s.toolMessage, e.toolCallId: index},
  );
}

FlitFoldState _updateMessage(
  FlitFoldState s,
  String messageId,
  ChatMessage Function(ChatMessage) update,
) {
  final index = s.messageIndex[messageId];
  if (index == null) {
    return s;
  }
  final messages = <ChatMessage>[...s.messages];
  messages[index] = update(messages[index]);
  return s.copyWith(messages: messages);
}

FlitFoldState _updateTool(
  FlitFoldState s,
  String toolCallId,
  ToolCall Function(ToolCall) update,
) {
  final index = s.toolMessage[toolCallId];
  if (index == null) {
    return s;
  }
  final message = s.messages[index];
  final tools = <ToolCall>[
    for (final t in message.toolCalls) t.id == toolCallId ? update(t) : t,
  ];
  final messages = <ChatMessage>[...s.messages];
  messages[index] = message.copyWith(toolCalls: tools);
  return s.copyWith(messages: messages);
}

/// A one-line summary of a tool call's arguments for its card: the command
/// for shell, the path or pattern for file tools.
String? toolContext(String name, String arguments) {
  Object? decoded;
  try {
    decoded = jsonDecode(arguments);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) {
    return null;
  }
  String? str(String key) {
    final v = decoded is Map ? decoded[key] : null;
    return v is String && v.isNotEmpty ? v : null;
  }

  return switch (name) {
    'shell' => str('command'),
    'grep' => [str('pattern'), str('path')].whereType<String>().join(' in '),
    'list' => str('path') ?? '.',
    _ => str('path'),
  };
}
