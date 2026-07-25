abstract interface class ConfigRepository {
  Future<String?> getReasoning();

  Future<ReasoningSetOutcome> setReasoning(String value);
}

sealed class ReasoningSetOutcome {
  const ReasoningSetOutcome();
}

final class ReasoningSetApplied extends ReasoningSetOutcome {
  const ReasoningSetApplied({required this.value});

  final String value;

  @override
  bool operator ==(Object other) {
    return other is ReasoningSetApplied && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ReasoningSetApplied(value: $value)';
}

final class ReasoningSetNeedsConfirm extends ReasoningSetOutcome {
  const ReasoningSetNeedsConfirm({required this.message});

  final String message;

  @override
  bool operator ==(Object other) {
    return other is ReasoningSetNeedsConfirm && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ReasoningSetNeedsConfirm(message: $message)';
}
