import 'package:flit/domain/models/project_facts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_facts_dtos.g.dart';

/// Wire DTO for the facts object inside `project.facts` result (ticket P6-04).
@JsonSerializable()
class ProjectFactsDto {
  const ProjectFactsDto({
    this.root,
    this.manifests = const <String>[],
    this.packageManagers = const <String>[],
    this.verifyCommands = const <String>[],
    this.contextFiles = const <String>[],
  });

  factory ProjectFactsDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectFactsDtoFromJson(json);

  @JsonKey(name: 'root')
  final String? root;

  @JsonKey(name: 'manifests')
  final List<String> manifests;

  @JsonKey(name: 'packageManagers')
  final List<String> packageManagers;

  @JsonKey(name: 'verifyCommands')
  final List<String> verifyCommands;

  @JsonKey(name: 'contextFiles')
  final List<String> contextFiles;

  Map<String, dynamic> toJson() => _$ProjectFactsDtoToJson(this);

  ProjectFacts toDomain() {
    return ProjectFacts(
      root: root ?? '',
      manifests: manifests,
      packageManagers: packageManagers,
      verifyCommands: verifyCommands,
      contextFiles: contextFiles,
    );
  }
}

/// Wire DTO for `project.facts` result (ticket P6-04).
@JsonSerializable()
class ProjectFactsResultDto {
  const ProjectFactsResultDto({this.facts});

  factory ProjectFactsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectFactsResultDtoFromJson(json);

  @JsonKey(name: 'facts')
  final ProjectFactsDto? facts;

  Map<String, dynamic> toJson() => _$ProjectFactsResultDtoToJson(this);

  ProjectFacts? toDomain() {
    return facts?.toDomain();
  }
}
