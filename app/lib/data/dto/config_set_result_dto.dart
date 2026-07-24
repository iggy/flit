import 'package:json_annotation/json_annotation.dart';

part 'config_set_result_dto.g.dart';

/// Wire DTO for the `config.set` result
/// (docs/reference/03-mvp-wire-shapes.md §9).
///
/// The result is polymorphic:
/// - normal: `{value, info?}` → [ConfigSetApplied]
/// - expensive model: `{confirm_required:true, confirm_message}` →
///   [ConfigSetConfirmRequired] (re-send with
///   `confirm_expensive_model:true` to proceed).
///
/// All fields nullable so either variant decodes; [toDomain] disambiguates.
@JsonSerializable()
class ConfigSetResultDto {
  const ConfigSetResultDto({
    this.value,
    this.info,
    this.confirmRequired,
    this.confirmMessage,
  });

  factory ConfigSetResultDto.fromJson(Map<String, dynamic> json) =>
      _$ConfigSetResultDtoFromJson(json);

  /// The applied value on success (string for `model`/`reasoning`, bool for
  /// `fast`, ... — hence dynamic).
  @JsonKey(name: 'value')
  final dynamic value;

  /// Opaque info dict on success.
  @JsonKey(name: 'info')
  final Map<String, dynamic>? info;

  /// True when the gateway demands confirmation before applying.
  @JsonKey(name: 'confirm_required')
  final bool? confirmRequired;

  /// The confirmation prompt to show, e.g.
  /// `This model is $X/Mtok. Continue?`.
  @JsonKey(name: 'confirm_message')
  final String? confirmMessage;

  Map<String, dynamic> toJson() => _$ConfigSetResultDtoToJson(this);

  /// Disambiguate the two wire variants (§9).
  ConfigSetResult toDomain() {
    if (confirmRequired ?? false) {
      return ConfigSetConfirmRequired(message: confirmMessage ?? '');
    }
    return ConfigSetApplied(value: value, info: info);
  }
}

/// Domain-facing result of `config.set` (§9). Kept in `data/dto` — it is a
/// wire concern, not a domain model.
sealed class ConfigSetResult {
  const ConfigSetResult();
}

/// The value was applied (wire `{value, info?}`).
final class ConfigSetApplied extends ConfigSetResult {
  const ConfigSetApplied({this.value, this.info});

  /// The applied value (type depends on the config key).
  final dynamic value;

  /// Opaque info dict, when the gateway returned one.
  final Map<String, dynamic>? info;

  @override
  bool operator ==(Object other) {
    return other is ConfigSetApplied &&
        other.value == value &&
        _infoEquals(other.info, info);
  }

  @override
  int get hashCode => Object.hash(value, info?.length);

  @override
  String toString() => 'ConfigSetApplied(value: $value, info: $info)';
}

/// The gateway demands confirmation (wire
/// `{confirm_required:true, confirm_message}`); re-send with
/// `confirm_expensive_model:true` to proceed (§9).
final class ConfigSetConfirmRequired extends ConfigSetResult {
  const ConfigSetConfirmRequired({required this.message});

  /// The confirmation prompt to show.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is ConfigSetConfirmRequired && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'ConfigSetConfirmRequired(message: $message)';
}

bool _infoEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
