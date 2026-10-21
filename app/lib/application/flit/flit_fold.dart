/// The flit event fold: a PURE reducer from a flit session's event log
/// (flit.v1 `Event`s, as domain [FlitEvent]s) to the app's chat models.
///
/// Unlike the Hermes fold, everything comes from the log — user messages
/// too, whichever client sent them — so every attached client converges on
/// the same view. Events at or below [FlitFoldState.lastSeq] are ignored,
/// which makes replays after a reconnect idempotent.
///
/// A session's log can hold several branches of the conversation (see
/// flit_branches.dart). The fold shows the active one: events on other
/// branches only update the branch bookkeeping, and a branch switch
/// re-folds the kept events of the new branch's path.
library;

import 'dart:convert';

import 'package:flit/application/flit/flit_branches.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/subagent.dart';
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
    this.sessionPatterns = const <String>[],
    this.safetyReason = '',
  });

  final String promptId;
  final String toolCallId;
  final String title;
  final String detail;

  /// Offered for "allow for this session".
  final List<String> sessionPatterns;

  /// Why the server's safety check left this to the user; empty when it
  /// didn't run.
  final String safetyReason;

  @override
  bool operator ==(Object other) {
    return other is FlitPendingPrompt &&
        other.promptId == promptId &&
        other.toolCallId == toolCallId &&
        other.title == title &&
        other.detail == detail &&
        deepListEquals(other.sessionPatterns, sessionPatterns) &&
        other.safetyReason == safetyReason;
  }

  @override
  int get hashCode => Object.hash(
    promptId,
    toolCallId,
    title,
    detail,
    Object.hashAll(sessionPatterns),
    safetyReason,
  );

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
    this.inputTokens = 0,
    this.cachedTokens = 0,
  });

  /// The call's prompt size and how much of it came from llama.cpp's cache.
  final int inputTokens;
  final int cachedTokens;

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
      other.inputTokens == inputTokens &&
      other.cachedTokens == cachedTokens &&
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
/// A message waiting in the session's queue for the turn's next step.
final class FlitQueuedMessage {
  const FlitQueuedMessage({
    required this.queueId,
    required this.text,
    this.client = '',
    this.time,
  });

  final String queueId;
  final String text;

  /// The device that sent it.
  final String client;
  final DateTime? time;

  @override
  bool operator ==(Object other) =>
      other is FlitQueuedMessage &&
      other.queueId == queueId &&
      other.text == text &&
      other.client == client &&
      other.time == time;

  @override
  int get hashCode => Object.hash(queueId, text, client, time);

  @override
  String toString() => 'FlitQueuedMessage($queueId, $text)';
}

/// The model call in progress, as the log shows it: what the chat shows
/// while it waits for the model.
final class FlitPendingCall {
  const FlitPendingCall({
    required this.messageId,
    required this.attempt,
    this.startedAt,
    this.lastActivity,
    this.processed = 0,
    this.total = 0,
    this.hasOutput = false,
    this.hasText = false,
    this.waitReason,
    this.totalSlots = 0,
    this.endRequested = false,
  });

  final String messageId;
  final int attempt;

  /// Whether the answer (not just thinking) has started.
  final bool hasText;

  /// Why the model server hasn't started on it, while it says so.
  final FlitWaitReason? waitReason;
  final int totalSlots;

  /// "Answer now" was asked for.
  final bool endRequested;

  /// The model is thinking and hasn't started its answer.
  bool get thinking => hasOutput && !hasText;

  /// When the request went out, and when anything last arrived for it
  /// (prompt progress or reply text), by the server's clock.
  final DateTime? startedAt;
  final DateTime? lastActivity;

  /// Prompt tokens read so far, of [total] (0 when the server doesn't say).
  final int processed;
  final int total;

  /// Whether any of the reply has arrived (then it can't be retried).
  final bool hasOutput;

  FlitPendingCall copyWith({
    DateTime? lastActivity,
    int? processed,
    int? total,
    bool? hasOutput,
    bool? hasText,
    FlitWaitReason? waitReason,
    bool clearWait = false,
    int? totalSlots,
    bool? endRequested,
  }) => FlitPendingCall(
    messageId: messageId,
    attempt: attempt,
    startedAt: startedAt,
    lastActivity: lastActivity ?? this.lastActivity,
    processed: processed ?? this.processed,
    total: total ?? this.total,
    hasOutput: hasOutput ?? this.hasOutput,
    hasText: hasText ?? this.hasText,
    waitReason: clearWait ? null : (waitReason ?? this.waitReason),
    totalSlots: totalSlots ?? this.totalSlots,
    endRequested: endRequested ?? this.endRequested,
  );

  @override
  bool operator ==(Object other) =>
      other is FlitPendingCall &&
      other.messageId == messageId &&
      other.attempt == attempt &&
      other.startedAt == startedAt &&
      other.lastActivity == lastActivity &&
      other.processed == processed &&
      other.total == total &&
      other.hasOutput == hasOutput &&
      other.hasText == hasText &&
      other.waitReason == waitReason &&
      other.totalSlots == totalSlots &&
      other.endRequested == endRequested;

  @override
  int get hashCode => Object.hash(
    messageId,
    attempt,
    startedAt,
    lastActivity,
    processed,
    total,
    hasOutput,
    hasText,
    waitReason,
    totalSlots,
    endRequested,
  );

  @override
  String toString() =>
      'FlitPendingCall($messageId #$attempt, $processed/$total, '
      'output: $hasOutput)';
}

/// A compaction in progress: the chat shows "compacting…".
final class FlitCompacting {
  const FlitCompacting({
    required this.compactionId,
    this.auto = false,
    this.provider = '',
    this.model = '',
    this.tokens = 0,
    this.contextLength = 0,
    this.startedAt,
  });

  final String compactionId;
  final bool auto;
  final String provider;
  final String model;
  final int tokens;
  final int contextLength;
  final DateTime? startedAt;

  @override
  bool operator ==(Object other) =>
      other is FlitCompacting &&
      other.compactionId == compactionId &&
      other.auto == auto &&
      other.provider == provider &&
      other.model == model &&
      other.tokens == tokens &&
      other.contextLength == contextLength &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(
    compactionId,
    auto,
    provider,
    model,
    tokens,
    contextLength,
    startedAt,
  );
}

/// Where a compaction cut the conversation, shown as a marker in the chat:
/// the messages before [beforeIndex] now reach the model only as [summary].
final class FlitCompactionMarker {
  const FlitCompactionMarker({
    required this.compactionId,
    required this.beforeIndex,
    required this.summary,
    this.auto = false,
    this.tokensBefore = 0,
    this.tokensAfter = 0,
    this.tokensExact = false,
    this.provider = '',
    this.model = '',
    this.time,
  });

  final String compactionId;

  /// The marker goes before this entry of [FlitFoldState.messages] (at the
  /// end when it equals their length).
  final int beforeIndex;
  final String summary;
  final bool auto;
  final int tokensBefore;
  final int tokensAfter;
  final bool tokensExact;
  final String provider;
  final String model;
  final DateTime? time;

  @override
  bool operator ==(Object other) =>
      other is FlitCompactionMarker &&
      other.compactionId == compactionId &&
      other.beforeIndex == beforeIndex &&
      other.summary == summary &&
      other.auto == auto &&
      other.tokensBefore == tokensBefore &&
      other.tokensAfter == tokensAfter &&
      other.tokensExact == tokensExact &&
      other.provider == provider &&
      other.model == model &&
      other.time == time;

  @override
  int get hashCode => Object.hash(
    compactionId,
    beforeIndex,
    summary,
    auto,
    tokensBefore,
    tokensAfter,
    tokensExact,
    provider,
    model,
    time,
  );

  @override
  String toString() =>
      'FlitCompactionMarker($compactionId before $beforeIndex: $summary)';
}

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
    this.messageIds = const <String?>[],
    this.ratings = const <String, bool>{},
    this.mcpServers,
    this.projectId,
    this.yolo,
    this.safety = const <String, String>{},
    this.call,
    this.queued = const <FlitQueuedMessage>[],
    this.reasoningEndIgnored = const <String>{},
    this.messageSeqs = const <int>[],
    this.compacting,
    this.compactions = const <FlitCompactionMarker>[],
    this.keptIndex,
    this.activeBranch = '',
    this.branches = const <String, FlitBranch>{},
    this.branchChoices = const <String, FlitBranchChoice>{},
    this.branchMessages = const <String, List<int>>{},
    this.branchLastSeq = const <String, int>{},
    this.pathLimits = const <String, int>{'': 1 << 53},
    this.kept = const <FlitEvent>[],
    this.keptCount = 0,
    this.subagents = const <String, FlitFoldState>{},
  });

  /// agent tool call id → the fold of its subagent's own conversation
  /// (shown as that tool call's [Subagent.transcript]).
  final Map<String, FlitFoldState> subagents;

  /// The seq of the event that started each entry of [messages].
  final List<int> messageSeqs;

  /// A compaction in progress, if any.
  final FlitCompacting? compacting;

  /// Compactions that took effect, oldest first.
  final List<FlitCompactionMarker> compactions;

  /// A message before the latest compaction marker that the model still
  /// sees: the request of a turn the compaction cut through.
  final int? keptIndex;

  /// Whether messages[i] reaches the model only through a compaction
  /// summary (the chat greys it out).
  bool summarized(int i) =>
      compactions.isNotEmpty &&
      i < compactions.last.beforeIndex &&
      i != keptIndex;

  /// The active branch ('' is the root); the fold shows its path.
  final String activeBranch;

  /// The session's branches besides the root, by id.
  final Map<String, FlitBranch> branches;

  /// Messages that start an alternative at a fork → the switch to show.
  final Map<String, FlitBranchChoice> branchChoices;

  /// Per branch, the seqs of the messages started on it (any branch).
  final Map<String, List<int>> branchMessages;

  /// Per branch, its most recent event's seq.
  final Map<String, int> branchLastSeq;

  /// The active path (see [flitPathLimits]).
  final Map<String, int> pathLimits;

  /// The events needed to re-fold another branch (not the deltas and live
  /// output a finished message or tool doesn't need), the first
  /// [keptCount] of them. The list is shared between states and only
  /// appended to (see [_keep]).
  final List<FlitEvent> kept;
  final int keptCount;

  /// Messages whose model ignored "answer now" (from the log).
  final Set<String> reasoningEndIgnored;

  /// The model call in progress, if any.
  final FlitPendingCall? call;

  /// Messages waiting for the turn's next step, oldest first.
  final List<FlitQueuedMessage> queued;

  /// Yolo mode, once a change is logged (null until then: fall back to the
  /// session's).
  final bool? yolo;

  /// tool call id → the safety check's verdict on it, as shown on the tool
  /// card (e.g. "safety check: safe, only reads").
  final Map<String, String> safety;

  /// The flit message id of each entry in [messages] (null for messages
  /// the fold made up, like errors).
  final List<String?> messageIds;

  /// Latest turn rating per message id (true = good), from any client.
  final Map<String, bool> ratings;

  /// MCP servers enabled, once a change is logged (null until then: fall
  /// back to the session's).
  final List<String>? mcpServers;

  /// The project, once a move is logged (null: the session's).
  final String? projectId;

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
    List<String?>? messageIds,
    Map<String, bool>? ratings,
    List<String>? mcpServers,
    String? projectId,
    bool? yolo,
    Map<String, String>? safety,
    FlitPendingCall? call,
    bool clearCall = false,
    List<FlitQueuedMessage>? queued,
    Set<String>? reasoningEndIgnored,
    List<int>? messageSeqs,
    FlitCompacting? compacting,
    bool clearCompacting = false,
    List<FlitCompactionMarker>? compactions,
    int? keptIndex,
    bool clearKept = false,
    String? activeBranch,
    Map<String, FlitBranch>? branches,
    Map<String, FlitBranchChoice>? branchChoices,
    Map<String, List<int>>? branchMessages,
    Map<String, int>? branchLastSeq,
    Map<String, int>? pathLimits,
    List<FlitEvent>? kept,
    int? keptCount,
    Map<String, FlitFoldState>? subagents,
  }) {
    return FlitFoldState(
      compacting: clearCompacting ? null : (compacting ?? this.compacting),
      compactions: compactions ?? this.compactions,
      keptIndex: clearKept ? null : (keptIndex ?? this.keptIndex),
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
      messageIds: messageIds ?? this.messageIds,
      ratings: ratings ?? this.ratings,
      mcpServers: mcpServers ?? this.mcpServers,
      projectId: projectId ?? this.projectId,
      yolo: yolo ?? this.yolo,
      safety: safety ?? this.safety,
      call: clearCall ? null : (call ?? this.call),
      queued: queued ?? this.queued,
      reasoningEndIgnored: reasoningEndIgnored ?? this.reasoningEndIgnored,
      activeBranch: activeBranch ?? this.activeBranch,
      branches: branches ?? this.branches,
      branchChoices: branchChoices ?? this.branchChoices,
      messageSeqs: messageSeqs ?? this.messageSeqs,
      branchMessages: branchMessages ?? this.branchMessages,
      branchLastSeq: branchLastSeq ?? this.branchLastSeq,
      pathLimits: pathLimits ?? this.pathLimits,
      kept: kept ?? this.kept,
      keptCount: keptCount ?? this.keptCount,
      subagents: subagents ?? this.subagents,
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
        other.speed == speed &&
        deepListEquals(other.messageIds, messageIds) &&
        shallowMapEquals(other.ratings, ratings) &&
        deepListEquals(
          other.mcpServers ?? const <String>[],
          mcpServers ?? const <String>[],
        ) &&
        (other.mcpServers == null) == (mcpServers == null) &&
        other.projectId == projectId &&
        other.yolo == yolo &&
        shallowMapEquals(other.safety, safety) &&
        other.call == call &&
        deepListEquals(other.queued, queued) &&
        other.reasoningEndIgnored.length == reasoningEndIgnored.length &&
        other.reasoningEndIgnored.containsAll(reasoningEndIgnored) &&
        deepListEquals(other.messageSeqs, messageSeqs) &&
        other.compacting == compacting &&
        deepListEquals(other.compactions, compactions) &&
        other.keptIndex == keptIndex &&
        other.activeBranch == activeBranch &&
        shallowMapEquals(other.branches, branches) &&
        shallowMapEquals(other.branchChoices, branchChoices);
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
    call,
    Object.hashAll(queued),
    compacting,
    Object.hashAll(compactions),
    activeBranch,
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
  final s = _track(state, event);
  switch (event) {
    case FlitBranchCreated():
      return _withChoices(
        s.copyWith(
          lastSeq: event.seq,
          branches: <String, FlitBranch>{
            ...s.branches,
            event.newBranchId: FlitBranch(
              id: event.newBranchId,
              parent: event.parentBranchId,
              forkSeq: event.forkSeq,
              createdSeq: event.seq,
              kind: event.kind,
              messageId: event.messageId,
            ),
          },
        ),
      );
    case FlitBranchSwitched():
      return _switchTo(s, event.newBranchId, event.seq);
    default:
      if (!flitOnPath(s.pathLimits, event)) {
        return s.copyWith(lastSeq: event.seq);
      }
      final next = _apply(s, event);
      return event is FlitMessageStarted ? _withChoices(next) : next;
  }
}

/// Records [e] in the branch bookkeeping and keeps it for re-folding.
FlitFoldState _track(FlitFoldState s, FlitEvent e) {
  final branch = e.branchId;
  var branchMessages = s.branchMessages;
  if (e is FlitMessageStarted) {
    branchMessages = <String, List<int>>{
      ...branchMessages,
      branch: <int>[...?branchMessages[branch], e.seq],
    };
  }
  final (kept, keptCount) = _transient(e) ? (s.kept, s.keptCount) : _keep(s, e);
  return s.copyWith(
    branchMessages: branchMessages,
    branchLastSeq: s.branchLastSeq[branch] == e.seq
        ? null
        : <String, int>{...s.branchLastSeq, branch: e.seq},
    kept: kept,
    keptCount: keptCount,
  );
}

/// Whether [e] only matters while it streams: deltas and live output a
/// finished message or tool doesn't need, for the agent or a subagent.
bool _transient(FlitEvent e) => switch (e) {
  FlitTextDelta() ||
  FlitReasoningDelta() ||
  FlitToolOutput() ||
  FlitPromptProgress() ||
  FlitModelCallWaiting() ||
  FlitUnknownEvent() => true,
  FlitSubagentEvent() => _transient(e.event),
  _ => false,
};

/// Appends [e] to the kept events. States share one list: appending in
/// place is safe while this state's count is its end; otherwise (an older
/// state folded again) it copies.
(List<FlitEvent>, int) _keep(FlitFoldState s, FlitEvent e) {
  if (s.keptCount > 0 && s.kept.length == s.keptCount) {
    s.kept.add(e);
    return (s.kept, s.keptCount + 1);
  }
  return (<FlitEvent>[...s.kept.take(s.keptCount), e], s.keptCount + 1);
}

/// Re-folds the kept events of [branch]'s path: the chat as that branch
/// has it. Switches only happen between turns, so nothing is streaming
/// and the deltas that weren't kept aren't needed.
FlitFoldState _switchTo(FlitFoldState s, String branch, int seq) {
  final limits = flitPathLimits(s.branches, branch);
  var next = FlitFoldState(
    activeBranch: branch,
    branches: s.branches,
    branchMessages: s.branchMessages,
    branchLastSeq: s.branchLastSeq,
    pathLimits: limits,
    kept: s.kept,
    keptCount: s.keptCount,
  );
  for (var i = 0; i < s.keptCount; i++) {
    final e = s.kept[i];
    if (e.seq < seq &&
        e is! FlitBranchCreated &&
        e is! FlitBranchSwitched &&
        flitOnPath(limits, e)) {
      next = _apply(next, e);
    }
  }
  return _withChoices(next.copyWith(lastSeq: seq));
}

FlitFoldState _withChoices(FlitFoldState s) => s.copyWith(
  branchChoices: flitBranchChoices(
    branches: s.branches,
    active: s.activeBranch,
    messageIds: s.messageIds,
    messageSeqs: s.messageSeqs,
    branchMessages: s.branchMessages,
    branchLastSeq: s.branchLastSeq,
  ),
);

/// Folds one event of the active path into the chat.
FlitFoldState _apply(FlitFoldState state, FlitEvent event) {
  final s = state.copyWith(lastSeq: event.seq);
  return switch (event) {
    FlitMessageStarted() => _started(s, event),
    FlitTextDelta() => _updateMessage(
      _callOutput(s, event.messageId, event.time, text: true),
      event.messageId,
      (m) => m.copyWith(text: m.text + event.text),
    ),
    FlitReasoningDelta() => _updateMessage(
      _callOutput(s, event.messageId, event.time, text: false),
      event.messageId,
      (m) => m.copyWith(
        reasoning: (m.reasoning ?? '') + event.text,
        reasoningStreaming: true,
      ),
    ),
    FlitMessageQueued() => s.copyWith(
      queued: <FlitQueuedMessage>[
        ...s.queued,
        FlitQueuedMessage(
          queueId: event.queueId,
          text: event.text,
          client: event.client,
          time: event.time,
        ),
      ],
    ),
    FlitQueuedMessageUpdated() => s.copyWith(
      queued: <FlitQueuedMessage>[
        for (final q in s.queued)
          if (q.queueId != event.queueId)
            q
          else if (!event.cancelled)
            FlitQueuedMessage(
              queueId: q.queueId,
              text: event.text,
              client: q.client,
              time: q.time,
            ),
      ],
    ),
    FlitQueuedMessageDelivered() => s.copyWith(
      queued: s.queued.where((q) => q.queueId != event.queueId).toList(),
    ),
    FlitModelCallStarted() => s.copyWith(
      call: FlitPendingCall(
        messageId: event.messageId,
        attempt: event.attempt,
        startedAt: event.time,
        lastActivity: event.time,
      ),
    ),
    FlitPromptProgress() =>
      s.call?.messageId == event.messageId
          ? s.copyWith(
              call: s.call!.copyWith(
                lastActivity: event.time,
                processed: event.processed,
                total: event.total,
                clearWait: true,
              ),
            )
          : s,
    FlitModelCallWaiting() =>
      s.call?.messageId == event.messageId
          ? s.copyWith(
              call: s.call!.copyWith(
                waitReason: event.reason,
                totalSlots: event.totalSlots,
              ),
            )
          : s,
    FlitReasoningEndRequested() =>
      s.call?.messageId == event.messageId
          ? s.copyWith(call: s.call!.copyWith(endRequested: true))
          : s,
    FlitReasoningEndIgnored() => s.copyWith(
      reasoningEndIgnored: <String>{...s.reasoningEndIgnored, event.messageId},
    ),
    FlitModelCallEnded() =>
      s.call?.messageId == event.messageId ? s.copyWith(clearCall: true) : s,
    FlitCompactionStarted() => s.copyWith(
      compacting: FlitCompacting(
        compactionId: event.compactionId,
        auto: event.auto,
        provider: event.provider,
        model: event.model,
        tokens: event.tokens,
        contextLength: event.contextLength,
        startedAt: event.time,
      ),
    ),
    FlitCompactionDone() => _compacted(
      s.copyWith(clearCompacting: true),
      event,
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
        summary: _toolSummary(s.safety[event.toolCallId], event.truncated),
        subagent: t.subagent,
      ),
    ),
    FlitSubagentStarted() => _updateTool(
      s.copyWith(
        subagents: <String, FlitFoldState>{
          ...s.subagents,
          event.toolCallId: const FlitFoldState(),
        },
      ),
      event.toolCallId,
      (t) => t.copyWith(
        subagent: Subagent(
          kind: event.kind,
          provider: event.provider,
          model: event.model,
          task: event.task,
          maxSteps: event.maxSteps,
        ),
      ),
    ),
    FlitSubagentEvent() => _subagentEvent(s, event.toolCallId, event.event),
    FlitSubagentDone() => _updateTool(
      s,
      event.toolCallId,
      (t) => t.copyWith(
        subagent: t.subagent?.copyWith(
          status: event.status,
          report: event.report,
          error: event.error,
          steps: event.steps,
        ),
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
          sessionPatterns: event.sessionPatterns,
          safetyReason: event.safetyReason,
        ),
      ],
    ),
    FlitPromptResolved() => s.copyWith(
      prompts: s.prompts.where((p) => p.promptId != event.promptId).toList(),
    ),
    FlitTaskStateChanged() => s.copyWith(
      taskState: event.state,
      taskReason: event.reason,
      clearCall:
          event.state != FlitTaskState.working &&
          event.state != FlitTaskState.waiting,
      clearCompacting:
          event.state != FlitTaskState.working &&
          event.state != FlitTaskState.waiting,
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
    FlitFeedback() =>
      event.target == FlitRatingTarget.turn && event.messageId.isNotEmpty
          ? s.copyWith(
              ratings: <String, bool>{
                ...s.ratings,
                event.messageId: event.good,
              },
            )
          : s,
    FlitMcpServersChanged() => s.copyWith(mcpServers: event.enabled),
    FlitSessionMoved() => s.copyWith(projectId: event.projectId),
    FlitYoloChanged() => s.copyWith(yolo: event.yolo),
    FlitPermissionCheck() => _permissionCheck(s, event),
    FlitTurnError() => s.copyWith(
      messageIds: <String?>[...s.messageIds, null],
      messageSeqs: <int>[...s.messageSeqs, event.seq],
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
    FlitUnknownEvent() || FlitBranchCreated() || FlitBranchSwitched() => s,
  };
}

/// Reply text for the call in progress: it has output now.
FlitFoldState _callOutput(
  FlitFoldState s,
  String messageId,
  DateTime? at, {
  required bool text,
}) {
  final call = s.call;
  if (call == null || call.messageId != messageId) {
    return s;
  }
  return s.copyWith(
    call: call.copyWith(
      hasOutput: true,
      hasText: text ? true : null,
      lastActivity: at,
      clearWait: true,
    ),
  );
}

/// Folds [e] into the conversation of the subagent run by [toolCallId]
/// and shows the result on that tool call.
FlitFoldState _subagentEvent(FlitFoldState s, String toolCallId, FlitEvent e) {
  final child = _apply(s.subagents[toolCallId] ?? const FlitFoldState(), e);
  return _updateTool(
    s.copyWith(
      subagents: <String, FlitFoldState>{...s.subagents, toolCallId: child},
    ),
    toolCallId,
    (t) =>
        t.copyWith(subagent: t.subagent?.copyWith(transcript: child.messages)),
  );
}

FlitFoldState _permissionCheck(FlitFoldState s, FlitPermissionCheck e) {
  // A subagent's command: its safety check shows on its own card.
  for (final MapEntry(key: id, value: child) in s.subagents.entries) {
    if (child.toolMessage.containsKey(e.toolCallId)) {
      return _subagentEvent(s, id, e);
    }
  }
  final text = e.reason.isEmpty
      ? 'safety check: ${e.verdict.name}'
      : 'safety check: ${e.verdict.name}, ${e.reason}';
  final withSafety = s.copyWith(
    safety: <String, String>{...s.safety, e.toolCallId: text},
  );
  return _updateTool(
    withSafety,
    e.toolCallId,
    (t) => t.copyWith(summary: text),
  );
}

String? _toolSummary(String? safety, bool truncated) {
  final parts = <String>[?safety, if (truncated) 'output shortened'];
  return parts.isEmpty ? null : parts.join(' · ');
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
            inputTokens: e.inputTokens,
            cachedTokens: e.cachedTokens,
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
    messageIds: <String?>[...s.messageIds, e.messageId],
    messageSeqs: <int>[...s.messageSeqs, e.seq],
  );
}

/// A compaction ended: a marker where it cut the conversation (everything
/// above it is greyed out), or a note that it failed.
FlitFoldState _compacted(FlitFoldState s, FlitCompactionDone e) {
  if (e.error.isNotEmpty) {
    return s.copyWith(
      messageIds: <String?>[...s.messageIds, null],
      messageSeqs: <int>[...s.messageSeqs, e.seq],
      messages: <ChatMessage>[
        ...s.messages,
        ChatMessage(
          role: MessageRole.system,
          text:
              "Couldn't compact the conversation: ${e.error}. "
              'It goes on with its full history.',
          terminalStatus: MessageTerminalStatus.error,
          timestamp: e.time,
        ),
      ],
    );
  }
  var before = s.messages.length;
  for (var i = 0; i < s.messageSeqs.length; i++) {
    if (s.messageSeqs[i] > e.coveredSeq) {
      before = i;
      break;
    }
  }
  // Cut inside a turn: the model still sees the request that started it.
  int? kept;
  for (var i = before; i < s.messages.length; i++) {
    if (i < s.messageIds.length && s.messageIds[i] == null) {
      continue;
    }
    if (s.messages[i].role == MessageRole.assistant) {
      for (var j = before - 1; j >= 0; j--) {
        if (s.messages[j].role == MessageRole.user) {
          kept = j;
          break;
        }
      }
    }
    break;
  }
  return s.copyWith(
    compactions: <FlitCompactionMarker>[
      ...s.compactions,
      FlitCompactionMarker(
        compactionId: e.compactionId,
        beforeIndex: before,
        summary: e.summary,
        auto: e.auto,
        tokensBefore: e.tokensBefore,
        tokensAfter: e.tokensAfter,
        tokensExact: e.tokensExact,
        provider: e.provider,
        model: e.model,
        time: e.time,
      ),
    ],
    keptIndex: kept,
    clearKept: kept == null,
    contextTokens: e.tokensAfter,
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
    'agent' => str('task'),
    _ => str('path'),
  };
}

/// Whether a session's stored details (title, state) are likely stale after
/// going from [prev] to [next]: the first message arrived, or a turn ended.
/// Replays of an already-finished history don't count as turns ending.
bool flitSessionNeedsRefresh(FlitFoldState? prev, FlitFoldState next) {
  if (prev == null) {
    return false;
  }
  if (prev.messages.isEmpty && next.messages.isNotEmpty) {
    return true;
  }
  final ended =
      prev.busy &&
      !next.busy &&
      (next.taskState == FlitTaskState.done ||
          next.taskState == FlitTaskState.stuck);
  return ended;
}
