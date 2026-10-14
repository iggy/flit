// This is a generated file - do not edit.
//
// Generated from flit/v1/role.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AgentRole extends $pb.GeneratedMessage {
  factory AgentRole({
    $core.String? name,
    $core.String? description,
    $core.String? provider,
    $core.String? model,
    $core.String? effort,
    $core.String? memoryFile,
    $core.String? error,
  }) {
    final result = AgentRole._();
    if (name != null) result.name = name;
    if (description != null) result.description = description;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (effort != null) result.effort = effort;
    if (memoryFile != null) result.memoryFile = memoryFile;
    if (error != null) result.error = error;
    return result;
  }

  AgentRole._();

  factory AgentRole.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AgentRole()..mergeFromBuffer(data, registry);
  factory AgentRole.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AgentRole()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AgentRole',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AgentRole.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'description')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..aOS(5, _omitFieldNames ? '' : 'effort')
    ..aOS(6, _omitFieldNames ? '' : 'memoryFile')
    ..aOS(7, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentRole clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AgentRole copyWith(void Function(AgentRole) updates) =>
      super.copyWith((message) => updates(message as AgentRole)) as AgentRole;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AgentRole() / AgentRole.new instead')
  static AgentRole create() => AgentRole._();
  static $pb.GeneratedMessage $_createMessage() => AgentRole._();
  @$core.override
  AgentRole createEmptyInstance() => AgentRole._();
  @$core.pragma('dart2js:noInline')
  static AgentRole getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AgentRole>(AgentRole.$_createMessage);
  static AgentRole? _defaultInstance;

  /// The file name without .md, unless the frontmatter sets name.
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

  /// Defaults for sessions using the role; empty means the config's.
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

  @$pb.TagNumber(5)
  $core.String get effort => $_getSZ(4);
  @$pb.TagNumber(5)
  set effort($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEffort() => $_has(4);
  @$pb.TagNumber(5)
  void clearEffort() => $_clearField(5);

  /// File whose contents are added to the system prompt each turn,
  /// relative to the session's working directory unless absolute.
  @$pb.TagNumber(6)
  $core.String get memoryFile => $_getSZ(5);
  @$pb.TagNumber(6)
  set memoryFile($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMemoryFile() => $_has(5);
  @$pb.TagNumber(6)
  void clearMemoryFile() => $_clearField(6);

  /// Problems reading the file, if any; such roles can't be picked.
  @$pb.TagNumber(7)
  $core.String get error => $_getSZ(6);
  @$pb.TagNumber(7)
  set error($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasError() => $_has(6);
  @$pb.TagNumber(7)
  void clearError() => $_clearField(7);
}

class ListRolesRequest extends $pb.GeneratedMessage {
  factory ListRolesRequest() => ListRolesRequest._();

  ListRolesRequest._();

  factory ListRolesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesRequest()..mergeFromBuffer(data, registry);
  factory ListRolesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRolesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListRolesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesRequest copyWith(void Function(ListRolesRequest) updates) =>
      super.copyWith((message) => updates(message as ListRolesRequest))
          as ListRolesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListRolesRequest() / ListRolesRequest.new instead')
  static ListRolesRequest create() => ListRolesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListRolesRequest._();
  @$core.override
  ListRolesRequest createEmptyInstance() => ListRolesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListRolesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListRolesRequest>(
          ListRolesRequest.$_createMessage);
  static ListRolesRequest? _defaultInstance;
}

class ListRolesResponse extends $pb.GeneratedMessage {
  factory ListRolesResponse({
    $core.Iterable<AgentRole>? roles,
  }) {
    final result = ListRolesResponse._();
    if (roles != null) result.roles.addAll(roles);
    return result;
  }

  ListRolesResponse._();

  factory ListRolesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesResponse()..mergeFromBuffer(data, registry);
  factory ListRolesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRolesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListRolesResponse.$_createMessage)
    ..pPM<AgentRole>(1, _omitFieldNames ? '' : 'roles',
        subBuilder: AgentRole.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesResponse copyWith(void Function(ListRolesResponse) updates) =>
      super.copyWith((message) => updates(message as ListRolesResponse))
          as ListRolesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListRolesResponse() / ListRolesResponse.new instead')
  static ListRolesResponse create() => ListRolesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListRolesResponse._();
  @$core.override
  ListRolesResponse createEmptyInstance() => ListRolesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListRolesResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListRolesResponse>(
          ListRolesResponse.$_createMessage);
  static ListRolesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AgentRole> get roles => $_getList(0);
}

/// RoleService lists roles. A role is a Markdown file with YAML frontmatter
/// in the server's roles directory: the body is added to the system prompt,
/// and the frontmatter sets a default model and effort, a memory file, and
/// per-task models. A session picks its role when it is created.
class RoleServiceApi {
  final $pb.RpcClient _client;

  RoleServiceApi(this._client);

  $async.Future<ListRolesResponse> listRoles(
          $pb.ClientContext? ctx, ListRolesRequest request) =>
      _client.invoke<ListRolesResponse>(
          ctx, 'RoleService', 'ListRoles', request, ListRolesResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
