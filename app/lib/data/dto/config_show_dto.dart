import 'package:flit/domain/models/config_view.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_show_dto.g.dart';

/// Wire DTO for `config.show` result (ticket P4-06).
///
/// Wire shape: `{sections:[{title:str, rows:[[label,value], ...]}]}`
/// where rows are 2-element string arrays.
@JsonSerializable()
class ConfigShowResultDto {
  const ConfigShowResultDto({this.sections = const <ConfigSectionDto>[]});

  factory ConfigShowResultDto.fromJson(Map<String, dynamic> json) =>
      _$ConfigShowResultDtoFromJson(json);

  @JsonKey(name: 'sections')
  final List<ConfigSectionDto> sections;

  Map<String, dynamic> toJson() => _$ConfigShowResultDtoToJson(this);

  List<ConfigSection> toDomain() {
    return sections.map((dto) => dto.toDomain()).toList();
  }
}

/// One config section from `config.show`.
@JsonSerializable()
class ConfigSectionDto {
  const ConfigSectionDto({this.title, this.rows = const <List<dynamic>>[]});

  factory ConfigSectionDto.fromJson(Map<String, dynamic> json) =>
      _$ConfigSectionDtoFromJson(json);

  @JsonKey(name: 'title')
  final String? title;

  /// Wire rows are `List<dynamic>` of 2-element arrays; each row is
  /// `[label:str, value:str]`.
  @JsonKey(name: 'rows')
  final List<List<dynamic>> rows;

  Map<String, dynamic> toJson() => _$ConfigSectionDtoToJson(this);

  ConfigSection toDomain() {
    final domainRows = <ConfigRow>[];
    for (final row in rows) {
      if (row.length >= 2) {
        final label = row[0];
        final value = row[1];
        if (label is String && value is String) {
          domainRows.add(ConfigRow(label: label, value: value));
        }
      }
    }
    return ConfigSection(title: title ?? '', rows: domainRows);
  }
}
