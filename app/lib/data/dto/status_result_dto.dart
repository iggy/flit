import 'package:json_annotation/json_annotation.dart';

part 'status_result_dto.g.dart';

/// Wire DTO for the single-field `{status}` results
/// (docs/reference/03-mvp-wire-shapes.md):
/// - §6 `prompt.submit` → `{"status":"streaming"}` — NOT `{ok:true}`
///   (divergence table, 00-overview.md).
/// - §12 `session.interrupt` → `{"status":"interrupted"}`.
///
/// Repositories assert the expected status string; there is no domain
/// model for this — it's a wire-level acknowledgement.
@JsonSerializable()
class StatusResultDto {
  const StatusResultDto({this.status});

  factory StatusResultDto.fromJson(Map<String, dynamic> json) =>
      _$StatusResultDtoFromJson(json);

  @JsonKey(name: 'status')
  final String? status;

  Map<String, dynamic> toJson() => _$StatusResultDtoToJson(this);
}
