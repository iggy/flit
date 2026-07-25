import 'package:flit/domain/models/deep_equals.dart';

/// A mid-turn blocking prompt the agent waits on (protocol §8).
///
/// Two correlation models — do not cross them:
/// - [ApprovalPrompt] is correlated by **session** (`approval.respond` takes
///   `session_id`); the event carries NO request id.
/// - [ClarifyPrompt] is correlated by **request_id** (`clarify.respond`).
sealed class InteractivePrompt {
  const InteractivePrompt();
}

/// `approval.request` (protocol §8.2 / wire §10): a command the user must
/// approve or deny before the tool proceeds.
final class ApprovalPrompt extends InteractivePrompt {
  const ApprovalPrompt({
    required this.sessionId,
    required this.command,
    required this.description,
    this.patternKey,
    this.patternKeys = const <String>[],
    this.allowPermanent = false,
  });

  /// Short live session id — the correlation key for `approval.respond`.
  final String sessionId;

  /// The command to approve (credential-redacted, protocol §8.2).
  final String command;

  /// Human-readable explanation, e.g. `Delete build dir`.
  final String description;

  /// Single match pattern, e.g. `rm`.
  final String? patternKey;

  /// All match patterns for "always allow" bookkeeping.
  final List<String> patternKeys;

  /// When true the UI may offer "always allow"
  /// (approve-and-remember, wire §10).
  final bool allowPermanent;

  @override
  bool operator ==(Object other) {
    return other is ApprovalPrompt &&
        other.sessionId == sessionId &&
        other.command == command &&
        other.description == description &&
        other.patternKey == patternKey &&
        deepListEquals(other.patternKeys, patternKeys) &&
        other.allowPermanent == allowPermanent;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    command,
    description,
    patternKey,
    Object.hashAll(patternKeys),
    allowPermanent,
  );

  @override
  String toString() {
    return 'ApprovalPrompt(sessionId: $sessionId, command: $command, '
        'description: $description, patternKey: $patternKey, '
        'patternKeys: $patternKeys, allowPermanent: $allowPermanent)';
  }
}

/// `clarify.request` (protocol §8.1 / wire §11): a question the agent
/// blocks on until the user answers.
final class ClarifyPrompt extends InteractivePrompt {
  const ClarifyPrompt({
    required this.sessionId,
    required this.question,
    this.choices,
    required this.requestId,
  });

  /// Short live session id the question belongs to.
  final String sessionId;

  /// The question text, e.g. `Which environment?`.
  final String question;

  /// Answer options; **null means free-text** (protocol §8.1:
  /// `choices: string[]|null`).
  final List<String>? choices;

  /// The correlation key for `clarify.respond` (8-hex request id minted by
  /// the gateway's `_block()`).
  final String requestId;

  @override
  bool operator ==(Object other) {
    return other is ClarifyPrompt &&
        other.sessionId == sessionId &&
        other.question == question &&
        _nullableListEquals(other.choices, choices) &&
        other.requestId == requestId;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    question,
    choices == null ? null : Object.hashAll(choices!),
    requestId,
  );

  @override
  String toString() {
    return 'ClarifyPrompt(sessionId: $sessionId, question: $question, '
        'choices: $choices, requestId: $requestId)';
  }
}

bool _nullableListEquals(List<String>? a, List<String>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return deepListEquals(a, b);
}
