/// Conversation branches in a flit session's log, for the fold: which
/// events are on the active branch's path, and where the chat offers a
/// "‹ 2 / 3 ›" switch between alternatives. Pure, like the fold.
///
/// A branch has its parent's events with seq <= its fork seq (and its
/// parent's ancestors' up to theirs), then its own. Branches that share a
/// parent and fork seq are alternatives at the same point, together with
/// the parent's own continuation after it, if it has one.
library;

import 'package:flit/domain/models/deep_equals.dart';
import 'package:flit/domain/models/flit_event.dart';

/// One branch of a session's conversation (not the root, which has the
/// empty id and no record).
final class FlitBranch {
  const FlitBranch({
    required this.id,
    required this.parent,
    required this.forkSeq,
    required this.createdSeq,
    this.kind = FlitBranchKind.unknown,
    this.messageId = '',
  });

  final String id;
  final String parent;
  final int forkSeq;

  /// Seq of its BranchCreated event.
  final int createdSeq;
  final FlitBranchKind kind;

  /// The user message retried or edited.
  final String messageId;

  @override
  bool operator ==(Object other) =>
      other is FlitBranch &&
      other.id == id &&
      other.parent == parent &&
      other.forkSeq == forkSeq &&
      other.createdSeq == createdSeq &&
      other.kind == kind &&
      other.messageId == messageId;

  @override
  int get hashCode =>
      Object.hash(id, parent, forkSeq, createdSeq, kind, messageId);
}

/// The alternatives at one fork, shown on the first message after it:
/// this is alternative [index] of [targets].length. Switching to
/// alternative i means switching to branch [targets][i] (the alternative's
/// most recently used branch).
final class FlitBranchChoice {
  const FlitBranchChoice({required this.index, required this.targets});

  final int index;
  final List<String> targets;

  int get count => targets.length;

  @override
  bool operator ==(Object other) =>
      other is FlitBranchChoice &&
      other.index == index &&
      deepListEquals(other.targets, targets);

  @override
  int get hashCode => Object.hash(index, Object.hashAll(targets));

  @override
  String toString() => 'FlitBranchChoice(${index + 1} of $count: $targets)';
}

/// For each branch on [active]'s path (the root is ''), the last seq of it
/// that's on the path.
Map<String, int> flitPathLimits(
  Map<String, FlitBranch> branches,
  String active,
) {
  const maxSeq = 1 << 53;
  final out = <String, int>{};
  var id = active;
  var upTo = maxSeq;
  while (!out.containsKey(id)) {
    final b = branches[id];
    if (b == null) {
      // The root, or an unknown branch (treated as the root).
      out[''] = upTo;
      break;
    }
    out[id] = upTo;
    upTo = b.forkSeq;
    id = b.parent;
  }
  return out;
}

/// Whether [e] is on the path described by [limits] (see [flitPathLimits]).
bool flitOnPath(Map<String, int> limits, FlitEvent e) {
  if (flitSessionWide(e)) {
    return true;
  }
  final limit = limits[e.branchId];
  return limit != null && e.seq <= limit;
}

/// Where the chat shows a branch switch: message id → its choice.
///
/// [messageIds] are the messages on the active path in order (nulls
/// ignored) and [messageSeqs] the seq each started at (parallel lists);
/// [branchMessages] lists, per branch, the seqs of messages started on it;
/// [branchLastSeq] is each branch's most recent event (to pick which
/// branch an alternative opens on).
Map<String, FlitBranchChoice> flitBranchChoices({
  required Map<String, FlitBranch> branches,
  required String active,
  required List<String?> messageIds,
  required List<int> messageSeqs,
  required Map<String, List<int>> branchMessages,
  required Map<String, int> branchLastSeq,
}) {
  if (branches.isEmpty) {
    return const <String, FlitBranchChoice>{};
  }
  final limits = flitPathLimits(branches, active);
  final ordered = branches.values.toList()
    ..sort((a, b) => a.createdSeq.compareTo(b.createdSeq));
  final children = <String, List<FlitBranch>>{};
  final groups = <String, List<FlitBranch>>{};
  for (final b in ordered) {
    (children[b.parent] ??= <FlitBranch>[]).add(b);
    (groups['${b.parent}\u0000${b.forkSeq}'] ??= <FlitBranch>[]).add(b);
  }

  // id plus every descendant; with [after], only the children forking
  // after that seq (the parent's own continuation past a fork).
  List<String> subtree(String id, {int? after}) {
    final out = <String>[id];
    for (final c in children[id] ?? const <FlitBranch>[]) {
      if (after == null || c.forkSeq > after) {
        out.addAll(subtree(c.id));
      }
    }
    return out;
  }

  String mostRecent(List<String> ids) {
    var best = ids.first;
    for (final id in ids) {
      final seq = branchLastSeq[id] ?? branches[id]?.createdSeq ?? 0;
      if (seq > (branchLastSeq[best] ?? branches[best]?.createdSeq ?? 0)) {
        best = id;
      }
    }
    return best;
  }

  final out = <String, FlitBranchChoice>{};
  for (final group in groups.values) {
    final parent = group.first.parent;
    final fork = group.first.forkSeq;
    final limit = limits[parent];
    if (limit == null || fork > limit) {
      continue; // this fork isn't on the path
    }
    final alternatives = <List<String>>[];
    var current = -1;
    final continues = (branchMessages[parent] ?? const <int>[]).any(
      (seq) => seq > fork,
    );
    if (continues) {
      if (limit > fork) {
        current = 0;
      }
      alternatives.add(subtree(parent, after: fork));
    }
    for (final c in group) {
      if (limits.containsKey(c.id)) {
        current = alternatives.length;
      }
      alternatives.add(subtree(c.id));
    }
    if (alternatives.length < 2 || current < 0) {
      continue;
    }
    String? anchor;
    for (var i = 0; i < messageIds.length && i < messageSeqs.length; i++) {
      final id = messageIds[i];
      if (id != null && messageSeqs[i] > fork) {
        anchor = id;
        break;
      }
    }
    if (anchor == null) {
      continue; // nothing after the fork yet; comes with its first message
    }
    out[anchor] = FlitBranchChoice(
      index: current,
      targets: <String>[
        for (var i = 0; i < alternatives.length; i++)
          i == current ? active : mostRecent(alternatives[i]),
      ],
    );
  }
  return out;
}
