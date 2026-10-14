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
  }) {
    final result = CreateSessionRequest._();
    if (workingDir != null) result.workingDir = workingDir;
    if (title != null) result.title = title;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (role != null) result.role = role;
    if (effort != null) result.effort = effort;
    if (projectId != null) result.projectId = projectId;
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
  }) {
    final result = SendRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (text != null) result.text = text;
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
}

class SendResponse extends $pb.GeneratedMessage {
  factory SendResponse({
    $fixnum.Int64? seq,
  }) {
    final result = SendResponse._();
    if (seq != null) result.seq = seq;
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

  /// Sequence number of the user message's first event.
  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);
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
  notSet
}

/// Event is one entry in a session's event log.
class Event extends $pb.GeneratedMessage {
  factory Event({
    $core.String? sessionId,
    $fixnum.Int64? seq,
    $0.Timestamp? time,
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
  }) {
    final result = Event._();
    if (sessionId != null) result.sessionId = sessionId;
    if (seq != null) result.seq = seq;
    if (time != null) result.time = time;
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
    0: Event_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Event.$_createMessage)
    ..oo(
        0, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26])
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aInt64(2, _omitFieldNames ? '' : 'seq')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'time',
        subBuilder: $0.Timestamp.$_createMessage)
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

  @$pb.TagNumber(10)
  MessageStarted get messageStarted => $_getN(3);
  @$pb.TagNumber(10)
  set messageStarted(MessageStarted value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMessageStarted() => $_has(3);
  @$pb.TagNumber(10)
  void clearMessageStarted() => $_clearField(10);
  @$pb.TagNumber(10)
  MessageStarted ensureMessageStarted() => $_ensure(3);

  @$pb.TagNumber(11)
  TextDelta get textDelta => $_getN(4);
  @$pb.TagNumber(11)
  set textDelta(TextDelta value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTextDelta() => $_has(4);
  @$pb.TagNumber(11)
  void clearTextDelta() => $_clearField(11);
  @$pb.TagNumber(11)
  TextDelta ensureTextDelta() => $_ensure(4);

  @$pb.TagNumber(12)
  ReasoningDelta get reasoningDelta => $_getN(5);
  @$pb.TagNumber(12)
  set reasoningDelta(ReasoningDelta value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasReasoningDelta() => $_has(5);
  @$pb.TagNumber(12)
  void clearReasoningDelta() => $_clearField(12);
  @$pb.TagNumber(12)
  ReasoningDelta ensureReasoningDelta() => $_ensure(5);

  @$pb.TagNumber(13)
  MessageDone get messageDone => $_getN(6);
  @$pb.TagNumber(13)
  set messageDone(MessageDone value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasMessageDone() => $_has(6);
  @$pb.TagNumber(13)
  void clearMessageDone() => $_clearField(13);
  @$pb.TagNumber(13)
  MessageDone ensureMessageDone() => $_ensure(6);

  @$pb.TagNumber(14)
  ToolCallStarted get toolCallStarted => $_getN(7);
  @$pb.TagNumber(14)
  set toolCallStarted(ToolCallStarted value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasToolCallStarted() => $_has(7);
  @$pb.TagNumber(14)
  void clearToolCallStarted() => $_clearField(14);
  @$pb.TagNumber(14)
  ToolCallStarted ensureToolCallStarted() => $_ensure(7);

  @$pb.TagNumber(15)
  ToolOutput get toolOutput => $_getN(8);
  @$pb.TagNumber(15)
  set toolOutput(ToolOutput value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasToolOutput() => $_has(8);
  @$pb.TagNumber(15)
  void clearToolOutput() => $_clearField(15);
  @$pb.TagNumber(15)
  ToolOutput ensureToolOutput() => $_ensure(8);

  @$pb.TagNumber(16)
  ToolCallDone get toolCallDone => $_getN(9);
  @$pb.TagNumber(16)
  set toolCallDone(ToolCallDone value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasToolCallDone() => $_has(9);
  @$pb.TagNumber(16)
  void clearToolCallDone() => $_clearField(16);
  @$pb.TagNumber(16)
  ToolCallDone ensureToolCallDone() => $_ensure(9);

  @$pb.TagNumber(17)
  PromptRequested get promptRequested => $_getN(10);
  @$pb.TagNumber(17)
  set promptRequested(PromptRequested value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPromptRequested() => $_has(10);
  @$pb.TagNumber(17)
  void clearPromptRequested() => $_clearField(17);
  @$pb.TagNumber(17)
  PromptRequested ensurePromptRequested() => $_ensure(10);

  @$pb.TagNumber(18)
  PromptResolved get promptResolved => $_getN(11);
  @$pb.TagNumber(18)
  set promptResolved(PromptResolved value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasPromptResolved() => $_has(11);
  @$pb.TagNumber(18)
  void clearPromptResolved() => $_clearField(18);
  @$pb.TagNumber(18)
  PromptResolved ensurePromptResolved() => $_ensure(11);

  @$pb.TagNumber(19)
  TaskStateChanged get taskStateChanged => $_getN(12);
  @$pb.TagNumber(19)
  set taskStateChanged(TaskStateChanged value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasTaskStateChanged() => $_has(12);
  @$pb.TagNumber(19)
  void clearTaskStateChanged() => $_clearField(19);
  @$pb.TagNumber(19)
  TaskStateChanged ensureTaskStateChanged() => $_ensure(12);

  @$pb.TagNumber(20)
  ModelChanged get modelChanged => $_getN(13);
  @$pb.TagNumber(20)
  set modelChanged(ModelChanged value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasModelChanged() => $_has(13);
  @$pb.TagNumber(20)
  void clearModelChanged() => $_clearField(20);
  @$pb.TagNumber(20)
  ModelChanged ensureModelChanged() => $_ensure(13);

  @$pb.TagNumber(21)
  Usage get usage => $_getN(14);
  @$pb.TagNumber(21)
  set usage(Usage value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasUsage() => $_has(14);
  @$pb.TagNumber(21)
  void clearUsage() => $_clearField(21);
  @$pb.TagNumber(21)
  Usage ensureUsage() => $_ensure(14);

  @$pb.TagNumber(22)
  TurnError get error => $_getN(15);
  @$pb.TagNumber(22)
  set error(TurnError value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasError() => $_has(15);
  @$pb.TagNumber(22)
  void clearError() => $_clearField(22);
  @$pb.TagNumber(22)
  TurnError ensureError() => $_ensure(15);

  @$pb.TagNumber(23)
  TodoUpdated get todoUpdated => $_getN(16);
  @$pb.TagNumber(23)
  set todoUpdated(TodoUpdated value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasTodoUpdated() => $_has(16);
  @$pb.TagNumber(23)
  void clearTodoUpdated() => $_clearField(23);
  @$pb.TagNumber(23)
  TodoUpdated ensureTodoUpdated() => $_ensure(16);

  @$pb.TagNumber(24)
  Feedback get feedback => $_getN(17);
  @$pb.TagNumber(24)
  set feedback(Feedback value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasFeedback() => $_has(17);
  @$pb.TagNumber(24)
  void clearFeedback() => $_clearField(24);
  @$pb.TagNumber(24)
  Feedback ensureFeedback() => $_ensure(17);

  @$pb.TagNumber(25)
  McpServersChanged get mcpServersChanged => $_getN(18);
  @$pb.TagNumber(25)
  set mcpServersChanged(McpServersChanged value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasMcpServersChanged() => $_has(18);
  @$pb.TagNumber(25)
  void clearMcpServersChanged() => $_clearField(25);
  @$pb.TagNumber(25)
  McpServersChanged ensureMcpServersChanged() => $_ensure(18);

  @$pb.TagNumber(26)
  SessionMoved get sessionMoved => $_getN(19);
  @$pb.TagNumber(26)
  set sessionMoved(SessionMoved value) => $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasSessionMoved() => $_has(19);
  @$pb.TagNumber(26)
  void clearSessionMoved() => $_clearField(26);
  @$pb.TagNumber(26)
  SessionMoved ensureSessionMoved() => $_ensure(19);
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
  }) {
    final result = PromptRequested._();
    if (promptId != null) result.promptId = promptId;
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (title != null) result.title = title;
    if (detail != null) result.detail = detail;
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
}

class PromptResolved extends $pb.GeneratedMessage {
  factory PromptResolved({
    $core.String? promptId,
    PromptDecision? decision,
    $core.String? client,
    $core.String? reason,
  }) {
    final result = PromptResolved._();
    if (promptId != null) result.promptId = promptId;
    if (decision != null) result.decision = decision;
    if (client != null) result.client = client;
    if (reason != null) result.reason = reason;
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

  /// Send adds a user message and starts a turn. Fails with
  /// FAILED_PRECONDITION while a turn is already running.
  $async.Future<SendResponse> send(
          $pb.ClientContext? ctx, SendRequest request) =>
      _client.invoke<SendResponse>(
          ctx, 'SessionService', 'Send', request, SendResponse());

  /// Interrupt stops the running turn, if any. Pending prompts are resolved
  /// as denied.
  $async.Future<InterruptResponse> interrupt(
          $pb.ClientContext? ctx, InterruptRequest request) =>
      _client.invoke<InterruptResponse>(
          ctx, 'SessionService', 'Interrupt', request, InterruptResponse());

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
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
