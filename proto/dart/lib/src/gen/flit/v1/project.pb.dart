// This is a generated file - do not edit.
//
// Generated from flit/v1/project.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Project extends $pb.GeneratedMessage {
  factory Project({
    $core.String? id,
    $core.String? teamId,
    $core.String? name,
    $core.String? directory,
    $core.int? sessionCount,
    $0.Timestamp? createTime,
    $core.bool? exportEnabled,
    $core.bool? worktrees,
    $core.bool? worktreesEnabled,
  }) {
    final result = Project._();
    if (id != null) result.id = id;
    if (teamId != null) result.teamId = teamId;
    if (name != null) result.name = name;
    if (directory != null) result.directory = directory;
    if (sessionCount != null) result.sessionCount = sessionCount;
    if (createTime != null) result.createTime = createTime;
    if (exportEnabled != null) result.exportEnabled = exportEnabled;
    if (worktrees != null) result.worktrees = worktrees;
    if (worktreesEnabled != null) result.worktreesEnabled = worktreesEnabled;
    return result;
  }

  Project._();

  factory Project.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Project()..mergeFromBuffer(data, registry);
  factory Project.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Project()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Project',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Project.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'teamId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'directory')
    ..aI(5, _omitFieldNames ? '' : 'sessionCount')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'createTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOB(7, _omitFieldNames ? '' : 'exportEnabled')
    ..aOB(8, _omitFieldNames ? '' : 'worktrees')
    ..aOB(9, _omitFieldNames ? '' : 'worktreesEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Project clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Project copyWith(void Function(Project) updates) =>
      super.copyWith((message) => updates(message as Project)) as Project;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Project() / Project.new instead')
  static Project create() => Project._();
  static $pb.GeneratedMessage $_createMessage() => Project._();
  @$core.override
  Project createEmptyInstance() => Project._();
  @$core.pragma('dart2js:noInline')
  static Project getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Project>(Project.$_createMessage);
  static Project? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get teamId => $_getSZ(1);
  @$pb.TagNumber(2)
  set teamId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTeamId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTeamId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  /// Absolute directory on the server; empty for Scratch.
  @$pb.TagNumber(4)
  $core.String get directory => $_getSZ(3);
  @$pb.TagNumber(4)
  set directory($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDirectory() => $_has(3);
  @$pb.TagNumber(4)
  void clearDirectory() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sessionCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set sessionCount($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSessionCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearSessionCount() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Timestamp get createTime => $_getN(5);
  @$pb.TagNumber(6)
  set createTime($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreateTime() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureCreateTime() => $_ensure(5);

  /// Whether "flit export" includes this project's sessions.
  @$pb.TagNumber(7)
  $core.bool get exportEnabled => $_getBF(6);
  @$pb.TagNumber(7)
  set exportEnabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasExportEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearExportEnabled() => $_clearField(7);

  /// The project's choice of per-session worktrees; unset means the
  /// config's default. worktrees_enabled is the result.
  @$pb.TagNumber(8)
  $core.bool get worktrees => $_getBF(7);
  @$pb.TagNumber(8)
  set worktrees($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWorktrees() => $_has(7);
  @$pb.TagNumber(8)
  void clearWorktrees() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get worktreesEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set worktreesEnabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWorktreesEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearWorktreesEnabled() => $_clearField(9);
}

class ListProjectsRequest extends $pb.GeneratedMessage {
  factory ListProjectsRequest() => ListProjectsRequest._();

  ListProjectsRequest._();

  factory ListProjectsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProjectsRequest()..mergeFromBuffer(data, registry);
  factory ListProjectsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProjectsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProjectsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListProjectsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProjectsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProjectsRequest copyWith(void Function(ListProjectsRequest) updates) =>
      super.copyWith((message) => updates(message as ListProjectsRequest))
          as ListProjectsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListProjectsRequest() / ListProjectsRequest.new instead')
  static ListProjectsRequest create() => ListProjectsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListProjectsRequest._();
  @$core.override
  ListProjectsRequest createEmptyInstance() => ListProjectsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListProjectsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProjectsRequest>(
          ListProjectsRequest.$_createMessage);
  static ListProjectsRequest? _defaultInstance;
}

class ListProjectsResponse extends $pb.GeneratedMessage {
  factory ListProjectsResponse({
    $core.Iterable<Project>? projects,
  }) {
    final result = ListProjectsResponse._();
    if (projects != null) result.projects.addAll(projects);
    return result;
  }

  ListProjectsResponse._();

  factory ListProjectsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProjectsResponse()..mergeFromBuffer(data, registry);
  factory ListProjectsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProjectsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProjectsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListProjectsResponse.$_createMessage)
    ..pPM<Project>(1, _omitFieldNames ? '' : 'projects',
        subBuilder: Project.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProjectsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProjectsResponse copyWith(void Function(ListProjectsResponse) updates) =>
      super.copyWith((message) => updates(message as ListProjectsResponse))
          as ListProjectsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListProjectsResponse() / ListProjectsResponse.new instead')
  static ListProjectsResponse create() => ListProjectsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListProjectsResponse._();
  @$core.override
  ListProjectsResponse createEmptyInstance() => ListProjectsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListProjectsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProjectsResponse>(
          ListProjectsResponse.$_createMessage);
  static ListProjectsResponse? _defaultInstance;

  /// Scratch first, then by name.
  @$pb.TagNumber(1)
  $pb.PbList<Project> get projects => $_getList(0);
}

class CreateProjectRequest extends $pb.GeneratedMessage {
  factory CreateProjectRequest({
    $core.String? directory,
    $core.String? name,
  }) {
    final result = CreateProjectRequest._();
    if (directory != null) result.directory = directory;
    if (name != null) result.name = name;
    return result;
  }

  CreateProjectRequest._();

  factory CreateProjectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateProjectRequest()..mergeFromBuffer(data, registry);
  factory CreateProjectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateProjectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateProjectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreateProjectRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'directory')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateProjectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateProjectRequest copyWith(void Function(CreateProjectRequest) updates) =>
      super.copyWith((message) => updates(message as CreateProjectRequest))
          as CreateProjectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateProjectRequest() / CreateProjectRequest.new instead')
  static CreateProjectRequest create() => CreateProjectRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateProjectRequest._();
  @$core.override
  CreateProjectRequest createEmptyInstance() => CreateProjectRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateProjectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateProjectRequest>(
          CreateProjectRequest.$_createMessage);
  static CreateProjectRequest? _defaultInstance;

  /// Directory on the server; must exist. Required.
  @$pb.TagNumber(1)
  $core.String get directory => $_getSZ(0);
  @$pb.TagNumber(1)
  set directory($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDirectory() => $_has(0);
  @$pb.TagNumber(1)
  void clearDirectory() => $_clearField(1);

  /// Empty means the directory's base name.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class CreateProjectResponse extends $pb.GeneratedMessage {
  factory CreateProjectResponse({
    Project? project,
  }) {
    final result = CreateProjectResponse._();
    if (project != null) result.project = project;
    return result;
  }

  CreateProjectResponse._();

  factory CreateProjectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateProjectResponse()..mergeFromBuffer(data, registry);
  factory CreateProjectResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateProjectResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateProjectResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreateProjectResponse.$_createMessage)
    ..aOM<Project>(1, _omitFieldNames ? '' : 'project',
        subBuilder: Project.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateProjectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateProjectResponse copyWith(
          void Function(CreateProjectResponse) updates) =>
      super.copyWith((message) => updates(message as CreateProjectResponse))
          as CreateProjectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateProjectResponse() / CreateProjectResponse.new instead')
  static CreateProjectResponse create() => CreateProjectResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateProjectResponse._();
  @$core.override
  CreateProjectResponse createEmptyInstance() => CreateProjectResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateProjectResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateProjectResponse>(
          CreateProjectResponse.$_createMessage);
  static CreateProjectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Project get project => $_getN(0);
  @$pb.TagNumber(1)
  set project(Project value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);
  @$pb.TagNumber(1)
  Project ensureProject() => $_ensure(0);
}

class SetProjectExportRequest extends $pb.GeneratedMessage {
  factory SetProjectExportRequest({
    $core.String? projectId,
    $core.bool? enabled,
  }) {
    final result = SetProjectExportRequest._();
    if (projectId != null) result.projectId = projectId;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetProjectExportRequest._();

  factory SetProjectExportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectExportRequest()..mergeFromBuffer(data, registry);
  factory SetProjectExportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectExportRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetProjectExportRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetProjectExportRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'projectId')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectExportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectExportRequest copyWith(
          void Function(SetProjectExportRequest) updates) =>
      super.copyWith((message) => updates(message as SetProjectExportRequest))
          as SetProjectExportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetProjectExportRequest() / SetProjectExportRequest.new instead')
  static SetProjectExportRequest create() => SetProjectExportRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetProjectExportRequest._();
  @$core.override
  SetProjectExportRequest createEmptyInstance() => SetProjectExportRequest._();
  @$core.pragma('dart2js:noInline')
  static SetProjectExportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetProjectExportRequest>(
          SetProjectExportRequest.$_createMessage);
  static SetProjectExportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get projectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set projectId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProjectId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class SetProjectExportResponse extends $pb.GeneratedMessage {
  factory SetProjectExportResponse({
    Project? project,
  }) {
    final result = SetProjectExportResponse._();
    if (project != null) result.project = project;
    return result;
  }

  SetProjectExportResponse._();

  factory SetProjectExportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectExportResponse()..mergeFromBuffer(data, registry);
  factory SetProjectExportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectExportResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetProjectExportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetProjectExportResponse.$_createMessage)
    ..aOM<Project>(1, _omitFieldNames ? '' : 'project',
        subBuilder: Project.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectExportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectExportResponse copyWith(
          void Function(SetProjectExportResponse) updates) =>
      super.copyWith((message) => updates(message as SetProjectExportResponse))
          as SetProjectExportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetProjectExportResponse() / SetProjectExportResponse.new instead')
  static SetProjectExportResponse create() => SetProjectExportResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetProjectExportResponse._();
  @$core.override
  SetProjectExportResponse createEmptyInstance() =>
      SetProjectExportResponse._();
  @$core.pragma('dart2js:noInline')
  static SetProjectExportResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetProjectExportResponse>(
          SetProjectExportResponse.$_createMessage);
  static SetProjectExportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Project get project => $_getN(0);
  @$pb.TagNumber(1)
  set project(Project value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);
  @$pb.TagNumber(1)
  Project ensureProject() => $_ensure(0);
}

class SetProjectWorktreesRequest extends $pb.GeneratedMessage {
  factory SetProjectWorktreesRequest({
    $core.String? projectId,
    $core.bool? enabled,
  }) {
    final result = SetProjectWorktreesRequest._();
    if (projectId != null) result.projectId = projectId;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetProjectWorktreesRequest._();

  factory SetProjectWorktreesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectWorktreesRequest()..mergeFromBuffer(data, registry);
  factory SetProjectWorktreesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectWorktreesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetProjectWorktreesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetProjectWorktreesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'projectId')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectWorktreesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectWorktreesRequest copyWith(
          void Function(SetProjectWorktreesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetProjectWorktreesRequest))
          as SetProjectWorktreesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetProjectWorktreesRequest() / SetProjectWorktreesRequest.new instead')
  static SetProjectWorktreesRequest create() => SetProjectWorktreesRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetProjectWorktreesRequest._();
  @$core.override
  SetProjectWorktreesRequest createEmptyInstance() =>
      SetProjectWorktreesRequest._();
  @$core.pragma('dart2js:noInline')
  static SetProjectWorktreesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetProjectWorktreesRequest>(
          SetProjectWorktreesRequest.$_createMessage);
  static SetProjectWorktreesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get projectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set projectId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProjectId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class SetProjectWorktreesResponse extends $pb.GeneratedMessage {
  factory SetProjectWorktreesResponse({
    Project? project,
  }) {
    final result = SetProjectWorktreesResponse._();
    if (project != null) result.project = project;
    return result;
  }

  SetProjectWorktreesResponse._();

  factory SetProjectWorktreesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectWorktreesResponse()..mergeFromBuffer(data, registry);
  factory SetProjectWorktreesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetProjectWorktreesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetProjectWorktreesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetProjectWorktreesResponse.$_createMessage)
    ..aOM<Project>(1, _omitFieldNames ? '' : 'project',
        subBuilder: Project.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectWorktreesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetProjectWorktreesResponse copyWith(
          void Function(SetProjectWorktreesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SetProjectWorktreesResponse))
          as SetProjectWorktreesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetProjectWorktreesResponse() / SetProjectWorktreesResponse.new instead')
  static SetProjectWorktreesResponse create() =>
      SetProjectWorktreesResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetProjectWorktreesResponse._();
  @$core.override
  SetProjectWorktreesResponse createEmptyInstance() =>
      SetProjectWorktreesResponse._();
  @$core.pragma('dart2js:noInline')
  static SetProjectWorktreesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetProjectWorktreesResponse>(
          SetProjectWorktreesResponse.$_createMessage);
  static SetProjectWorktreesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Project get project => $_getN(0);
  @$pb.TagNumber(1)
  set project(Project value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);
  @$pb.TagNumber(1)
  Project ensureProject() => $_ensure(0);
}

/// ProjectService manages projects. A project groups sessions and usually
/// points at a directory on the server, which new sessions in it work in.
/// Every team starts with a project called "Scratch" that has no directory.
class ProjectServiceApi {
  final $pb.RpcClient _client;

  ProjectServiceApi(this._client);

  $async.Future<ListProjectsResponse> listProjects(
          $pb.ClientContext? ctx, ListProjectsRequest request) =>
      _client.invoke<ListProjectsResponse>(ctx, 'ProjectService',
          'ListProjects', request, ListProjectsResponse());

  /// CreateProject adds a project for a directory on the server.
  $async.Future<CreateProjectResponse> createProject(
          $pb.ClientContext? ctx, CreateProjectRequest request) =>
      _client.invoke<CreateProjectResponse>(ctx, 'ProjectService',
          'CreateProject', request, CreateProjectResponse());

  /// SetProjectExport includes or excludes a project's sessions from
  /// "flit export". Projects are included by default.
  $async.Future<SetProjectExportResponse> setProjectExport(
          $pb.ClientContext? ctx, SetProjectExportRequest request) =>
      _client.invoke<SetProjectExportResponse>(ctx, 'ProjectService',
          'SetProjectExport', request, SetProjectExportResponse());

  /// SetProjectWorktrees sets whether new sessions in the project get their
  /// own git worktree and branch (when its directory is in a repository).
  /// Unset goes back to the config's git.worktrees.default. Existing
  /// sessions keep what they have.
  $async.Future<SetProjectWorktreesResponse> setProjectWorktrees(
          $pb.ClientContext? ctx, SetProjectWorktreesRequest request) =>
      _client.invoke<SetProjectWorktreesResponse>(ctx, 'ProjectService',
          'SetProjectWorktrees', request, SetProjectWorktreesResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
