import 'package:flit/domain/models/config_view.dart';

abstract interface class ConfigRepository {
  Future<String?> getReasoning();

  Future<ReasoningSetOutcome> setReasoning(String value);

  /// `config.get{key:"fast"}` (ticket P4-02).
  Future<bool> getFast();

  /// `config.set{key:"fast", value:"fast"|"normal"}` (ticket P4-02).
  Future<void> setFast(bool value);

  /// `config.get{key:"personality"}` (ticket P4-02).
  Future<String?> getPersonality();

  /// `config.set{key:"personality", value:"<name>"}` (ticket P4-02).
  Future<void> setPersonality(String value);

  /// `config.get{key:"prompt"}` — NOTE: result field is `prompt` not `value`
  /// (ticket P4-02).
  Future<String?> getPrompt();

  /// `config.set{key:"prompt", value:"<text>"|"clear"}` (ticket P4-02).
  Future<void> setPrompt(String value);

  /// `config.show` — list all config sections (ticket P4-06).
  Future<List<ConfigSection>> showConfig();

  /// `config.get{key}` — generic key getter, returns raw result map
  /// (ticket P4-06).
  Future<Map<String, dynamic>> getKey(String key, {String? sessionId});

  /// `config.set{key, value}` — generic key setter (ticket P4-06).
  Future<ConfigSetOutcome> setKey(
    String key,
    dynamic value, {
    String? sessionId,
    bool confirmExpensive = false,
  });
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

/// Generic config.set result (ticket P4-06). Maps from
/// [ConfigSetResultDto.toDomain()].
sealed class ConfigSetOutcome {
  const ConfigSetOutcome();
}

/// The config value was applied (ticket P4-06).
final class ConfigKeyApplied extends ConfigSetOutcome {
  const ConfigKeyApplied({required this.value, this.warning});

  /// The applied value (type depends on the config key).
  final dynamic value;

  /// Non-empty warning indicates credential-warning (ticket P4-06).
  final String? warning;

  @override
  bool operator ==(Object other) {
    return other is ConfigKeyApplied &&
        other.value == value &&
        other.warning == warning;
  }

  @override
  int get hashCode => Object.hash(value, warning);

  @override
  String toString() => 'ConfigKeyApplied(value: $value, warning: $warning)';
}

/// The gateway demands confirmation before applying (ticket P4-06).
final class ConfigKeyNeedsConfirm extends ConfigSetOutcome {
  const ConfigKeyNeedsConfirm(this.message);

  final String message;

  @override
  bool operator ==(Object other) {
    return other is ConfigKeyNeedsConfirm && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ConfigKeyNeedsConfirm(message: $message)';
}
