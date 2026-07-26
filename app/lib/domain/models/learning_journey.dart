import 'package:flit/domain/models/deep_equals.dart';

/// A learning journey timeline (wire `learning.frames` result, P6-01).
final class LearningJourney {
  const LearningJourney({
    required this.buckets,
    required this.summary,
    required this.legend,
    required this.categories,
    required this.axis,
    required this.count,
  });

  /// Timeline buckets (oldest → newest).
  final List<LearningBucket> buckets;

  /// Human-readable summary lines.
  final List<String> summary;

  /// Legend entries (glyphs + styles).
  final List<LearningLegend> legend;

  /// Colored skill categories.
  final List<LearningCategory> categories;

  /// Axis labels (start/end dates).
  final ({String start, String end}) axis;

  /// Total node count.
  final int count;

  @override
  bool operator ==(Object other) {
    return other is LearningJourney &&
        deepListEquals(other.buckets, buckets) &&
        deepListEquals(other.summary, summary) &&
        deepListEquals(other.legend, legend) &&
        deepListEquals(other.categories, categories) &&
        other.axis == axis &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(buckets),
    Object.hashAll(summary),
    Object.hashAll(legend),
    Object.hashAll(categories),
    axis,
    count,
  );

  @override
  String toString() {
    return 'LearningJourney(buckets: $buckets, summary: $summary, '
        'legend: $legend, categories: $categories, axis: $axis, count: $count)';
  }
}

/// One timeline bucket (period grouping).
final class LearningBucket {
  const LearningBucket({
    required this.index,
    required this.label,
    required this.date,
    required this.skills,
    required this.memories,
    required this.total,
    this.category,
    this.color,
    required this.nodes,
  });

  /// Bucket index (0-based, oldest → newest).
  final int index;

  /// Period label (e.g., "Jul 2026").
  final String label;

  /// Formatted representative date.
  final String date;

  /// Number of skills in this bucket.
  final int skills;

  /// Number of memories in this bucket.
  final int memories;

  /// Total nodes (skills + memories).
  final int total;

  /// Dominant skill category (nullable).
  final String? category;

  /// Category color hex (nullable).
  final String? color;

  /// Chronological nodes within this bucket.
  final List<LearningNode> nodes;

  @override
  bool operator ==(Object other) {
    return other is LearningBucket &&
        other.index == index &&
        other.label == label &&
        other.date == date &&
        other.skills == skills &&
        other.memories == memories &&
        other.total == total &&
        other.category == category &&
        other.color == color &&
        deepListEquals(other.nodes, nodes);
  }

  @override
  int get hashCode => Object.hash(
    index,
    label,
    date,
    skills,
    memories,
    total,
    category,
    color,
    Object.hashAll(nodes),
  );

  @override
  String toString() {
    return 'LearningBucket(index: $index, label: $label, date: $date, '
        'skills: $skills, memories: $memories, total: $total, '
        'category: $category, color: $color, nodes: $nodes)';
  }
}

/// One node within a bucket (skill or memory).
final class LearningNode {
  const LearningNode({
    required this.id,
    required this.glyph,
    required this.label,
    required this.fullLabel,
    required this.meta,
    required this.body,
    required this.style,
  });

  /// Node ID (skill name or `memory:<source>:<idx>`).
  final String id;

  /// Glyph (● skill, ◆ memory).
  final String glyph;

  /// Truncated label (≤26 chars).
  final String label;

  /// Full untruncated label.
  final String fullLabel;

  /// Source · date line.
  final String meta;

  /// Memory chunk body (skills: "").
  final String body;

  /// "skill" | "memory".
  final String style;

  @override
  bool operator ==(Object other) {
    return other is LearningNode &&
        other.id == id &&
        other.glyph == glyph &&
        other.label == label &&
        other.fullLabel == fullLabel &&
        other.meta == meta &&
        other.body == body &&
        other.style == style;
  }

  @override
  int get hashCode =>
      Object.hash(id, glyph, label, fullLabel, meta, body, style);

  @override
  String toString() {
    return 'LearningNode(id: $id, glyph: $glyph, label: $label, '
        'fullLabel: $fullLabel, meta: $meta, body: $body, style: $style)';
  }
}

/// Legend entry (glyph + style + label).
final class LearningLegend {
  const LearningLegend({
    required this.glyph,
    required this.style,
    required this.label,
  });

  /// Glyph character.
  final String glyph;

  /// Style identifier.
  final String style;

  /// Human-readable label.
  final String label;

  @override
  bool operator ==(Object other) {
    return other is LearningLegend &&
        other.glyph == glyph &&
        other.style == style &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(glyph, style, label);

  @override
  String toString() {
    return 'LearningLegend(glyph: $glyph, style: $style, label: $label)';
  }
}

/// Category legend entry (glyph + color + label).
final class LearningCategory {
  const LearningCategory({
    required this.glyph,
    required this.color,
    required this.label,
  });

  /// Glyph character.
  final String glyph;

  /// Color hex (#RRGGBB).
  final String color;

  /// Category label.
  final String label;

  @override
  bool operator ==(Object other) {
    return other is LearningCategory &&
        other.glyph == glyph &&
        other.color == color &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(glyph, color, label);

  @override
  String toString() {
    return 'LearningCategory(glyph: $glyph, color: $color, label: $label)';
  }
}

/// Full detail for a learning node (wire `learning.detail` result, P6-02).
final class LearningNodeDetail {
  const LearningNodeDetail({
    required this.ok,
    this.kind,
    required this.id,
    required this.label,
    required this.content,
    this.message,
  });

  /// Success flag.
  final bool ok;

  /// Node kind ("skill" | "memory", nullable on failure).
  final String? kind;

  /// Node ID.
  final String id;

  /// Display label.
  final String label;

  /// Full content text.
  final String content;

  /// Failure message (nullable on success).
  final String? message;

  @override
  bool operator ==(Object other) {
    return other is LearningNodeDetail &&
        other.ok == ok &&
        other.kind == kind &&
        other.id == id &&
        other.label == label &&
        other.content == content &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(ok, kind, id, label, content, message);

  @override
  String toString() {
    return 'LearningNodeDetail(ok: $ok, kind: $kind, id: $id, '
        'label: $label, content: $content, message: $message)';
  }
}

/// Result of a learning mutation (edit/delete).
typedef LearningMutationResult = ({bool ok, String message});
