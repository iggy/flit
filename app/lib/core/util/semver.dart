/// Semantic version comparison utility (ticket P9-08).
///
/// Numeric comparison (not lexicographic) of semver strings in `major.minor.patch`
/// format, tolerating build metadata (`+build`), pre-release tags (`-beta`), and
/// malformed input.
library;

/// Compares two semantic version strings numerically.
///
/// Returns:
/// - negative if [a] < [b]
/// - zero if [a] == [b] or both are unparsable
/// - positive if [a] > [b]
///
/// Tolerates:
/// - short forms: `"1"`, `"1.2"` treated as `"1.0.0"`, `"1.2.0"`
/// - build metadata: `"1.2.3+456"` (ignored)
/// - pre-release: `"1.2.3-beta"` (ignored)
/// - malformed input: `"abc"`, `"1.x.3"` → returns 0
///
/// Examples:
/// ```dart
/// compareSemver("1.10.0", "1.9.0") > 0   // numeric, not lexicographic
/// compareSemver("2.0.0", "1.99.99") > 0
/// compareSemver("1.2.3", "1.2.3") == 0
/// compareSemver("1.2.3+100", "1.2.3+200") == 0  // build metadata ignored
/// compareSemver("abc", "xyz") == 0  // unparsable → equal
/// ```
int compareSemver(String a, String b) {
  final verA = _parseSemver(a);
  final verB = _parseSemver(b);

  if (verA == null || verB == null) {
    return 0; // Unparsable → treat as equal
  }

  // Compare major, minor, patch numerically
  if (verA.major != verB.major) {
    return verA.major - verB.major;
  }
  if (verA.minor != verB.minor) {
    return verA.minor - verB.minor;
  }
  return verA.patch - verB.patch;
}

/// Parsed semantic version (major.minor.patch).
final class _SemverTriple {
  const _SemverTriple(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;
}

/// Parses a semantic version string into (major, minor, patch).
///
/// Returns null for unparsable input (non-numeric parts, empty string, etc.).
_SemverTriple? _parseSemver(String version) {
  if (version.isEmpty) {
    return null;
  }

  // Strip build metadata: "1.2.3+456" → "1.2.3"
  var stripped = version;
  if (stripped.contains('+')) {
    stripped = stripped.split('+').first;
  }

  // Strip pre-release: "1.2.3-beta" → "1.2.3"
  if (stripped.contains('-')) {
    stripped = stripped.split('-').first;
  }

  // Split on dots
  final parts = stripped.split('.');

  if (parts.isEmpty) {
    return null;
  }

  // Parse major, minor, patch (default to 0 for missing parts)
  final major = int.tryParse(parts[0]);
  if (major == null) {
    return null;
  }

  final minor = parts.length > 1 ? int.tryParse(parts[1]) : 0;
  if (minor == null) {
    return null;
  }

  final patch = parts.length > 2 ? int.tryParse(parts[2]) : 0;
  if (patch == null) {
    return null;
  }

  return _SemverTriple(major, minor, patch);
}
