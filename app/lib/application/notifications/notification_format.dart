/// Notification formatting utilities (ticket P9-03).
///
/// Pure functions for notification ID generation and body truncation, kept
/// separate and testable without Riverpod or Flutter dependencies.
library;

import 'dart:convert' show utf8;

import 'package:crypto/crypto.dart' show sha256;

/// Generate a stable, collision-resistant notification ID from a source key.
///
/// Returns a positive 31-bit integer (Android notification IDs must be
/// positive int32). The same key always produces the same ID; different keys
/// are unlikely to collide.
int notificationIdFor(String key) {
  // Hash the key with SHA-256, take the first 4 bytes, and mask to 31 bits.
  final hash = sha256.convert(utf8.encode(key));
  final firstFourBytes = hash.bytes.sublist(0, 4);
  final raw =
      (firstFourBytes[0] << 24) |
      (firstFourBytes[1] << 16) |
      (firstFourBytes[2] << 8) |
      firstFourBytes[3];
  // Mask to 31 bits to ensure positive.
  return raw & 0x7FFFFFFF;
}

/// Truncate and format raw text for a notification body.
///
/// Collapses newlines into spaces, trims whitespace, and caps the result at
/// [maxLength] characters (default 140). Returns empty string for empty input.
String notificationBody(String raw, {int maxLength = 140}) {
  if (raw.isEmpty) {
    return '';
  }
  // Collapse newlines and normalize whitespace.
  final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (collapsed.length <= maxLength) {
    return collapsed;
  }
  // Truncate with ellipsis.
  return '${collapsed.substring(0, maxLength - 1)}…';
}
