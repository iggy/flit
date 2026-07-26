/// Pure fuzzy-matching functions for command palette filtering (P9-04).
/// No Riverpod, no Flutter — unit-testable.
library;

/// Check if [query] matches [candidate] as a case-insensitive subsequence.
/// An empty query matches everything.
bool fuzzyMatches(String query, String candidate) {
  if (query.isEmpty) {
    return true;
  }
  final queryLower = query.toLowerCase();
  final candidateLower = candidate.toLowerCase();
  var queryIndex = 0;
  for (
    var i = 0;
    i < candidateLower.length && queryIndex < queryLower.length;
    i++
  ) {
    if (candidateLower[i] == queryLower[queryIndex]) {
      queryIndex++;
    }
  }
  return queryIndex == queryLower.length;
}

/// Score [query] against [candidate] (higher = better match).
/// Returns 0 if no match. Rules:
/// - Exact prefix = 1000
/// - Word-boundary prefix (after space/slash) = 500
/// - Scattered subsequence = 100
int fuzzyScore(String query, String candidate) {
  if (query.isEmpty) {
    return 0;
  }
  if (!fuzzyMatches(query, candidate)) {
    return 0;
  }
  final queryLower = query.toLowerCase();
  final candidateLower = candidate.toLowerCase();

  // Exact prefix
  if (candidateLower.startsWith(queryLower)) {
    return 1000;
  }

  // Word-boundary prefix (after space or slash)
  for (var i = 1; i < candidateLower.length; i++) {
    final prev = candidateLower[i - 1];
    if ((prev == ' ' || prev == '/') &&
        candidateLower.startsWith(queryLower, i)) {
      return 500;
    }
  }

  // Scattered subsequence
  return 100;
}

/// Rank [commands] by matching [query]. Empty query returns all commands in
/// original order. Non-matching commands are filtered out. Ties preserve
/// original relative order (stable sort).
List<T> rankCommands<T>(
  List<T> commands,
  String query,
  String Function(T) label,
) {
  if (query.isEmpty) {
    return commands;
  }
  final scored = <({T command, int score, int originalIndex})>[];
  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    final score = fuzzyScore(query, label(command));
    if (score > 0) {
      scored.add((command: command, score: score, originalIndex: i));
    }
  }
  // Sort by score descending, then by originalIndex ascending (stable).
  scored.sort((a, b) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) {
      return scoreCmp;
    }
    return a.originalIndex.compareTo(b.originalIndex);
  });
  return scored.map((e) => e.command).toList();
}
