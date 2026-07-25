/// The spawn-tree fold (ticket P3-04): a PURE reducer that folds the
/// `subagent.*` event stream into a tree of subagent nodes.
///
/// Mirroring [foldGatewayEvent] (message_fold.dart), this is kept pure (no
/// Riverpod, no I/O) for trivial unit testing. Each node is keyed by
/// `subagent_id` and linked to its parent via `parent_id`.
library;

import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/subagent_node.dart';

/// Immutable state of the subagent spawn tree: a map of nodes keyed by
/// subagent_id plus an insertion-order list for stable rendering.
final class SpawnTreeState {
  const SpawnTreeState({
    this.nodes = const <String, SubagentNode>{},
    this.order = const <String>[],
  });

  /// Nodes keyed by `subagent_id`.
  final Map<String, SubagentNode> nodes;

  /// Insertion order of node ids (for stable rendering when iterating).
  final List<String> order;

  SpawnTreeState copyWith({
    Map<String, SubagentNode>? nodes,
    List<String>? order,
  }) {
    return SpawnTreeState(
      nodes: nodes ?? this.nodes,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpawnTreeState &&
        shallowMapEquals(other.nodes, nodes) &&
        deepListEquals(other.order, order);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(nodes.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(order),
      );

  @override
  String toString() => 'SpawnTreeState(nodes: $nodes, order: $order)';
}

/// Fold one [SubagentEvent] into [state], returning the next state.
/// NEVER throws; events with no `subagent_id` are ignored (no key to upsert).
///
/// Rules:
/// - If `event.subagentId == null`, return state unchanged (e.g., thin
///   `subagent.spawn_requested` events lack identity).
/// - On any event with a subagentId: upsert the node. If new, create it and
///   append the id to `order`. If existing, copyWith the changed fields.
/// - Per type:
///   - `subagent.start` → status running; lastActivity = text.
///   - `subagent.thinking` → lastActivity = text (status unchanged or set to thinking).
///   - `subagent.tool` → lastToolName = toolName; lastActivity = toolPreview ?? text; toolCount from event.
///   - `subagent.progress` → lastActivity = text.
///   - `subagent.complete` → status from wire; summary, durationSeconds, costUsd, token rollups, filesRead/filesWritten.
/// - Merge token/file fields defensively: only overwrite when the event provides
///   a non-null value (use `event.field ?? node.field`).
SpawnTreeState foldSubagentEvent(SpawnTreeState state, SubagentEvent event) {
  final subagentId = event.subagentId;
  if (subagentId == null) {
    // Thin event (e.g., spawn_requested) with no identity → no-op.
    return state;
  }

  final existing = state.nodes[subagentId];
  final SubagentNode updated;

  if (existing == null) {
    // New node: create it with the event's fields.
    updated = SubagentNode(
      id: subagentId,
      parentId: event.parentId,
      depth: event.depth ?? 0,
      goal: event.goal,
      model: event.model,
      status: _statusForEvent(event),
      lastActivity: event.text,
      lastToolName: event.toolName,
      toolCount: event.toolCount ?? 0,
      inputTokens: event.inputTokens ?? 0,
      outputTokens: event.outputTokens ?? 0,
      reasoningTokens: event.reasoningTokens ?? 0,
      apiCalls: event.apiCalls ?? 0,
      filesRead: event.filesRead ?? const <String>[],
      filesWritten: event.filesWritten ?? const <String>[],
      summary: event.summary,
      durationSeconds: event.durationSeconds,
      costUsd: event.costUsd,
    );
  } else {
    // Existing node: merge fields per event type.
    updated = _updateNode(existing, event);
  }

  final newNodes = <String, SubagentNode>{...state.nodes};
  newNodes[subagentId] = updated;

  final newOrder = existing == null ? <String>[...state.order, subagentId] : state.order;

  return SpawnTreeState(nodes: newNodes, order: newOrder);
}

/// Compute the status for a NEW node based on the event type and payload.
SubagentStatus _statusForEvent(SubagentEvent event) {
  return switch (event.type) {
    'subagent.start' => SubagentStatus.running,
    'subagent.thinking' => SubagentStatus.thinking,
    'subagent.complete' => parseSubagentStatus(event.status),
    _ => parseSubagentStatus(event.status),
  };
}

/// Update an EXISTING node with fields from [event], per event type.
SubagentNode _updateNode(SubagentNode node, SubagentEvent event) {
  return switch (event.type) {
    'subagent.start' => node.copyWith(
        status: SubagentStatus.running,
        lastActivity: event.text ?? node.lastActivity,
      ),
    'subagent.thinking' => node.copyWith(
        status: SubagentStatus.thinking,
        lastActivity: event.text ?? node.lastActivity,
      ),
    'subagent.tool' => node.copyWith(
        lastToolName: event.toolName ?? node.lastToolName,
        lastActivity: event.toolPreview ?? event.text ?? node.lastActivity,
        toolCount: event.toolCount ?? node.toolCount,
      ),
    'subagent.progress' => node.copyWith(
        lastActivity: event.text ?? node.lastActivity,
      ),
    'subagent.complete' => node.copyWith(
        status: parseSubagentStatus(event.status),
        summary: event.summary ?? node.summary,
        lastActivity: event.summary ?? event.text ?? node.lastActivity,
        durationSeconds: event.durationSeconds ?? node.durationSeconds,
        costUsd: event.costUsd ?? node.costUsd,
        inputTokens: event.inputTokens ?? node.inputTokens,
        outputTokens: event.outputTokens ?? node.outputTokens,
        reasoningTokens: event.reasoningTokens ?? node.reasoningTokens,
        apiCalls: event.apiCalls ?? node.apiCalls,
        filesRead: event.filesRead ?? node.filesRead,
        filesWritten: event.filesWritten ?? node.filesWritten,
      ),
    _ => node, // Unknown subagent event type → no-op.
  };
}
