import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/tool_call.dart';
import 'package:flit/domain/models/usage.dart';

/// Who authored a message.
enum MessageRole { user, assistant, system }

/// How a streaming assistant message ended (protocol §6:
/// `message.complete.payload.status` ∈ complete|interrupted|error).
enum MessageTerminalStatus {
  /// Still streaming (or not an assistant turn message at all).
  none,

  /// Turn finished normally.
  complete,

  /// Turn was interrupted (`session.interrupt`).
  interrupted,

  /// Turn ended with an error (terminal `error` event or
  /// `message.complete` with status `error`).
  error,
}

/// One chat message in the conversation list. Immutable; the event fold
/// (ticket P1-06) mutates via [copyWith].
final class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.rendered,
    this.reasoning,
    this.reasoningStreaming = false,
    this.streaming = false,
    this.toolCalls = const <ToolCall>[],
    this.terminalStatus = MessageTerminalStatus.none,
    this.usage,
    this.timestamp,
  });

  /// Who authored the message.
  final MessageRole role;

  /// Plain-text content. Accumulates across `message.delta` events;
  /// `message.complete.text` carries the full final text (protocol §5).
  final String text;

  /// Pre-rendered (markdown/HTML) content when the gateway provides it
  /// (`message.delta.rendered?` / `message.complete.rendered?`, §6).
  final String? rendered;

  /// The model's extended thinking for this turn: accumulated from
  /// `reasoning.delta` while the turn is live, or handed over whole by
  /// `reasoning.available` / `message.complete.reasoning`. Null when the model
  /// did not think (or the gateway is not sharing it) — the disclosure is
  /// hidden, not empty.
  final String? reasoning;

  /// True while `reasoning.delta` frames are still arriving — i.e. the model
  /// is thinking RIGHT NOW, which is what makes the disclosure say "Thinking…"
  /// and auto-expand. Goes false at the terminal frame even though
  /// [reasoning] is kept.
  final bool reasoningStreaming;

  /// True while deltas are still arriving (between `message.start` and the
  /// terminal event).
  final bool streaming;

  /// Tool calls attached to this message (protocol §7), in arrival order.
  final List<ToolCall> toolCalls;

  /// Terminal status of the turn; [MessageTerminalStatus.none] while
  /// streaming or for non-turn messages.
  final MessageTerminalStatus terminalStatus;

  /// Token usage for the turn, carried by `message.complete.payload.usage`
  /// (wire §7); null until the terminal event (and for non-turn messages).
  final Usage? usage;

  /// Client-side timestamp (display only; not a wire field).
  final DateTime? timestamp;

  /// The event fold mutates via copy (ticket P1-01).
  ChatMessage copyWith({
    MessageRole? role,
    String? text,
    String? rendered,
    String? reasoning,
    bool? reasoningStreaming,
    bool? streaming,
    List<ToolCall>? toolCalls,
    MessageTerminalStatus? terminalStatus,
    Usage? usage,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      text: text ?? this.text,
      rendered: rendered ?? this.rendered,
      reasoning: reasoning ?? this.reasoning,
      reasoningStreaming: reasoningStreaming ?? this.reasoningStreaming,
      streaming: streaming ?? this.streaming,
      toolCalls: toolCalls ?? this.toolCalls,
      terminalStatus: terminalStatus ?? this.terminalStatus,
      usage: usage ?? this.usage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessage &&
        other.role == role &&
        other.text == text &&
        other.rendered == rendered &&
        other.reasoning == reasoning &&
        other.reasoningStreaming == reasoningStreaming &&
        other.streaming == streaming &&
        deepListEquals(other.toolCalls, toolCalls) &&
        other.terminalStatus == terminalStatus &&
        other.usage == usage &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
    role,
    text,
    rendered,
    reasoning,
    reasoningStreaming,
    streaming,
    Object.hashAll(toolCalls),
    terminalStatus,
    usage,
    timestamp,
  );

  @override
  String toString() {
    return 'ChatMessage(role: ${role.name}, text: $text, '
        'rendered: $rendered, reasoning: $reasoning, '
        'reasoningStreaming: $reasoningStreaming, streaming: $streaming, '
        'toolCalls: $toolCalls, terminalStatus: ${terminalStatus.name}, '
        'usage: $usage, timestamp: $timestamp)';
  }
}
