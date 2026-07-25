import 'package:json_annotation/json_annotation.dart';

part 'background_dtos.g.dart';

/// Wire DTO for `prompt.background` result (ticket P5-02).
@JsonSerializable()
class PromptBackgroundResultDto {
  const PromptBackgroundResultDto({
    this.taskId,
  });

  factory PromptBackgroundResultDto.fromJson(Map<String, dynamic> json) =>
      _$PromptBackgroundResultDtoFromJson(json);

  @JsonKey(name: 'task_id')
  final String? taskId;

  Map<String, dynamic> toJson() => _$PromptBackgroundResultDtoToJson(this);

  String toDomain() {
    return taskId ?? '';
  }
}
