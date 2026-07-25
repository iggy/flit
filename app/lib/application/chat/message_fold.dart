/// The event fold (ticket P1-06): a PURE reducer that folds the typed turn
/// event stream into the chat message list + pending interactive prompts.
///
/// Semantics per docs/reference/04-app-architecture.md "Event → state
/// folding" and 01-gateway-protocol.md §6–§8. Kept pure (no Riverpod, no
/// I/O) so it is trivially unit-testable — this is the highest-value, most
/// bug-prone code in the app.
library;

import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/interactive_prompt.dart';
import 'package:flit/domain/models/tool_call.dart';

/// Immutable state of one session's chat view: the ordered message list
/// plus the interactive prompts still awaiting an answer.
///
/// Interactive prompts are NOT chat messages (they render inline, out of
/// band) — `approval.request` / `clarify.request` land in [pendingPrompts];
/// removing them once answered is the notifier's job, not the fold's.
final class FoldState {
  const FoldState({
    this.messages = const <ChatMessage>[],
    this.pendingPrompts = const <InteractivePrompt>[],
  });

  /// Ordered conversation: user messages (appended by the composer, not the
  /// fold) and assistant turn messages (appended by the fold).
  final List<ChatMessage> messages;

  /// Blocking prompts the agent is waiting on (protocol §8), in arrival
  /// order.
  final List<InteractivePrompt> pendingPrompts;

  FoldState copyWith({
    List<ChatMessage>? messages,
    List<InteractivePrompt>? pendingPrompts,
  }) {
    return FoldState(
      messages: messages ?? this.messages,
      pendingPrompts: pendingPrompts ?? this.pendingPrompts,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoldState &&
        deepListEquals(other.messages, messages) &&
        deepListEquals(other.pendingPrompts, pendingPrompts);
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(messages), Object.hashAll(pendingPrompts));

  @override
  String toString() =>
      'FoldState(messages: $messages, pendingPrompts: $pendingPrompts)';
}

/// Fold one [TypedGatewayEvent] into [state], returning the next state.
/// NEVER throws; unknown/irrelevant events pass through unchanged.
///
/// Turn-terminal frames are BOTH `message.complete` (any status) and
/// `error` (protocol §6). A terminal message is IMMUTABLE to the fold:
/// anything arriving for a new turn appends a fresh assistant message
/// rather than merging into a finalized one.
FoldState foldGatewayEvent(FoldState state, TypedGatewayEvent event) {
  return switch (event) {
    MessageStart() => _onMessageStart(state),
    MessageDelta() => _onMessageDelta(state, event),
    ToolStart() => _onToolStart(state, event),
    ToolProgress() => _onToolProgress(state, event),
    ToolComplete() => _onToolComplete(state, event),
    MessageComplete() => _onMessageComplete(state, event),
    TurnError() => _onTurnError(state, event),
    ApprovalRequestEvent() => _onApprovalRequest(state, event),
    ClarifyRequestEvent() => _onClarifyRequest(state, event),
    // session.info / status.update / gateway.ready / unknown: no
    // message-list change (pass through).
    SessionInfo() ||
    StatusUpdate() ||
    GatewayReady() ||
    UnknownEvent() => state,
  };
}

/// `message.start` → append a streaming assistant message. Always appends —
/// a new turn NEVER merges into a terminal message.
FoldState _onMessageStart(FoldState state) {
  return state.copyWith(
    messages: <ChatMessage>[
      ...state.messages,
      const ChatMessage(role: MessageRole.assistant, text: '', streaming: true),
    ],
  );
}

/// `message.delta` → append [event.text] to the current streaming message;
/// [MessageDelta.rendered] supersedes when present.
///
/// Defensive (delta before any `message.start`, or after a terminal frame):
/// a fresh streaming assistant message is created rather than dropping text
/// or mutating a terminal message.
FoldState _onMessageDelta(FoldState state, MessageDelta event) {
  final index = _streamingAssistantIndex(state.messages);
  if (index == null) {
    return state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          role: MessageRole.assistant,
          text: event.text,
          rendered: event.rendered,
          streaming: true,
        ),
      ],
    );
  }
  final current = state.messages[index];
  return _replaceMessage(
    state,
    index,
    current.copyWith(
      text: current.text + event.text,
      rendered: event.rendered ?? current.rendered,
    ),
  );
}

/// `tool.start` → attach a running [ToolCall] to the current streaming
/// message, creating the assistant message if absent (defensive).
FoldState _onToolStart(FoldState state, ToolStart event) {
  final tool = ToolCall(
    id: event.toolId,
    name: event.name,
    context: event.context,
  );
  final index = _streamingAssistantIndex(state.messages);
  if (index == null) {
    return state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          role: MessageRole.assistant,
          text: '',
          streaming: true,
          toolCalls: <ToolCall>[tool],
        ),
      ],
    );
  }
  final current = state.messages[index];
  return _replaceMessage(
    state,
    index,
    current.copyWith(toolCalls: <ToolCall>[...current.toolCalls, tool]),
  );
}

/// `tool.progress` (`{name, preview}` — protocol §7) carries NO tool id, so
/// correlation is best-effort: the LAST still-running tool call with a
/// matching name in the current streaming message gets its `context`
/// replaced by the progress preview (mirroring the TUI's live status line;
/// `tool.complete` does not carry context, so the last preview sticks).
/// No match (or no streaming message) → NO-OP.
FoldState _onToolProgress(FoldState state, ToolProgress event) {
  final index = _streamingAssistantIndex(state.messages);
  if (index == null) {
    return state;
  }
  final current = state.messages[index];
  for (var i = current.toolCalls.length - 1; i >= 0; i--) {
    final tool = current.toolCalls[i];
    if (tool.name == event.name && tool.status == ToolCallStatus.running) {
      final tools = <ToolCall>[...current.toolCalls];
      tools[i] = tool.copyWith(context: event.preview);
      return _replaceMessage(state, index, current.copyWith(toolCalls: tools));
    }
  }
  return state;
}

/// `tool.complete` → resolve the [ToolCall] by `tool_id` (protocol §7):
/// status done, or error when [ToolComplete.error] is non-null; fills
/// result/summary/inlineDiff/durationS. Searched ONLY in the current
/// streaming message (a tool always completes before its turn's terminal
/// frame — §6 ordering).
///
/// Unknown tool id (or no streaming message) → NO-OP: the completion is
/// dropped, existing tool calls stay as they are. Never throws.
FoldState _onToolComplete(FoldState state, ToolComplete event) {
  final index = _streamingAssistantIndex(state.messages);
  if (index == null) {
    return state;
  }
  final current = state.messages[index];
  final toolIndex = current.toolCalls.indexWhere(
    (tool) => tool.id == event.toolId && tool.status == ToolCallStatus.running,
  );
  if (toolIndex < 0) {
    return state;
  }
  final tool = current.toolCalls[toolIndex];
  final tools = <ToolCall>[...current.toolCalls];
  tools[toolIndex] = tool.copyWith(
    status: event.error != null ? ToolCallStatus.error : ToolCallStatus.done,
    result: event.result,
    summary: event.summary,
    inlineDiff: event.inlineDiff,
    durationS: event.durationS,
  );
  return _replaceMessage(state, index, current.copyWith(toolCalls: tools));
}

/// `message.complete` → turn-terminal: streaming off, terminal status from
/// the payload (∈ complete|interrupted|error), text = the authoritative
/// final payload text, rendered supersedes when present, usage recorded.
///
/// Defensive (complete without a streaming message): append an
/// already-finalized assistant message rather than dropping the text.
FoldState _onMessageComplete(FoldState state, MessageComplete event) {
  final index = _streamingAssistantIndex(state.messages);
  if (index == null) {
    return state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          role: MessageRole.assistant,
          text: event.text,
          rendered: event.rendered,
          terminalStatus: event.status,
          usage: event.usage,
        ),
      ],
    );
  }
  final current = state.messages[index];
  return _replaceMessage(
    state,
    index,
    current.copyWith(
      text: event.text,
      rendered: event.rendered ?? current.rendered,
      streaming: false,
      terminalStatus: event.status,
      usage: event.usage,
    ),
  );
}

/// `error` → the OTHER turn-terminal frame (protocol §6): finalize the
/// current streaming message with status error, appending the gateway's
/// error message to the accumulated text when non-empty.
///
/// Defensive (error without a streaming message): append a finalized
/// assistant message carrying the error text.
FoldState _onTurnError(FoldState state, TurnError event) {
  final index = _streamingAssistantIndex(state.messages);
  final detail = event.message ?? '';
  if (index == null) {
    return state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          role: MessageRole.assistant,
          text: detail,
          terminalStatus: MessageTerminalStatus.error,
        ),
      ],
    );
  }
  final current = state.messages[index];
  final text = detail.isEmpty
      ? current.text
      : current.text.isEmpty
      ? detail
      : '${current.text}\n\n$detail';
  return _replaceMessage(
    state,
    index,
    current.copyWith(
      text: text,
      streaming: false,
      terminalStatus: MessageTerminalStatus.error,
    ),
  );
}

/// `approval.request` → surface out-of-band (protocol §8.2: correlated by
/// SESSION, no request id on the wire). The message list is untouched.
FoldState _onApprovalRequest(FoldState state, ApprovalRequestEvent event) {
  return state.copyWith(
    pendingPrompts: <InteractivePrompt>[
      ...state.pendingPrompts,
      ApprovalPrompt(
        sessionId: event.sessionId ?? '',
        command: event.command,
        description: event.description,
        patternKey: event.patternKey,
        patternKeys: event.patternKeys,
        allowPermanent: event.allowPermanent,
      ),
    ],
  );
}

/// `clarify.request` → surface out-of-band (protocol §8.1: correlated by
/// request_id). The message list is untouched.
FoldState _onClarifyRequest(FoldState state, ClarifyRequestEvent event) {
  return state.copyWith(
    pendingPrompts: <InteractivePrompt>[
      ...state.pendingPrompts,
      ClarifyPrompt(
        sessionId: event.sessionId ?? '',
        question: event.question,
        choices: event.choices,
        requestId: event.requestId,
      ),
    ],
  );
}

/// The "current" turn message is always the LAST message, and only while it
/// is a streaming assistant message. A terminal message is never current —
/// so turn events can never merge into a finalized message.
int? _streamingAssistantIndex(List<ChatMessage> messages) {
  if (messages.isEmpty) {
    return null;
  }
  final last = messages[messages.length - 1];
  if (last.role == MessageRole.assistant && last.streaming) {
    return messages.length - 1;
  }
  return null;
}

FoldState _replaceMessage(FoldState state, int index, ChatMessage next) {
  final messages = <ChatMessage>[...state.messages];
  messages[index] = next;
  return state.copyWith(messages: messages);
}
