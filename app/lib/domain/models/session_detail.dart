import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/deep_equals.dart';

/// Phase 2 session-depth domain models (from
/// docs/reference/07-session-depth-wire-shapes.md). All immutable, hand-written
/// equality.

/// Usage statistics from `session.usage` (and the `usage` sub-dict of
/// `session.info`). Wire shape documented in §session.usage.
final class SessionUsageStats {
  const SessionUsageStats({
    this.model = '',
    this.input = 0,
    this.output = 0,
    this.total = 0,
    this.calls = 0,
    this.reasoning,
    this.contextUsed,
    this.contextMax,
    this.contextPercent,
    this.compressions,
  });

  final String model;
  final int input;
  final int output;
  final int total;
  final int calls;

  /// Optional reasoning tokens (only when a reasoning model is used).
  final int? reasoning;

  /// Context occupancy fields — CONDITIONAL: only when a context compressor
  /// + real occupancy exist (wire `context_used`, `context_max`,
  /// `context_percent`).
  final int? contextUsed;
  final int? contextMax;
  final int? contextPercent;

  /// Compression count (only when a compressor exists).
  final int? compressions;

  @override
  bool operator ==(Object other) {
    return other is SessionUsageStats &&
        other.model == model &&
        other.input == input &&
        other.output == output &&
        other.total == total &&
        other.calls == calls &&
        other.reasoning == reasoning &&
        other.contextUsed == contextUsed &&
        other.contextMax == contextMax &&
        other.contextPercent == contextPercent &&
        other.compressions == compressions;
  }

  @override
  int get hashCode => Object.hash(
    model,
    input,
    output,
    total,
    calls,
    reasoning,
    contextUsed,
    contextMax,
    contextPercent,
    compressions,
  );

  @override
  String toString() {
    return 'SessionUsageStats(model: $model, input: $input, output: $output, '
        'total: $total, calls: $calls, reasoning: $reasoning, '
        'contextUsed: $contextUsed, contextMax: $contextMax, '
        'contextPercent: $contextPercent, compressions: $compressions)';
  }
}

/// One category entry from `session.context_breakdown`. Wire shape documented
/// in §session.context_breakdown.
final class ContextCategory {
  const ContextCategory({
    required this.id,
    required this.label,
    required this.tokens,
    required this.color,
  });

  /// Category id (e.g. `system_prompt`, `conversation`, `tool_definitions`).
  final String id;

  /// Human-readable label.
  final String label;

  /// Token count for this category.
  final int tokens;

  /// CSS var reference for UI rendering (e.g. `var(--context-usage-system)`).
  final String color;

  @override
  bool operator ==(Object other) {
    return other is ContextCategory &&
        other.id == id &&
        other.label == label &&
        other.tokens == tokens &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(id, label, tokens, color);

  @override
  String toString() {
    return 'ContextCategory(id: $id, label: $label, tokens: $tokens, '
        'color: $color)';
  }
}

/// Result of `session.context_breakdown`. Wire shape documented in
/// §session.context_breakdown.
final class ContextBreakdown {
  const ContextBreakdown({
    required this.categories,
    required this.contextMax,
    required this.contextPercent,
    required this.contextUsed,
    required this.estimatedTotal,
    required this.model,
  });

  /// Token breakdown by category (omits zero-token categories).
  final List<ContextCategory> categories;

  /// Maximum context size.
  final int contextMax;

  /// Context usage percentage.
  final int contextPercent;

  /// Tokens currently used.
  final int contextUsed;

  /// Estimated total (wire `estimated_total`).
  final int estimatedTotal;

  /// Model name.
  final String model;

  @override
  bool operator ==(Object other) {
    return other is ContextBreakdown &&
        deepListEquals(other.categories, categories) &&
        other.contextMax == contextMax &&
        other.contextPercent == contextPercent &&
        other.contextUsed == contextUsed &&
        other.estimatedTotal == estimatedTotal &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categories),
    contextMax,
    contextPercent,
    contextUsed,
    estimatedTotal,
    model,
  );

  @override
  String toString() {
    return 'ContextBreakdown(categories: $categories, contextMax: $contextMax, '
        'contextPercent: $contextPercent, contextUsed: $contextUsed, '
        'estimatedTotal: $estimatedTotal, model: $model)';
  }
}

/// Result of `session.compress` LOCAL success path. Wire shape documented in
/// §session.compress. Gateway 0.18→0.20 adds the `summary` (incl. its
/// `aborted` flag), opaque `usage` / `info`, and post-compression canonical
/// `messages` — see docs/updates/gateway-0.18-to-0.20-required.md #1.
final class CompressResult {
  const CompressResult({
    this.status = '',
    this.removed,
    this.beforeMessages,
    this.afterMessages,
    this.beforeTokens,
    this.afterTokens,
    this.lockHeld = false,
    this.message,
    this.summary,
    this.usage,
    this.info,
    this.messages = const <ChatMessage>[],
    this.aborted = false,
  });

  /// Compression status (e.g. `compressed`, `aborted`).
  final String status;

  /// Number of messages removed.
  final int? removed;

  /// Message count before compression.
  final int? beforeMessages;

  /// Message count after compression.
  final int? afterMessages;

  /// Token count before compression.
  final int? beforeTokens;

  /// Token count after compression.
  final int? afterTokens;

  /// Lock-held variant: when true, compression did not run (another operation
  /// holds the session lock). Wire `lock_held`.
  final bool lockHeld;

  /// Lock-held message (from the lock-held variant).
  final String? message;

  /// Opaque compress summary dict. Wire `summary` — the only pinned key is
  /// `aborted`; the rest are not documented.
  final Map<String, dynamic>? summary;

  /// Opaque session usage dict (same shape as `session.usage`). Wire `usage`.
  final Map<String, dynamic>? usage;

  /// Full `_session_info` dict. Wire `info` — same shape as the
  /// `session.info` event payload.
  final Map<String, dynamic>? info;

  /// Canonical message list, post-compression. Wire `messages` — same shape
  /// `session.resume` returns.
  final List<ChatMessage> messages;

  /// True when compression was refused (tool mid-flight or model declined) —
  /// the desktop surfaces this as a distinct toast. Derived from
  /// `summary.aborted` (or `status == "aborted"`); always false for the
  /// lock-held variant (which omits `summary` entirely).
  final bool aborted;

  @override
  bool operator ==(Object other) {
    return other is CompressResult &&
        other.status == status &&
        other.removed == removed &&
        other.beforeMessages == beforeMessages &&
        other.afterMessages == afterMessages &&
        other.beforeTokens == beforeTokens &&
        other.afterTokens == afterTokens &&
        other.lockHeld == lockHeld &&
        other.message == message &&
        _nullableMapEquals(other.summary, summary) &&
        _nullableMapEquals(other.usage, usage) &&
        _nullableMapEquals(other.info, info) &&
        deepListEquals(other.messages, messages) &&
        other.aborted == aborted;
  }

  @override
  int get hashCode => Object.hash(
    status,
    removed,
    beforeMessages,
    afterMessages,
    beforeTokens,
    afterTokens,
    lockHeld,
    message,
    summary == null ? null : Object.hashAll(summary!.keys),
    usage == null ? null : Object.hashAll(usage!.keys),
    info == null ? null : Object.hashAll(info!.keys),
    Object.hashAll(messages),
    aborted,
  );

  @override
  String toString() {
    return 'CompressResult(status: $status, removed: $removed, '
        'beforeMessages: $beforeMessages, afterMessages: $afterMessages, '
        'beforeTokens: $beforeTokens, afterTokens: $afterTokens, '
        'lockHeld: $lockHeld, message: $message, aborted: $aborted)';
  }
}

/// Null-safe shallow map equality for the opaque dicts on [CompressResult].
bool _nullableMapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return shallowMapEquals(a, b);
}

/// Result of `session.branch`. Wire shape documented in §session.branch.
final class BranchResult {
  const BranchResult({
    required this.liveId,
    required this.title,
    required this.parentDurableId,
  });

  /// NEW live id of the branch (wire `session_id`).
  final String liveId;

  /// Title of the new branch.
  final String title;

  /// Parent's DURABLE session_key (wire `parent`).
  final String parentDurableId;

  @override
  bool operator ==(Object other) {
    return other is BranchResult &&
        other.liveId == liveId &&
        other.title == title &&
        other.parentDurableId == parentDurableId;
  }

  @override
  int get hashCode => Object.hash(liveId, title, parentDurableId);

  @override
  String toString() {
    return 'BranchResult(liveId: $liveId, title: $title, '
        'parentDurableId: $parentDurableId)';
  }
}

/// Result of `session.most_recent` found shape. Wire shape documented in
/// §session.most_recent. The repository returns `MostRecentSession?` — null
/// when wire `session_id` is null.
final class MostRecentSession {
  const MostRecentSession({
    required this.durableId,
    required this.title,
    this.startedAt,
    required this.source,
  });

  /// DURABLE id (wire `session_id`).
  final String durableId;

  /// Session title.
  final String title;

  /// Start time (wire `started_at`, epoch SECONDS).
  final DateTime? startedAt;

  /// Session source (e.g. `cli`).
  final String source;

  @override
  bool operator ==(Object other) {
    return other is MostRecentSession &&
        other.durableId == durableId &&
        other.title == title &&
        other.startedAt == startedAt &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(durableId, title, startedAt, source);

  @override
  String toString() {
    return 'MostRecentSession(durableId: $durableId, title: $title, '
        'startedAt: $startedAt, source: $source)';
  }
}

/// Inflight turn snapshot from `session.resume`. Wire shape documented in
/// §session.resume `inflight` field (P2-02). Treat both `null` and missing as
/// "no inflight turn."
final class InflightTurn {
  const InflightTurn({
    required this.user,
    required this.assistant,
    required this.streaming,
  });

  /// User prompt that was submitted.
  final String user;

  /// Partial assistant response.
  final String assistant;

  /// Whether the turn is currently streaming.
  final bool streaming;

  @override
  bool operator ==(Object other) {
    return other is InflightTurn &&
        other.user == user &&
        other.assistant == assistant &&
        other.streaming == streaming;
  }

  @override
  int get hashCode => Object.hash(user, assistant, streaming);

  @override
  String toString() {
    return 'InflightTurn(user: $user, assistant: $assistant, '
        'streaming: $streaming)';
  }
}
