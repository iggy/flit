import 'package:flit/domain/repositories/reload_repository.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reload_dtos.g.dart';

/// Wire DTO for `reload.mcp` result.
@JsonSerializable()
class ReloadMcpResultDto {
  const ReloadMcpResultDto({
    this.status,
    this.message,
    this.coalesced,
  });

  factory ReloadMcpResultDto.fromJson(Map<String, dynamic> json) =>
      _$ReloadMcpResultDtoFromJson(json);

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'coalesced')
  final bool? coalesced;

  Map<String, dynamic> toJson() => _$ReloadMcpResultDtoToJson(this);

  ReloadMcpOutcome toDomain() {
    if (status == 'confirm_required') {
      return ReloadMcpConfirmRequired(message: message ?? '');
    }
    return ReloadMcpDone(coalesced: coalesced ?? false);
  }
}
