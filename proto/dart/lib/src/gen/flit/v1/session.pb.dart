// This is a generated file - do not edit.
//
// Generated from flit/v1/session.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $0;

import 'session.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'session.pbenum.dart';

class Session extends $pb.GeneratedMessage {
  factory Session({
    $core.String? id,
    $core.String? teamId,
    $core.String? projectId,
    $core.String? title,
    $core.String? workingDir,
    $core.String? provider,
    $core.String? model,
    TaskState? state,
    $fixnum.Int64? lastSeq,
    $0.Timestamp? createTime,
    $0.Timestamp? updateTime,
    $core.String? effort,
    $core.String? role,
    $fixnum.Int64? contextTokens,
    $fixnum.Int64? contextLength,
    $core.Iterable<$core.String>? mcpServers,
    $core.bool? yolo,
    $core.String? branchId,
    $core.String? baseCommit,
  }) {
    final result = Session._();
    if (id != null) result.id = id;
    if (teamId != null) result.teamId = teamId;
    if (projectId != null) result.projectId = projectId;
    if (title != null) result.title = title;
    if (workingDir != null) result.workingDir = workingDir;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (state != null) result.state = state;
    if (lastSeq != null) result.lastSeq = lastSeq;
    if (createTime != null) result.createTime = createTime;
    if (updateTime != null) result.updateTime = updateTime;
    if (effort != null) result.effort = effort;
    if (role != null) result.role = role;
    if (contextTokens != null) result.contextTokens = contextTokens;
    if (contextLength != null) result.contextLength = contextLength;
    if (mcpServers != null) result.mcpServers.addAll(mcpServers);
    if (yolo != null) result.yolo = yolo;
    if (branchId != null) result.branchId = branchId;
    if (baseCommit != null) result.baseCommit = baseCommit;
    return result;
  }

  Session._();

  factory Session.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromBuffer(data, registry);
  factory Session.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Session',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Session.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'teamId')
    ..aOS(3, _omitFieldNames ? '' : 'projectId')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'workingDir')
    ..aOS(6, _omitFieldNames ? '' : 'provider')
    ..aOS(7, _omitFieldNames ? '' : 'model')
    ..aE<TaskState>(8, _omitFieldNames ? '' : 'state',
        enumValues: TaskState.values)
    ..aInt64(9, _omitFieldNames ? '' : 'lastSeq')
    ..aOM<$0.Timestamp>(10, _omitFieldNames ? '' : 'createTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(11, _omitFieldNames ? '' : 'updateTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(12, _omitFieldNames ? '' : 'effort')
    ..aOS(13, _omitFieldNames ? '' : 'role')
    ..aInt64(14, _omitFieldNames ? '' : 'contextTokens')
    ..aInt64(15, _omitFieldNames ? '' : 'contextLength')
    ..pPS(16, _omitFieldNames ? '' : 'mcpServers')
    ..aOB(17, _omitFieldNames ? '' : 'yolo')
    ..aOS(18, _omitFieldNames ? '' : 'branchId')
    ..aOS(19, _omitFieldNames ? '' : 'baseCommit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session copyWith(void Function(Session) updates) =>
      super.copyWith((message) => updates(message as Session)) as Session;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Session() / Session.new instead')
  static Session create() => Session._();
  static $pb.GeneratedMessage $_createMessage() => Session._();
  @$core.override
  Session createEmptyInstance() => Session._();
  @$core.pragma('dart2js:noInline')
  static Session getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Session>(Session.$_createMessage);
  static Session? _defaultInstance;

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
  $core.String get projectId => $_getSZ(2);
  @$pb.TagNumber(3)
  set projectId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProjectId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProjectId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  /// Absolute path the agent works in.
  @$pb.TagNumber(5)
  $core.String get workingDir => $_getSZ(4);
  @$pb.TagNumber(5)
  set workingDir($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWorkingDir() => $_has(4);
  @$pb.TagNumber(5)
  void clearWorkingDir() => $_clearField(5);

  /// Name of the configured provider endpoint, and the model on it.
  @$pb.TagNumber(6)
  $core.String get provider => $_getSZ(5);
  @$pb.TagNumber(6)
  set provider($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearProvider() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get model => $_getSZ(6);
  @$pb.TagNumber(7)
  set model($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearModel() => $_clearField(7);

  @$pb.TagNumber(8)
  TaskState get state => $_getN(7);
  @$pb.TagNumber(8)
  set state(TaskState value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(8)
  void clearState() => $_clearField(8);

  /// Sequence number of the newest event; 0 if there are none.
  @$pb.TagNumber(9)
  $fixnum.Int64 get lastSeq => $_getI64(8);
  @$pb.TagNumber(9)
  set lastSeq($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastSeq() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastSeq() => $_clearField(9);

  @$pb.TagNumber(10)
  $0.Timestamp get createTime => $_getN(9);
  @$pb.TagNumber(10)
  set createTime($0.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCreateTime() => $_has(9);
  @$pb.TagNumber(10)
  void clearCreateTime() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.Timestamp ensureCreateTime() => $_ensure(9);

  @$pb.TagNumber(11)
  $0.Timestamp get updateTime => $_getN(10);
  @$pb.TagNumber(11)
  set updateTime($0.Timestamp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasUpdateTime() => $_has(10);
  @$pb.TagNumber(11)
  void clearUpdateTime() => $_clearField(11);
  @$pb.TagNumber(11)
  $0.Timestamp ensureUpdateTime() => $_ensure(10);

  /// Reasoning effort ("low", "medium", "high", ...); empty means the
  /// model's default.
  @$pb.TagNumber(12)
  $core.String get effort => $_getSZ(11);
  @$pb.TagNumber(12)
  set effort($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasEffort() => $_has(11);
  @$pb.TagNumber(12)
  void clearEffort() => $_clearField(12);

  /// The role the session was created with; empty for none.
  @$pb.TagNumber(13)
  $core.String get role => $_getSZ(12);
  @$pb.TagNumber(13)
  set role($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasRole() => $_has(12);
  @$pb.TagNumber(13)
  void clearRole() => $_clearField(13);

  /// Context use after the last model call: tokens in the prompt plus the
  /// reply, and the model's context window (0 if unknown).
  @$pb.TagNumber(14)
  $fixnum.Int64 get contextTokens => $_getI64(13);
  @$pb.TagNumber(14)
  set contextTokens($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasContextTokens() => $_has(13);
  @$pb.TagNumber(14)
  void clearContextTokens() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get contextLength => $_getI64(14);
  @$pb.TagNumber(15)
  set contextLength($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasContextLength() => $_has(14);
  @$pb.TagNumber(15)
  void clearContextLength() => $_clearField(15);

  /// MCP servers enabled for the session.
  @$pb.TagNumber(16)
  $pb.PbList<$core.String> get mcpServers => $_getList(15);

  /// Yolo mode: every shell command runs unless a deny rule matches.
  @$pb.TagNumber(17)
  $core.bool get yolo => $_getBF(16);
  @$pb.TagNumber(17)
  set yolo($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasYolo() => $_has(16);
  @$pb.TagNumber(17)
  void clearYolo() => $_clearField(17);

  /// The active branch (see Event.branch_id); empty is the root branch.
  @$pb.TagNumber(18)
  $core.String get branchId => $_getSZ(17);
  @$pb.TagNumber(18)
  set branchId($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasBranchId() => $_has(17);
  @$pb.TagNumber(18)
  void clearBranchId() => $_clearField(18);

  /// The git commit HEAD was on when the session was created; empty if the
  /// working directory wasn't in a git repository with commits.
  @$pb.TagNumber(19)
  $core.String get baseCommit => $_getSZ(18);
  @$pb.TagNumber(19)
  set baseCommit($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasBaseCommit() => $_has(18);
  @$pb.TagNumber(19)
  void clearBaseCommit() => $_clearField(19);
}

class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? workingDir,
    $core.String? title,
    $core.String? provider,
    $core.String? model,
    $core.String? role,
    $core.String? effort,
    $core.String? projectId,
    $core.bool? yolo,
  }) {
    final result = CreateSessionRequest._();
    if (workingDir != null) result.workingDir = workingDir;
    if (title != null) result.title = title;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (role != null) result.role = role;
    if (effort != null) result.effort = effort;
    if (projectId != null) result.projectId = projectId;
    if (yolo != null) result.yolo = yolo;
    return result;
  }

  CreateSessionRequest._();

  factory CreateSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionRequest()..mergeFromBuffer(data, registry);
  factory CreateSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreateSessionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'workingDir')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..aOS(5, _omitFieldNames ? '' : 'role')
    ..aOS(6, _omitFieldNames ? '' : 'effort')
    ..aOS(7, _omitFieldNames ? '' : 'projectId')
    ..aOB(8, _omitFieldNames ? '' : 'yolo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest copyWith(void Function(CreateSessionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSessionRequest))
          as CreateSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateSessionRequest() / CreateSessionRequest.new instead')
  static CreateSessionRequest create() => CreateSessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateSessionRequest._();
  @$core.override
  CreateSessionRequest createEmptyInstance() => CreateSessionRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionRequest>(
          CreateSessionRequest.$_createMessage);
  static CreateSessionRequest? _defaultInstance;

  /// Directory the agent works in. Must exist. Required.
  @$pb.TagNumber(1)
  $core.String get workingDir => $_getSZ(0);
  @$pb.TagNumber(1)
  set workingDir($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWorkingDir() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkingDir() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  /// Provider and model. Empty means the role's, then the config's chat
  /// task defaults.
  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get model => $_getSZ(3);
  @$pb.TagNumber(4)
  set model($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);

  /// Role name (see RoleService); empty for none.
  @$pb.TagNumber(5)
  $core.String get role => $_getSZ(4);
  @$pb.TagNumber(5)
  set role($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRole() => $_has(4);
  @$pb.TagNumber(5)
  void clearRole() => $_clearField(5);

  /// Reasoning effort; empty means the role's, then the config's.
  @$pb.TagNumber(6)
  $core.String get effort => $_getSZ(5);
  @$pb.TagNumber(6)
  set effort($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEffort() => $_has(5);
  @$pb.TagNumber(6)
  void clearEffort() => $_clearField(6);

  /// Project to create the session in; empty means Scratch. If
  /// working_dir is empty, the project's directory is used.
  @$pb.TagNumber(7)
  $core.String get projectId => $_getSZ(6);
  @$pb.TagNumber(7)
  set projectId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProjectId() => $_has(6);
  @$pb.TagNumber(7)
  void clearProjectId() => $_clearField(7);

  /// Yolo mode (see Session.yolo); unset means the config's shell.yolo.
  @$pb.TagNumber(8)
  $core.bool get yolo => $_getBF(7);
  @$pb.TagNumber(8)
  set yolo($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasYolo() => $_has(7);
  @$pb.TagNumber(8)
  void clearYolo() => $_clearField(8);
}

class CreateSessionResponse extends $pb.GeneratedMessage {
  factory CreateSessionResponse({
    Session? session,
  }) {
    final result = CreateSessionResponse._();
    if (session != null) result.session = session;
    return result;
  }

  CreateSessionResponse._();

  factory CreateSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionResponse()..mergeFromBuffer(data, registry);
  factory CreateSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreateSessionResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionResponse copyWith(
          void Function(CreateSessionResponse) updates) =>
      super.copyWith((message) => updates(message as CreateSessionResponse))
          as CreateSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateSessionResponse() / CreateSessionResponse.new instead')
  static CreateSessionResponse create() => CreateSessionResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateSessionResponse._();
  @$core.override
  CreateSessionResponse createEmptyInstance() => CreateSessionResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionResponse>(
          CreateSessionResponse.$_createMessage);
  static CreateSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class ListSessionsRequest extends $pb.GeneratedMessage {
  factory ListSessionsRequest({
    $core.int? pageSize,
    $core.String? pageToken,
    $core.String? projectId,
  }) {
    final result = ListSessionsRequest._();
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    if (projectId != null) result.projectId = projectId;
    return result;
  }

  ListSessionsRequest._();

  factory ListSessionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSessionsRequest()..mergeFromBuffer(data, registry);
  factory ListSessionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSessionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListSessionsRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'pageSize')
    ..aOS(2, _omitFieldNames ? '' : 'pageToken')
    ..aOS(3, _omitFieldNames ? '' : 'projectId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsRequest copyWith(void Function(ListSessionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSessionsRequest))
          as ListSessionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListSessionsRequest() / ListSessionsRequest.new instead')
  static ListSessionsRequest create() => ListSessionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListSessionsRequest._();
  @$core.override
  ListSessionsRequest createEmptyInstance() => ListSessionsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListSessionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsRequest>(
          ListSessionsRequest.$_createMessage);
  static ListSessionsRequest? _defaultInstance;

  /// Maximum sessions to return; 0 means a server default.
  @$pb.TagNumber(1)
  $core.int get pageSize => $_getIZ(0);
  @$pb.TagNumber(1)
  set pageSize($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPageSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearPageSize() => $_clearField(1);

  /// From a previous response's next_page_token.
  @$pb.TagNumber(2)
  $core.String get pageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set pageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageToken() => $_clearField(2);

  /// Only sessions in this project; empty means all.
  @$pb.TagNumber(3)
  $core.String get projectId => $_getSZ(2);
  @$pb.TagNumber(3)
  set projectId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProjectId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProjectId() => $_clearField(3);
}

class ListSessionsResponse extends $pb.GeneratedMessage {
  factory ListSessionsResponse({
    $core.Iterable<Session>? sessions,
    $core.String? nextPageToken,
  }) {
    final result = ListSessionsResponse._();
    if (sessions != null) result.sessions.addAll(sessions);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListSessionsResponse._();

  factory ListSessionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSessionsResponse()..mergeFromBuffer(data, registry);
  factory ListSessionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSessionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSessionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListSessionsResponse.$_createMessage)
    ..pPM<Session>(1, _omitFieldNames ? '' : 'sessions',
        subBuilder: Session.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSessionsResponse copyWith(void Function(ListSessionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSessionsResponse))
          as ListSessionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListSessionsResponse() / ListSessionsResponse.new instead')
  static ListSessionsResponse create() => ListSessionsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListSessionsResponse._();
  @$core.override
  ListSessionsResponse createEmptyInstance() => ListSessionsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListSessionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSessionsResponse>(
          ListSessionsResponse.$_createMessage);
  static ListSessionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Session> get sessions => $_getList(0);

  /// Empty when there are no more.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

class GetSessionRequest extends $pb.GeneratedMessage {
  factory GetSessionRequest({
    $core.String? sessionId,
  }) {
    final result = GetSessionRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetSessionRequest._();

  factory GetSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSessionRequest()..mergeFromBuffer(data, registry);
  factory GetSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GetSessionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionRequest copyWith(void Function(GetSessionRequest) updates) =>
      super.copyWith((message) => updates(message as GetSessionRequest))
          as GetSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSessionRequest() / GetSessionRequest.new instead')
  static GetSessionRequest create() => GetSessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSessionRequest._();
  @$core.override
  GetSessionRequest createEmptyInstance() => GetSessionRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSessionRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSessionRequest>(
          GetSessionRequest.$_createMessage);
  static GetSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class GetSessionResponse extends $pb.GeneratedMessage {
  factory GetSessionResponse({
    Session? session,
  }) {
    final result = GetSessionResponse._();
    if (session != null) result.session = session;
    return result;
  }

  GetSessionResponse._();

  factory GetSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSessionResponse()..mergeFromBuffer(data, registry);
  factory GetSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSessionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSessionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GetSessionResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSessionResponse copyWith(void Function(GetSessionResponse) updates) =>
      super.copyWith((message) => updates(message as GetSessionResponse))
          as GetSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSessionResponse() / GetSessionResponse.new instead')
  static GetSessionResponse create() => GetSessionResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSessionResponse._();
  @$core.override
  GetSessionResponse createEmptyInstance() => GetSessionResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSessionResponse>(
          GetSessionResponse.$_createMessage);
  static GetSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class AttachRequest extends $pb.GeneratedMessage {
  factory AttachRequest({
    $core.String? sessionId,
    $fixnum.Int64? fromSeq,
  }) {
    final result = AttachRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (fromSeq != null) result.fromSeq = fromSeq;
    return result;
  }

  AttachRequest._();

  factory AttachRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachRequest()..mergeFromBuffer(data, registry);
  factory AttachRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AttachRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aInt64(2, _omitFieldNames ? '' : 'fromSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachRequest copyWith(void Function(AttachRequest) updates) =>
      super.copyWith((message) => updates(message as AttachRequest))
          as AttachRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttachRequest() / AttachRequest.new instead')
  static AttachRequest create() => AttachRequest._();
  static $pb.GeneratedMessage $_createMessage() => AttachRequest._();
  @$core.override
  AttachRequest createEmptyInstance() => AttachRequest._();
  @$core.pragma('dart2js:noInline')
  static AttachRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachRequest>(
          AttachRequest.$_createMessage);
  static AttachRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// First sequence number to send. 0 or 1 replays everything; last_seq + 1
  /// sends only new events.
  @$pb.TagNumber(2)
  $fixnum.Int64 get fromSeq => $_getI64(1);
  @$pb.TagNumber(2)
  set fromSeq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromSeq() => $_clearField(2);
}

class AttachResponse extends $pb.GeneratedMessage {
  factory AttachResponse({
    Event? event,
  }) {
    final result = AttachResponse._();
    if (event != null) result.event = event;
    return result;
  }

  AttachResponse._();

  factory AttachResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachResponse()..mergeFromBuffer(data, registry);
  factory AttachResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AttachResponse.$_createMessage)
    ..aOM<Event>(1, _omitFieldNames ? '' : 'event',
        subBuilder: Event.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachResponse copyWith(void Function(AttachResponse) updates) =>
      super.copyWith((message) => updates(message as AttachResponse))
          as AttachResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttachResponse() / AttachResponse.new instead')
  static AttachResponse create() => AttachResponse._();
  static $pb.GeneratedMessage $_createMessage() => AttachResponse._();
  @$core.override
  AttachResponse createEmptyInstance() => AttachResponse._();
  @$core.pragma('dart2js:noInline')
  static AttachResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachResponse>(
          AttachResponse.$_createMessage);
  static AttachResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Event get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(Event value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  Event ensureEvent() => $_ensure(0);
}

class SendRequest extends $pb.GeneratedMessage {
  factory SendRequest({
    $core.String? sessionId,
    $core.String? text,
    $core.String? client,
  }) {
    final result = SendRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (text != null) result.text = text;
    if (client != null) result.client = client;
    return result;
  }

  SendRequest._();

  factory SendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendRequest()..mergeFromBuffer(data, registry);
  factory SendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SendRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendRequest copyWith(void Function(SendRequest) updates) =>
      super.copyWith((message) => updates(message as SendRequest))
          as SendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendRequest() / SendRequest.new instead')
  static SendRequest create() => SendRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendRequest._();
  @$core.override
  SendRequest createEmptyInstance() => SendRequest._();
  @$core.pragma('dart2js:noInline')
  static SendRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendRequest>(
          SendRequest.$_createMessage);
  static SendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  /// Who sent it, for the log (like AnswerPromptRequest.client).
  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);
}

class SendResponse extends $pb.GeneratedMessage {
  factory SendResponse({
    $fixnum.Int64? seq,
    $core.String? queueId,
  }) {
    final result = SendResponse._();
    if (seq != null) result.seq = seq;
    if (queueId != null) result.queueId = queueId;
    return result;
  }

  SendResponse._();

  factory SendResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendResponse()..mergeFromBuffer(data, registry);
  factory SendResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SendResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'seq')
    ..aOS(2, _omitFieldNames ? '' : 'queueId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendResponse copyWith(void Function(SendResponse) updates) =>
      super.copyWith((message) => updates(message as SendResponse))
          as SendResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendResponse() / SendResponse.new instead')
  static SendResponse create() => SendResponse._();
  static $pb.GeneratedMessage $_createMessage() => SendResponse._();
  @$core.override
  SendResponse createEmptyInstance() => SendResponse._();
  @$core.pragma('dart2js:noInline')
  static SendResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendResponse>(
          SendResponse.$_createMessage);
  static SendResponse? _defaultInstance;

  /// Sequence number of the user message's first event (or of its
  /// MessageQueued event).
  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  /// Set when the message was queued because a turn is running.
  @$pb.TagNumber(2)
  $core.String get queueId => $_getSZ(1);
  @$pb.TagNumber(2)
  set queueId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQueueId() => $_has(1);
  @$pb.TagNumber(2)
  void clearQueueId() => $_clearField(2);
}

class EditQueuedMessageRequest extends $pb.GeneratedMessage {
  factory EditQueuedMessageRequest({
    $core.String? sessionId,
    $core.String? queueId,
    $core.String? text,
  }) {
    final result = EditQueuedMessageRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (queueId != null) result.queueId = queueId;
    if (text != null) result.text = text;
    return result;
  }

  EditQueuedMessageRequest._();

  factory EditQueuedMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditQueuedMessageRequest()..mergeFromBuffer(data, registry);
  factory EditQueuedMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditQueuedMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditQueuedMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EditQueuedMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'queueId')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditQueuedMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditQueuedMessageRequest copyWith(
          void Function(EditQueuedMessageRequest) updates) =>
      super.copyWith((message) => updates(message as EditQueuedMessageRequest))
          as EditQueuedMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EditQueuedMessageRequest() / EditQueuedMessageRequest.new instead')
  static EditQueuedMessageRequest create() => EditQueuedMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => EditQueuedMessageRequest._();
  @$core.override
  EditQueuedMessageRequest createEmptyInstance() =>
      EditQueuedMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static EditQueuedMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditQueuedMessageRequest>(
          EditQueuedMessageRequest.$_createMessage);
  static EditQueuedMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get queueId => $_getSZ(1);
  @$pb.TagNumber(2)
  set queueId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQueueId() => $_has(1);
  @$pb.TagNumber(2)
  void clearQueueId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

class EditQueuedMessageResponse extends $pb.GeneratedMessage {
  factory EditQueuedMessageResponse() => EditQueuedMessageResponse._();

  EditQueuedMessageResponse._();

  factory EditQueuedMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditQueuedMessageResponse()..mergeFromBuffer(data, registry);
  factory EditQueuedMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditQueuedMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditQueuedMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EditQueuedMessageResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditQueuedMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditQueuedMessageResponse copyWith(
          void Function(EditQueuedMessageResponse) updates) =>
      super.copyWith((message) => updates(message as EditQueuedMessageResponse))
          as EditQueuedMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EditQueuedMessageResponse() / EditQueuedMessageResponse.new instead')
  static EditQueuedMessageResponse create() => EditQueuedMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      EditQueuedMessageResponse._();
  @$core.override
  EditQueuedMessageResponse createEmptyInstance() =>
      EditQueuedMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static EditQueuedMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditQueuedMessageResponse>(
          EditQueuedMessageResponse.$_createMessage);
  static EditQueuedMessageResponse? _defaultInstance;
}

class CancelQueuedMessageRequest extends $pb.GeneratedMessage {
  factory CancelQueuedMessageRequest({
    $core.String? sessionId,
    $core.String? queueId,
  }) {
    final result = CancelQueuedMessageRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (queueId != null) result.queueId = queueId;
    return result;
  }

  CancelQueuedMessageRequest._();

  factory CancelQueuedMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelQueuedMessageRequest()..mergeFromBuffer(data, registry);
  factory CancelQueuedMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelQueuedMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelQueuedMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CancelQueuedMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'queueId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelQueuedMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelQueuedMessageRequest copyWith(
          void Function(CancelQueuedMessageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CancelQueuedMessageRequest))
          as CancelQueuedMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CancelQueuedMessageRequest() / CancelQueuedMessageRequest.new instead')
  static CancelQueuedMessageRequest create() => CancelQueuedMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      CancelQueuedMessageRequest._();
  @$core.override
  CancelQueuedMessageRequest createEmptyInstance() =>
      CancelQueuedMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static CancelQueuedMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelQueuedMessageRequest>(
          CancelQueuedMessageRequest.$_createMessage);
  static CancelQueuedMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get queueId => $_getSZ(1);
  @$pb.TagNumber(2)
  set queueId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQueueId() => $_has(1);
  @$pb.TagNumber(2)
  void clearQueueId() => $_clearField(2);
}

class CancelQueuedMessageResponse extends $pb.GeneratedMessage {
  factory CancelQueuedMessageResponse() => CancelQueuedMessageResponse._();

  CancelQueuedMessageResponse._();

  factory CancelQueuedMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelQueuedMessageResponse()..mergeFromBuffer(data, registry);
  factory CancelQueuedMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelQueuedMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelQueuedMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CancelQueuedMessageResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelQueuedMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelQueuedMessageResponse copyWith(
          void Function(CancelQueuedMessageResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CancelQueuedMessageResponse))
          as CancelQueuedMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CancelQueuedMessageResponse() / CancelQueuedMessageResponse.new instead')
  static CancelQueuedMessageResponse create() =>
      CancelQueuedMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CancelQueuedMessageResponse._();
  @$core.override
  CancelQueuedMessageResponse createEmptyInstance() =>
      CancelQueuedMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static CancelQueuedMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelQueuedMessageResponse>(
          CancelQueuedMessageResponse.$_createMessage);
  static CancelQueuedMessageResponse? _defaultInstance;
}

class InterruptRequest extends $pb.GeneratedMessage {
  factory InterruptRequest({
    $core.String? sessionId,
  }) {
    final result = InterruptRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  InterruptRequest._();

  factory InterruptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InterruptRequest()..mergeFromBuffer(data, registry);
  factory InterruptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InterruptRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InterruptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: InterruptRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptRequest copyWith(void Function(InterruptRequest) updates) =>
      super.copyWith((message) => updates(message as InterruptRequest))
          as InterruptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InterruptRequest() / InterruptRequest.new instead')
  static InterruptRequest create() => InterruptRequest._();
  static $pb.GeneratedMessage $_createMessage() => InterruptRequest._();
  @$core.override
  InterruptRequest createEmptyInstance() => InterruptRequest._();
  @$core.pragma('dart2js:noInline')
  static InterruptRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InterruptRequest>(
          InterruptRequest.$_createMessage);
  static InterruptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class InterruptResponse extends $pb.GeneratedMessage {
  factory InterruptResponse({
    $core.bool? interrupted,
  }) {
    final result = InterruptResponse._();
    if (interrupted != null) result.interrupted = interrupted;
    return result;
  }

  InterruptResponse._();

  factory InterruptResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InterruptResponse()..mergeFromBuffer(data, registry);
  factory InterruptResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InterruptResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InterruptResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: InterruptResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'interrupted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InterruptResponse copyWith(void Function(InterruptResponse) updates) =>
      super.copyWith((message) => updates(message as InterruptResponse))
          as InterruptResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InterruptResponse() / InterruptResponse.new instead')
  static InterruptResponse create() => InterruptResponse._();
  static $pb.GeneratedMessage $_createMessage() => InterruptResponse._();
  @$core.override
  InterruptResponse createEmptyInstance() => InterruptResponse._();
  @$core.pragma('dart2js:noInline')
  static InterruptResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InterruptResponse>(
          InterruptResponse.$_createMessage);
  static InterruptResponse? _defaultInstance;

  /// Whether a turn was running.
  @$pb.TagNumber(1)
  $core.bool get interrupted => $_getBF(0);
  @$pb.TagNumber(1)
  set interrupted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInterrupted() => $_has(0);
  @$pb.TagNumber(1)
  void clearInterrupted() => $_clearField(1);
}

class RetryModelCallRequest extends $pb.GeneratedMessage {
  factory RetryModelCallRequest({
    $core.String? sessionId,
  }) {
    final result = RetryModelCallRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  RetryModelCallRequest._();

  factory RetryModelCallRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryModelCallRequest()..mergeFromBuffer(data, registry);
  factory RetryModelCallRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryModelCallRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryModelCallRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RetryModelCallRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryModelCallRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryModelCallRequest copyWith(
          void Function(RetryModelCallRequest) updates) =>
      super.copyWith((message) => updates(message as RetryModelCallRequest))
          as RetryModelCallRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RetryModelCallRequest() / RetryModelCallRequest.new instead')
  static RetryModelCallRequest create() => RetryModelCallRequest._();
  static $pb.GeneratedMessage $_createMessage() => RetryModelCallRequest._();
  @$core.override
  RetryModelCallRequest createEmptyInstance() => RetryModelCallRequest._();
  @$core.pragma('dart2js:noInline')
  static RetryModelCallRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryModelCallRequest>(
          RetryModelCallRequest.$_createMessage);
  static RetryModelCallRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class RetryModelCallResponse extends $pb.GeneratedMessage {
  factory RetryModelCallResponse() => RetryModelCallResponse._();

  RetryModelCallResponse._();

  factory RetryModelCallResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryModelCallResponse()..mergeFromBuffer(data, registry);
  factory RetryModelCallResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryModelCallResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryModelCallResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RetryModelCallResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryModelCallResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryModelCallResponse copyWith(
          void Function(RetryModelCallResponse) updates) =>
      super.copyWith((message) => updates(message as RetryModelCallResponse))
          as RetryModelCallResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RetryModelCallResponse() / RetryModelCallResponse.new instead')
  static RetryModelCallResponse create() => RetryModelCallResponse._();
  static $pb.GeneratedMessage $_createMessage() => RetryModelCallResponse._();
  @$core.override
  RetryModelCallResponse createEmptyInstance() => RetryModelCallResponse._();
  @$core.pragma('dart2js:noInline')
  static RetryModelCallResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryModelCallResponse>(
          RetryModelCallResponse.$_createMessage);
  static RetryModelCallResponse? _defaultInstance;
}

class EndReasoningRequest extends $pb.GeneratedMessage {
  factory EndReasoningRequest({
    $core.String? sessionId,
    $core.String? client,
  }) {
    final result = EndReasoningRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (client != null) result.client = client;
    return result;
  }

  EndReasoningRequest._();

  factory EndReasoningRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndReasoningRequest()..mergeFromBuffer(data, registry);
  factory EndReasoningRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndReasoningRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EndReasoningRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EndReasoningRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndReasoningRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndReasoningRequest copyWith(void Function(EndReasoningRequest) updates) =>
      super.copyWith((message) => updates(message as EndReasoningRequest))
          as EndReasoningRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EndReasoningRequest() / EndReasoningRequest.new instead')
  static EndReasoningRequest create() => EndReasoningRequest._();
  static $pb.GeneratedMessage $_createMessage() => EndReasoningRequest._();
  @$core.override
  EndReasoningRequest createEmptyInstance() => EndReasoningRequest._();
  @$core.pragma('dart2js:noInline')
  static EndReasoningRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EndReasoningRequest>(
          EndReasoningRequest.$_createMessage);
  static EndReasoningRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Who asked, for the log.
  @$pb.TagNumber(2)
  $core.String get client => $_getSZ(1);
  @$pb.TagNumber(2)
  set client($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClient() => $_has(1);
  @$pb.TagNumber(2)
  void clearClient() => $_clearField(2);
}

class EndReasoningResponse extends $pb.GeneratedMessage {
  factory EndReasoningResponse() => EndReasoningResponse._();

  EndReasoningResponse._();

  factory EndReasoningResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndReasoningResponse()..mergeFromBuffer(data, registry);
  factory EndReasoningResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EndReasoningResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EndReasoningResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EndReasoningResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndReasoningResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EndReasoningResponse copyWith(void Function(EndReasoningResponse) updates) =>
      super.copyWith((message) => updates(message as EndReasoningResponse))
          as EndReasoningResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EndReasoningResponse() / EndReasoningResponse.new instead')
  static EndReasoningResponse create() => EndReasoningResponse._();
  static $pb.GeneratedMessage $_createMessage() => EndReasoningResponse._();
  @$core.override
  EndReasoningResponse createEmptyInstance() => EndReasoningResponse._();
  @$core.pragma('dart2js:noInline')
  static EndReasoningResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EndReasoningResponse>(
          EndReasoningResponse.$_createMessage);
  static EndReasoningResponse? _defaultInstance;
}

class CompactRequest extends $pb.GeneratedMessage {
  factory CompactRequest({
    $core.String? sessionId,
    $core.String? client,
    $core.String? instructions,
  }) {
    final result = CompactRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (client != null) result.client = client;
    if (instructions != null) result.instructions = instructions;
    return result;
  }

  CompactRequest._();

  factory CompactRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactRequest()..mergeFromBuffer(data, registry);
  factory CompactRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompactRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CompactRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'client')
    ..aOS(3, _omitFieldNames ? '' : 'instructions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactRequest copyWith(void Function(CompactRequest) updates) =>
      super.copyWith((message) => updates(message as CompactRequest))
          as CompactRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompactRequest() / CompactRequest.new instead')
  static CompactRequest create() => CompactRequest._();
  static $pb.GeneratedMessage $_createMessage() => CompactRequest._();
  @$core.override
  CompactRequest createEmptyInstance() => CompactRequest._();
  @$core.pragma('dart2js:noInline')
  static CompactRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompactRequest>(
          CompactRequest.$_createMessage);
  static CompactRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Who asked, for the log.
  @$pb.TagNumber(2)
  $core.String get client => $_getSZ(1);
  @$pb.TagNumber(2)
  set client($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClient() => $_has(1);
  @$pb.TagNumber(2)
  void clearClient() => $_clearField(2);

  /// Optional extra instructions for the summary, e.g. "keep the API
  /// details".
  @$pb.TagNumber(3)
  $core.String get instructions => $_getSZ(2);
  @$pb.TagNumber(3)
  set instructions($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInstructions() => $_has(2);
  @$pb.TagNumber(3)
  void clearInstructions() => $_clearField(3);
}

class CompactResponse extends $pb.GeneratedMessage {
  factory CompactResponse({
    $core.bool? queued,
  }) {
    final result = CompactResponse._();
    if (queued != null) result.queued = queued;
    return result;
  }

  CompactResponse._();

  factory CompactResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactResponse()..mergeFromBuffer(data, registry);
  factory CompactResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompactResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CompactResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'queued')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactResponse copyWith(void Function(CompactResponse) updates) =>
      super.copyWith((message) => updates(message as CompactResponse))
          as CompactResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompactResponse() / CompactResponse.new instead')
  static CompactResponse create() => CompactResponse._();
  static $pb.GeneratedMessage $_createMessage() => CompactResponse._();
  @$core.override
  CompactResponse createEmptyInstance() => CompactResponse._();
  @$core.pragma('dart2js:noInline')
  static CompactResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompactResponse>(
          CompactResponse.$_createMessage);
  static CompactResponse? _defaultInstance;

  /// True when a turn is running and compaction waits for its next step.
  @$pb.TagNumber(1)
  $core.bool get queued => $_getBF(0);
  @$pb.TagNumber(1)
  set queued($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueued() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueued() => $_clearField(1);
}

class AnswerPromptRequest extends $pb.GeneratedMessage {
  factory AnswerPromptRequest({
    $core.String? sessionId,
    $core.String? promptId,
    PromptDecision? decision,
    $core.String? client,
  }) {
    final result = AnswerPromptRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (promptId != null) result.promptId = promptId;
    if (decision != null) result.decision = decision;
    if (client != null) result.client = client;
    return result;
  }

  AnswerPromptRequest._();

  factory AnswerPromptRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AnswerPromptRequest()..mergeFromBuffer(data, registry);
  factory AnswerPromptRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AnswerPromptRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnswerPromptRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AnswerPromptRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'promptId')
    ..aE<PromptDecision>(3, _omitFieldNames ? '' : 'decision',
        enumValues: PromptDecision.values)
    ..aOS(4, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnswerPromptRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnswerPromptRequest copyWith(void Function(AnswerPromptRequest) updates) =>
      super.copyWith((message) => updates(message as AnswerPromptRequest))
          as AnswerPromptRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use AnswerPromptRequest() / AnswerPromptRequest.new instead')
  static AnswerPromptRequest create() => AnswerPromptRequest._();
  static $pb.GeneratedMessage $_createMessage() => AnswerPromptRequest._();
  @$core.override
  AnswerPromptRequest createEmptyInstance() => AnswerPromptRequest._();
  @$core.pragma('dart2js:noInline')
  static AnswerPromptRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnswerPromptRequest>(
          AnswerPromptRequest.$_createMessage);
  static AnswerPromptRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get promptId => $_getSZ(1);
  @$pb.TagNumber(2)
  set promptId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPromptId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPromptId() => $_clearField(2);

  @$pb.TagNumber(3)
  PromptDecision get decision => $_getN(2);
  @$pb.TagNumber(3)
  set decision(PromptDecision value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDecision() => $_has(2);
  @$pb.TagNumber(3)
  void clearDecision() => $_clearField(3);

  /// Free-form name of the answering client, e.g. "flit-app/ios". Recorded in
  /// the PromptResolved event.
  @$pb.TagNumber(4)
  $core.String get client => $_getSZ(3);
  @$pb.TagNumber(4)
  set client($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClient() => $_has(3);
  @$pb.TagNumber(4)
  void clearClient() => $_clearField(4);
}

class AnswerPromptResponse extends $pb.GeneratedMessage {
  factory AnswerPromptResponse() => AnswerPromptResponse._();

  AnswerPromptResponse._();

  factory AnswerPromptResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AnswerPromptResponse()..mergeFromBuffer(data, registry);
  factory AnswerPromptResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AnswerPromptResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AnswerPromptResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AnswerPromptResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnswerPromptResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AnswerPromptResponse copyWith(void Function(AnswerPromptResponse) updates) =>
      super.copyWith((message) => updates(message as AnswerPromptResponse))
          as AnswerPromptResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AnswerPromptResponse() / AnswerPromptResponse.new instead')
  static AnswerPromptResponse create() => AnswerPromptResponse._();
  static $pb.GeneratedMessage $_createMessage() => AnswerPromptResponse._();
  @$core.override
  AnswerPromptResponse createEmptyInstance() => AnswerPromptResponse._();
  @$core.pragma('dart2js:noInline')
  static AnswerPromptResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AnswerPromptResponse>(
          AnswerPromptResponse.$_createMessage);
  static AnswerPromptResponse? _defaultInstance;
}

class SetModelRequest extends $pb.GeneratedMessage {
  factory SetModelRequest({
    $core.String? sessionId,
    $core.String? provider,
    $core.String? model,
  }) {
    final result = SetModelRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  SetModelRequest._();

  factory SetModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetModelRequest()..mergeFromBuffer(data, registry);
  factory SetModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetModelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetModelRequest copyWith(void Function(SetModelRequest) updates) =>
      super.copyWith((message) => updates(message as SetModelRequest))
          as SetModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetModelRequest() / SetModelRequest.new instead')
  static SetModelRequest create() => SetModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetModelRequest._();
  @$core.override
  SetModelRequest createEmptyInstance() => SetModelRequest._();
  @$core.pragma('dart2js:noInline')
  static SetModelRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetModelRequest>(
          SetModelRequest.$_createMessage);
  static SetModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get provider => $_getSZ(1);
  @$pb.TagNumber(2)
  set provider($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProvider() => $_has(1);
  @$pb.TagNumber(2)
  void clearProvider() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get model => $_getSZ(2);
  @$pb.TagNumber(3)
  set model($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearModel() => $_clearField(3);
}

class SetModelResponse extends $pb.GeneratedMessage {
  factory SetModelResponse({
    Session? session,
  }) {
    final result = SetModelResponse._();
    if (session != null) result.session = session;
    return result;
  }

  SetModelResponse._();

  factory SetModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetModelResponse()..mergeFromBuffer(data, registry);
  factory SetModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetModelResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetModelResponse copyWith(void Function(SetModelResponse) updates) =>
      super.copyWith((message) => updates(message as SetModelResponse))
          as SetModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetModelResponse() / SetModelResponse.new instead')
  static SetModelResponse create() => SetModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetModelResponse._();
  @$core.override
  SetModelResponse createEmptyInstance() => SetModelResponse._();
  @$core.pragma('dart2js:noInline')
  static SetModelResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetModelResponse>(
          SetModelResponse.$_createMessage);
  static SetModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class MoveSessionRequest extends $pb.GeneratedMessage {
  factory MoveSessionRequest({
    $core.String? sessionId,
    $core.String? projectId,
  }) {
    final result = MoveSessionRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (projectId != null) result.projectId = projectId;
    return result;
  }

  MoveSessionRequest._();

  factory MoveSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveSessionRequest()..mergeFromBuffer(data, registry);
  factory MoveSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveSessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: MoveSessionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'projectId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveSessionRequest copyWith(void Function(MoveSessionRequest) updates) =>
      super.copyWith((message) => updates(message as MoveSessionRequest))
          as MoveSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MoveSessionRequest() / MoveSessionRequest.new instead')
  static MoveSessionRequest create() => MoveSessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => MoveSessionRequest._();
  @$core.override
  MoveSessionRequest createEmptyInstance() => MoveSessionRequest._();
  @$core.pragma('dart2js:noInline')
  static MoveSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveSessionRequest>(
          MoveSessionRequest.$_createMessage);
  static MoveSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get projectId => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProjectId() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectId() => $_clearField(2);
}

class MoveSessionResponse extends $pb.GeneratedMessage {
  factory MoveSessionResponse({
    Session? session,
  }) {
    final result = MoveSessionResponse._();
    if (session != null) result.session = session;
    return result;
  }

  MoveSessionResponse._();

  factory MoveSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveSessionResponse()..mergeFromBuffer(data, registry);
  factory MoveSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveSessionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveSessionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: MoveSessionResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveSessionResponse copyWith(void Function(MoveSessionResponse) updates) =>
      super.copyWith((message) => updates(message as MoveSessionResponse))
          as MoveSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use MoveSessionResponse() / MoveSessionResponse.new instead')
  static MoveSessionResponse create() => MoveSessionResponse._();
  static $pb.GeneratedMessage $_createMessage() => MoveSessionResponse._();
  @$core.override
  MoveSessionResponse createEmptyInstance() => MoveSessionResponse._();
  @$core.pragma('dart2js:noInline')
  static MoveSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MoveSessionResponse>(
          MoveSessionResponse.$_createMessage);
  static MoveSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class RateRequest extends $pb.GeneratedMessage {
  factory RateRequest({
    $core.String? sessionId,
    RatingTarget? target,
    Rating? rating,
    $core.String? messageId,
    $core.String? note,
  }) {
    final result = RateRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (target != null) result.target = target;
    if (rating != null) result.rating = rating;
    if (messageId != null) result.messageId = messageId;
    if (note != null) result.note = note;
    return result;
  }

  RateRequest._();

  factory RateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RateRequest()..mergeFromBuffer(data, registry);
  factory RateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RateRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aE<RatingTarget>(2, _omitFieldNames ? '' : 'target',
        enumValues: RatingTarget.values)
    ..aE<Rating>(3, _omitFieldNames ? '' : 'rating', enumValues: Rating.values)
    ..aOS(4, _omitFieldNames ? '' : 'messageId')
    ..aOS(5, _omitFieldNames ? '' : 'note')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RateRequest copyWith(void Function(RateRequest) updates) =>
      super.copyWith((message) => updates(message as RateRequest))
          as RateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RateRequest() / RateRequest.new instead')
  static RateRequest create() => RateRequest._();
  static $pb.GeneratedMessage $_createMessage() => RateRequest._();
  @$core.override
  RateRequest createEmptyInstance() => RateRequest._();
  @$core.pragma('dart2js:noInline')
  static RateRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RateRequest>(
          RateRequest.$_createMessage);
  static RateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  RatingTarget get target => $_getN(1);
  @$pb.TagNumber(2)
  set target(RatingTarget value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearTarget() => $_clearField(2);

  @$pb.TagNumber(3)
  Rating get rating => $_getN(2);
  @$pb.TagNumber(3)
  set rating(Rating value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRating() => $_has(2);
  @$pb.TagNumber(3)
  void clearRating() => $_clearField(3);

  /// The assistant message rated; empty rates the model in general.
  @$pb.TagNumber(4)
  $core.String get messageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set messageId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessageId() => $_clearField(4);

  /// Optional free-text reason.
  @$pb.TagNumber(5)
  $core.String get note => $_getSZ(4);
  @$pb.TagNumber(5)
  set note($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasNote() => $_has(4);
  @$pb.TagNumber(5)
  void clearNote() => $_clearField(5);
}

class RateResponse extends $pb.GeneratedMessage {
  factory RateResponse() => RateResponse._();

  RateResponse._();

  factory RateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RateResponse()..mergeFromBuffer(data, registry);
  factory RateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RateResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RateResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RateResponse copyWith(void Function(RateResponse) updates) =>
      super.copyWith((message) => updates(message as RateResponse))
          as RateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RateResponse() / RateResponse.new instead')
  static RateResponse create() => RateResponse._();
  static $pb.GeneratedMessage $_createMessage() => RateResponse._();
  @$core.override
  RateResponse createEmptyInstance() => RateResponse._();
  @$core.pragma('dart2js:noInline')
  static RateResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RateResponse>(
          RateResponse.$_createMessage);
  static RateResponse? _defaultInstance;
}

class McpServer extends $pb.GeneratedMessage {
  factory McpServer({
    $core.String? name,
    $core.bool? enabled,
    $core.bool? running,
    $core.int? toolCount,
    $core.String? error,
  }) {
    final result = McpServer._();
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    if (running != null) result.running = running;
    if (toolCount != null) result.toolCount = toolCount;
    if (error != null) result.error = error;
    return result;
  }

  McpServer._();

  factory McpServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      McpServer()..mergeFromBuffer(data, registry);
  factory McpServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      McpServer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'McpServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: McpServer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOB(3, _omitFieldNames ? '' : 'running')
    ..aI(4, _omitFieldNames ? '' : 'toolCount')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  McpServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  McpServer copyWith(void Function(McpServer) updates) =>
      super.copyWith((message) => updates(message as McpServer)) as McpServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use McpServer() / McpServer.new instead')
  static McpServer create() => McpServer._();
  static $pb.GeneratedMessage $_createMessage() => McpServer._();
  @$core.override
  McpServer createEmptyInstance() => McpServer._();
  @$core.pragma('dart2js:noInline')
  static McpServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<McpServer>(McpServer.$_createMessage);
  static McpServer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Enabled for this session.
  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);

  /// Started and answering; tool_count is how many tools it offers.
  @$pb.TagNumber(3)
  $core.bool get running => $_getBF(2);
  @$pb.TagNumber(3)
  set running($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRunning() => $_has(2);
  @$pb.TagNumber(3)
  void clearRunning() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get toolCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set toolCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasToolCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearToolCount() => $_clearField(4);

  /// Why it failed to start or list tools, if it did.
  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class ListMcpServersRequest extends $pb.GeneratedMessage {
  factory ListMcpServersRequest({
    $core.String? sessionId,
  }) {
    final result = ListMcpServersRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ListMcpServersRequest._();

  factory ListMcpServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMcpServersRequest()..mergeFromBuffer(data, registry);
  factory ListMcpServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMcpServersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMcpServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListMcpServersRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMcpServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMcpServersRequest copyWith(
          void Function(ListMcpServersRequest) updates) =>
      super.copyWith((message) => updates(message as ListMcpServersRequest))
          as ListMcpServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListMcpServersRequest() / ListMcpServersRequest.new instead')
  static ListMcpServersRequest create() => ListMcpServersRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListMcpServersRequest._();
  @$core.override
  ListMcpServersRequest createEmptyInstance() => ListMcpServersRequest._();
  @$core.pragma('dart2js:noInline')
  static ListMcpServersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMcpServersRequest>(
          ListMcpServersRequest.$_createMessage);
  static ListMcpServersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class ListMcpServersResponse extends $pb.GeneratedMessage {
  factory ListMcpServersResponse({
    $core.Iterable<McpServer>? servers,
  }) {
    final result = ListMcpServersResponse._();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  ListMcpServersResponse._();

  factory ListMcpServersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMcpServersResponse()..mergeFromBuffer(data, registry);
  factory ListMcpServersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMcpServersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMcpServersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListMcpServersResponse.$_createMessage)
    ..pPM<McpServer>(1, _omitFieldNames ? '' : 'servers',
        subBuilder: McpServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMcpServersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMcpServersResponse copyWith(
          void Function(ListMcpServersResponse) updates) =>
      super.copyWith((message) => updates(message as ListMcpServersResponse))
          as ListMcpServersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListMcpServersResponse() / ListMcpServersResponse.new instead')
  static ListMcpServersResponse create() => ListMcpServersResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListMcpServersResponse._();
  @$core.override
  ListMcpServersResponse createEmptyInstance() => ListMcpServersResponse._();
  @$core.pragma('dart2js:noInline')
  static ListMcpServersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListMcpServersResponse>(
          ListMcpServersResponse.$_createMessage);
  static ListMcpServersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<McpServer> get servers => $_getList(0);
}

class Skill extends $pb.GeneratedMessage {
  factory Skill({
    $core.String? name,
    $core.String? description,
    $core.String? source,
  }) {
    final result = Skill._();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (source != null) result.source = source;
    return result;
  }

  Skill._();

  factory Skill.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Skill()..mergeFromBuffer(data, registry);
  factory Skill.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Skill()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Skill',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Skill.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Skill clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Skill copyWith(void Function(Skill) updates) =>
      super.copyWith((message) => updates(message as Skill)) as Skill;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Skill() / Skill.new instead')
  static Skill create() => Skill._();
  static $pb.GeneratedMessage $_createMessage() => Skill._();
  @$core.override
  Skill createEmptyInstance() => Skill._();
  @$core.pragma('dart2js:noInline')
  static Skill getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Skill>(Skill.$_createMessage);
  static Skill? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get description => $_getSZ(1);
  @$pb.TagNumber(2)
  set description($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDescription() => $_has(1);
  @$pb.TagNumber(2)
  void clearDescription() => $_clearField(2);

  /// Where it was found: "repo .agents/skills", "repo root .claude/skills",
  /// "global", ...
  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);
}

class ListSkillsRequest extends $pb.GeneratedMessage {
  factory ListSkillsRequest({
    $core.String? sessionId,
  }) {
    final result = ListSkillsRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ListSkillsRequest._();

  factory ListSkillsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSkillsRequest()..mergeFromBuffer(data, registry);
  factory ListSkillsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSkillsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSkillsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListSkillsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsRequest copyWith(void Function(ListSkillsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSkillsRequest))
          as ListSkillsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListSkillsRequest() / ListSkillsRequest.new instead')
  static ListSkillsRequest create() => ListSkillsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListSkillsRequest._();
  @$core.override
  ListSkillsRequest createEmptyInstance() => ListSkillsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListSkillsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListSkillsRequest>(
          ListSkillsRequest.$_createMessage);
  static ListSkillsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class ListSkillsResponse extends $pb.GeneratedMessage {
  factory ListSkillsResponse({
    $core.Iterable<Skill>? skills,
  }) {
    final result = ListSkillsResponse._();
    if (skills != null) result.skills.addAll(skills);
    return result;
  }

  ListSkillsResponse._();

  factory ListSkillsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSkillsResponse()..mergeFromBuffer(data, registry);
  factory ListSkillsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSkillsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSkillsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListSkillsResponse.$_createMessage)
    ..pPM<Skill>(1, _omitFieldNames ? '' : 'skills',
        subBuilder: Skill.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSkillsResponse copyWith(void Function(ListSkillsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSkillsResponse))
          as ListSkillsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListSkillsResponse() / ListSkillsResponse.new instead')
  static ListSkillsResponse create() => ListSkillsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListSkillsResponse._();
  @$core.override
  ListSkillsResponse createEmptyInstance() => ListSkillsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListSkillsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSkillsResponse>(
          ListSkillsResponse.$_createMessage);
  static ListSkillsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Skill> get skills => $_getList(0);
}

class SetMcpServerRequest extends $pb.GeneratedMessage {
  factory SetMcpServerRequest({
    $core.String? sessionId,
    $core.String? server,
    $core.bool? enabled,
  }) {
    final result = SetMcpServerRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (server != null) result.server = server;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetMcpServerRequest._();

  factory SetMcpServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetMcpServerRequest()..mergeFromBuffer(data, registry);
  factory SetMcpServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetMcpServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetMcpServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetMcpServerRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'server')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetMcpServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetMcpServerRequest copyWith(void Function(SetMcpServerRequest) updates) =>
      super.copyWith((message) => updates(message as SetMcpServerRequest))
          as SetMcpServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SetMcpServerRequest() / SetMcpServerRequest.new instead')
  static SetMcpServerRequest create() => SetMcpServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetMcpServerRequest._();
  @$core.override
  SetMcpServerRequest createEmptyInstance() => SetMcpServerRequest._();
  @$core.pragma('dart2js:noInline')
  static SetMcpServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetMcpServerRequest>(
          SetMcpServerRequest.$_createMessage);
  static SetMcpServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get server => $_getSZ(1);
  @$pb.TagNumber(2)
  set server($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);
}

class RetryFromMessageRequest extends $pb.GeneratedMessage {
  factory RetryFromMessageRequest({
    $core.String? sessionId,
    $core.String? messageId,
    $core.String? client,
  }) {
    final result = RetryFromMessageRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (messageId != null) result.messageId = messageId;
    if (client != null) result.client = client;
    return result;
  }

  RetryFromMessageRequest._();

  factory RetryFromMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryFromMessageRequest()..mergeFromBuffer(data, registry);
  factory RetryFromMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryFromMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryFromMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RetryFromMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryFromMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryFromMessageRequest copyWith(
          void Function(RetryFromMessageRequest) updates) =>
      super.copyWith((message) => updates(message as RetryFromMessageRequest))
          as RetryFromMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RetryFromMessageRequest() / RetryFromMessageRequest.new instead')
  static RetryFromMessageRequest create() => RetryFromMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => RetryFromMessageRequest._();
  @$core.override
  RetryFromMessageRequest createEmptyInstance() => RetryFromMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static RetryFromMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryFromMessageRequest>(
          RetryFromMessageRequest.$_createMessage);
  static RetryFromMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// A user message on the active branch's path.
  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  /// Who asked, for the log.
  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);
}

class RetryFromMessageResponse extends $pb.GeneratedMessage {
  factory RetryFromMessageResponse({
    $core.String? branchId,
    $fixnum.Int64? seq,
  }) {
    final result = RetryFromMessageResponse._();
    if (branchId != null) result.branchId = branchId;
    if (seq != null) result.seq = seq;
    return result;
  }

  RetryFromMessageResponse._();

  factory RetryFromMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryFromMessageResponse()..mergeFromBuffer(data, registry);
  factory RetryFromMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RetryFromMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryFromMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RetryFromMessageResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'branchId')
    ..aInt64(2, _omitFieldNames ? '' : 'seq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryFromMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryFromMessageResponse copyWith(
          void Function(RetryFromMessageResponse) updates) =>
      super.copyWith((message) => updates(message as RetryFromMessageResponse))
          as RetryFromMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RetryFromMessageResponse() / RetryFromMessageResponse.new instead')
  static RetryFromMessageResponse create() => RetryFromMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => RetryFromMessageResponse._();
  @$core.override
  RetryFromMessageResponse createEmptyInstance() =>
      RetryFromMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static RetryFromMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryFromMessageResponse>(
          RetryFromMessageResponse.$_createMessage);
  static RetryFromMessageResponse? _defaultInstance;

  /// The new branch.
  @$pb.TagNumber(1)
  $core.String get branchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set branchId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBranchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBranchId() => $_clearField(1);

  /// Sequence number of its BranchCreated event.
  @$pb.TagNumber(2)
  $fixnum.Int64 get seq => $_getI64(1);
  @$pb.TagNumber(2)
  set seq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);
}

class EditMessageRequest extends $pb.GeneratedMessage {
  factory EditMessageRequest({
    $core.String? sessionId,
    $core.String? messageId,
    $core.String? text,
    $core.String? client,
  }) {
    final result = EditMessageRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (messageId != null) result.messageId = messageId;
    if (text != null) result.text = text;
    if (client != null) result.client = client;
    return result;
  }

  EditMessageRequest._();

  factory EditMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageRequest()..mergeFromBuffer(data, registry);
  factory EditMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EditMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..aOS(4, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageRequest copyWith(void Function(EditMessageRequest) updates) =>
      super.copyWith((message) => updates(message as EditMessageRequest))
          as EditMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EditMessageRequest() / EditMessageRequest.new instead')
  static EditMessageRequest create() => EditMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => EditMessageRequest._();
  @$core.override
  EditMessageRequest createEmptyInstance() => EditMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static EditMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditMessageRequest>(
          EditMessageRequest.$_createMessage);
  static EditMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// A user message on the active branch's path.
  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  /// The new text. Required.
  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get client => $_getSZ(3);
  @$pb.TagNumber(4)
  set client($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClient() => $_has(3);
  @$pb.TagNumber(4)
  void clearClient() => $_clearField(4);
}

class EditMessageResponse extends $pb.GeneratedMessage {
  factory EditMessageResponse({
    $core.String? branchId,
    $fixnum.Int64? seq,
  }) {
    final result = EditMessageResponse._();
    if (branchId != null) result.branchId = branchId;
    if (seq != null) result.seq = seq;
    return result;
  }

  EditMessageResponse._();

  factory EditMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageResponse()..mergeFromBuffer(data, registry);
  factory EditMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EditMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EditMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: EditMessageResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'branchId')
    ..aInt64(2, _omitFieldNames ? '' : 'seq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EditMessageResponse copyWith(void Function(EditMessageResponse) updates) =>
      super.copyWith((message) => updates(message as EditMessageResponse))
          as EditMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EditMessageResponse() / EditMessageResponse.new instead')
  static EditMessageResponse create() => EditMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => EditMessageResponse._();
  @$core.override
  EditMessageResponse createEmptyInstance() => EditMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static EditMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EditMessageResponse>(
          EditMessageResponse.$_createMessage);
  static EditMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get branchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set branchId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBranchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBranchId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get seq => $_getI64(1);
  @$pb.TagNumber(2)
  set seq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);
}

class SwitchBranchRequest extends $pb.GeneratedMessage {
  factory SwitchBranchRequest({
    $core.String? sessionId,
    $core.String? branchId,
    $core.String? client,
  }) {
    final result = SwitchBranchRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (branchId != null) result.branchId = branchId;
    if (client != null) result.client = client;
    return result;
  }

  SwitchBranchRequest._();

  factory SwitchBranchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchBranchRequest()..mergeFromBuffer(data, registry);
  factory SwitchBranchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchBranchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SwitchBranchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SwitchBranchRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'branchId')
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchBranchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchBranchRequest copyWith(void Function(SwitchBranchRequest) updates) =>
      super.copyWith((message) => updates(message as SwitchBranchRequest))
          as SwitchBranchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SwitchBranchRequest() / SwitchBranchRequest.new instead')
  static SwitchBranchRequest create() => SwitchBranchRequest._();
  static $pb.GeneratedMessage $_createMessage() => SwitchBranchRequest._();
  @$core.override
  SwitchBranchRequest createEmptyInstance() => SwitchBranchRequest._();
  @$core.pragma('dart2js:noInline')
  static SwitchBranchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SwitchBranchRequest>(
          SwitchBranchRequest.$_createMessage);
  static SwitchBranchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Empty is the root branch.
  @$pb.TagNumber(2)
  $core.String get branchId => $_getSZ(1);
  @$pb.TagNumber(2)
  set branchId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBranchId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBranchId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);
}

class SwitchBranchResponse extends $pb.GeneratedMessage {
  factory SwitchBranchResponse({
    Session? session,
  }) {
    final result = SwitchBranchResponse._();
    if (session != null) result.session = session;
    return result;
  }

  SwitchBranchResponse._();

  factory SwitchBranchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchBranchResponse()..mergeFromBuffer(data, registry);
  factory SwitchBranchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SwitchBranchResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SwitchBranchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SwitchBranchResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchBranchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SwitchBranchResponse copyWith(void Function(SwitchBranchResponse) updates) =>
      super.copyWith((message) => updates(message as SwitchBranchResponse))
          as SwitchBranchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SwitchBranchResponse() / SwitchBranchResponse.new instead')
  static SwitchBranchResponse create() => SwitchBranchResponse._();
  static $pb.GeneratedMessage $_createMessage() => SwitchBranchResponse._();
  @$core.override
  SwitchBranchResponse createEmptyInstance() => SwitchBranchResponse._();
  @$core.pragma('dart2js:noInline')
  static SwitchBranchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SwitchBranchResponse>(
          SwitchBranchResponse.$_createMessage);
  static SwitchBranchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class SetMcpServerResponse extends $pb.GeneratedMessage {
  factory SetMcpServerResponse({
    Session? session,
  }) {
    final result = SetMcpServerResponse._();
    if (session != null) result.session = session;
    return result;
  }

  SetMcpServerResponse._();

  factory SetMcpServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetMcpServerResponse()..mergeFromBuffer(data, registry);
  factory SetMcpServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetMcpServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetMcpServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetMcpServerResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetMcpServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetMcpServerResponse copyWith(void Function(SetMcpServerResponse) updates) =>
      super.copyWith((message) => updates(message as SetMcpServerResponse))
          as SetMcpServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetMcpServerResponse() / SetMcpServerResponse.new instead')
  static SetMcpServerResponse create() => SetMcpServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetMcpServerResponse._();
  @$core.override
  SetMcpServerResponse createEmptyInstance() => SetMcpServerResponse._();
  @$core.pragma('dart2js:noInline')
  static SetMcpServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetMcpServerResponse>(
          SetMcpServerResponse.$_createMessage);
  static SetMcpServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class SetEffortRequest extends $pb.GeneratedMessage {
  factory SetEffortRequest({
    $core.String? sessionId,
    $core.String? effort,
  }) {
    final result = SetEffortRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (effort != null) result.effort = effort;
    return result;
  }

  SetEffortRequest._();

  factory SetEffortRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetEffortRequest()..mergeFromBuffer(data, registry);
  factory SetEffortRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetEffortRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetEffortRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetEffortRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'effort')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetEffortRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetEffortRequest copyWith(void Function(SetEffortRequest) updates) =>
      super.copyWith((message) => updates(message as SetEffortRequest))
          as SetEffortRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetEffortRequest() / SetEffortRequest.new instead')
  static SetEffortRequest create() => SetEffortRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetEffortRequest._();
  @$core.override
  SetEffortRequest createEmptyInstance() => SetEffortRequest._();
  @$core.pragma('dart2js:noInline')
  static SetEffortRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetEffortRequest>(
          SetEffortRequest.$_createMessage);
  static SetEffortRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// E.g. "low", "medium", "high"; empty means the model's default.
  @$pb.TagNumber(2)
  $core.String get effort => $_getSZ(1);
  @$pb.TagNumber(2)
  set effort($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEffort() => $_has(1);
  @$pb.TagNumber(2)
  void clearEffort() => $_clearField(2);
}

class SetEffortResponse extends $pb.GeneratedMessage {
  factory SetEffortResponse({
    Session? session,
  }) {
    final result = SetEffortResponse._();
    if (session != null) result.session = session;
    return result;
  }

  SetEffortResponse._();

  factory SetEffortResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetEffortResponse()..mergeFromBuffer(data, registry);
  factory SetEffortResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetEffortResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetEffortResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetEffortResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetEffortResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetEffortResponse copyWith(void Function(SetEffortResponse) updates) =>
      super.copyWith((message) => updates(message as SetEffortResponse))
          as SetEffortResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetEffortResponse() / SetEffortResponse.new instead')
  static SetEffortResponse create() => SetEffortResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetEffortResponse._();
  @$core.override
  SetEffortResponse createEmptyInstance() => SetEffortResponse._();
  @$core.pragma('dart2js:noInline')
  static SetEffortResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetEffortResponse>(
          SetEffortResponse.$_createMessage);
  static SetEffortResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

class SetYoloRequest extends $pb.GeneratedMessage {
  factory SetYoloRequest({
    $core.String? sessionId,
    $core.bool? yolo,
  }) {
    final result = SetYoloRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (yolo != null) result.yolo = yolo;
    return result;
  }

  SetYoloRequest._();

  factory SetYoloRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetYoloRequest()..mergeFromBuffer(data, registry);
  factory SetYoloRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetYoloRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetYoloRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetYoloRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOB(2, _omitFieldNames ? '' : 'yolo')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetYoloRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetYoloRequest copyWith(void Function(SetYoloRequest) updates) =>
      super.copyWith((message) => updates(message as SetYoloRequest))
          as SetYoloRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetYoloRequest() / SetYoloRequest.new instead')
  static SetYoloRequest create() => SetYoloRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetYoloRequest._();
  @$core.override
  SetYoloRequest createEmptyInstance() => SetYoloRequest._();
  @$core.pragma('dart2js:noInline')
  static SetYoloRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetYoloRequest>(
          SetYoloRequest.$_createMessage);
  static SetYoloRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get yolo => $_getBF(1);
  @$pb.TagNumber(2)
  set yolo($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasYolo() => $_has(1);
  @$pb.TagNumber(2)
  void clearYolo() => $_clearField(2);
}

class SetYoloResponse extends $pb.GeneratedMessage {
  factory SetYoloResponse({
    Session? session,
  }) {
    final result = SetYoloResponse._();
    if (session != null) result.session = session;
    return result;
  }

  SetYoloResponse._();

  factory SetYoloResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetYoloResponse()..mergeFromBuffer(data, registry);
  factory SetYoloResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetYoloResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetYoloResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetYoloResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetYoloResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetYoloResponse copyWith(void Function(SetYoloResponse) updates) =>
      super.copyWith((message) => updates(message as SetYoloResponse))
          as SetYoloResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetYoloResponse() / SetYoloResponse.new instead')
  static SetYoloResponse create() => SetYoloResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetYoloResponse._();
  @$core.override
  SetYoloResponse createEmptyInstance() => SetYoloResponse._();
  @$core.pragma('dart2js:noInline')
  static SetYoloResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetYoloResponse>(
          SetYoloResponse.$_createMessage);
  static SetYoloResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

enum Event_Payload {
  messageStarted,
  textDelta,
  reasoningDelta,
  messageDone,
  toolCallStarted,
  toolOutput,
  toolCallDone,
  promptRequested,
  promptResolved,
  taskStateChanged,
  modelChanged,
  usage,
  error,
  todoUpdated,
  feedback,
  mcpServersChanged,
  sessionMoved,
  yoloChanged,
  permissionCheck,
  modelCallStarted,
  promptProgress,
  modelCallEnded,
  messageQueued,
  queuedMessageUpdated,
  queuedMessageDelivered,
  modelCallWaiting,
  promptCache,
  reasoningEndRequested,
  reasoningEndIgnored,
  compactionStarted,
  compactionDone,
  branchCreated,
  branchSwitched,
  notSet
}

/// Event is one entry in a session's event log.
class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? sessionId,
    $fixnum.Int64? seq,
    $0.Timestamp? time,
    $core.String? branchId,
    MessageStarted? messageStarted,
    TextDelta? textDelta,
    ReasoningDelta? reasoningDelta,
    MessageDone? messageDone,
    ToolCallStarted? toolCallStarted,
    ToolOutput? toolOutput,
    ToolCallDone? toolCallDone,
    PromptRequested? promptRequested,
    PromptResolved? promptResolved,
    TaskStateChanged? taskStateChanged,
    ModelChanged? modelChanged,
    Usage? usage,
    TurnError? error,
    TodoUpdated? todoUpdated,
    Feedback? feedback,
    McpServersChanged? mcpServersChanged,
    SessionMoved? sessionMoved,
    YoloChanged? yoloChanged,
    PermissionCheck? permissionCheck,
    ModelCallStarted? modelCallStarted,
    PromptProgress? promptProgress,
    ModelCallEnded? modelCallEnded,
    MessageQueued? messageQueued,
    QueuedMessageUpdated? queuedMessageUpdated,
    QueuedMessageDelivered? queuedMessageDelivered,
    ModelCallWaiting? modelCallWaiting,
    PromptCache? promptCache,
    ReasoningEndRequested? reasoningEndRequested,
    ReasoningEndIgnored? reasoningEndIgnored,
    CompactionStarted? compactionStarted,
    CompactionDone? compactionDone,
    BranchCreated? branchCreated,
    BranchSwitched? branchSwitched,
  }) {
    final result = Event._();
    if (sessionId != null) result.sessionId = sessionId;
    if (seq != null) result.seq = seq;
    if (time != null) result.time = time;
    if (branchId != null) result.branchId = branchId;
    if (messageStarted != null) result.messageStarted = messageStarted;
    if (textDelta != null) result.textDelta = textDelta;
    if (reasoningDelta != null) result.reasoningDelta = reasoningDelta;
    if (messageDone != null) result.messageDone = messageDone;
    if (toolCallStarted != null) result.toolCallStarted = toolCallStarted;
    if (toolOutput != null) result.toolOutput = toolOutput;
    if (toolCallDone != null) result.toolCallDone = toolCallDone;
    if (promptRequested != null) result.promptRequested = promptRequested;
    if (promptResolved != null) result.promptResolved = promptResolved;
    if (taskStateChanged != null) result.taskStateChanged = taskStateChanged;
    if (modelChanged != null) result.modelChanged = modelChanged;
    if (usage != null) result.usage = usage;
    if (error != null) result.error = error;
    if (todoUpdated != null) result.todoUpdated = todoUpdated;
    if (feedback != null) result.feedback = feedback;
    if (mcpServersChanged != null) result.mcpServersChanged = mcpServersChanged;
    if (sessionMoved != null) result.sessionMoved = sessionMoved;
    if (yoloChanged != null) result.yoloChanged = yoloChanged;
    if (permissionCheck != null) result.permissionCheck = permissionCheck;
    if (modelCallStarted != null) result.modelCallStarted = modelCallStarted;
    if (promptProgress != null) result.promptProgress = promptProgress;
    if (modelCallEnded != null) result.modelCallEnded = modelCallEnded;
    if (messageQueued != null) result.messageQueued = messageQueued;
    if (queuedMessageUpdated != null)
      result.queuedMessageUpdated = queuedMessageUpdated;
    if (queuedMessageDelivered != null)
      result.queuedMessageDelivered = queuedMessageDelivered;
    if (modelCallWaiting != null) result.modelCallWaiting = modelCallWaiting;
    if (promptCache != null) result.promptCache = promptCache;
    if (reasoningEndRequested != null)
      result.reasoningEndRequested = reasoningEndRequested;
    if (reasoningEndIgnored != null)
      result.reasoningEndIgnored = reasoningEndIgnored;
    if (compactionStarted != null) result.compactionStarted = compactionStarted;
    if (compactionDone != null) result.compactionDone = compactionDone;
    if (branchCreated != null) result.branchCreated = branchCreated;
    if (branchSwitched != null) result.branchSwitched = branchSwitched;
    return result;
  }

  Event._();

  factory Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromBuffer(data, registry);
  factory Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Event()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Event_Payload> _Event_PayloadByTag = {
    10: Event_Payload.messageStarted,
    11: Event_Payload.textDelta,
    12: Event_Payload.reasoningDelta,
    13: Event_Payload.messageDone,
    14: Event_Payload.toolCallStarted,
    15: Event_Payload.toolOutput,
    16: Event_Payload.toolCallDone,
    17: Event_Payload.promptRequested,
    18: Event_Payload.promptResolved,
    19: Event_Payload.taskStateChanged,
    20: Event_Payload.modelChanged,
    21: Event_Payload.usage,
    22: Event_Payload.error,
    23: Event_Payload.todoUpdated,
    24: Event_Payload.feedback,
    25: Event_Payload.mcpServersChanged,
    26: Event_Payload.sessionMoved,
    27: Event_Payload.yoloChanged,
    28: Event_Payload.permissionCheck,
    29: Event_Payload.modelCallStarted,
    30: Event_Payload.promptProgress,
    31: Event_Payload.modelCallEnded,
    32: Event_Payload.messageQueued,
    33: Event_Payload.queuedMessageUpdated,
    34: Event_Payload.queuedMessageDelivered,
    35: Event_Payload.modelCallWaiting,
    36: Event_Payload.promptCache,
    37: Event_Payload.reasoningEndRequested,
    38: Event_Payload.reasoningEndIgnored,
    39: Event_Payload.compactionStarted,
    40: Event_Payload.compactionDone,
    41: Event_Payload.branchCreated,
    42: Event_Payload.branchSwitched,
    0: Event_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..oo(0, [
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42
    ])
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aInt64(2, _omitFieldNames ? '' : 'seq')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'time',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'branchId')
    ..aOM<MessageStarted>(10, _omitFieldNames ? '' : 'messageStarted',
        subBuilder: MessageStarted.$_createMessage)
    ..aOM<TextDelta>(11, _omitFieldNames ? '' : 'textDelta',
        subBuilder: TextDelta.$_createMessage)
    ..aOM<ReasoningDelta>(12, _omitFieldNames ? '' : 'reasoningDelta',
        subBuilder: ReasoningDelta.$_createMessage)
    ..aOM<MessageDone>(13, _omitFieldNames ? '' : 'messageDone',
        subBuilder: MessageDone.$_createMessage)
    ..aOM<ToolCallStarted>(14, _omitFieldNames ? '' : 'toolCallStarted',
        subBuilder: ToolCallStarted.$_createMessage)
    ..aOM<ToolOutput>(15, _omitFieldNames ? '' : 'toolOutput',
        subBuilder: ToolOutput.$_createMessage)
    ..aOM<ToolCallDone>(16, _omitFieldNames ? '' : 'toolCallDone',
        subBuilder: ToolCallDone.$_createMessage)
    ..aOM<PromptRequested>(17, _omitFieldNames ? '' : 'promptRequested',
        subBuilder: PromptRequested.$_createMessage)
    ..aOM<PromptResolved>(18, _omitFieldNames ? '' : 'promptResolved',
        subBuilder: PromptResolved.$_createMessage)
    ..aOM<TaskStateChanged>(19, _omitFieldNames ? '' : 'taskStateChanged',
        subBuilder: TaskStateChanged.$_createMessage)
    ..aOM<ModelChanged>(20, _omitFieldNames ? '' : 'modelChanged',
        subBuilder: ModelChanged.$_createMessage)
    ..aOM<Usage>(21, _omitFieldNames ? '' : 'usage',
        subBuilder: Usage.$_createMessage)
    ..aOM<TurnError>(22, _omitFieldNames ? '' : 'error',
        subBuilder: TurnError.$_createMessage)
    ..aOM<TodoUpdated>(23, _omitFieldNames ? '' : 'todoUpdated',
        subBuilder: TodoUpdated.$_createMessage)
    ..aOM<Feedback>(24, _omitFieldNames ? '' : 'feedback',
        subBuilder: Feedback.$_createMessage)
    ..aOM<McpServersChanged>(25, _omitFieldNames ? '' : 'mcpServersChanged',
        subBuilder: McpServersChanged.$_createMessage)
    ..aOM<SessionMoved>(26, _omitFieldNames ? '' : 'sessionMoved',
        subBuilder: SessionMoved.$_createMessage)
    ..aOM<YoloChanged>(27, _omitFieldNames ? '' : 'yoloChanged',
        subBuilder: YoloChanged.$_createMessage)
    ..aOM<PermissionCheck>(28, _omitFieldNames ? '' : 'permissionCheck',
        subBuilder: PermissionCheck.$_createMessage)
    ..aOM<ModelCallStarted>(29, _omitFieldNames ? '' : 'modelCallStarted',
        subBuilder: ModelCallStarted.$_createMessage)
    ..aOM<PromptProgress>(30, _omitFieldNames ? '' : 'promptProgress',
        subBuilder: PromptProgress.$_createMessage)
    ..aOM<ModelCallEnded>(31, _omitFieldNames ? '' : 'modelCallEnded',
        subBuilder: ModelCallEnded.$_createMessage)
    ..aOM<MessageQueued>(32, _omitFieldNames ? '' : 'messageQueued',
        subBuilder: MessageQueued.$_createMessage)
    ..aOM<QueuedMessageUpdated>(
        33, _omitFieldNames ? '' : 'queuedMessageUpdated',
        subBuilder: QueuedMessageUpdated.$_createMessage)
    ..aOM<QueuedMessageDelivered>(
        34, _omitFieldNames ? '' : 'queuedMessageDelivered',
        subBuilder: QueuedMessageDelivered.$_createMessage)
    ..aOM<ModelCallWaiting>(35, _omitFieldNames ? '' : 'modelCallWaiting',
        subBuilder: ModelCallWaiting.$_createMessage)
    ..aOM<PromptCache>(36, _omitFieldNames ? '' : 'promptCache',
        subBuilder: PromptCache.$_createMessage)
    ..aOM<ReasoningEndRequested>(
        37, _omitFieldNames ? '' : 'reasoningEndRequested',
        subBuilder: ReasoningEndRequested.$_createMessage)
    ..aOM<ReasoningEndIgnored>(38, _omitFieldNames ? '' : 'reasoningEndIgnored',
        subBuilder: ReasoningEndIgnored.$_createMessage)
    ..aOM<CompactionStarted>(39, _omitFieldNames ? '' : 'compactionStarted',
        subBuilder: CompactionStarted.$_createMessage)
    ..aOM<CompactionDone>(40, _omitFieldNames ? '' : 'compactionDone',
        subBuilder: CompactionDone.$_createMessage)
    ..aOM<BranchCreated>(41, _omitFieldNames ? '' : 'branchCreated',
        subBuilder: BranchCreated.$_createMessage)
    ..aOM<BranchSwitched>(42, _omitFieldNames ? '' : 'branchSwitched',
        subBuilder: BranchSwitched.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Event copyWith(void Function(Event) updates) =>
      super.copyWith((message) => updates(message as Event)) as Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Event() / Event.new instead')
  static Event create() => Event._();
  static $pb.GeneratedMessage $_createMessage() => Event._();
  @$core.override
  Event createEmptyInstance() => Event._();
  @$core.pragma('dart2js:noInline')
  static Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Event>(Event.$_createMessage);
  static Event? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  Event_Payload whichPayload() => _Event_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  @$pb.TagNumber(35)
  @$pb.TagNumber(36)
  @$pb.TagNumber(37)
  @$pb.TagNumber(38)
  @$pb.TagNumber(39)
  @$pb.TagNumber(40)
  @$pb.TagNumber(41)
  @$pb.TagNumber(42)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Per-session sequence number, starting at 1, with no gaps.
  @$pb.TagNumber(2)
  $fixnum.Int64 get seq => $_getI64(1);
  @$pb.TagNumber(2)
  set seq($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeq() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeq() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get time => $_getN(2);
  @$pb.TagNumber(3)
  set time($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureTime() => $_ensure(2);

  /// The branch the event belongs to: the session's active branch when it
  /// was recorded. Empty is the root branch (every event of a session that
  /// never forked). A branch's history is its ancestors' events up to each
  /// fork point plus its own events. Session-wide events (task state,
  /// model, yolo, MCP servers, project, queue, branches) apply whatever
  /// their branch_id.
  @$pb.TagNumber(4)
  $core.String get branchId => $_getSZ(3);
  @$pb.TagNumber(4)
  set branchId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBranchId() => $_has(3);
  @$pb.TagNumber(4)
  void clearBranchId() => $_clearField(4);

  @$pb.TagNumber(10)
  MessageStarted get messageStarted => $_getN(4);
  @$pb.TagNumber(10)
  set messageStarted(MessageStarted value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMessageStarted() => $_has(4);
  @$pb.TagNumber(10)
  void clearMessageStarted() => $_clearField(10);
  @$pb.TagNumber(10)
  MessageStarted ensureMessageStarted() => $_ensure(4);

  @$pb.TagNumber(11)
  TextDelta get textDelta => $_getN(5);
  @$pb.TagNumber(11)
  set textDelta(TextDelta value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTextDelta() => $_has(5);
  @$pb.TagNumber(11)
  void clearTextDelta() => $_clearField(11);
  @$pb.TagNumber(11)
  TextDelta ensureTextDelta() => $_ensure(5);

  @$pb.TagNumber(12)
  ReasoningDelta get reasoningDelta => $_getN(6);
  @$pb.TagNumber(12)
  set reasoningDelta(ReasoningDelta value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasReasoningDelta() => $_has(6);
  @$pb.TagNumber(12)
  void clearReasoningDelta() => $_clearField(12);
  @$pb.TagNumber(12)
  ReasoningDelta ensureReasoningDelta() => $_ensure(6);

  @$pb.TagNumber(13)
  MessageDone get messageDone => $_getN(7);
  @$pb.TagNumber(13)
  set messageDone(MessageDone value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasMessageDone() => $_has(7);
  @$pb.TagNumber(13)
  void clearMessageDone() => $_clearField(13);
  @$pb.TagNumber(13)
  MessageDone ensureMessageDone() => $_ensure(7);

  @$pb.TagNumber(14)
  ToolCallStarted get toolCallStarted => $_getN(8);
  @$pb.TagNumber(14)
  set toolCallStarted(ToolCallStarted value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasToolCallStarted() => $_has(8);
  @$pb.TagNumber(14)
  void clearToolCallStarted() => $_clearField(14);
  @$pb.TagNumber(14)
  ToolCallStarted ensureToolCallStarted() => $_ensure(8);

  @$pb.TagNumber(15)
  ToolOutput get toolOutput => $_getN(9);
  @$pb.TagNumber(15)
  set toolOutput(ToolOutput value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasToolOutput() => $_has(9);
  @$pb.TagNumber(15)
  void clearToolOutput() => $_clearField(15);
  @$pb.TagNumber(15)
  ToolOutput ensureToolOutput() => $_ensure(9);

  @$pb.TagNumber(16)
  ToolCallDone get toolCallDone => $_getN(10);
  @$pb.TagNumber(16)
  set toolCallDone(ToolCallDone value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasToolCallDone() => $_has(10);
  @$pb.TagNumber(16)
  void clearToolCallDone() => $_clearField(16);
  @$pb.TagNumber(16)
  ToolCallDone ensureToolCallDone() => $_ensure(10);

  @$pb.TagNumber(17)
  PromptRequested get promptRequested => $_getN(11);
  @$pb.TagNumber(17)
  set promptRequested(PromptRequested value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPromptRequested() => $_has(11);
  @$pb.TagNumber(17)
  void clearPromptRequested() => $_clearField(17);
  @$pb.TagNumber(17)
  PromptRequested ensurePromptRequested() => $_ensure(11);

  @$pb.TagNumber(18)
  PromptResolved get promptResolved => $_getN(12);
  @$pb.TagNumber(18)
  set promptResolved(PromptResolved value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasPromptResolved() => $_has(12);
  @$pb.TagNumber(18)
  void clearPromptResolved() => $_clearField(18);
  @$pb.TagNumber(18)
  PromptResolved ensurePromptResolved() => $_ensure(12);

  @$pb.TagNumber(19)
  TaskStateChanged get taskStateChanged => $_getN(13);
  @$pb.TagNumber(19)
  set taskStateChanged(TaskStateChanged value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasTaskStateChanged() => $_has(13);
  @$pb.TagNumber(19)
  void clearTaskStateChanged() => $_clearField(19);
  @$pb.TagNumber(19)
  TaskStateChanged ensureTaskStateChanged() => $_ensure(13);

  @$pb.TagNumber(20)
  ModelChanged get modelChanged => $_getN(14);
  @$pb.TagNumber(20)
  set modelChanged(ModelChanged value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasModelChanged() => $_has(14);
  @$pb.TagNumber(20)
  void clearModelChanged() => $_clearField(20);
  @$pb.TagNumber(20)
  ModelChanged ensureModelChanged() => $_ensure(14);

  @$pb.TagNumber(21)
  Usage get usage => $_getN(15);
  @$pb.TagNumber(21)
  set usage(Usage value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasUsage() => $_has(15);
  @$pb.TagNumber(21)
  void clearUsage() => $_clearField(21);
  @$pb.TagNumber(21)
  Usage ensureUsage() => $_ensure(15);

  @$pb.TagNumber(22)
  TurnError get error => $_getN(16);
  @$pb.TagNumber(22)
  set error(TurnError value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasError() => $_has(16);
  @$pb.TagNumber(22)
  void clearError() => $_clearField(22);
  @$pb.TagNumber(22)
  TurnError ensureError() => $_ensure(16);

  @$pb.TagNumber(23)
  TodoUpdated get todoUpdated => $_getN(17);
  @$pb.TagNumber(23)
  set todoUpdated(TodoUpdated value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTodoUpdated() => $_has(17);
  @$pb.TagNumber(23)
  void clearTodoUpdated() => $_clearField(23);
  @$pb.TagNumber(23)
  TodoUpdated ensureTodoUpdated() => $_ensure(17);

  @$pb.TagNumber(24)
  Feedback get feedback => $_getN(18);
  @$pb.TagNumber(24)
  set feedback(Feedback value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasFeedback() => $_has(18);
  @$pb.TagNumber(24)
  void clearFeedback() => $_clearField(24);
  @$pb.TagNumber(24)
  Feedback ensureFeedback() => $_ensure(18);

  @$pb.TagNumber(25)
  McpServersChanged get mcpServersChanged => $_getN(19);
  @$pb.TagNumber(25)
  set mcpServersChanged(McpServersChanged value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasMcpServersChanged() => $_has(19);
  @$pb.TagNumber(25)
  void clearMcpServersChanged() => $_clearField(25);
  @$pb.TagNumber(25)
  McpServersChanged ensureMcpServersChanged() => $_ensure(19);

  @$pb.TagNumber(26)
  SessionMoved get sessionMoved => $_getN(20);
  @$pb.TagNumber(26)
  set sessionMoved(SessionMoved value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasSessionMoved() => $_has(20);
  @$pb.TagNumber(26)
  void clearSessionMoved() => $_clearField(26);
  @$pb.TagNumber(26)
  SessionMoved ensureSessionMoved() => $_ensure(20);

  @$pb.TagNumber(27)
  YoloChanged get yoloChanged => $_getN(21);
  @$pb.TagNumber(27)
  set yoloChanged(YoloChanged value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasYoloChanged() => $_has(21);
  @$pb.TagNumber(27)
  void clearYoloChanged() => $_clearField(27);
  @$pb.TagNumber(27)
  YoloChanged ensureYoloChanged() => $_ensure(21);

  @$pb.TagNumber(28)
  PermissionCheck get permissionCheck => $_getN(22);
  @$pb.TagNumber(28)
  set permissionCheck(PermissionCheck value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasPermissionCheck() => $_has(22);
  @$pb.TagNumber(28)
  void clearPermissionCheck() => $_clearField(28);
  @$pb.TagNumber(28)
  PermissionCheck ensurePermissionCheck() => $_ensure(22);

  @$pb.TagNumber(29)
  ModelCallStarted get modelCallStarted => $_getN(23);
  @$pb.TagNumber(29)
  set modelCallStarted(ModelCallStarted value) => $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasModelCallStarted() => $_has(23);
  @$pb.TagNumber(29)
  void clearModelCallStarted() => $_clearField(29);
  @$pb.TagNumber(29)
  ModelCallStarted ensureModelCallStarted() => $_ensure(23);

  @$pb.TagNumber(30)
  PromptProgress get promptProgress => $_getN(24);
  @$pb.TagNumber(30)
  set promptProgress(PromptProgress value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasPromptProgress() => $_has(24);
  @$pb.TagNumber(30)
  void clearPromptProgress() => $_clearField(30);
  @$pb.TagNumber(30)
  PromptProgress ensurePromptProgress() => $_ensure(24);

  @$pb.TagNumber(31)
  ModelCallEnded get modelCallEnded => $_getN(25);
  @$pb.TagNumber(31)
  set modelCallEnded(ModelCallEnded value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasModelCallEnded() => $_has(25);
  @$pb.TagNumber(31)
  void clearModelCallEnded() => $_clearField(31);
  @$pb.TagNumber(31)
  ModelCallEnded ensureModelCallEnded() => $_ensure(25);

  @$pb.TagNumber(32)
  MessageQueued get messageQueued => $_getN(26);
  @$pb.TagNumber(32)
  set messageQueued(MessageQueued value) => $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasMessageQueued() => $_has(26);
  @$pb.TagNumber(32)
  void clearMessageQueued() => $_clearField(32);
  @$pb.TagNumber(32)
  MessageQueued ensureMessageQueued() => $_ensure(26);

  @$pb.TagNumber(33)
  QueuedMessageUpdated get queuedMessageUpdated => $_getN(27);
  @$pb.TagNumber(33)
  set queuedMessageUpdated(QueuedMessageUpdated value) => $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasQueuedMessageUpdated() => $_has(27);
  @$pb.TagNumber(33)
  void clearQueuedMessageUpdated() => $_clearField(33);
  @$pb.TagNumber(33)
  QueuedMessageUpdated ensureQueuedMessageUpdated() => $_ensure(27);

  @$pb.TagNumber(34)
  QueuedMessageDelivered get queuedMessageDelivered => $_getN(28);
  @$pb.TagNumber(34)
  set queuedMessageDelivered(QueuedMessageDelivered value) =>
      $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasQueuedMessageDelivered() => $_has(28);
  @$pb.TagNumber(34)
  void clearQueuedMessageDelivered() => $_clearField(34);
  @$pb.TagNumber(34)
  QueuedMessageDelivered ensureQueuedMessageDelivered() => $_ensure(28);

  @$pb.TagNumber(35)
  ModelCallWaiting get modelCallWaiting => $_getN(29);
  @$pb.TagNumber(35)
  set modelCallWaiting(ModelCallWaiting value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasModelCallWaiting() => $_has(29);
  @$pb.TagNumber(35)
  void clearModelCallWaiting() => $_clearField(35);
  @$pb.TagNumber(35)
  ModelCallWaiting ensureModelCallWaiting() => $_ensure(29);

  @$pb.TagNumber(36)
  PromptCache get promptCache => $_getN(30);
  @$pb.TagNumber(36)
  set promptCache(PromptCache value) => $_setField(36, value);
  @$pb.TagNumber(36)
  $core.bool hasPromptCache() => $_has(30);
  @$pb.TagNumber(36)
  void clearPromptCache() => $_clearField(36);
  @$pb.TagNumber(36)
  PromptCache ensurePromptCache() => $_ensure(30);

  @$pb.TagNumber(37)
  ReasoningEndRequested get reasoningEndRequested => $_getN(31);
  @$pb.TagNumber(37)
  set reasoningEndRequested(ReasoningEndRequested value) =>
      $_setField(37, value);
  @$pb.TagNumber(37)
  $core.bool hasReasoningEndRequested() => $_has(31);
  @$pb.TagNumber(37)
  void clearReasoningEndRequested() => $_clearField(37);
  @$pb.TagNumber(37)
  ReasoningEndRequested ensureReasoningEndRequested() => $_ensure(31);

  @$pb.TagNumber(38)
  ReasoningEndIgnored get reasoningEndIgnored => $_getN(32);
  @$pb.TagNumber(38)
  set reasoningEndIgnored(ReasoningEndIgnored value) => $_setField(38, value);
  @$pb.TagNumber(38)
  $core.bool hasReasoningEndIgnored() => $_has(32);
  @$pb.TagNumber(38)
  void clearReasoningEndIgnored() => $_clearField(38);
  @$pb.TagNumber(38)
  ReasoningEndIgnored ensureReasoningEndIgnored() => $_ensure(32);

  @$pb.TagNumber(39)
  CompactionStarted get compactionStarted => $_getN(33);
  @$pb.TagNumber(39)
  set compactionStarted(CompactionStarted value) => $_setField(39, value);
  @$pb.TagNumber(39)
  $core.bool hasCompactionStarted() => $_has(33);
  @$pb.TagNumber(39)
  void clearCompactionStarted() => $_clearField(39);
  @$pb.TagNumber(39)
  CompactionStarted ensureCompactionStarted() => $_ensure(33);

  @$pb.TagNumber(40)
  CompactionDone get compactionDone => $_getN(34);
  @$pb.TagNumber(40)
  set compactionDone(CompactionDone value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasCompactionDone() => $_has(34);
  @$pb.TagNumber(40)
  void clearCompactionDone() => $_clearField(40);
  @$pb.TagNumber(40)
  CompactionDone ensureCompactionDone() => $_ensure(34);

  @$pb.TagNumber(41)
  BranchCreated get branchCreated => $_getN(35);
  @$pb.TagNumber(41)
  set branchCreated(BranchCreated value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasBranchCreated() => $_has(35);
  @$pb.TagNumber(41)
  void clearBranchCreated() => $_clearField(41);
  @$pb.TagNumber(41)
  BranchCreated ensureBranchCreated() => $_ensure(35);

  @$pb.TagNumber(42)
  BranchSwitched get branchSwitched => $_getN(36);
  @$pb.TagNumber(42)
  set branchSwitched(BranchSwitched value) => $_setField(42, value);
  @$pb.TagNumber(42)
  $core.bool hasBranchSwitched() => $_has(36);
  @$pb.TagNumber(42)
  void clearBranchSwitched() => $_clearField(42);
  @$pb.TagNumber(42)
  BranchSwitched ensureBranchSwitched() => $_ensure(36);
}

/// MessageStarted opens a message. Its text arrives as TextDelta events and
/// it ends with MessageDone.
class MessageStarted extends $pb.GeneratedMessage {
  factory MessageStarted({
    $core.String? messageId,
    Role? role,
    $core.String? provider,
    $core.String? model,
  }) {
    final result = MessageStarted._();
    if (messageId != null) result.messageId = messageId;
    if (role != null) result.role = role;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  MessageStarted._();

  factory MessageStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageStarted()..mergeFromBuffer(data, registry);
  factory MessageStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: MessageStarted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aE<Role>(2, _omitFieldNames ? '' : 'role', enumValues: Role.values)
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageStarted copyWith(void Function(MessageStarted) updates) =>
      super.copyWith((message) => updates(message as MessageStarted))
          as MessageStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageStarted() / MessageStarted.new instead')
  static MessageStarted create() => MessageStarted._();
  static $pb.GeneratedMessage $_createMessage() => MessageStarted._();
  @$core.override
  MessageStarted createEmptyInstance() => MessageStarted._();
  @$core.pragma('dart2js:noInline')
  static MessageStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageStarted>(
          MessageStarted.$_createMessage);
  static MessageStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  Role get role => $_getN(1);
  @$pb.TagNumber(2)
  set role(Role value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  /// For assistant messages, the model writing it.
  @$pb.TagNumber(3)
  $core.String get provider => $_getSZ(2);
  @$pb.TagNumber(3)
  set provider($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProvider() => $_has(2);
  @$pb.TagNumber(3)
  void clearProvider() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get model => $_getSZ(3);
  @$pb.TagNumber(4)
  set model($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModel() => $_has(3);
  @$pb.TagNumber(4)
  void clearModel() => $_clearField(4);
}

class TextDelta extends $pb.GeneratedMessage {
  factory TextDelta({
    $core.String? messageId,
    $core.String? text,
  }) {
    final result = TextDelta._();
    if (messageId != null) result.messageId = messageId;
    if (text != null) result.text = text;
    return result;
  }

  TextDelta._();

  factory TextDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextDelta()..mergeFromBuffer(data, registry);
  factory TextDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TextDelta()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextDelta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: TextDelta.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextDelta copyWith(void Function(TextDelta) updates) =>
      super.copyWith((message) => updates(message as TextDelta)) as TextDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TextDelta() / TextDelta.new instead')
  static TextDelta create() => TextDelta._();
  static $pb.GeneratedMessage $_createMessage() => TextDelta._();
  @$core.override
  TextDelta createEmptyInstance() => TextDelta._();
  @$core.pragma('dart2js:noInline')
  static TextDelta getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextDelta>(TextDelta.$_createMessage);
  static TextDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

/// ReasoningDelta is model reasoning ("thinking") text, for models that
/// expose it.
class ReasoningDelta extends $pb.GeneratedMessage {
  factory ReasoningDelta({
    $core.String? messageId,
    $core.String? text,
  }) {
    final result = ReasoningDelta._();
    if (messageId != null) result.messageId = messageId;
    if (text != null) result.text = text;
    return result;
  }

  ReasoningDelta._();

  factory ReasoningDelta.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningDelta()..mergeFromBuffer(data, registry);
  factory ReasoningDelta.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningDelta()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReasoningDelta',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ReasoningDelta.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningDelta clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningDelta copyWith(void Function(ReasoningDelta) updates) =>
      super.copyWith((message) => updates(message as ReasoningDelta))
          as ReasoningDelta;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReasoningDelta() / ReasoningDelta.new instead')
  static ReasoningDelta create() => ReasoningDelta._();
  static $pb.GeneratedMessage $_createMessage() => ReasoningDelta._();
  @$core.override
  ReasoningDelta createEmptyInstance() => ReasoningDelta._();
  @$core.pragma('dart2js:noInline')
  static ReasoningDelta getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReasoningDelta>(
          ReasoningDelta.$_createMessage);
  static ReasoningDelta? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

/// MessageDone closes a message and repeats its full text.
class MessageDone extends $pb.GeneratedMessage {
  factory MessageDone({
    $core.String? messageId,
    $core.String? text,
    $core.String? reasoning,
    $core.String? finishReason,
  }) {
    final result = MessageDone._();
    if (messageId != null) result.messageId = messageId;
    if (text != null) result.text = text;
    if (reasoning != null) result.reasoning = reasoning;
    if (finishReason != null) result.finishReason = finishReason;
    return result;
  }

  MessageDone._();

  factory MessageDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageDone()..mergeFromBuffer(data, registry);
  factory MessageDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageDone()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: MessageDone.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'reasoning')
    ..aOS(4, _omitFieldNames ? '' : 'finishReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageDone copyWith(void Function(MessageDone) updates) =>
      super.copyWith((message) => updates(message as MessageDone))
          as MessageDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageDone() / MessageDone.new instead')
  static MessageDone create() => MessageDone._();
  static $pb.GeneratedMessage $_createMessage() => MessageDone._();
  @$core.override
  MessageDone createEmptyInstance() => MessageDone._();
  @$core.pragma('dart2js:noInline')
  static MessageDone getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageDone>(
          MessageDone.$_createMessage);
  static MessageDone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reasoning => $_getSZ(2);
  @$pb.TagNumber(3)
  set reasoning($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReasoning() => $_has(2);
  @$pb.TagNumber(3)
  void clearReasoning() => $_clearField(3);

  /// Why the model stopped: "stop", "tool_calls", "length", "interrupted", ...
  @$pb.TagNumber(4)
  $core.String get finishReason => $_getSZ(3);
  @$pb.TagNumber(4)
  set finishReason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFinishReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearFinishReason() => $_clearField(4);
}

/// ToolCallStarted is a tool call the model made in message message_id.
class ToolCallStarted extends $pb.GeneratedMessage {
  factory ToolCallStarted({
    $core.String? messageId,
    $core.String? toolCallId,
    $core.String? name,
    $core.String? arguments,
  }) {
    final result = ToolCallStarted._();
    if (messageId != null) result.messageId = messageId;
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (name != null) result.name = name;
    if (arguments != null) result.arguments = arguments;
    return result;
  }

  ToolCallStarted._();

  factory ToolCallStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolCallStarted()..mergeFromBuffer(data, registry);
  factory ToolCallStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolCallStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolCallStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ToolCallStarted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'arguments')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCallStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCallStarted copyWith(void Function(ToolCallStarted) updates) =>
      super.copyWith((message) => updates(message as ToolCallStarted))
          as ToolCallStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ToolCallStarted() / ToolCallStarted.new instead')
  static ToolCallStarted create() => ToolCallStarted._();
  static $pb.GeneratedMessage $_createMessage() => ToolCallStarted._();
  @$core.override
  ToolCallStarted createEmptyInstance() => ToolCallStarted._();
  @$core.pragma('dart2js:noInline')
  static ToolCallStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ToolCallStarted>(
          ToolCallStarted.$_createMessage);
  static ToolCallStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get toolCallId => $_getSZ(1);
  @$pb.TagNumber(2)
  set toolCallId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToolCallId() => $_has(1);
  @$pb.TagNumber(2)
  void clearToolCallId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  /// Arguments as the JSON text the model produced.
  @$pb.TagNumber(4)
  $core.String get arguments => $_getSZ(3);
  @$pb.TagNumber(4)
  set arguments($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasArguments() => $_has(3);
  @$pb.TagNumber(4)
  void clearArguments() => $_clearField(4);
}

/// ToolOutput is live output from a running tool (e.g. shell stdout/stderr).
/// The model sees ToolCallDone.result, not these chunks.
class ToolOutput extends $pb.GeneratedMessage {
  factory ToolOutput({
    $core.String? toolCallId,
    $core.String? text,
  }) {
    final result = ToolOutput._();
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (text != null) result.text = text;
    return result;
  }

  ToolOutput._();

  factory ToolOutput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolOutput()..mergeFromBuffer(data, registry);
  factory ToolOutput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolOutput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolOutput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ToolOutput.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolOutput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolOutput copyWith(void Function(ToolOutput) updates) =>
      super.copyWith((message) => updates(message as ToolOutput)) as ToolOutput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ToolOutput() / ToolOutput.new instead')
  static ToolOutput create() => ToolOutput._();
  static $pb.GeneratedMessage $_createMessage() => ToolOutput._();
  @$core.override
  ToolOutput createEmptyInstance() => ToolOutput._();
  @$core.pragma('dart2js:noInline')
  static ToolOutput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToolOutput>(ToolOutput.$_createMessage);
  static ToolOutput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toolCallId => $_getSZ(0);
  @$pb.TagNumber(1)
  set toolCallId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToolCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearToolCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class ToolCallDone extends $pb.GeneratedMessage {
  factory ToolCallDone({
    $core.String? toolCallId,
    $core.String? result,
    $core.bool? isError,
    $core.bool? truncated,
    $fixnum.Int64? omittedBytes,
  }) {
    final result$ = ToolCallDone._();
    if (toolCallId != null) result$.toolCallId = toolCallId;
    if (result != null) result$.result = result;
    if (isError != null) result$.isError = isError;
    if (truncated != null) result$.truncated = truncated;
    if (omittedBytes != null) result$.omittedBytes = omittedBytes;
    return result$;
  }

  ToolCallDone._();

  factory ToolCallDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolCallDone()..mergeFromBuffer(data, registry);
  factory ToolCallDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolCallDone()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolCallDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ToolCallDone.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(2, _omitFieldNames ? '' : 'result')
    ..aOB(3, _omitFieldNames ? '' : 'isError')
    ..aOB(4, _omitFieldNames ? '' : 'truncated')
    ..aInt64(5, _omitFieldNames ? '' : 'omittedBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCallDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolCallDone copyWith(void Function(ToolCallDone) updates) =>
      super.copyWith((message) => updates(message as ToolCallDone))
          as ToolCallDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ToolCallDone() / ToolCallDone.new instead')
  static ToolCallDone create() => ToolCallDone._();
  static $pb.GeneratedMessage $_createMessage() => ToolCallDone._();
  @$core.override
  ToolCallDone createEmptyInstance() => ToolCallDone._();
  @$core.pragma('dart2js:noInline')
  static ToolCallDone getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ToolCallDone>(
          ToolCallDone.$_createMessage);
  static ToolCallDone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toolCallId => $_getSZ(0);
  @$pb.TagNumber(1)
  set toolCallId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToolCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearToolCallId() => $_clearField(1);

  /// What the model sees, after truncation.
  @$pb.TagNumber(2)
  $core.String get result => $_getSZ(1);
  @$pb.TagNumber(2)
  set result($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isError => $_getBF(2);
  @$pb.TagNumber(3)
  set isError($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsError() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsError() => $_clearField(3);

  /// Whether result was shortened, and by how many bytes.
  @$pb.TagNumber(4)
  $core.bool get truncated => $_getBF(3);
  @$pb.TagNumber(4)
  set truncated($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTruncated() => $_has(3);
  @$pb.TagNumber(4)
  void clearTruncated() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get omittedBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set omittedBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOmittedBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearOmittedBytes() => $_clearField(5);
}

/// PromptRequested asks the user to allow or deny something, such as a shell
/// command. The turn waits until a client calls AnswerPrompt.
class PromptRequested extends $pb.GeneratedMessage {
  factory PromptRequested({
    $core.String? promptId,
    $core.String? toolCallId,
    $core.String? title,
    $core.String? detail,
    $core.Iterable<$core.String>? sessionPatterns,
    $core.String? safetyReason,
  }) {
    final result = PromptRequested._();
    if (promptId != null) result.promptId = promptId;
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (title != null) result.title = title;
    if (detail != null) result.detail = detail;
    if (sessionPatterns != null) result.sessionPatterns.addAll(sessionPatterns);
    if (safetyReason != null) result.safetyReason = safetyReason;
    return result;
  }

  PromptRequested._();

  factory PromptRequested.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRequested()..mergeFromBuffer(data, registry);
  factory PromptRequested.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptRequested()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptRequested',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PromptRequested.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'promptId')
    ..aOS(2, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'detail')
    ..pPS(5, _omitFieldNames ? '' : 'sessionPatterns')
    ..aOS(6, _omitFieldNames ? '' : 'safetyReason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRequested clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptRequested copyWith(void Function(PromptRequested) updates) =>
      super.copyWith((message) => updates(message as PromptRequested))
          as PromptRequested;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptRequested() / PromptRequested.new instead')
  static PromptRequested create() => PromptRequested._();
  static $pb.GeneratedMessage $_createMessage() => PromptRequested._();
  @$core.override
  PromptRequested createEmptyInstance() => PromptRequested._();
  @$core.pragma('dart2js:noInline')
  static PromptRequested getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptRequested>(
          PromptRequested.$_createMessage);
  static PromptRequested? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get promptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set promptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromptId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get toolCallId => $_getSZ(1);
  @$pb.TagNumber(2)
  set toolCallId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToolCallId() => $_has(1);
  @$pb.TagNumber(2)
  void clearToolCallId() => $_clearField(2);

  /// Short description, e.g. "Run shell command".
  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  /// What exactly would happen, e.g. the command line.
  @$pb.TagNumber(4)
  $core.String get detail => $_getSZ(3);
  @$pb.TagNumber(4)
  set detail($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetail() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetail() => $_clearField(4);

  /// What "allow for this session" would allow from now on, e.g.
  /// ["go test *"]: each command's program and subcommand, ignoring a
  /// leading "cd ... &&" and variable assignments. Empty when it isn't
  /// offered.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get sessionPatterns => $_getList(4);

  /// Why the safety check (the permission task's model) wants the user to
  /// decide; empty when it didn't run.
  @$pb.TagNumber(6)
  $core.String get safetyReason => $_getSZ(5);
  @$pb.TagNumber(6)
  set safetyReason($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSafetyReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearSafetyReason() => $_clearField(6);
}

class PromptResolved extends $pb.GeneratedMessage {
  factory PromptResolved({
    $core.String? promptId,
    PromptDecision? decision,
    $core.String? client,
    $core.String? reason,
    $core.Iterable<$core.String>? sessionPatterns,
  }) {
    final result = PromptResolved._();
    if (promptId != null) result.promptId = promptId;
    if (decision != null) result.decision = decision;
    if (client != null) result.client = client;
    if (reason != null) result.reason = reason;
    if (sessionPatterns != null) result.sessionPatterns.addAll(sessionPatterns);
    return result;
  }

  PromptResolved._();

  factory PromptResolved.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptResolved()..mergeFromBuffer(data, registry);
  factory PromptResolved.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptResolved()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptResolved',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PromptResolved.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'promptId')
    ..aE<PromptDecision>(2, _omitFieldNames ? '' : 'decision',
        enumValues: PromptDecision.values)
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..pPS(5, _omitFieldNames ? '' : 'sessionPatterns')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptResolved clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptResolved copyWith(void Function(PromptResolved) updates) =>
      super.copyWith((message) => updates(message as PromptResolved))
          as PromptResolved;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptResolved() / PromptResolved.new instead')
  static PromptResolved create() => PromptResolved._();
  static $pb.GeneratedMessage $_createMessage() => PromptResolved._();
  @$core.override
  PromptResolved createEmptyInstance() => PromptResolved._();
  @$core.pragma('dart2js:noInline')
  static PromptResolved getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptResolved>(
          PromptResolved.$_createMessage);
  static PromptResolved? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get promptId => $_getSZ(0);
  @$pb.TagNumber(1)
  set promptId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromptId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromptId() => $_clearField(1);

  @$pb.TagNumber(2)
  PromptDecision get decision => $_getN(1);
  @$pb.TagNumber(2)
  set decision(PromptDecision value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDecision() => $_has(1);
  @$pb.TagNumber(2)
  void clearDecision() => $_clearField(2);

  /// Client that answered (AnswerPromptRequest.client), or empty if the
  /// server resolved it, e.g. on interrupt.
  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);

  /// Why the server resolved it, when it did.
  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);

  /// With PROMPT_DECISION_ALLOW_SESSION: the patterns now allowed for the
  /// rest of the session.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get sessionPatterns => $_getList(4);
}

class TaskStateChanged extends $pb.GeneratedMessage {
  factory TaskStateChanged({
    TaskState? state,
    $core.String? reason,
  }) {
    final result = TaskStateChanged._();
    if (state != null) result.state = state;
    if (reason != null) result.reason = reason;
    return result;
  }

  TaskStateChanged._();

  factory TaskStateChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskStateChanged()..mergeFromBuffer(data, registry);
  factory TaskStateChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TaskStateChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskStateChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: TaskStateChanged.$_createMessage)
    ..aE<TaskState>(1, _omitFieldNames ? '' : 'state',
        enumValues: TaskState.values)
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskStateChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TaskStateChanged copyWith(void Function(TaskStateChanged) updates) =>
      super.copyWith((message) => updates(message as TaskStateChanged))
          as TaskStateChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TaskStateChanged() / TaskStateChanged.new instead')
  static TaskStateChanged create() => TaskStateChanged._();
  static $pb.GeneratedMessage $_createMessage() => TaskStateChanged._();
  @$core.override
  TaskStateChanged createEmptyInstance() => TaskStateChanged._();
  @$core.pragma('dart2js:noInline')
  static TaskStateChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TaskStateChanged>(
          TaskStateChanged.$_createMessage);
  static TaskStateChanged? _defaultInstance;

  @$pb.TagNumber(1)
  TaskState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(TaskState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Human-readable detail, e.g. "interrupted".
  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);
}

class ModelChanged extends $pb.GeneratedMessage {
  factory ModelChanged({
    $core.String? provider,
    $core.String? model,
    $core.String? effort,
    $fixnum.Int64? contextLength,
  }) {
    final result = ModelChanged._();
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (effort != null) result.effort = effort;
    if (contextLength != null) result.contextLength = contextLength;
    return result;
  }

  ModelChanged._();

  factory ModelChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelChanged()..mergeFromBuffer(data, registry);
  factory ModelChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelChanged.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aOS(3, _omitFieldNames ? '' : 'effort')
    ..aInt64(4, _omitFieldNames ? '' : 'contextLength')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelChanged copyWith(void Function(ModelChanged) updates) =>
      super.copyWith((message) => updates(message as ModelChanged))
          as ModelChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelChanged() / ModelChanged.new instead')
  static ModelChanged create() => ModelChanged._();
  static $pb.GeneratedMessage $_createMessage() => ModelChanged._();
  @$core.override
  ModelChanged createEmptyInstance() => ModelChanged._();
  @$core.pragma('dart2js:noInline')
  static ModelChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelChanged>(
          ModelChanged.$_createMessage);
  static ModelChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get provider => $_getSZ(0);
  @$pb.TagNumber(1)
  set provider($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get model => $_getSZ(1);
  @$pb.TagNumber(2)
  set model($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasModel() => $_has(1);
  @$pb.TagNumber(2)
  void clearModel() => $_clearField(2);

  /// Reasoning effort; empty means the model's default.
  @$pb.TagNumber(3)
  $core.String get effort => $_getSZ(2);
  @$pb.TagNumber(3)
  set effort($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEffort() => $_has(2);
  @$pb.TagNumber(3)
  void clearEffort() => $_clearField(3);

  /// The model's context window, if known.
  @$pb.TagNumber(4)
  $fixnum.Int64 get contextLength => $_getI64(3);
  @$pb.TagNumber(4)
  set contextLength($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContextLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextLength() => $_clearField(4);
}

/// Usage is token usage and speed for one model call.
class Usage extends $pb.GeneratedMessage {
  factory Usage({
    $core.String? messageId,
    $fixnum.Int64? inputTokens,
    $fixnum.Int64? outputTokens,
    $fixnum.Int64? totalTokens,
    $fixnum.Int64? contextLength,
    $fixnum.Int64? timeToFirstTokenMs,
    $core.double? promptTokensPerSecond,
    $core.double? generationTokensPerSecond,
    $core.String? timingSource,
    $fixnum.Int64? cachedTokens,
  }) {
    final result = Usage._();
    if (messageId != null) result.messageId = messageId;
    if (inputTokens != null) result.inputTokens = inputTokens;
    if (outputTokens != null) result.outputTokens = outputTokens;
    if (totalTokens != null) result.totalTokens = totalTokens;
    if (contextLength != null) result.contextLength = contextLength;
    if (timeToFirstTokenMs != null)
      result.timeToFirstTokenMs = timeToFirstTokenMs;
    if (promptTokensPerSecond != null)
      result.promptTokensPerSecond = promptTokensPerSecond;
    if (generationTokensPerSecond != null)
      result.generationTokensPerSecond = generationTokensPerSecond;
    if (timingSource != null) result.timingSource = timingSource;
    if (cachedTokens != null) result.cachedTokens = cachedTokens;
    return result;
  }

  Usage._();

  factory Usage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Usage()..mergeFromBuffer(data, registry);
  factory Usage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Usage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Usage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Usage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aInt64(2, _omitFieldNames ? '' : 'inputTokens')
    ..aInt64(3, _omitFieldNames ? '' : 'outputTokens')
    ..aInt64(4, _omitFieldNames ? '' : 'totalTokens')
    ..aInt64(5, _omitFieldNames ? '' : 'contextLength')
    ..aInt64(6, _omitFieldNames ? '' : 'timeToFirstTokenMs')
    ..aD(7, _omitFieldNames ? '' : 'promptTokensPerSecond')
    ..aD(8, _omitFieldNames ? '' : 'generationTokensPerSecond')
    ..aOS(9, _omitFieldNames ? '' : 'timingSource')
    ..aInt64(10, _omitFieldNames ? '' : 'cachedTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Usage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Usage copyWith(void Function(Usage) updates) =>
      super.copyWith((message) => updates(message as Usage)) as Usage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Usage() / Usage.new instead')
  static Usage create() => Usage._();
  static $pb.GeneratedMessage $_createMessage() => Usage._();
  @$core.override
  Usage createEmptyInstance() => Usage._();
  @$core.pragma('dart2js:noInline')
  static Usage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Usage>(Usage.$_createMessage);
  static Usage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get inputTokens => $_getI64(1);
  @$pb.TagNumber(2)
  set inputTokens($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInputTokens() => $_has(1);
  @$pb.TagNumber(2)
  void clearInputTokens() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get outputTokens => $_getI64(2);
  @$pb.TagNumber(3)
  set outputTokens($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOutputTokens() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutputTokens() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get totalTokens => $_getI64(3);
  @$pb.TagNumber(4)
  set totalTokens($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalTokens() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalTokens() => $_clearField(4);

  /// Context window of the model, if known; input + output tokens is how
  /// much of it this call used.
  @$pb.TagNumber(5)
  $fixnum.Int64 get contextLength => $_getI64(4);
  @$pb.TagNumber(5)
  set contextLength($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContextLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearContextLength() => $_clearField(5);

  /// Time from sending the request to the first token, in milliseconds.
  @$pb.TagNumber(6)
  $fixnum.Int64 get timeToFirstTokenMs => $_getI64(5);
  @$pb.TagNumber(6)
  set timeToFirstTokenMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimeToFirstTokenMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimeToFirstTokenMs() => $_clearField(6);

  /// Prompt processing and generation speed in tokens per second; 0 if
  /// unknown.
  @$pb.TagNumber(7)
  $core.double get promptTokensPerSecond => $_getN(6);
  @$pb.TagNumber(7)
  set promptTokensPerSecond($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPromptTokensPerSecond() => $_has(6);
  @$pb.TagNumber(7)
  void clearPromptTokensPerSecond() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get generationTokensPerSecond => $_getN(7);
  @$pb.TagNumber(8)
  set generationTokensPerSecond($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGenerationTokensPerSecond() => $_has(7);
  @$pb.TagNumber(8)
  void clearGenerationTokensPerSecond() => $_clearField(8);

  /// Where the timings came from: "llama.cpp" when the server reported its
  /// own timings, "measured" when flit timed the stream itself.
  @$pb.TagNumber(9)
  $core.String get timingSource => $_getSZ(8);
  @$pb.TagNumber(9)
  set timingSource($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTimingSource() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimingSource() => $_clearField(9);

  /// Prompt tokens the server reused from its cache instead of reading
  /// again (llama.cpp); part of input_tokens.
  @$pb.TagNumber(10)
  $fixnum.Int64 get cachedTokens => $_getI64(9);
  @$pb.TagNumber(10)
  set cachedTokens($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCachedTokens() => $_has(9);
  @$pb.TagNumber(10)
  void clearCachedTokens() => $_clearField(10);
}

/// TodoUpdated is the agent's task list after it changed (the todo tool).
class TodoUpdated extends $pb.GeneratedMessage {
  factory TodoUpdated({
    $core.Iterable<TodoItem>? items,
  }) {
    final result = TodoUpdated._();
    if (items != null) result.items.addAll(items);
    return result;
  }

  TodoUpdated._();

  factory TodoUpdated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TodoUpdated()..mergeFromBuffer(data, registry);
  factory TodoUpdated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TodoUpdated()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TodoUpdated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: TodoUpdated.$_createMessage)
    ..pPM<TodoItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: TodoItem.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TodoUpdated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TodoUpdated copyWith(void Function(TodoUpdated) updates) =>
      super.copyWith((message) => updates(message as TodoUpdated))
          as TodoUpdated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TodoUpdated() / TodoUpdated.new instead')
  static TodoUpdated create() => TodoUpdated._();
  static $pb.GeneratedMessage $_createMessage() => TodoUpdated._();
  @$core.override
  TodoUpdated createEmptyInstance() => TodoUpdated._();
  @$core.pragma('dart2js:noInline')
  static TodoUpdated getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TodoUpdated>(
          TodoUpdated.$_createMessage);
  static TodoUpdated? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<TodoItem> get items => $_getList(0);
}

class TodoItem extends $pb.GeneratedMessage {
  factory TodoItem({
    $core.String? content,
    TodoStatus? status,
  }) {
    final result = TodoItem._();
    if (content != null) result.content = content;
    if (status != null) result.status = status;
    return result;
  }

  TodoItem._();

  factory TodoItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TodoItem()..mergeFromBuffer(data, registry);
  factory TodoItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TodoItem()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TodoItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: TodoItem.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'content')
    ..aE<TodoStatus>(2, _omitFieldNames ? '' : 'status',
        enumValues: TodoStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TodoItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TodoItem copyWith(void Function(TodoItem) updates) =>
      super.copyWith((message) => updates(message as TodoItem)) as TodoItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TodoItem() / TodoItem.new instead')
  static TodoItem create() => TodoItem._();
  static $pb.GeneratedMessage $_createMessage() => TodoItem._();
  @$core.override
  TodoItem createEmptyInstance() => TodoItem._();
  @$core.pragma('dart2js:noInline')
  static TodoItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TodoItem>(TodoItem.$_createMessage);
  static TodoItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get content => $_getSZ(0);
  @$pb.TagNumber(1)
  set content($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasContent() => $_has(0);
  @$pb.TagNumber(1)
  void clearContent() => $_clearField(1);

  @$pb.TagNumber(2)
  TodoStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(TodoStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class TurnError extends $pb.GeneratedMessage {
  factory TurnError({
    $core.String? message,
    $core.bool? turnCanContinue,
  }) {
    final result = TurnError._();
    if (message != null) result.message = message;
    if (turnCanContinue != null) result.turnCanContinue = turnCanContinue;
    return result;
  }

  TurnError._();

  factory TurnError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TurnError()..mergeFromBuffer(data, registry);
  factory TurnError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TurnError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TurnError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: TurnError.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..aOB(2, _omitFieldNames ? '' : 'turnCanContinue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TurnError copyWith(void Function(TurnError) updates) =>
      super.copyWith((message) => updates(message as TurnError)) as TurnError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TurnError() / TurnError.new instead')
  static TurnError create() => TurnError._();
  static $pb.GeneratedMessage $_createMessage() => TurnError._();
  @$core.override
  TurnError createEmptyInstance() => TurnError._();
  @$core.pragma('dart2js:noInline')
  static TurnError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TurnError>(TurnError.$_createMessage);
  static TurnError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  /// Whether the session can go on: true means a new Send may succeed (e.g. a
  /// network blip); false means something must change first (e.g. config).
  @$pb.TagNumber(2)
  $core.bool get turnCanContinue => $_getBF(1);
  @$pb.TagNumber(2)
  set turnCanContinue($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTurnCanContinue() => $_has(1);
  @$pb.TagNumber(2)
  void clearTurnCanContinue() => $_clearField(2);
}

/// Feedback is a rating someone gave a turn or a model.
class Feedback extends $pb.GeneratedMessage {
  factory Feedback({
    RatingTarget? target,
    Rating? rating,
    $core.String? messageId,
    $core.String? note,
    $core.String? provider,
    $core.String? model,
    $core.String? client,
    $core.String? turnId,
  }) {
    final result = Feedback._();
    if (target != null) result.target = target;
    if (rating != null) result.rating = rating;
    if (messageId != null) result.messageId = messageId;
    if (note != null) result.note = note;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (client != null) result.client = client;
    if (turnId != null) result.turnId = turnId;
    return result;
  }

  Feedback._();

  factory Feedback.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Feedback()..mergeFromBuffer(data, registry);
  factory Feedback.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Feedback()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Feedback',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Feedback.$_createMessage)
    ..aE<RatingTarget>(1, _omitFieldNames ? '' : 'target',
        enumValues: RatingTarget.values)
    ..aE<Rating>(2, _omitFieldNames ? '' : 'rating', enumValues: Rating.values)
    ..aOS(3, _omitFieldNames ? '' : 'messageId')
    ..aOS(4, _omitFieldNames ? '' : 'note')
    ..aOS(5, _omitFieldNames ? '' : 'provider')
    ..aOS(6, _omitFieldNames ? '' : 'model')
    ..aOS(7, _omitFieldNames ? '' : 'client')
    ..aOS(8, _omitFieldNames ? '' : 'turnId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Feedback clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Feedback copyWith(void Function(Feedback) updates) =>
      super.copyWith((message) => updates(message as Feedback)) as Feedback;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Feedback() / Feedback.new instead')
  static Feedback create() => Feedback._();
  static $pb.GeneratedMessage $_createMessage() => Feedback._();
  @$core.override
  Feedback createEmptyInstance() => Feedback._();
  @$core.pragma('dart2js:noInline')
  static Feedback getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Feedback>(Feedback.$_createMessage);
  static Feedback? _defaultInstance;

  @$pb.TagNumber(1)
  RatingTarget get target => $_getN(0);
  @$pb.TagNumber(1)
  set target(RatingTarget value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => $_clearField(1);

  @$pb.TagNumber(2)
  Rating get rating => $_getN(1);
  @$pb.TagNumber(2)
  set rating(Rating value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRating() => $_has(1);
  @$pb.TagNumber(2)
  void clearRating() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get messageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set messageId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(4)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(4)
  void clearNote() => $_clearField(4);

  /// The model in use for the rated message (or at the time, for a model
  /// rating without a message).
  @$pb.TagNumber(5)
  $core.String get provider => $_getSZ(4);
  @$pb.TagNumber(5)
  set provider($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProvider() => $_has(4);
  @$pb.TagNumber(5)
  void clearProvider() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => $_clearField(6);

  /// The client that rated.
  @$pb.TagNumber(7)
  $core.String get client => $_getSZ(6);
  @$pb.TagNumber(7)
  set client($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasClient() => $_has(6);
  @$pb.TagNumber(7)
  void clearClient() => $_clearField(7);

  /// The turn the rated message belongs to: the id of the user message
  /// that started it.
  @$pb.TagNumber(8)
  $core.String get turnId => $_getSZ(7);
  @$pb.TagNumber(8)
  set turnId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTurnId() => $_has(7);
  @$pb.TagNumber(8)
  void clearTurnId() => $_clearField(8);
}

/// McpServersChanged lists the MCP servers enabled for the session after a
/// change.
class McpServersChanged extends $pb.GeneratedMessage {
  factory McpServersChanged({
    $core.Iterable<$core.String>? enabled,
  }) {
    final result = McpServersChanged._();
    if (enabled != null) result.enabled.addAll(enabled);
    return result;
  }

  McpServersChanged._();

  factory McpServersChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      McpServersChanged()..mergeFromBuffer(data, registry);
  factory McpServersChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      McpServersChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'McpServersChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: McpServersChanged.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  McpServersChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  McpServersChanged copyWith(void Function(McpServersChanged) updates) =>
      super.copyWith((message) => updates(message as McpServersChanged))
          as McpServersChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use McpServersChanged() / McpServersChanged.new instead')
  static McpServersChanged create() => McpServersChanged._();
  static $pb.GeneratedMessage $_createMessage() => McpServersChanged._();
  @$core.override
  McpServersChanged createEmptyInstance() => McpServersChanged._();
  @$core.pragma('dart2js:noInline')
  static McpServersChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<McpServersChanged>(
          McpServersChanged.$_createMessage);
  static McpServersChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get enabled => $_getList(0);
}

/// SessionMoved says the session moved to another project.
class SessionMoved extends $pb.GeneratedMessage {
  factory SessionMoved({
    $core.String? projectId,
  }) {
    final result = SessionMoved._();
    if (projectId != null) result.projectId = projectId;
    return result;
  }

  SessionMoved._();

  factory SessionMoved.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionMoved()..mergeFromBuffer(data, registry);
  factory SessionMoved.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionMoved()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionMoved',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SessionMoved.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'projectId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionMoved clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionMoved copyWith(void Function(SessionMoved) updates) =>
      super.copyWith((message) => updates(message as SessionMoved))
          as SessionMoved;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionMoved() / SessionMoved.new instead')
  static SessionMoved create() => SessionMoved._();
  static $pb.GeneratedMessage $_createMessage() => SessionMoved._();
  @$core.override
  SessionMoved createEmptyInstance() => SessionMoved._();
  @$core.pragma('dart2js:noInline')
  static SessionMoved getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionMoved>(
          SessionMoved.$_createMessage);
  static SessionMoved? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get projectId => $_getSZ(0);
  @$pb.TagNumber(1)
  set projectId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProjectId() => $_has(0);
  @$pb.TagNumber(1)
  void clearProjectId() => $_clearField(1);
}

/// YoloChanged records yolo mode being turned on or off for the session.
class YoloChanged extends $pb.GeneratedMessage {
  factory YoloChanged({
    $core.bool? yolo,
    $core.String? client,
  }) {
    final result = YoloChanged._();
    if (yolo != null) result.yolo = yolo;
    if (client != null) result.client = client;
    return result;
  }

  YoloChanged._();

  factory YoloChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YoloChanged()..mergeFromBuffer(data, registry);
  factory YoloChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      YoloChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'YoloChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: YoloChanged.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'yolo')
    ..aOS(2, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YoloChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  YoloChanged copyWith(void Function(YoloChanged) updates) =>
      super.copyWith((message) => updates(message as YoloChanged))
          as YoloChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use YoloChanged() / YoloChanged.new instead')
  static YoloChanged create() => YoloChanged._();
  static $pb.GeneratedMessage $_createMessage() => YoloChanged._();
  @$core.override
  YoloChanged createEmptyInstance() => YoloChanged._();
  @$core.pragma('dart2js:noInline')
  static YoloChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<YoloChanged>(
          YoloChanged.$_createMessage);
  static YoloChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get yolo => $_getBF(0);
  @$pb.TagNumber(1)
  set yolo($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasYolo() => $_has(0);
  @$pb.TagNumber(1)
  void clearYolo() => $_clearField(1);

  /// Client that changed it (its device name), if known.
  @$pb.TagNumber(2)
  $core.String get client => $_getSZ(1);
  @$pb.TagNumber(2)
  set client($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClient() => $_has(1);
  @$pb.TagNumber(2)
  void clearClient() => $_clearField(2);
}

/// PermissionCheck is the safety check's rating of a shell command that the
/// shell rules would have asked about, recorded before it takes effect.
class PermissionCheck extends $pb.GeneratedMessage {
  factory PermissionCheck({
    $core.String? toolCallId,
    $core.String? command,
    PermissionVerdict? verdict,
    $core.String? reason,
    $core.String? provider,
    $core.String? model,
    $core.String? modelCallId,
    $core.String? turnId,
  }) {
    final result = PermissionCheck._();
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (command != null) result.command = command;
    if (verdict != null) result.verdict = verdict;
    if (reason != null) result.reason = reason;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (modelCallId != null) result.modelCallId = modelCallId;
    if (turnId != null) result.turnId = turnId;
    return result;
  }

  PermissionCheck._();

  factory PermissionCheck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionCheck()..mergeFromBuffer(data, registry);
  factory PermissionCheck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionCheck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionCheck',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PermissionCheck.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(2, _omitFieldNames ? '' : 'command')
    ..aE<PermissionVerdict>(3, _omitFieldNames ? '' : 'verdict',
        enumValues: PermissionVerdict.values)
    ..aOS(4, _omitFieldNames ? '' : 'reason')
    ..aOS(5, _omitFieldNames ? '' : 'provider')
    ..aOS(6, _omitFieldNames ? '' : 'model')
    ..aOS(7, _omitFieldNames ? '' : 'modelCallId')
    ..aOS(8, _omitFieldNames ? '' : 'turnId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionCheck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionCheck copyWith(void Function(PermissionCheck) updates) =>
      super.copyWith((message) => updates(message as PermissionCheck))
          as PermissionCheck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PermissionCheck() / PermissionCheck.new instead')
  static PermissionCheck create() => PermissionCheck._();
  static $pb.GeneratedMessage $_createMessage() => PermissionCheck._();
  @$core.override
  PermissionCheck createEmptyInstance() => PermissionCheck._();
  @$core.pragma('dart2js:noInline')
  static PermissionCheck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PermissionCheck>(
          PermissionCheck.$_createMessage);
  static PermissionCheck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toolCallId => $_getSZ(0);
  @$pb.TagNumber(1)
  set toolCallId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToolCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearToolCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get command => $_getSZ(1);
  @$pb.TagNumber(2)
  set command($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommand() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommand() => $_clearField(2);

  @$pb.TagNumber(3)
  PermissionVerdict get verdict => $_getN(2);
  @$pb.TagNumber(3)
  set verdict(PermissionVerdict value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVerdict() => $_has(2);
  @$pb.TagNumber(3)
  void clearVerdict() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get reason => $_getSZ(3);
  @$pb.TagNumber(4)
  set reason($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearReason() => $_clearField(4);

  /// The model that rated it (agent.tasks.permission).
  @$pb.TagNumber(5)
  $core.String get provider => $_getSZ(4);
  @$pb.TagNumber(5)
  set provider($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProvider() => $_has(4);
  @$pb.TagNumber(5)
  void clearProvider() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get model => $_getSZ(5);
  @$pb.TagNumber(6)
  set model($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasModel() => $_has(5);
  @$pb.TagNumber(6)
  void clearModel() => $_clearField(6);

  /// The recorded model call (see flit export) and the turn it ran in.
  @$pb.TagNumber(7)
  $core.String get modelCallId => $_getSZ(6);
  @$pb.TagNumber(7)
  set modelCallId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModelCallId() => $_has(6);
  @$pb.TagNumber(7)
  void clearModelCallId() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get turnId => $_getSZ(7);
  @$pb.TagNumber(8)
  set turnId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTurnId() => $_has(7);
  @$pb.TagNumber(8)
  void clearTurnId() => $_clearField(8);
}

/// ModelCallStarted is a request to the model for message message_id being
/// sent. With the ModelCallEnded that follows (and the PromptProgress
/// between) it shows where a slow or frozen call is: a call with no end is
/// still waiting.
class ModelCallStarted extends $pb.GeneratedMessage {
  factory ModelCallStarted({
    $core.String? messageId,
    $core.int? attempt,
    $fixnum.Int64? firstByteTimeoutMs,
    $fixnum.Int64? stallTimeoutMs,
  }) {
    final result = ModelCallStarted._();
    if (messageId != null) result.messageId = messageId;
    if (attempt != null) result.attempt = attempt;
    if (firstByteTimeoutMs != null)
      result.firstByteTimeoutMs = firstByteTimeoutMs;
    if (stallTimeoutMs != null) result.stallTimeoutMs = stallTimeoutMs;
    return result;
  }

  ModelCallStarted._();

  factory ModelCallStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallStarted()..mergeFromBuffer(data, registry);
  factory ModelCallStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelCallStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelCallStarted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aI(2, _omitFieldNames ? '' : 'attempt')
    ..aInt64(3, _omitFieldNames ? '' : 'firstByteTimeoutMs')
    ..aInt64(4, _omitFieldNames ? '' : 'stallTimeoutMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallStarted copyWith(void Function(ModelCallStarted) updates) =>
      super.copyWith((message) => updates(message as ModelCallStarted))
          as ModelCallStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelCallStarted() / ModelCallStarted.new instead')
  static ModelCallStarted create() => ModelCallStarted._();
  static $pb.GeneratedMessage $_createMessage() => ModelCallStarted._();
  @$core.override
  ModelCallStarted createEmptyInstance() => ModelCallStarted._();
  @$core.pragma('dart2js:noInline')
  static ModelCallStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelCallStarted>(
          ModelCallStarted.$_createMessage);
  static ModelCallStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  /// 1 for the first try, 2 for an automatic retry, ...
  @$pb.TagNumber(2)
  $core.int get attempt => $_getIZ(1);
  @$pb.TagNumber(2)
  set attempt($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAttempt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttempt() => $_clearField(2);

  /// The watchdog limits in effect (agent.model_first_byte_timeout and
  /// agent.model_stall_timeout); 0 means none.
  @$pb.TagNumber(3)
  $fixnum.Int64 get firstByteTimeoutMs => $_getI64(2);
  @$pb.TagNumber(3)
  set firstByteTimeoutMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFirstByteTimeoutMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearFirstByteTimeoutMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get stallTimeoutMs => $_getI64(3);
  @$pb.TagNumber(4)
  set stallTimeoutMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStallTimeoutMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStallTimeoutMs() => $_clearField(4);
}

/// PromptProgress is how far the model server has got reading the prompt,
/// for servers that report it (llama.cpp). Sent at most about once a second.
class PromptProgress extends $pb.GeneratedMessage {
  factory PromptProgress({
    $core.String? messageId,
    $core.int? attempt,
    $fixnum.Int64? processed,
    $fixnum.Int64? total,
    $fixnum.Int64? cached,
    $fixnum.Int64? elapsedMs,
  }) {
    final result = PromptProgress._();
    if (messageId != null) result.messageId = messageId;
    if (attempt != null) result.attempt = attempt;
    if (processed != null) result.processed = processed;
    if (total != null) result.total = total;
    if (cached != null) result.cached = cached;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    return result;
  }

  PromptProgress._();

  factory PromptProgress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptProgress()..mergeFromBuffer(data, registry);
  factory PromptProgress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptProgress()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptProgress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PromptProgress.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aI(2, _omitFieldNames ? '' : 'attempt')
    ..aInt64(3, _omitFieldNames ? '' : 'processed')
    ..aInt64(4, _omitFieldNames ? '' : 'total')
    ..aInt64(5, _omitFieldNames ? '' : 'cached')
    ..aInt64(6, _omitFieldNames ? '' : 'elapsedMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptProgress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptProgress copyWith(void Function(PromptProgress) updates) =>
      super.copyWith((message) => updates(message as PromptProgress))
          as PromptProgress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptProgress() / PromptProgress.new instead')
  static PromptProgress create() => PromptProgress._();
  static $pb.GeneratedMessage $_createMessage() => PromptProgress._();
  @$core.override
  PromptProgress createEmptyInstance() => PromptProgress._();
  @$core.pragma('dart2js:noInline')
  static PromptProgress getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptProgress>(
          PromptProgress.$_createMessage);
  static PromptProgress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get attempt => $_getIZ(1);
  @$pb.TagNumber(2)
  set attempt($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAttempt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttempt() => $_clearField(2);

  /// Prompt tokens processed so far, of total; cached tokens were reused
  /// from the server's cache and needed no processing.
  @$pb.TagNumber(3)
  $fixnum.Int64 get processed => $_getI64(2);
  @$pb.TagNumber(3)
  set processed($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProcessed() => $_has(2);
  @$pb.TagNumber(3)
  void clearProcessed() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get total => $_getI64(3);
  @$pb.TagNumber(4)
  set total($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotal() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotal() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get cached => $_getI64(4);
  @$pb.TagNumber(5)
  set cached($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCached() => $_has(4);
  @$pb.TagNumber(5)
  void clearCached() => $_clearField(5);

  /// Time the server has spent on the prompt so far.
  @$pb.TagNumber(6)
  $fixnum.Int64 get elapsedMs => $_getI64(5);
  @$pb.TagNumber(6)
  set elapsedMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasElapsedMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearElapsedMs() => $_clearField(6);
}

/// ModelCallEnded is how one model call (attempt) went, with its timeline.
/// Times are milliseconds from sending the request; 0 means it never got
/// that far.
class ModelCallEnded extends $pb.GeneratedMessage {
  factory ModelCallEnded({
    $core.String? messageId,
    $core.int? attempt,
    ModelCallOutcome? outcome,
    $core.String? phase,
    $core.String? error,
    $fixnum.Int64? responseHeadersMs,
    $fixnum.Int64? firstByteMs,
    $fixnum.Int64? firstTokenMs,
    $fixnum.Int64? lastByteMs,
    $fixnum.Int64? totalMs,
    $fixnum.Int64? bytes,
    $fixnum.Int64? inputTokens,
    $fixnum.Int64? outputTokens,
    $fixnum.Int64? promptTokens,
    $fixnum.Int64? promptMs,
    $fixnum.Int64? predictedTokens,
    $fixnum.Int64? predictedMs,
    $core.bool? willRetry,
    $fixnum.Int64? cachedTokens,
  }) {
    final result = ModelCallEnded._();
    if (messageId != null) result.messageId = messageId;
    if (attempt != null) result.attempt = attempt;
    if (outcome != null) result.outcome = outcome;
    if (phase != null) result.phase = phase;
    if (error != null) result.error = error;
    if (responseHeadersMs != null) result.responseHeadersMs = responseHeadersMs;
    if (firstByteMs != null) result.firstByteMs = firstByteMs;
    if (firstTokenMs != null) result.firstTokenMs = firstTokenMs;
    if (lastByteMs != null) result.lastByteMs = lastByteMs;
    if (totalMs != null) result.totalMs = totalMs;
    if (bytes != null) result.bytes = bytes;
    if (inputTokens != null) result.inputTokens = inputTokens;
    if (outputTokens != null) result.outputTokens = outputTokens;
    if (promptTokens != null) result.promptTokens = promptTokens;
    if (promptMs != null) result.promptMs = promptMs;
    if (predictedTokens != null) result.predictedTokens = predictedTokens;
    if (predictedMs != null) result.predictedMs = predictedMs;
    if (willRetry != null) result.willRetry = willRetry;
    if (cachedTokens != null) result.cachedTokens = cachedTokens;
    return result;
  }

  ModelCallEnded._();

  factory ModelCallEnded.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallEnded()..mergeFromBuffer(data, registry);
  factory ModelCallEnded.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallEnded()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelCallEnded',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelCallEnded.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aI(2, _omitFieldNames ? '' : 'attempt')
    ..aE<ModelCallOutcome>(3, _omitFieldNames ? '' : 'outcome',
        enumValues: ModelCallOutcome.values)
    ..aOS(4, _omitFieldNames ? '' : 'phase')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..aInt64(6, _omitFieldNames ? '' : 'responseHeadersMs')
    ..aInt64(7, _omitFieldNames ? '' : 'firstByteMs')
    ..aInt64(8, _omitFieldNames ? '' : 'firstTokenMs')
    ..aInt64(9, _omitFieldNames ? '' : 'lastByteMs')
    ..aInt64(10, _omitFieldNames ? '' : 'totalMs')
    ..aInt64(11, _omitFieldNames ? '' : 'bytes')
    ..aInt64(12, _omitFieldNames ? '' : 'inputTokens')
    ..aInt64(13, _omitFieldNames ? '' : 'outputTokens')
    ..aInt64(14, _omitFieldNames ? '' : 'promptTokens')
    ..aInt64(15, _omitFieldNames ? '' : 'promptMs')
    ..aInt64(16, _omitFieldNames ? '' : 'predictedTokens')
    ..aInt64(17, _omitFieldNames ? '' : 'predictedMs')
    ..aOB(18, _omitFieldNames ? '' : 'willRetry')
    ..aInt64(19, _omitFieldNames ? '' : 'cachedTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallEnded clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallEnded copyWith(void Function(ModelCallEnded) updates) =>
      super.copyWith((message) => updates(message as ModelCallEnded))
          as ModelCallEnded;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelCallEnded() / ModelCallEnded.new instead')
  static ModelCallEnded create() => ModelCallEnded._();
  static $pb.GeneratedMessage $_createMessage() => ModelCallEnded._();
  @$core.override
  ModelCallEnded createEmptyInstance() => ModelCallEnded._();
  @$core.pragma('dart2js:noInline')
  static ModelCallEnded getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelCallEnded>(
          ModelCallEnded.$_createMessage);
  static ModelCallEnded? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get attempt => $_getIZ(1);
  @$pb.TagNumber(2)
  set attempt($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAttempt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttempt() => $_clearField(2);

  @$pb.TagNumber(3)
  ModelCallOutcome get outcome => $_getN(2);
  @$pb.TagNumber(3)
  set outcome(ModelCallOutcome value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOutcome() => $_has(2);
  @$pb.TagNumber(3)
  void clearOutcome() => $_clearField(3);

  /// For anything but OK, where it stopped: "connecting",
  /// "waiting_for_first_byte", "processing_prompt",
  /// "waiting_for_first_token" or "streaming".
  @$pb.TagNumber(4)
  $core.String get phase => $_getSZ(3);
  @$pb.TagNumber(4)
  set phase($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPhase() => $_has(3);
  @$pb.TagNumber(4)
  void clearPhase() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get responseHeadersMs => $_getI64(5);
  @$pb.TagNumber(6)
  set responseHeadersMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasResponseHeadersMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearResponseHeadersMs() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get firstByteMs => $_getI64(6);
  @$pb.TagNumber(7)
  set firstByteMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFirstByteMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearFirstByteMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get firstTokenMs => $_getI64(7);
  @$pb.TagNumber(8)
  set firstTokenMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFirstTokenMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearFirstTokenMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lastByteMs => $_getI64(8);
  @$pb.TagNumber(9)
  set lastByteMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastByteMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastByteMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get totalMs => $_getI64(9);
  @$pb.TagNumber(10)
  set totalMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasTotalMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearTotalMs() => $_clearField(10);

  /// Response body bytes received.
  @$pb.TagNumber(11)
  $fixnum.Int64 get bytes => $_getI64(10);
  @$pb.TagNumber(11)
  set bytes($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearBytes() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get inputTokens => $_getI64(11);
  @$pb.TagNumber(12)
  set inputTokens($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasInputTokens() => $_has(11);
  @$pb.TagNumber(12)
  void clearInputTokens() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get outputTokens => $_getI64(12);
  @$pb.TagNumber(13)
  set outputTokens($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasOutputTokens() => $_has(12);
  @$pb.TagNumber(13)
  void clearOutputTokens() => $_clearField(13);

  /// llama.cpp's own timings, when it sent them.
  @$pb.TagNumber(14)
  $fixnum.Int64 get promptTokens => $_getI64(13);
  @$pb.TagNumber(14)
  set promptTokens($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasPromptTokens() => $_has(13);
  @$pb.TagNumber(14)
  void clearPromptTokens() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get promptMs => $_getI64(14);
  @$pb.TagNumber(15)
  set promptMs($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasPromptMs() => $_has(14);
  @$pb.TagNumber(15)
  void clearPromptMs() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get predictedTokens => $_getI64(15);
  @$pb.TagNumber(16)
  set predictedTokens($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasPredictedTokens() => $_has(15);
  @$pb.TagNumber(16)
  void clearPredictedTokens() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get predictedMs => $_getI64(16);
  @$pb.TagNumber(17)
  set predictedMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasPredictedMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearPredictedMs() => $_clearField(17);

  /// Whether flit tries the call again (agent.model_retries, or
  /// RetryModelCall).
  @$pb.TagNumber(18)
  $core.bool get willRetry => $_getBF(17);
  @$pb.TagNumber(18)
  set willRetry($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasWillRetry() => $_has(17);
  @$pb.TagNumber(18)
  void clearWillRetry() => $_clearField(18);

  /// Prompt tokens llama.cpp reused from its cache.
  @$pb.TagNumber(19)
  $fixnum.Int64 get cachedTokens => $_getI64(18);
  @$pb.TagNumber(19)
  set cachedTokens($fixnum.Int64 value) => $_setInt64(18, value);
  @$pb.TagNumber(19)
  $core.bool hasCachedTokens() => $_has(18);
  @$pb.TagNumber(19)
  void clearCachedTokens() => $_clearField(19);
}

/// MessageQueued is a user message sent while a turn was running. It waits
/// for the turn's next step (see Send); QueuedMessageUpdated edits or
/// cancels it and QueuedMessageDelivered turns it into a user message.
class MessageQueued extends $pb.GeneratedMessage {
  factory MessageQueued({
    $core.String? queueId,
    $core.String? text,
    $core.String? client,
  }) {
    final result = MessageQueued._();
    if (queueId != null) result.queueId = queueId;
    if (text != null) result.text = text;
    if (client != null) result.client = client;
    return result;
  }

  MessageQueued._();

  factory MessageQueued.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageQueued()..mergeFromBuffer(data, registry);
  factory MessageQueued.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageQueued()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageQueued',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: MessageQueued.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'queueId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageQueued clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageQueued copyWith(void Function(MessageQueued) updates) =>
      super.copyWith((message) => updates(message as MessageQueued))
          as MessageQueued;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageQueued() / MessageQueued.new instead')
  static MessageQueued create() => MessageQueued._();
  static $pb.GeneratedMessage $_createMessage() => MessageQueued._();
  @$core.override
  MessageQueued createEmptyInstance() => MessageQueued._();
  @$core.pragma('dart2js:noInline')
  static MessageQueued getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageQueued>(
          MessageQueued.$_createMessage);
  static MessageQueued? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get queueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set queueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  /// Who sent it (SendRequest.client).
  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);
}

/// QueuedMessageUpdated is a queued message edited (text) or withdrawn
/// (cancelled).
class QueuedMessageUpdated extends $pb.GeneratedMessage {
  factory QueuedMessageUpdated({
    $core.String? queueId,
    $core.String? text,
    $core.bool? cancelled,
  }) {
    final result = QueuedMessageUpdated._();
    if (queueId != null) result.queueId = queueId;
    if (text != null) result.text = text;
    if (cancelled != null) result.cancelled = cancelled;
    return result;
  }

  QueuedMessageUpdated._();

  factory QueuedMessageUpdated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueuedMessageUpdated()..mergeFromBuffer(data, registry);
  factory QueuedMessageUpdated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueuedMessageUpdated()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueuedMessageUpdated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: QueuedMessageUpdated.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'queueId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOB(3, _omitFieldNames ? '' : 'cancelled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueuedMessageUpdated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueuedMessageUpdated copyWith(void Function(QueuedMessageUpdated) updates) =>
      super.copyWith((message) => updates(message as QueuedMessageUpdated))
          as QueuedMessageUpdated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use QueuedMessageUpdated() / QueuedMessageUpdated.new instead')
  static QueuedMessageUpdated create() => QueuedMessageUpdated._();
  static $pb.GeneratedMessage $_createMessage() => QueuedMessageUpdated._();
  @$core.override
  QueuedMessageUpdated createEmptyInstance() => QueuedMessageUpdated._();
  @$core.pragma('dart2js:noInline')
  static QueuedMessageUpdated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueuedMessageUpdated>(
          QueuedMessageUpdated.$_createMessage);
  static QueuedMessageUpdated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get queueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set queueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get cancelled => $_getBF(2);
  @$pb.TagNumber(3)
  set cancelled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCancelled() => $_has(2);
  @$pb.TagNumber(3)
  void clearCancelled() => $_clearField(3);
}

/// QueuedMessageDelivered is a queued message delivered as user message
/// message_id, whose MessageStarted follows.
class QueuedMessageDelivered extends $pb.GeneratedMessage {
  factory QueuedMessageDelivered({
    $core.String? queueId,
    $core.String? messageId,
  }) {
    final result = QueuedMessageDelivered._();
    if (queueId != null) result.queueId = queueId;
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  QueuedMessageDelivered._();

  factory QueuedMessageDelivered.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueuedMessageDelivered()..mergeFromBuffer(data, registry);
  factory QueuedMessageDelivered.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueuedMessageDelivered()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueuedMessageDelivered',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: QueuedMessageDelivered.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'queueId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueuedMessageDelivered clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueuedMessageDelivered copyWith(
          void Function(QueuedMessageDelivered) updates) =>
      super.copyWith((message) => updates(message as QueuedMessageDelivered))
          as QueuedMessageDelivered;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use QueuedMessageDelivered() / QueuedMessageDelivered.new instead')
  static QueuedMessageDelivered create() => QueuedMessageDelivered._();
  static $pb.GeneratedMessage $_createMessage() => QueuedMessageDelivered._();
  @$core.override
  QueuedMessageDelivered createEmptyInstance() => QueuedMessageDelivered._();
  @$core.pragma('dart2js:noInline')
  static QueuedMessageDelivered getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueuedMessageDelivered>(
          QueuedMessageDelivered.$_createMessage);
  static QueuedMessageDelivered? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get queueId => $_getSZ(0);
  @$pb.TagNumber(1)
  set queueId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQueueId() => $_has(0);
  @$pb.TagNumber(1)
  void clearQueueId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);
}

/// ModelCallWaiting says why the model call for message_id hasn't started
/// yet (llama.cpp only). Sent when the reason changes, until the server
/// starts on the call (PromptProgress or reply text follow).
class ModelCallWaiting extends $pb.GeneratedMessage {
  factory ModelCallWaiting({
    $core.String? messageId,
    $core.int? attempt,
    ModelWaitReason? reason,
    $core.int? totalSlots,
  }) {
    final result = ModelCallWaiting._();
    if (messageId != null) result.messageId = messageId;
    if (attempt != null) result.attempt = attempt;
    if (reason != null) result.reason = reason;
    if (totalSlots != null) result.totalSlots = totalSlots;
    return result;
  }

  ModelCallWaiting._();

  factory ModelCallWaiting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallWaiting()..mergeFromBuffer(data, registry);
  factory ModelCallWaiting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallWaiting()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelCallWaiting',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelCallWaiting.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aI(2, _omitFieldNames ? '' : 'attempt')
    ..aE<ModelWaitReason>(3, _omitFieldNames ? '' : 'reason',
        enumValues: ModelWaitReason.values)
    ..aI(4, _omitFieldNames ? '' : 'totalSlots')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallWaiting clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallWaiting copyWith(void Function(ModelCallWaiting) updates) =>
      super.copyWith((message) => updates(message as ModelCallWaiting))
          as ModelCallWaiting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelCallWaiting() / ModelCallWaiting.new instead')
  static ModelCallWaiting create() => ModelCallWaiting._();
  static $pb.GeneratedMessage $_createMessage() => ModelCallWaiting._();
  @$core.override
  ModelCallWaiting createEmptyInstance() => ModelCallWaiting._();
  @$core.pragma('dart2js:noInline')
  static ModelCallWaiting getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelCallWaiting>(
          ModelCallWaiting.$_createMessage);
  static ModelCallWaiting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get attempt => $_getIZ(1);
  @$pb.TagNumber(2)
  set attempt($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAttempt() => $_has(1);
  @$pb.TagNumber(2)
  void clearAttempt() => $_clearField(2);

  @$pb.TagNumber(3)
  ModelWaitReason get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason(ModelWaitReason value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);

  /// For SLOTS_BUSY: how many slots there are (all busy).
  @$pb.TagNumber(4)
  $core.int get totalSlots => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalSlots($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalSlots() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalSlots() => $_clearField(4);
}

/// PromptCache is flit saving or restoring the session's llama.cpp prompt
/// cache (config llamacpp.kv_cache).
class PromptCache extends $pb.GeneratedMessage {
  factory PromptCache({
    PromptCacheAction? action,
    $core.String? messageId,
    $core.int? slot,
    $core.String? file,
    $fixnum.Int64? tokens,
    $fixnum.Int64? elapsedMs,
    $core.String? error,
  }) {
    final result = PromptCache._();
    if (action != null) result.action = action;
    if (messageId != null) result.messageId = messageId;
    if (slot != null) result.slot = slot;
    if (file != null) result.file = file;
    if (tokens != null) result.tokens = tokens;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    if (error != null) result.error = error;
    return result;
  }

  PromptCache._();

  factory PromptCache.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptCache()..mergeFromBuffer(data, registry);
  factory PromptCache.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PromptCache()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PromptCache',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PromptCache.$_createMessage)
    ..aE<PromptCacheAction>(1, _omitFieldNames ? '' : 'action',
        enumValues: PromptCacheAction.values)
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aI(3, _omitFieldNames ? '' : 'slot')
    ..aOS(4, _omitFieldNames ? '' : 'file')
    ..aInt64(5, _omitFieldNames ? '' : 'tokens')
    ..aInt64(6, _omitFieldNames ? '' : 'elapsedMs')
    ..aOS(7, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptCache clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PromptCache copyWith(void Function(PromptCache) updates) =>
      super.copyWith((message) => updates(message as PromptCache))
          as PromptCache;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PromptCache() / PromptCache.new instead')
  static PromptCache create() => PromptCache._();
  static $pb.GeneratedMessage $_createMessage() => PromptCache._();
  @$core.override
  PromptCache createEmptyInstance() => PromptCache._();
  @$core.pragma('dart2js:noInline')
  static PromptCache getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PromptCache>(
          PromptCache.$_createMessage);
  static PromptCache? _defaultInstance;

  @$pb.TagNumber(1)
  PromptCacheAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(PromptCacheAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  /// The call it was for, when restoring.
  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get slot => $_getIZ(2);
  @$pb.TagNumber(3)
  set slot($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSlot() => $_has(2);
  @$pb.TagNumber(3)
  void clearSlot() => $_clearField(3);

  /// Save file on the server, e.g. flit-kv-2.bin.
  @$pb.TagNumber(4)
  $core.String get file => $_getSZ(3);
  @$pb.TagNumber(4)
  set file($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFile() => $_has(3);
  @$pb.TagNumber(4)
  void clearFile() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get tokens => $_getI64(4);
  @$pb.TagNumber(5)
  set tokens($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTokens() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokens() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get elapsedMs => $_getI64(5);
  @$pb.TagNumber(6)
  set elapsedMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasElapsedMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearElapsedMs() => $_clearField(6);

  /// Set when it failed (the call goes ahead without it).
  @$pb.TagNumber(7)
  $core.String get error => $_getSZ(6);
  @$pb.TagNumber(7)
  set error($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
}

/// ReasoningEndRequested is someone asking the model to stop thinking and
/// answer now (EndReasoning).
class ReasoningEndRequested extends $pb.GeneratedMessage {
  factory ReasoningEndRequested({
    $core.String? messageId,
    $core.String? client,
  }) {
    final result = ReasoningEndRequested._();
    if (messageId != null) result.messageId = messageId;
    if (client != null) result.client = client;
    return result;
  }

  ReasoningEndRequested._();

  factory ReasoningEndRequested.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningEndRequested()..mergeFromBuffer(data, registry);
  factory ReasoningEndRequested.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningEndRequested()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReasoningEndRequested',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ReasoningEndRequested.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningEndRequested clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningEndRequested copyWith(
          void Function(ReasoningEndRequested) updates) =>
      super.copyWith((message) => updates(message as ReasoningEndRequested))
          as ReasoningEndRequested;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReasoningEndRequested() / ReasoningEndRequested.new instead')
  static ReasoningEndRequested create() => ReasoningEndRequested._();
  static $pb.GeneratedMessage $_createMessage() => ReasoningEndRequested._();
  @$core.override
  ReasoningEndRequested createEmptyInstance() => ReasoningEndRequested._();
  @$core.pragma('dart2js:noInline')
  static ReasoningEndRequested getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReasoningEndRequested>(
          ReasoningEndRequested.$_createMessage);
  static ReasoningEndRequested? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get client => $_getSZ(1);
  @$pb.TagNumber(2)
  set client($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClient() => $_has(1);
  @$pb.TagNumber(2)
  void clearClient() => $_clearField(2);
}

/// ReasoningEndIgnored is the model still thinking a while after
/// EndReasoning: its server can't cut it short. flit won't offer it for
/// that model again.
class ReasoningEndIgnored extends $pb.GeneratedMessage {
  factory ReasoningEndIgnored({
    $core.String? messageId,
  }) {
    final result = ReasoningEndIgnored._();
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  ReasoningEndIgnored._();

  factory ReasoningEndIgnored.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningEndIgnored()..mergeFromBuffer(data, registry);
  factory ReasoningEndIgnored.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReasoningEndIgnored()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReasoningEndIgnored',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ReasoningEndIgnored.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningEndIgnored clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReasoningEndIgnored copyWith(void Function(ReasoningEndIgnored) updates) =>
      super.copyWith((message) => updates(message as ReasoningEndIgnored))
          as ReasoningEndIgnored;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ReasoningEndIgnored() / ReasoningEndIgnored.new instead')
  static ReasoningEndIgnored create() => ReasoningEndIgnored._();
  static $pb.GeneratedMessage $_createMessage() => ReasoningEndIgnored._();
  @$core.override
  ReasoningEndIgnored createEmptyInstance() => ReasoningEndIgnored._();
  @$core.pragma('dart2js:noInline')
  static ReasoningEndIgnored getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReasoningEndIgnored>(
          ReasoningEndIgnored.$_createMessage);
  static ReasoningEndIgnored? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);
}

/// CompactionStarted: flit is summarizing the older part of the
/// conversation (automatically near the context limit, or because someone
/// asked). CompactionDone follows.
class CompactionStarted extends $pb.GeneratedMessage {
  factory CompactionStarted({
    $core.String? compactionId,
    $core.bool? auto,
    $core.String? client,
    $fixnum.Int64? tokens,
    $fixnum.Int64? contextLength,
    $core.String? provider,
    $core.String? model,
  }) {
    final result = CompactionStarted._();
    if (compactionId != null) result.compactionId = compactionId;
    if (auto != null) result.auto = auto;
    if (client != null) result.client = client;
    if (tokens != null) result.tokens = tokens;
    if (contextLength != null) result.contextLength = contextLength;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  CompactionStarted._();

  factory CompactionStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactionStarted()..mergeFromBuffer(data, registry);
  factory CompactionStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactionStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompactionStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CompactionStarted.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'compactionId')
    ..aOB(2, _omitFieldNames ? '' : 'auto')
    ..aOS(3, _omitFieldNames ? '' : 'client')
    ..aInt64(4, _omitFieldNames ? '' : 'tokens')
    ..aInt64(5, _omitFieldNames ? '' : 'contextLength')
    ..aOS(6, _omitFieldNames ? '' : 'provider')
    ..aOS(7, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactionStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactionStarted copyWith(void Function(CompactionStarted) updates) =>
      super.copyWith((message) => updates(message as CompactionStarted))
          as CompactionStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompactionStarted() / CompactionStarted.new instead')
  static CompactionStarted create() => CompactionStarted._();
  static $pb.GeneratedMessage $_createMessage() => CompactionStarted._();
  @$core.override
  CompactionStarted createEmptyInstance() => CompactionStarted._();
  @$core.pragma('dart2js:noInline')
  static CompactionStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompactionStarted>(
          CompactionStarted.$_createMessage);
  static CompactionStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get compactionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set compactionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCompactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompactionId() => $_clearField(1);

  /// True when flit started it near the context limit; false for Compact.
  @$pb.TagNumber(2)
  $core.bool get auto => $_getBF(1);
  @$pb.TagNumber(2)
  set auto($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuto() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuto() => $_clearField(2);

  /// Who asked (Compact), for the log.
  @$pb.TagNumber(3)
  $core.String get client => $_getSZ(2);
  @$pb.TagNumber(3)
  set client($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClient() => $_has(2);
  @$pb.TagNumber(3)
  void clearClient() => $_clearField(3);

  /// The model's context use now, and its window (0 if unknown).
  @$pb.TagNumber(4)
  $fixnum.Int64 get tokens => $_getI64(3);
  @$pb.TagNumber(4)
  set tokens($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTokens() => $_has(3);
  @$pb.TagNumber(4)
  void clearTokens() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get contextLength => $_getI64(4);
  @$pb.TagNumber(5)
  set contextLength($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContextLength() => $_has(4);
  @$pb.TagNumber(5)
  void clearContextLength() => $_clearField(5);

  /// The model writing the summary: the compaction task model, or the
  /// session's own.
  @$pb.TagNumber(6)
  $core.String get provider => $_getSZ(5);
  @$pb.TagNumber(6)
  set provider($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProvider() => $_has(5);
  @$pb.TagNumber(6)
  void clearProvider() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get model => $_getSZ(6);
  @$pb.TagNumber(7)
  set model($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasModel() => $_has(6);
  @$pb.TagNumber(7)
  void clearModel() => $_clearField(7);
}

/// CompactionDone ends a compaction. Unless error is set, the model's
/// context is rebuilt from here on as the summary (in the system prompt)
/// followed by the events after covered_seq, the turns kept verbatim. When
/// the cut falls inside a turn, the user message that started that turn is
/// kept too. Older events stay in the log. With error set nothing changed
/// and the session goes on with its full history.
class CompactionDone extends $pb.GeneratedMessage {
  factory CompactionDone({
    $core.String? compactionId,
    $core.bool? auto,
    $core.String? summary,
    $fixnum.Int64? coveredSeq,
    $fixnum.Int64? tokensBefore,
    $fixnum.Int64? tokensAfter,
    $core.bool? tokensExact,
    $fixnum.Int64? contextLength,
    $core.String? provider,
    $core.String? model,
    $core.String? modelCallId,
    $fixnum.Int64? elapsedMs,
    $core.int? keptTurns,
    $core.String? error,
  }) {
    final result = CompactionDone._();
    if (compactionId != null) result.compactionId = compactionId;
    if (auto != null) result.auto = auto;
    if (summary != null) result.summary = summary;
    if (coveredSeq != null) result.coveredSeq = coveredSeq;
    if (tokensBefore != null) result.tokensBefore = tokensBefore;
    if (tokensAfter != null) result.tokensAfter = tokensAfter;
    if (tokensExact != null) result.tokensExact = tokensExact;
    if (contextLength != null) result.contextLength = contextLength;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (modelCallId != null) result.modelCallId = modelCallId;
    if (elapsedMs != null) result.elapsedMs = elapsedMs;
    if (keptTurns != null) result.keptTurns = keptTurns;
    if (error != null) result.error = error;
    return result;
  }

  CompactionDone._();

  factory CompactionDone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactionDone()..mergeFromBuffer(data, registry);
  factory CompactionDone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompactionDone()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompactionDone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CompactionDone.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'compactionId')
    ..aOB(2, _omitFieldNames ? '' : 'auto')
    ..aOS(3, _omitFieldNames ? '' : 'summary')
    ..aInt64(4, _omitFieldNames ? '' : 'coveredSeq')
    ..aInt64(5, _omitFieldNames ? '' : 'tokensBefore')
    ..aInt64(6, _omitFieldNames ? '' : 'tokensAfter')
    ..aOB(7, _omitFieldNames ? '' : 'tokensExact')
    ..aInt64(8, _omitFieldNames ? '' : 'contextLength')
    ..aOS(9, _omitFieldNames ? '' : 'provider')
    ..aOS(10, _omitFieldNames ? '' : 'model')
    ..aOS(11, _omitFieldNames ? '' : 'modelCallId')
    ..aInt64(12, _omitFieldNames ? '' : 'elapsedMs')
    ..aI(13, _omitFieldNames ? '' : 'keptTurns')
    ..aOS(14, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactionDone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompactionDone copyWith(void Function(CompactionDone) updates) =>
      super.copyWith((message) => updates(message as CompactionDone))
          as CompactionDone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompactionDone() / CompactionDone.new instead')
  static CompactionDone create() => CompactionDone._();
  static $pb.GeneratedMessage $_createMessage() => CompactionDone._();
  @$core.override
  CompactionDone createEmptyInstance() => CompactionDone._();
  @$core.pragma('dart2js:noInline')
  static CompactionDone getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompactionDone>(
          CompactionDone.$_createMessage);
  static CompactionDone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get compactionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set compactionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCompactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompactionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get auto => $_getBF(1);
  @$pb.TagNumber(2)
  set auto($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuto() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuto() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get summary => $_getSZ(2);
  @$pb.TagNumber(3)
  set summary($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSummary() => $_has(2);
  @$pb.TagNumber(3)
  void clearSummary() => $_clearField(3);

  /// The last event the summary covers (with any earlier summary). Events
  /// after it reach the model verbatim.
  @$pb.TagNumber(4)
  $fixnum.Int64 get coveredSeq => $_getI64(3);
  @$pb.TagNumber(4)
  set coveredSeq($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCoveredSeq() => $_has(3);
  @$pb.TagNumber(4)
  void clearCoveredSeq() => $_clearField(4);

  /// Context use before and after (after: what the next call will send),
  /// and whether they are exact counts (llama.cpp) or estimates.
  @$pb.TagNumber(5)
  $fixnum.Int64 get tokensBefore => $_getI64(4);
  @$pb.TagNumber(5)
  set tokensBefore($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTokensBefore() => $_has(4);
  @$pb.TagNumber(5)
  void clearTokensBefore() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get tokensAfter => $_getI64(5);
  @$pb.TagNumber(6)
  set tokensAfter($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTokensAfter() => $_has(5);
  @$pb.TagNumber(6)
  void clearTokensAfter() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get tokensExact => $_getBF(6);
  @$pb.TagNumber(7)
  set tokensExact($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTokensExact() => $_has(6);
  @$pb.TagNumber(7)
  void clearTokensExact() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get contextLength => $_getI64(7);
  @$pb.TagNumber(8)
  set contextLength($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasContextLength() => $_has(7);
  @$pb.TagNumber(8)
  void clearContextLength() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get provider => $_getSZ(8);
  @$pb.TagNumber(9)
  set provider($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasProvider() => $_has(8);
  @$pb.TagNumber(9)
  void clearProvider() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get model => $_getSZ(9);
  @$pb.TagNumber(10)
  set model($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasModel() => $_has(9);
  @$pb.TagNumber(10)
  void clearModel() => $_clearField(10);

  /// The summarization call's record id (an export model_call with task
  /// "compaction").
  @$pb.TagNumber(11)
  $core.String get modelCallId => $_getSZ(10);
  @$pb.TagNumber(11)
  set modelCallId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasModelCallId() => $_has(10);
  @$pb.TagNumber(11)
  void clearModelCallId() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get elapsedMs => $_getI64(11);
  @$pb.TagNumber(12)
  set elapsedMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasElapsedMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearElapsedMs() => $_clearField(12);

  /// Turns kept verbatim after the summary.
  @$pb.TagNumber(13)
  $core.int get keptTurns => $_getIZ(12);
  @$pb.TagNumber(13)
  set keptTurns($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasKeptTurns() => $_has(12);
  @$pb.TagNumber(13)
  void clearKeptTurns() => $_clearField(13);

  /// Set when it failed (or was interrupted).
  @$pb.TagNumber(14)
  $core.String get error => $_getSZ(13);
  @$pb.TagNumber(14)
  set error($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasError() => $_has(13);
  @$pb.TagNumber(14)
  void clearError() => $_clearField(14);
}

/// BranchCreated is a new branch of the conversation. It holds its parent's
/// events with seq <= fork_seq (and, through the parent, the parent's
/// ancestors' up to their fork points), then its own. Branches that share a
/// parent and fork_seq are alternatives at the same point: clients show
/// them as "2 of 3" on the first message after the fork.
class BranchCreated extends $pb.GeneratedMessage {
  factory BranchCreated({
    $core.String? branchId,
    $core.String? parentBranchId,
    $fixnum.Int64? forkSeq,
    BranchKind? kind,
    $core.String? messageId,
    $core.String? client,
  }) {
    final result = BranchCreated._();
    if (branchId != null) result.branchId = branchId;
    if (parentBranchId != null) result.parentBranchId = parentBranchId;
    if (forkSeq != null) result.forkSeq = forkSeq;
    if (kind != null) result.kind = kind;
    if (messageId != null) result.messageId = messageId;
    if (client != null) result.client = client;
    return result;
  }

  BranchCreated._();

  factory BranchCreated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BranchCreated()..mergeFromBuffer(data, registry);
  factory BranchCreated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BranchCreated()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BranchCreated',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: BranchCreated.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'branchId')
    ..aOS(2, _omitFieldNames ? '' : 'parentBranchId')
    ..aInt64(3, _omitFieldNames ? '' : 'forkSeq')
    ..aE<BranchKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: BranchKind.values)
    ..aOS(5, _omitFieldNames ? '' : 'messageId')
    ..aOS(6, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BranchCreated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BranchCreated copyWith(void Function(BranchCreated) updates) =>
      super.copyWith((message) => updates(message as BranchCreated))
          as BranchCreated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BranchCreated() / BranchCreated.new instead')
  static BranchCreated create() => BranchCreated._();
  static $pb.GeneratedMessage $_createMessage() => BranchCreated._();
  @$core.override
  BranchCreated createEmptyInstance() => BranchCreated._();
  @$core.pragma('dart2js:noInline')
  static BranchCreated getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BranchCreated>(
          BranchCreated.$_createMessage);
  static BranchCreated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get branchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set branchId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBranchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBranchId() => $_clearField(1);

  /// Empty is the root branch.
  @$pb.TagNumber(2)
  $core.String get parentBranchId => $_getSZ(1);
  @$pb.TagNumber(2)
  set parentBranchId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParentBranchId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentBranchId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get forkSeq => $_getI64(2);
  @$pb.TagNumber(3)
  set forkSeq($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasForkSeq() => $_has(2);
  @$pb.TagNumber(3)
  void clearForkSeq() => $_clearField(3);

  @$pb.TagNumber(4)
  BranchKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(BranchKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);

  /// The user message it was made from: kept by a retry, replaced by an
  /// edit.
  @$pb.TagNumber(5)
  $core.String get messageId => $_getSZ(4);
  @$pb.TagNumber(5)
  set messageId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessageId() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessageId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get client => $_getSZ(5);
  @$pb.TagNumber(6)
  set client($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClient() => $_has(5);
  @$pb.TagNumber(6)
  void clearClient() => $_clearField(6);
}

/// BranchSwitched makes branch_id the active branch. It is recorded on
/// that branch.
class BranchSwitched extends $pb.GeneratedMessage {
  factory BranchSwitched({
    $core.String? branchId,
    $core.String? client,
  }) {
    final result = BranchSwitched._();
    if (branchId != null) result.branchId = branchId;
    if (client != null) result.client = client;
    return result;
  }

  BranchSwitched._();

  factory BranchSwitched.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BranchSwitched()..mergeFromBuffer(data, registry);
  factory BranchSwitched.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BranchSwitched()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BranchSwitched',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: BranchSwitched.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'branchId')
    ..aOS(2, _omitFieldNames ? '' : 'client')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BranchSwitched clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BranchSwitched copyWith(void Function(BranchSwitched) updates) =>
      super.copyWith((message) => updates(message as BranchSwitched))
          as BranchSwitched;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BranchSwitched() / BranchSwitched.new instead')
  static BranchSwitched create() => BranchSwitched._();
  static $pb.GeneratedMessage $_createMessage() => BranchSwitched._();
  @$core.override
  BranchSwitched createEmptyInstance() => BranchSwitched._();
  @$core.pragma('dart2js:noInline')
  static BranchSwitched getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BranchSwitched>(
          BranchSwitched.$_createMessage);
  static BranchSwitched? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get branchId => $_getSZ(0);
  @$pb.TagNumber(1)
  set branchId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBranchId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBranchId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get client => $_getSZ(1);
  @$pb.TagNumber(2)
  set client($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClient() => $_has(1);
  @$pb.TagNumber(2)
  void clearClient() => $_clearField(2);
}

class GitStatusRequest extends $pb.GeneratedMessage {
  factory GitStatusRequest({
    $core.String? sessionId,
  }) {
    final result = GitStatusRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GitStatusRequest._();

  factory GitStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitStatusRequest()..mergeFromBuffer(data, registry);
  factory GitStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GitStatusRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitStatusRequest copyWith(void Function(GitStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GitStatusRequest))
          as GitStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GitStatusRequest() / GitStatusRequest.new instead')
  static GitStatusRequest create() => GitStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GitStatusRequest._();
  @$core.override
  GitStatusRequest createEmptyInstance() => GitStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GitStatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitStatusRequest>(
          GitStatusRequest.$_createMessage);
  static GitStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

/// GitFileChange is a file changed since the diff base.
class GitFileChange extends $pb.GeneratedMessage {
  factory GitFileChange({
    $core.String? path,
    $core.String? oldPath,
    GitFileStatus? status,
    $core.int? additions,
    $core.int? deletions,
    $core.bool? binary,
    $core.bool? staged,
    $core.bool? unstaged,
    $core.bool? untracked,
  }) {
    final result = GitFileChange._();
    if (path != null) result.path = path;
    if (oldPath != null) result.oldPath = oldPath;
    if (status != null) result.status = status;
    if (additions != null) result.additions = additions;
    if (deletions != null) result.deletions = deletions;
    if (binary != null) result.binary = binary;
    if (staged != null) result.staged = staged;
    if (unstaged != null) result.unstaged = unstaged;
    if (untracked != null) result.untracked = untracked;
    return result;
  }

  GitFileChange._();

  factory GitFileChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitFileChange()..mergeFromBuffer(data, registry);
  factory GitFileChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitFileChange()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitFileChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GitFileChange.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aOS(2, _omitFieldNames ? '' : 'oldPath')
    ..aE<GitFileStatus>(3, _omitFieldNames ? '' : 'status',
        enumValues: GitFileStatus.values)
    ..aI(4, _omitFieldNames ? '' : 'additions')
    ..aI(5, _omitFieldNames ? '' : 'deletions')
    ..aOB(6, _omitFieldNames ? '' : 'binary')
    ..aOB(7, _omitFieldNames ? '' : 'staged')
    ..aOB(8, _omitFieldNames ? '' : 'unstaged')
    ..aOB(9, _omitFieldNames ? '' : 'untracked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitFileChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitFileChange copyWith(void Function(GitFileChange) updates) =>
      super.copyWith((message) => updates(message as GitFileChange))
          as GitFileChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GitFileChange() / GitFileChange.new instead')
  static GitFileChange create() => GitFileChange._();
  static $pb.GeneratedMessage $_createMessage() => GitFileChange._();
  @$core.override
  GitFileChange createEmptyInstance() => GitFileChange._();
  @$core.pragma('dart2js:noInline')
  static GitFileChange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitFileChange>(
          GitFileChange.$_createMessage);
  static GitFileChange? _defaultInstance;

  /// Relative to the repository root, slash-separated.
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  /// The path before a rename or copy.
  @$pb.TagNumber(2)
  $core.String get oldPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set oldPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOldPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearOldPath() => $_clearField(2);

  @$pb.TagNumber(3)
  GitFileStatus get status => $_getN(2);
  @$pb.TagNumber(3)
  set status(GitFileStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => $_clearField(3);

  /// Changed lines; both 0 for a binary file.
  @$pb.TagNumber(4)
  $core.int get additions => $_getIZ(3);
  @$pb.TagNumber(4)
  set additions($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAdditions() => $_has(3);
  @$pb.TagNumber(4)
  void clearAdditions() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get deletions => $_getIZ(4);
  @$pb.TagNumber(5)
  set deletions($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeletions() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeletions() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get binary => $_getBF(5);
  @$pb.TagNumber(6)
  set binary($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBinary() => $_has(5);
  @$pb.TagNumber(6)
  void clearBinary() => $_clearField(6);

  /// Where the change is relative to HEAD. A file committed since the base
  /// and not touched since has none of these set.
  @$pb.TagNumber(7)
  $core.bool get staged => $_getBF(6);
  @$pb.TagNumber(7)
  set staged($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStaged() => $_has(6);
  @$pb.TagNumber(7)
  void clearStaged() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get unstaged => $_getBF(7);
  @$pb.TagNumber(8)
  set unstaged($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUnstaged() => $_has(7);
  @$pb.TagNumber(8)
  void clearUnstaged() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get untracked => $_getBF(8);
  @$pb.TagNumber(9)
  set untracked($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUntracked() => $_has(8);
  @$pb.TagNumber(9)
  void clearUntracked() => $_clearField(9);
}

class GitStatusResponse extends $pb.GeneratedMessage {
  factory GitStatusResponse({
    $core.bool? isRepo,
    $core.String? root,
    $core.String? branch,
    $core.String? head,
    $core.bool? detached,
    $core.String? upstream,
    $core.int? ahead,
    $core.int? behind,
    $core.int? stagedCount,
    $core.int? unstagedCount,
    $core.int? untrackedCount,
    $core.int? conflictedCount,
    $core.String? baseCommit,
    $core.String? diffBase,
    GitDiffBase? diffBaseKind,
    $core.Iterable<GitFileChange>? files,
    $core.bool? filesTruncated,
  }) {
    final result = GitStatusResponse._();
    if (isRepo != null) result.isRepo = isRepo;
    if (root != null) result.root = root;
    if (branch != null) result.branch = branch;
    if (head != null) result.head = head;
    if (detached != null) result.detached = detached;
    if (upstream != null) result.upstream = upstream;
    if (ahead != null) result.ahead = ahead;
    if (behind != null) result.behind = behind;
    if (stagedCount != null) result.stagedCount = stagedCount;
    if (unstagedCount != null) result.unstagedCount = unstagedCount;
    if (untrackedCount != null) result.untrackedCount = untrackedCount;
    if (conflictedCount != null) result.conflictedCount = conflictedCount;
    if (baseCommit != null) result.baseCommit = baseCommit;
    if (diffBase != null) result.diffBase = diffBase;
    if (diffBaseKind != null) result.diffBaseKind = diffBaseKind;
    if (files != null) result.files.addAll(files);
    if (filesTruncated != null) result.filesTruncated = filesTruncated;
    return result;
  }

  GitStatusResponse._();

  factory GitStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitStatusResponse()..mergeFromBuffer(data, registry);
  factory GitStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GitStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isRepo')
    ..aOS(2, _omitFieldNames ? '' : 'root')
    ..aOS(3, _omitFieldNames ? '' : 'branch')
    ..aOS(4, _omitFieldNames ? '' : 'head')
    ..aOB(5, _omitFieldNames ? '' : 'detached')
    ..aOS(6, _omitFieldNames ? '' : 'upstream')
    ..aI(7, _omitFieldNames ? '' : 'ahead')
    ..aI(8, _omitFieldNames ? '' : 'behind')
    ..aI(9, _omitFieldNames ? '' : 'stagedCount')
    ..aI(10, _omitFieldNames ? '' : 'unstagedCount')
    ..aI(11, _omitFieldNames ? '' : 'untrackedCount')
    ..aI(12, _omitFieldNames ? '' : 'conflictedCount')
    ..aOS(13, _omitFieldNames ? '' : 'baseCommit')
    ..aOS(14, _omitFieldNames ? '' : 'diffBase')
    ..aE<GitDiffBase>(15, _omitFieldNames ? '' : 'diffBaseKind',
        enumValues: GitDiffBase.values)
    ..pPM<GitFileChange>(16, _omitFieldNames ? '' : 'files',
        subBuilder: GitFileChange.$_createMessage)
    ..aOB(17, _omitFieldNames ? '' : 'filesTruncated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitStatusResponse copyWith(void Function(GitStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GitStatusResponse))
          as GitStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GitStatusResponse() / GitStatusResponse.new instead')
  static GitStatusResponse create() => GitStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GitStatusResponse._();
  @$core.override
  GitStatusResponse createEmptyInstance() => GitStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GitStatusResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitStatusResponse>(
          GitStatusResponse.$_createMessage);
  static GitStatusResponse? _defaultInstance;

  /// False when the working directory isn't in a git work tree; nothing
  /// else is set then.
  @$pb.TagNumber(1)
  $core.bool get isRepo => $_getBF(0);
  @$pb.TagNumber(1)
  set isRepo($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsRepo() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsRepo() => $_clearField(1);

  /// The work tree's top directory.
  @$pb.TagNumber(2)
  $core.String get root => $_getSZ(1);
  @$pb.TagNumber(2)
  set root($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoot() => $_clearField(2);

  /// The checked-out branch; empty when HEAD is detached.
  @$pb.TagNumber(3)
  $core.String get branch => $_getSZ(2);
  @$pb.TagNumber(3)
  set branch($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearBranch() => $_clearField(3);

  /// HEAD's commit; empty on a branch with no commits yet.
  @$pb.TagNumber(4)
  $core.String get head => $_getSZ(3);
  @$pb.TagNumber(4)
  set head($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHead() => $_has(3);
  @$pb.TagNumber(4)
  void clearHead() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get detached => $_getBF(4);
  @$pb.TagNumber(5)
  set detached($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDetached() => $_has(4);
  @$pb.TagNumber(5)
  void clearDetached() => $_clearField(5);

  /// The branch's upstream (e.g. origin/main); empty if none. ahead and
  /// behind count commits relative to it.
  @$pb.TagNumber(6)
  $core.String get upstream => $_getSZ(5);
  @$pb.TagNumber(6)
  set upstream($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUpstream() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpstream() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get ahead => $_getIZ(6);
  @$pb.TagNumber(7)
  set ahead($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAhead() => $_has(6);
  @$pb.TagNumber(7)
  void clearAhead() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get behind => $_getIZ(7);
  @$pb.TagNumber(8)
  set behind($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasBehind() => $_has(7);
  @$pb.TagNumber(8)
  void clearBehind() => $_clearField(8);

  /// Files with staged, unstaged, untracked and conflicted changes relative
  /// to HEAD, as git status counts them.
  @$pb.TagNumber(9)
  $core.int get stagedCount => $_getIZ(8);
  @$pb.TagNumber(9)
  set stagedCount($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStagedCount() => $_has(8);
  @$pb.TagNumber(9)
  void clearStagedCount() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get unstagedCount => $_getIZ(9);
  @$pb.TagNumber(10)
  set unstagedCount($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUnstagedCount() => $_has(9);
  @$pb.TagNumber(10)
  void clearUnstagedCount() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get untrackedCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set untrackedCount($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUntrackedCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearUntrackedCount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get conflictedCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set conflictedCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasConflictedCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearConflictedCount() => $_clearField(12);

  /// The session's base commit (Session.base_commit), and the commit (or
  /// tree) actually diffed against, which differs when there is no usable
  /// base.
  @$pb.TagNumber(13)
  $core.String get baseCommit => $_getSZ(12);
  @$pb.TagNumber(13)
  set baseCommit($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBaseCommit() => $_has(12);
  @$pb.TagNumber(13)
  void clearBaseCommit() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get diffBase => $_getSZ(13);
  @$pb.TagNumber(14)
  set diffBase($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDiffBase() => $_has(13);
  @$pb.TagNumber(14)
  void clearDiffBase() => $_clearField(14);

  @$pb.TagNumber(15)
  GitDiffBase get diffBaseKind => $_getN(14);
  @$pb.TagNumber(15)
  set diffBaseKind(GitDiffBase value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasDiffBaseKind() => $_has(14);
  @$pb.TagNumber(15)
  void clearDiffBaseKind() => $_clearField(15);

  /// Files changed since diff_base. At most a server limit are listed;
  /// files_truncated says some were left out.
  @$pb.TagNumber(16)
  $pb.PbList<GitFileChange> get files => $_getList(15);

  @$pb.TagNumber(17)
  $core.bool get filesTruncated => $_getBF(16);
  @$pb.TagNumber(17)
  set filesTruncated($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasFilesTruncated() => $_has(16);
  @$pb.TagNumber(17)
  void clearFilesTruncated() => $_clearField(17);
}

class GitDiffRequest extends $pb.GeneratedMessage {
  factory GitDiffRequest({
    $core.String? sessionId,
    $core.String? path,
    $core.int? maxBytes,
  }) {
    final result = GitDiffRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (path != null) result.path = path;
    if (maxBytes != null) result.maxBytes = maxBytes;
    return result;
  }

  GitDiffRequest._();

  factory GitDiffRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitDiffRequest()..mergeFromBuffer(data, registry);
  factory GitDiffRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitDiffRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitDiffRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GitDiffRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aI(3, _omitFieldNames ? '' : 'maxBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitDiffRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitDiffRequest copyWith(void Function(GitDiffRequest) updates) =>
      super.copyWith((message) => updates(message as GitDiffRequest))
          as GitDiffRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GitDiffRequest() / GitDiffRequest.new instead')
  static GitDiffRequest create() => GitDiffRequest._();
  static $pb.GeneratedMessage $_createMessage() => GitDiffRequest._();
  @$core.override
  GitDiffRequest createEmptyInstance() => GitDiffRequest._();
  @$core.pragma('dart2js:noInline')
  static GitDiffRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitDiffRequest>(
          GitDiffRequest.$_createMessage);
  static GitDiffRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Only this file or directory, relative to the repository root; empty
  /// means every change.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  /// Size limit in bytes; 0 means 1 MiB. The server caps it at 8 MiB.
  @$pb.TagNumber(3)
  $core.int get maxBytes => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxBytes($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxBytes() => $_clearField(3);
}

class GitDiffResponse extends $pb.GeneratedMessage {
  factory GitDiffResponse({
    $core.bool? isRepo,
    $core.String? diffBase,
    GitDiffBase? diffBaseKind,
    $core.String? diff,
    $core.bool? truncated,
  }) {
    final result = GitDiffResponse._();
    if (isRepo != null) result.isRepo = isRepo;
    if (diffBase != null) result.diffBase = diffBase;
    if (diffBaseKind != null) result.diffBaseKind = diffBaseKind;
    if (diff != null) result.diff = diff;
    if (truncated != null) result.truncated = truncated;
    return result;
  }

  GitDiffResponse._();

  factory GitDiffResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitDiffResponse()..mergeFromBuffer(data, registry);
  factory GitDiffResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GitDiffResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GitDiffResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: GitDiffResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isRepo')
    ..aOS(2, _omitFieldNames ? '' : 'diffBase')
    ..aE<GitDiffBase>(3, _omitFieldNames ? '' : 'diffBaseKind',
        enumValues: GitDiffBase.values)
    ..aOS(4, _omitFieldNames ? '' : 'diff')
    ..aOB(5, _omitFieldNames ? '' : 'truncated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitDiffResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GitDiffResponse copyWith(void Function(GitDiffResponse) updates) =>
      super.copyWith((message) => updates(message as GitDiffResponse))
          as GitDiffResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GitDiffResponse() / GitDiffResponse.new instead')
  static GitDiffResponse create() => GitDiffResponse._();
  static $pb.GeneratedMessage $_createMessage() => GitDiffResponse._();
  @$core.override
  GitDiffResponse createEmptyInstance() => GitDiffResponse._();
  @$core.pragma('dart2js:noInline')
  static GitDiffResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitDiffResponse>(
          GitDiffResponse.$_createMessage);
  static GitDiffResponse? _defaultInstance;

  /// False when the working directory isn't in a git work tree.
  @$pb.TagNumber(1)
  $core.bool get isRepo => $_getBF(0);
  @$pb.TagNumber(1)
  set isRepo($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsRepo() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsRepo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get diffBase => $_getSZ(1);
  @$pb.TagNumber(2)
  set diffBase($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDiffBase() => $_has(1);
  @$pb.TagNumber(2)
  void clearDiffBase() => $_clearField(2);

  @$pb.TagNumber(3)
  GitDiffBase get diffBaseKind => $_getN(2);
  @$pb.TagNumber(3)
  set diffBaseKind(GitDiffBase value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasDiffBaseKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearDiffBaseKind() => $_clearField(3);

  /// The unified diff (git diff format).
  @$pb.TagNumber(4)
  $core.String get diff => $_getSZ(3);
  @$pb.TagNumber(4)
  set diff($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDiff() => $_has(3);
  @$pb.TagNumber(4)
  void clearDiff() => $_clearField(4);

  /// The diff was cut at the size limit, at the end of a line.
  @$pb.TagNumber(5)
  $core.bool get truncated => $_getBF(4);
  @$pb.TagNumber(5)
  set truncated($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTruncated() => $_has(4);
  @$pb.TagNumber(5)
  void clearTruncated() => $_clearField(5);
}

/// SessionService runs agent sessions. A session is a conversation with the
/// agent in a working directory. Everything that happens in it is recorded as
/// an append-only, numbered event log, so a client can attach at any point,
/// replay from any sequence number and then follow live.
class SessionServiceApi {
  final $pb.RpcClient _client;

  SessionServiceApi(this._client);

  /// CreateSession starts a new, idle session. Give working_dir, or a
  /// project_id whose project has a directory.
  $async.Future<CreateSessionResponse> createSession(
          $pb.ClientContext? ctx, CreateSessionRequest request) =>
      _client.invoke<CreateSessionResponse>(ctx, 'SessionService',
          'CreateSession', request, CreateSessionResponse());

  /// ListSessions lists sessions, most recently updated first.
  $async.Future<ListSessionsResponse> listSessions(
          $pb.ClientContext? ctx, ListSessionsRequest request) =>
      _client.invoke<ListSessionsResponse>(ctx, 'SessionService',
          'ListSessions', request, ListSessionsResponse());

  /// GetSession returns one session.
  $async.Future<GetSessionResponse> getSession(
          $pb.ClientContext? ctx, GetSessionRequest request) =>
      _client.invoke<GetSessionResponse>(
          ctx, 'SessionService', 'GetSession', request, GetSessionResponse());

  /// Attach streams a session's events with seq >= from_seq, then follows new
  /// events live until the client disconnects. Replayed events are identical
  /// to what a live client saw, deltas included.
  $async.Future<AttachResponse> attach(
          $pb.ClientContext? ctx, AttachRequest request) =>
      _client.invoke<AttachResponse>(
          ctx, 'SessionService', 'Attach', request, AttachResponse());

  /// Send adds a user message and starts a turn. While a turn is running
  /// the message is queued instead (MessageQueued) and delivered at the
  /// turn's next step: after the current model call or tool, before the
  /// next model call; if the turn ends without another call, it starts the
  /// next turn. Messages still queued when a turn is interrupted wait for
  /// the next Send, which delivers them first; with an empty text, Send
  /// just delivers the queue.
  $async.Future<SendResponse> send(
          $pb.ClientContext? ctx, SendRequest request) =>
      _client.invoke<SendResponse>(
          ctx, 'SessionService', 'Send', request, SendResponse());

  /// EditQueuedMessage changes, and CancelQueuedMessage withdraws, a queued
  /// message that hasn't been delivered yet. Once it has, they fail with
  /// FAILED_PRECONDITION.
  $async.Future<EditQueuedMessageResponse> editQueuedMessage(
          $pb.ClientContext? ctx, EditQueuedMessageRequest request) =>
      _client.invoke<EditQueuedMessageResponse>(ctx, 'SessionService',
          'EditQueuedMessage', request, EditQueuedMessageResponse());
  $async.Future<CancelQueuedMessageResponse> cancelQueuedMessage(
          $pb.ClientContext? ctx, CancelQueuedMessageRequest request) =>
      _client.invoke<CancelQueuedMessageResponse>(ctx, 'SessionService',
          'CancelQueuedMessage', request, CancelQueuedMessageResponse());

  /// Interrupt stops the running turn, if any. Pending prompts are resolved
  /// as denied.
  $async.Future<InterruptResponse> interrupt(
          $pb.ClientContext? ctx, InterruptRequest request) =>
      _client.invoke<InterruptResponse>(
          ctx, 'SessionService', 'Interrupt', request, InterruptResponse());

  /// RetryModelCall gives up on the model call in progress and sends it
  /// again, for when the model hasn't answered. Only while none of the reply
  /// has arrived: once it is streaming, the call fails with
  /// FAILED_PRECONDITION (interrupt instead).
  $async.Future<RetryModelCallResponse> retryModelCall(
          $pb.ClientContext? ctx, RetryModelCallRequest request) =>
      _client.invoke<RetryModelCallResponse>(ctx, 'SessionService',
          'RetryModelCall', request, RetryModelCallResponse());

  /// EndReasoning asks the model to stop thinking and answer now (llama.cpp
  /// only, for models where it can: ListModels' can_end_reasoning). Only
  /// while the model is thinking and hasn't started its answer; otherwise
  /// FAILED_PRECONDITION. If the model keeps thinking anyway, the log gets
  /// ReasoningEndIgnored and the model is marked as not supporting it.
  $async.Future<EndReasoningResponse> endReasoning(
          $pb.ClientContext? ctx, EndReasoningRequest request) =>
      _client.invoke<EndReasoningResponse>(ctx, 'SessionService',
          'EndReasoning', request, EndReasoningResponse());

  /// Compact summarizes the older part of the conversation so it takes less
  /// of the model's context: from then on the model sees the summary plus
  /// the most recent turns instead of the whole log (nothing is deleted).
  /// The log gets CompactionStarted and then CompactionDone. While the
  /// session is idle it runs right away, as a turn of its own (messages
  /// sent meanwhile are queued); while a turn runs, it happens at the
  /// turn's next step (queued = true). flit also compacts on its own near
  /// the context limit (agent.compaction in the config).
  $async.Future<CompactResponse> compact(
          $pb.ClientContext? ctx, CompactRequest request) =>
      _client.invoke<CompactResponse>(
          ctx, 'SessionService', 'Compact', request, CompactResponse());

  /// AnswerPrompt answers a prompt the agent is waiting on. The first answer
  /// wins; later answers fail with FAILED_PRECONDITION.
  $async.Future<AnswerPromptResponse> answerPrompt(
          $pb.ClientContext? ctx, AnswerPromptRequest request) =>
      _client.invoke<AnswerPromptResponse>(ctx, 'SessionService',
          'AnswerPrompt', request, AnswerPromptResponse());

  /// SetModel changes the provider and model used from the next model call.
  $async.Future<SetModelResponse> setModel(
          $pb.ClientContext? ctx, SetModelRequest request) =>
      _client.invoke<SetModelResponse>(
          ctx, 'SessionService', 'SetModel', request, SetModelResponse());

  /// SetEffort changes the reasoning effort used from the next model call.
  $async.Future<SetEffortResponse> setEffort(
          $pb.ClientContext? ctx, SetEffortRequest request) =>
      _client.invoke<SetEffortResponse>(
          ctx, 'SessionService', 'SetEffort', request, SetEffortResponse());

  /// SetYolo turns yolo mode on or off for the session: every shell command
  /// runs unless a deny rule matches. Effective from the next command.
  $async.Future<SetYoloResponse> setYolo(
          $pb.ClientContext? ctx, SetYoloRequest request) =>
      _client.invoke<SetYoloResponse>(
          ctx, 'SessionService', 'SetYolo', request, SetYoloResponse());

  /// MoveSession moves a session to another project. Its working directory
  /// stays the same.
  $async.Future<MoveSessionResponse> moveSession(
          $pb.ClientContext? ctx, MoveSessionRequest request) =>
      _client.invoke<MoveSessionResponse>(
          ctx, 'SessionService', 'MoveSession', request, MoveSessionResponse());

  /// Rate records whether a turn's result or the model choice was good or
  /// bad. Ratings are events in the session log.
  $async.Future<RateResponse> rate(
          $pb.ClientContext? ctx, RateRequest request) =>
      _client.invoke<RateResponse>(
          ctx, 'SessionService', 'Rate', request, RateResponse());

  /// ListMcpServers lists the configured MCP servers and whether each is
  /// enabled for the session. Only enabled servers' tools reach the model.
  $async.Future<ListMcpServersResponse> listMcpServers(
          $pb.ClientContext? ctx, ListMcpServersRequest request) =>
      _client.invoke<ListMcpServersResponse>(ctx, 'SessionService',
          'ListMcpServers', request, ListMcpServersResponse());

  /// SetMcpServer enables or disables an MCP server for the session, from
  /// its next model call.
  $async.Future<SetMcpServerResponse> setMcpServer(
          $pb.ClientContext? ctx, SetMcpServerRequest request) =>
      _client.invoke<SetMcpServerResponse>(ctx, 'SessionService',
          'SetMcpServer', request, SetMcpServerResponse());

  /// ListSkills lists the skills the session's agent can load: the repo's
  /// own (.agents/skills, .claude/skills) and the global ones.
  $async.Future<ListSkillsResponse> listSkills(
          $pb.ClientContext? ctx, ListSkillsRequest request) =>
      _client.invoke<ListSkillsResponse>(
          ctx, 'SessionService', 'ListSkills', request, ListSkillsResponse());

  /// RetryFromMessage starts a new branch of the conversation that keeps
  /// user message message_id (on the active branch's path) and everything
  /// before it, drops what came after, and runs the turn again with the
  /// session's current model. EditMessage does the same but forks just
  /// before the message and sends text in its place. Both switch the
  /// session to the new branch (BranchCreated, BranchSwitched) and fail
  /// with FAILED_PRECONDITION while a turn is running (Interrupt first) or
  /// while messages are queued (send or cancel them first). Files the agent
  /// changed stay as they are: a branch only forks the conversation.
  $async.Future<RetryFromMessageResponse> retryFromMessage(
          $pb.ClientContext? ctx, RetryFromMessageRequest request) =>
      _client.invoke<RetryFromMessageResponse>(ctx, 'SessionService',
          'RetryFromMessage', request, RetryFromMessageResponse());
  $async.Future<EditMessageResponse> editMessage(
          $pb.ClientContext? ctx, EditMessageRequest request) =>
      _client.invoke<EditMessageResponse>(
          ctx, 'SessionService', 'EditMessage', request, EditMessageResponse());

  /// SwitchBranch makes another branch the active one: the next message
  /// continues it and the model sees its history. FAILED_PRECONDITION while
  /// a turn is running.
  $async.Future<SwitchBranchResponse> switchBranch(
          $pb.ClientContext? ctx, SwitchBranchRequest request) =>
      _client.invoke<SwitchBranchResponse>(ctx, 'SessionService',
          'SwitchBranch', request, SwitchBranchResponse());

  /// GitStatus reports the git repository the session works in: branch,
  /// upstream, counts like git status, and the files changed since the
  /// session's base commit (Session.base_commit), committed or not. A
  /// working directory outside git is not an error: is_repo is false.
  /// Clients refresh it when a turn ends or a tool call finishes.
  $async.Future<GitStatusResponse> gitStatus(
          $pb.ClientContext? ctx, GitStatusRequest request) =>
      _client.invoke<GitStatusResponse>(
          ctx, 'SessionService', 'GitStatus', request, GitStatusResponse());

  /// GitDiff returns the unified diff of the session's changes: the base
  /// commit against the working tree, untracked files included as new
  /// files. The repository's index is left untouched.
  $async.Future<GitDiffResponse> gitDiff(
          $pb.ClientContext? ctx, GitDiffRequest request) =>
      _client.invoke<GitDiffResponse>(
          ctx, 'SessionService', 'GitDiff', request, GitDiffResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
