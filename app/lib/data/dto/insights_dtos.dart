import 'package:flit/domain/models/insights.dart';
import 'package:json_annotation/json_annotation.dart';

part 'insights_dtos.g.dart';

/// Wire DTO for `insights.get` result (ticket P6-03).
@JsonSerializable()
class InsightsResultDto {
  const InsightsResultDto({this.days, this.sessions, this.messages});

  factory InsightsResultDto.fromJson(Map<String, dynamic> json) =>
      _$InsightsResultDtoFromJson(json);

  @JsonKey(name: 'days')
  final int? days;

  @JsonKey(name: 'sessions')
  final int? sessions;

  @JsonKey(name: 'messages')
  final int? messages;

  Map<String, dynamic> toJson() => _$InsightsResultDtoToJson(this);

  Insights toDomain() {
    return Insights(
      days: days ?? 0,
      sessions: sessions ?? 0,
      messages: messages ?? 0,
    );
  }
}
