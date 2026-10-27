// This is a generated file - do not edit.
//
// Generated from flit/v1/system.proto.

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

import 'session.pbenum.dart' as $1;
import 'system.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'system.pbenum.dart';

class VersionRequest extends $pb.GeneratedMessage {
  factory VersionRequest() => VersionRequest._();

  VersionRequest._();

  factory VersionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VersionRequest()..mergeFromBuffer(data, registry);
  factory VersionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VersionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: VersionRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionRequest copyWith(void Function(VersionRequest) updates) =>
      super.copyWith((message) => updates(message as VersionRequest))
          as VersionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VersionRequest() / VersionRequest.new instead')
  static VersionRequest create() => VersionRequest._();
  static $pb.GeneratedMessage $_createMessage() => VersionRequest._();
  @$core.override
  VersionRequest createEmptyInstance() => VersionRequest._();
  @$core.pragma('dart2js:noInline')
  static VersionRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VersionRequest>(
          VersionRequest.$_createMessage);
  static VersionRequest? _defaultInstance;
}

class VersionResponse extends $pb.GeneratedMessage {
  factory VersionResponse({
    $core.String? version,
    $core.String? commit,
    $core.String? buildTime,
    $core.String? goVersion,
    $core.String? os,
    $core.String? arch,
    $core.String? apiVersion,
  }) {
    final result = VersionResponse._();
    if (version != null) result.version = version;
    if (commit != null) result.commit = commit;
    if (buildTime != null) result.buildTime = buildTime;
    if (goVersion != null) result.goVersion = goVersion;
    if (os != null) result.os = os;
    if (arch != null) result.arch = arch;
    if (apiVersion != null) result.apiVersion = apiVersion;
    return result;
  }

  VersionResponse._();

  factory VersionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VersionResponse()..mergeFromBuffer(data, registry);
  factory VersionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VersionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VersionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: VersionResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aOS(2, _omitFieldNames ? '' : 'commit')
    ..aOS(3, _omitFieldNames ? '' : 'buildTime')
    ..aOS(4, _omitFieldNames ? '' : 'goVersion')
    ..aOS(5, _omitFieldNames ? '' : 'os')
    ..aOS(6, _omitFieldNames ? '' : 'arch')
    ..aOS(7, _omitFieldNames ? '' : 'apiVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse copyWith(void Function(VersionResponse) updates) =>
      super.copyWith((message) => updates(message as VersionResponse))
          as VersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VersionResponse() / VersionResponse.new instead')
  static VersionResponse create() => VersionResponse._();
  static $pb.GeneratedMessage $_createMessage() => VersionResponse._();
  @$core.override
  VersionResponse createEmptyInstance() => VersionResponse._();
  @$core.pragma('dart2js:noInline')
  static VersionResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VersionResponse>(
          VersionResponse.$_createMessage);
  static VersionResponse? _defaultInstance;

  /// Release version of the server binary, e.g. "0.1.0" or "dev".
  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  /// VCS revision the binary was built from, if known.
  @$pb.TagNumber(2)
  $core.String get commit => $_getSZ(1);
  @$pb.TagNumber(2)
  set commit($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => $_clearField(2);

  /// Build time in RFC 3339 format, if known.
  @$pb.TagNumber(3)
  $core.String get buildTime => $_getSZ(2);
  @$pb.TagNumber(3)
  set buildTime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBuildTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuildTime() => $_clearField(3);

  /// Go toolchain version the binary was built with.
  @$pb.TagNumber(4)
  $core.String get goVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set goVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGoVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoVersion() => $_clearField(4);

  /// GOOS and GOARCH of the binary.
  @$pb.TagNumber(5)
  $core.String get os => $_getSZ(4);
  @$pb.TagNumber(5)
  set os($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOs() => $_has(4);
  @$pb.TagNumber(5)
  void clearOs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get arch => $_getSZ(5);
  @$pb.TagNumber(6)
  set arch($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasArch() => $_has(5);
  @$pb.TagNumber(6)
  void clearArch() => $_clearField(6);

  /// Highest API package version the server speaks, e.g. "v1".
  @$pb.TagNumber(7)
  $core.String get apiVersion => $_getSZ(6);
  @$pb.TagNumber(7)
  set apiVersion($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasApiVersion() => $_has(6);
  @$pb.TagNumber(7)
  void clearApiVersion() => $_clearField(7);
}

class HealthRequest extends $pb.GeneratedMessage {
  factory HealthRequest() => HealthRequest._();

  HealthRequest._();

  factory HealthRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthRequest()..mergeFromBuffer(data, registry);
  factory HealthRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: HealthRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthRequest copyWith(void Function(HealthRequest) updates) =>
      super.copyWith((message) => updates(message as HealthRequest))
          as HealthRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HealthRequest() / HealthRequest.new instead')
  static HealthRequest create() => HealthRequest._();
  static $pb.GeneratedMessage $_createMessage() => HealthRequest._();
  @$core.override
  HealthRequest createEmptyInstance() => HealthRequest._();
  @$core.pragma('dart2js:noInline')
  static HealthRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HealthRequest>(
          HealthRequest.$_createMessage);
  static HealthRequest? _defaultInstance;
}

class HealthResponse extends $pb.GeneratedMessage {
  factory HealthResponse({
    HealthResponse_Status? status,
  }) {
    final result = HealthResponse._();
    if (status != null) result.status = status;
    return result;
  }

  HealthResponse._();

  factory HealthResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthResponse()..mergeFromBuffer(data, registry);
  factory HealthResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: HealthResponse.$_createMessage)
    ..aE<HealthResponse_Status>(1, _omitFieldNames ? '' : 'status',
        enumValues: HealthResponse_Status.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthResponse copyWith(void Function(HealthResponse) updates) =>
      super.copyWith((message) => updates(message as HealthResponse))
          as HealthResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HealthResponse() / HealthResponse.new instead')
  static HealthResponse create() => HealthResponse._();
  static $pb.GeneratedMessage $_createMessage() => HealthResponse._();
  @$core.override
  HealthResponse createEmptyInstance() => HealthResponse._();
  @$core.pragma('dart2js:noInline')
  static HealthResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HealthResponse>(
          HealthResponse.$_createMessage);
  static HealthResponse? _defaultInstance;

  @$pb.TagNumber(1)
  HealthResponse_Status get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(HealthResponse_Status value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

class CreatePairingCodeRequest extends $pb.GeneratedMessage {
  factory CreatePairingCodeRequest() => CreatePairingCodeRequest._();

  CreatePairingCodeRequest._();

  factory CreatePairingCodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePairingCodeRequest()..mergeFromBuffer(data, registry);
  factory CreatePairingCodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePairingCodeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePairingCodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreatePairingCodeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingCodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingCodeRequest copyWith(
          void Function(CreatePairingCodeRequest) updates) =>
      super.copyWith((message) => updates(message as CreatePairingCodeRequest))
          as CreatePairingCodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreatePairingCodeRequest() / CreatePairingCodeRequest.new instead')
  static CreatePairingCodeRequest create() => CreatePairingCodeRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreatePairingCodeRequest._();
  @$core.override
  CreatePairingCodeRequest createEmptyInstance() =>
      CreatePairingCodeRequest._();
  @$core.pragma('dart2js:noInline')
  static CreatePairingCodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePairingCodeRequest>(
          CreatePairingCodeRequest.$_createMessage);
  static CreatePairingCodeRequest? _defaultInstance;
}

class CreatePairingCodeResponse extends $pb.GeneratedMessage {
  factory CreatePairingCodeResponse({
    $core.String? code,
    $0.Timestamp? expireTime,
    $core.String? serverUrl,
  }) {
    final result = CreatePairingCodeResponse._();
    if (code != null) result.code = code;
    if (expireTime != null) result.expireTime = expireTime;
    if (serverUrl != null) result.serverUrl = serverUrl;
    return result;
  }

  CreatePairingCodeResponse._();

  factory CreatePairingCodeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePairingCodeResponse()..mergeFromBuffer(data, registry);
  factory CreatePairingCodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreatePairingCodeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePairingCodeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: CreatePairingCodeResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'expireTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'serverUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingCodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePairingCodeResponse copyWith(
          void Function(CreatePairingCodeResponse) updates) =>
      super.copyWith((message) => updates(message as CreatePairingCodeResponse))
          as CreatePairingCodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreatePairingCodeResponse() / CreatePairingCodeResponse.new instead')
  static CreatePairingCodeResponse create() => CreatePairingCodeResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreatePairingCodeResponse._();
  @$core.override
  CreatePairingCodeResponse createEmptyInstance() =>
      CreatePairingCodeResponse._();
  @$core.pragma('dart2js:noInline')
  static CreatePairingCodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePairingCodeResponse>(
          CreatePairingCodeResponse.$_createMessage);
  static CreatePairingCodeResponse? _defaultInstance;

  /// The code, e.g. "K7QM-4XPZ". Case and dashes are ignored by Pair.
  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get expireTime => $_getN(1);
  @$pb.TagNumber(2)
  set expireTime($0.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpireTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpireTime() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureExpireTime() => $_ensure(1);

  /// The URL clients should use to reach this server (config public_url, or
  /// a best guess from the listen address). May be empty if unknown.
  @$pb.TagNumber(3)
  $core.String get serverUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set serverUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServerUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearServerUrl() => $_clearField(3);
}

class PairRequest extends $pb.GeneratedMessage {
  factory PairRequest({
    $core.String? code,
    $core.String? deviceName,
  }) {
    final result = PairRequest._();
    if (code != null) result.code = code;
    if (deviceName != null) result.deviceName = deviceName;
    return result;
  }

  PairRequest._();

  factory PairRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairRequest()..mergeFromBuffer(data, registry);
  factory PairRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PairRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'code')
    ..aOS(2, _omitFieldNames ? '' : 'deviceName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairRequest copyWith(void Function(PairRequest) updates) =>
      super.copyWith((message) => updates(message as PairRequest))
          as PairRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairRequest() / PairRequest.new instead')
  static PairRequest create() => PairRequest._();
  static $pb.GeneratedMessage $_createMessage() => PairRequest._();
  @$core.override
  PairRequest createEmptyInstance() => PairRequest._();
  @$core.pragma('dart2js:noInline')
  static PairRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairRequest>(
          PairRequest.$_createMessage);
  static PairRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get code => $_getSZ(0);
  @$pb.TagNumber(1)
  set code($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  /// Human-readable device name, e.g. "Pixel 9" or "laptop". Shown in
  /// ListDevices and in PromptResolved.client.
  @$pb.TagNumber(2)
  $core.String get deviceName => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceName() => $_clearField(2);
}

class PairResponse extends $pb.GeneratedMessage {
  factory PairResponse({
    Device? device,
    $core.String? token,
  }) {
    final result = PairResponse._();
    if (device != null) result.device = device;
    if (token != null) result.token = token;
    return result;
  }

  PairResponse._();

  factory PairResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairResponse()..mergeFromBuffer(data, registry);
  factory PairResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: PairResponse.$_createMessage)
    ..aOM<Device>(1, _omitFieldNames ? '' : 'device',
        subBuilder: Device.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairResponse copyWith(void Function(PairResponse) updates) =>
      super.copyWith((message) => updates(message as PairResponse))
          as PairResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairResponse() / PairResponse.new instead')
  static PairResponse create() => PairResponse._();
  static $pb.GeneratedMessage $_createMessage() => PairResponse._();
  @$core.override
  PairResponse createEmptyInstance() => PairResponse._();
  @$core.pragma('dart2js:noInline')
  static PairResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairResponse>(
          PairResponse.$_createMessage);
  static PairResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Device get device => $_getN(0);
  @$pb.TagNumber(1)
  set device(Device value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  Device ensureDevice() => $_ensure(0);

  /// The device's token. Shown only here; store it securely.
  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);
}

/// Device is a paired client.
class Device extends $pb.GeneratedMessage {
  factory Device({
    $core.String? id,
    $core.String? name,
    $0.Timestamp? createTime,
    $0.Timestamp? lastSeenTime,
    $0.Timestamp? revokeTime,
  }) {
    final result = Device._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (createTime != null) result.createTime = createTime;
    if (lastSeenTime != null) result.lastSeenTime = lastSeenTime;
    if (revokeTime != null) result.revokeTime = revokeTime;
    return result;
  }

  Device._();

  factory Device.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromBuffer(data, registry);
  factory Device.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Device',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Device.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'createTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'lastSeenTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'revokeTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device copyWith(void Function(Device) updates) =>
      super.copyWith((message) => updates(message as Device)) as Device;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Device() / Device.new instead')
  static Device create() => Device._();
  static $pb.GeneratedMessage $_createMessage() => Device._();
  @$core.override
  Device createEmptyInstance() => Device._();
  @$core.pragma('dart2js:noInline')
  static Device getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Device>(Device.$_createMessage);
  static Device? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get createTime => $_getN(2);
  @$pb.TagNumber(3)
  set createTime($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreateTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreateTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureCreateTime() => $_ensure(2);

  /// Last time the device made an authenticated call (updated at most about
  /// once a minute). Unset if never.
  @$pb.TagNumber(4)
  $0.Timestamp get lastSeenTime => $_getN(3);
  @$pb.TagNumber(4)
  set lastSeenTime($0.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLastSeenTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastSeenTime() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureLastSeenTime() => $_ensure(3);

  /// Set once revoked; revoked devices' tokens no longer work.
  @$pb.TagNumber(5)
  $0.Timestamp get revokeTime => $_getN(4);
  @$pb.TagNumber(5)
  set revokeTime($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRevokeTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearRevokeTime() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureRevokeTime() => $_ensure(4);
}

class ListDevicesRequest extends $pb.GeneratedMessage {
  factory ListDevicesRequest({
    $core.bool? includeRevoked,
  }) {
    final result = ListDevicesRequest._();
    if (includeRevoked != null) result.includeRevoked = includeRevoked;
    return result;
  }

  ListDevicesRequest._();

  factory ListDevicesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesRequest()..mergeFromBuffer(data, registry);
  factory ListDevicesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDevicesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListDevicesRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'includeRevoked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesRequest copyWith(void Function(ListDevicesRequest) updates) =>
      super.copyWith((message) => updates(message as ListDevicesRequest))
          as ListDevicesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListDevicesRequest() / ListDevicesRequest.new instead')
  static ListDevicesRequest create() => ListDevicesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListDevicesRequest._();
  @$core.override
  ListDevicesRequest createEmptyInstance() => ListDevicesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListDevicesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDevicesRequest>(
          ListDevicesRequest.$_createMessage);
  static ListDevicesRequest? _defaultInstance;

  /// Include revoked devices.
  @$pb.TagNumber(1)
  $core.bool get includeRevoked => $_getBF(0);
  @$pb.TagNumber(1)
  set includeRevoked($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIncludeRevoked() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludeRevoked() => $_clearField(1);
}

class ListDevicesResponse extends $pb.GeneratedMessage {
  factory ListDevicesResponse({
    $core.Iterable<Device>? devices,
  }) {
    final result = ListDevicesResponse._();
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  ListDevicesResponse._();

  factory ListDevicesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesResponse()..mergeFromBuffer(data, registry);
  factory ListDevicesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDevicesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListDevicesResponse.$_createMessage)
    ..pPM<Device>(1, _omitFieldNames ? '' : 'devices',
        subBuilder: Device.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesResponse copyWith(void Function(ListDevicesResponse) updates) =>
      super.copyWith((message) => updates(message as ListDevicesResponse))
          as ListDevicesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListDevicesResponse() / ListDevicesResponse.new instead')
  static ListDevicesResponse create() => ListDevicesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListDevicesResponse._();
  @$core.override
  ListDevicesResponse createEmptyInstance() => ListDevicesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListDevicesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDevicesResponse>(
          ListDevicesResponse.$_createMessage);
  static ListDevicesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Device> get devices => $_getList(0);
}

class RevokeDeviceRequest extends $pb.GeneratedMessage {
  factory RevokeDeviceRequest({
    $core.String? deviceId,
  }) {
    final result = RevokeDeviceRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  RevokeDeviceRequest._();

  factory RevokeDeviceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceRequest()..mergeFromBuffer(data, registry);
  factory RevokeDeviceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RevokeDeviceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceRequest copyWith(void Function(RevokeDeviceRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceRequest))
          as RevokeDeviceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RevokeDeviceRequest() / RevokeDeviceRequest.new instead')
  static RevokeDeviceRequest create() => RevokeDeviceRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceRequest._();
  @$core.override
  RevokeDeviceRequest createEmptyInstance() => RevokeDeviceRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceRequest>(
          RevokeDeviceRequest.$_createMessage);
  static RevokeDeviceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

class RevokeDeviceResponse extends $pb.GeneratedMessage {
  factory RevokeDeviceResponse() => RevokeDeviceResponse._();

  RevokeDeviceResponse._();

  factory RevokeDeviceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceResponse()..mergeFromBuffer(data, registry);
  factory RevokeDeviceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RevokeDeviceResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceResponse copyWith(void Function(RevokeDeviceResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceResponse))
          as RevokeDeviceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RevokeDeviceResponse() / RevokeDeviceResponse.new instead')
  static RevokeDeviceResponse create() => RevokeDeviceResponse._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceResponse._();
  @$core.override
  RevokeDeviceResponse createEmptyInstance() => RevokeDeviceResponse._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceResponse>(
          RevokeDeviceResponse.$_createMessage);
  static RevokeDeviceResponse? _defaultInstance;
}

class DebugDumpRequest extends $pb.GeneratedMessage {
  factory DebugDumpRequest({
    $core.bool? goroutines,
  }) {
    final result = DebugDumpRequest._();
    if (goroutines != null) result.goroutines = goroutines;
    return result;
  }

  DebugDumpRequest._();

  factory DebugDumpRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugDumpRequest()..mergeFromBuffer(data, registry);
  factory DebugDumpRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugDumpRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugDumpRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: DebugDumpRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'goroutines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugDumpRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugDumpRequest copyWith(void Function(DebugDumpRequest) updates) =>
      super.copyWith((message) => updates(message as DebugDumpRequest))
          as DebugDumpRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DebugDumpRequest() / DebugDumpRequest.new instead')
  static DebugDumpRequest create() => DebugDumpRequest._();
  static $pb.GeneratedMessage $_createMessage() => DebugDumpRequest._();
  @$core.override
  DebugDumpRequest createEmptyInstance() => DebugDumpRequest._();
  @$core.pragma('dart2js:noInline')
  static DebugDumpRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DebugDumpRequest>(
          DebugDumpRequest.$_createMessage);
  static DebugDumpRequest? _defaultInstance;

  /// Include every goroutine's stack (can be large).
  @$pb.TagNumber(1)
  $core.bool get goroutines => $_getBF(0);
  @$pb.TagNumber(1)
  set goroutines($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGoroutines() => $_has(0);
  @$pb.TagNumber(1)
  void clearGoroutines() => $_clearField(1);
}

class DebugDumpResponse extends $pb.GeneratedMessage {
  factory DebugDumpResponse({
    $0.Timestamp? time,
    $core.Iterable<SessionDebug>? sessions,
    $core.Iterable<ModelLimitDebug>? limits,
    $core.String? goroutines,
    $core.bool? sessionsLockFree,
  }) {
    final result = DebugDumpResponse._();
    if (time != null) result.time = time;
    if (sessions != null) result.sessions.addAll(sessions);
    if (limits != null) result.limits.addAll(limits);
    if (goroutines != null) result.goroutines = goroutines;
    if (sessionsLockFree != null) result.sessionsLockFree = sessionsLockFree;
    return result;
  }

  DebugDumpResponse._();

  factory DebugDumpResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugDumpResponse()..mergeFromBuffer(data, registry);
  factory DebugDumpResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DebugDumpResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DebugDumpResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: DebugDumpResponse.$_createMessage)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'time',
        subBuilder: $0.Timestamp.$_createMessage)
    ..pPM<SessionDebug>(2, _omitFieldNames ? '' : 'sessions',
        subBuilder: SessionDebug.$_createMessage)
    ..pPM<ModelLimitDebug>(3, _omitFieldNames ? '' : 'limits',
        subBuilder: ModelLimitDebug.$_createMessage)
    ..aOS(4, _omitFieldNames ? '' : 'goroutines')
    ..aOB(5, _omitFieldNames ? '' : 'sessionsLockFree')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugDumpResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DebugDumpResponse copyWith(void Function(DebugDumpResponse) updates) =>
      super.copyWith((message) => updates(message as DebugDumpResponse))
          as DebugDumpResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DebugDumpResponse() / DebugDumpResponse.new instead')
  static DebugDumpResponse create() => DebugDumpResponse._();
  static $pb.GeneratedMessage $_createMessage() => DebugDumpResponse._();
  @$core.override
  DebugDumpResponse createEmptyInstance() => DebugDumpResponse._();
  @$core.pragma('dart2js:noInline')
  static DebugDumpResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DebugDumpResponse>(
          DebugDumpResponse.$_createMessage);
  static DebugDumpResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Timestamp get time => $_getN(0);
  @$pb.TagNumber(1)
  set time($0.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearTime() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureTime() => $_ensure(0);

  /// The sessions loaded in memory (any used since the server started).
  @$pb.TagNumber(2)
  $pb.PbList<SessionDebug> get sessions => $_getList(1);

  /// Model calls holding or waiting for a concurrency slot
  /// (providers[].concurrency), per provider and model.
  @$pb.TagNumber(3)
  $pb.PbList<ModelLimitDebug> get limits => $_getList(2);

  /// Every goroutine's stack, as Go prints them, if asked for.
  @$pb.TagNumber(4)
  $core.String get goroutines => $_getSZ(3);
  @$pb.TagNumber(4)
  set goroutines($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGoroutines() => $_has(3);
  @$pb.TagNumber(4)
  void clearGoroutines() => $_clearField(4);

  /// Whether the session table itself could be locked; false means the
  /// sessions list is empty because something holds it (see goroutines).
  @$pb.TagNumber(5)
  $core.bool get sessionsLockFree => $_getBF(4);
  @$pb.TagNumber(5)
  set sessionsLockFree($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSessionsLockFree() => $_has(4);
  @$pb.TagNumber(5)
  void clearSessionsLockFree() => $_clearField(5);
}

/// SessionDebug is one session's live state.
class SessionDebug extends $pb.GeneratedMessage {
  factory SessionDebug({
    $core.String? sessionId,
    $core.String? title,
    $core.bool? lockFree,
    $1.TaskState? state,
    $core.bool? turnRunning,
    $fixnum.Int64? lastSeq,
    $0.Timestamp? lastEventTime,
    $core.int? queuedMessages,
    $core.int? pendingPrompts,
    ModelCallDebug? call,
    ToolDebug? tool,
    $core.Iterable<ModelCallDebug>? subagentCalls,
  }) {
    final result = SessionDebug._();
    if (sessionId != null) result.sessionId = sessionId;
    if (title != null) result.title = title;
    if (lockFree != null) result.lockFree = lockFree;
    if (state != null) result.state = state;
    if (turnRunning != null) result.turnRunning = turnRunning;
    if (lastSeq != null) result.lastSeq = lastSeq;
    if (lastEventTime != null) result.lastEventTime = lastEventTime;
    if (queuedMessages != null) result.queuedMessages = queuedMessages;
    if (pendingPrompts != null) result.pendingPrompts = pendingPrompts;
    if (call != null) result.call = call;
    if (tool != null) result.tool = tool;
    if (subagentCalls != null) result.subagentCalls.addAll(subagentCalls);
    return result;
  }

  SessionDebug._();

  factory SessionDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionDebug()..mergeFromBuffer(data, registry);
  factory SessionDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SessionDebug.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOB(3, _omitFieldNames ? '' : 'lockFree')
    ..aE<$1.TaskState>(4, _omitFieldNames ? '' : 'state',
        enumValues: $1.TaskState.values)
    ..aOB(5, _omitFieldNames ? '' : 'turnRunning')
    ..aInt64(6, _omitFieldNames ? '' : 'lastSeq')
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'lastEventTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aI(8, _omitFieldNames ? '' : 'queuedMessages')
    ..aI(9, _omitFieldNames ? '' : 'pendingPrompts')
    ..aOM<ModelCallDebug>(10, _omitFieldNames ? '' : 'call',
        subBuilder: ModelCallDebug.$_createMessage)
    ..aOM<ToolDebug>(11, _omitFieldNames ? '' : 'tool',
        subBuilder: ToolDebug.$_createMessage)
    ..pPM<ModelCallDebug>(12, _omitFieldNames ? '' : 'subagentCalls',
        subBuilder: ModelCallDebug.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionDebug copyWith(void Function(SessionDebug) updates) =>
      super.copyWith((message) => updates(message as SessionDebug))
          as SessionDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionDebug() / SessionDebug.new instead')
  static SessionDebug create() => SessionDebug._();
  static $pb.GeneratedMessage $_createMessage() => SessionDebug._();
  @$core.override
  SessionDebug createEmptyInstance() => SessionDebug._();
  @$core.pragma('dart2js:noInline')
  static SessionDebug getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionDebug>(
          SessionDebug.$_createMessage);
  static SessionDebug? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  /// False when the session's lock couldn't be taken within a couple of
  /// seconds: something holds it (a stuck event log write, or a deadlock;
  /// the goroutine stacks show what). The fields below are then unset.
  @$pb.TagNumber(3)
  $core.bool get lockFree => $_getBF(2);
  @$pb.TagNumber(3)
  set lockFree($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLockFree() => $_has(2);
  @$pb.TagNumber(3)
  void clearLockFree() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.TaskState get state => $_getN(3);
  @$pb.TagNumber(4)
  set state($1.TaskState value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get turnRunning => $_getBF(4);
  @$pb.TagNumber(5)
  set turnRunning($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTurnRunning() => $_has(4);
  @$pb.TagNumber(5)
  void clearTurnRunning() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get lastSeq => $_getI64(5);
  @$pb.TagNumber(6)
  set lastSeq($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastSeq() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastSeq() => $_clearField(6);

  @$pb.TagNumber(7)
  $0.Timestamp get lastEventTime => $_getN(6);
  @$pb.TagNumber(7)
  set lastEventTime($0.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasLastEventTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastEventTime() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureLastEventTime() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.int get queuedMessages => $_getIZ(7);
  @$pb.TagNumber(8)
  set queuedMessages($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasQueuedMessages() => $_has(7);
  @$pb.TagNumber(8)
  void clearQueuedMessages() => $_clearField(8);

  /// Prompts waiting for the user.
  @$pb.TagNumber(9)
  $core.int get pendingPrompts => $_getIZ(8);
  @$pb.TagNumber(9)
  set pendingPrompts($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasPendingPrompts() => $_has(8);
  @$pb.TagNumber(9)
  void clearPendingPrompts() => $_clearField(9);

  /// The model call in flight, if any.
  @$pb.TagNumber(10)
  ModelCallDebug get call => $_getN(9);
  @$pb.TagNumber(10)
  set call(ModelCallDebug value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCall() => $_has(9);
  @$pb.TagNumber(10)
  void clearCall() => $_clearField(10);
  @$pb.TagNumber(10)
  ModelCallDebug ensureCall() => $_ensure(9);

  /// The tool the turn is running, if any.
  @$pb.TagNumber(11)
  ToolDebug get tool => $_getN(10);
  @$pb.TagNumber(11)
  set tool(ToolDebug value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasTool() => $_has(10);
  @$pb.TagNumber(11)
  void clearTool() => $_clearField(11);
  @$pb.TagNumber(11)
  ToolDebug ensureTool() => $_ensure(10);

  /// Model calls of subagents (the agent tool) in flight.
  @$pb.TagNumber(12)
  $pb.PbList<ModelCallDebug> get subagentCalls => $_getList(11);
}

/// ToolDebug is a tool run in progress.
class ToolDebug extends $pb.GeneratedMessage {
  factory ToolDebug({
    $core.String? toolCallId,
    $core.String? name,
    $0.Timestamp? startTime,
  }) {
    final result = ToolDebug._();
    if (toolCallId != null) result.toolCallId = toolCallId;
    if (name != null) result.name = name;
    if (startTime != null) result.startTime = startTime;
    return result;
  }

  ToolDebug._();

  factory ToolDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolDebug()..mergeFromBuffer(data, registry);
  factory ToolDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToolDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToolDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ToolDebug.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'toolCallId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'startTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToolDebug copyWith(void Function(ToolDebug) updates) =>
      super.copyWith((message) => updates(message as ToolDebug)) as ToolDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ToolDebug() / ToolDebug.new instead')
  static ToolDebug create() => ToolDebug._();
  static $pb.GeneratedMessage $_createMessage() => ToolDebug._();
  @$core.override
  ToolDebug createEmptyInstance() => ToolDebug._();
  @$core.pragma('dart2js:noInline')
  static ToolDebug getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToolDebug>(ToolDebug.$_createMessage);
  static ToolDebug? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get toolCallId => $_getSZ(0);
  @$pb.TagNumber(1)
  set toolCallId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToolCallId() => $_has(0);
  @$pb.TagNumber(1)
  void clearToolCallId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Timestamp get startTime => $_getN(2);
  @$pb.TagNumber(3)
  set startTime($0.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStartTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureStartTime() => $_ensure(2);
}

/// ModelCallDebug is a model call in flight.
class ModelCallDebug extends $pb.GeneratedMessage {
  factory ModelCallDebug({
    $core.String? messageId,
    $core.String? provider,
    $core.String? model,
    $core.bool? queued,
    $core.String? phase,
    $0.Timestamp? sentTime,
    $fixnum.Int64? idleMs,
    $fixnum.Int64? watchdogMs,
    $fixnum.Int64? bytes,
    $fixnum.Int64? streamedTokens,
    $fixnum.Int64? promptProcessed,
    $fixnum.Int64? promptTotal,
    $core.String? completionId,
  }) {
    final result = ModelCallDebug._();
    if (messageId != null) result.messageId = messageId;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (queued != null) result.queued = queued;
    if (phase != null) result.phase = phase;
    if (sentTime != null) result.sentTime = sentTime;
    if (idleMs != null) result.idleMs = idleMs;
    if (watchdogMs != null) result.watchdogMs = watchdogMs;
    if (bytes != null) result.bytes = bytes;
    if (streamedTokens != null) result.streamedTokens = streamedTokens;
    if (promptProcessed != null) result.promptProcessed = promptProcessed;
    if (promptTotal != null) result.promptTotal = promptTotal;
    if (completionId != null) result.completionId = completionId;
    return result;
  }

  ModelCallDebug._();

  factory ModelCallDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallDebug()..mergeFromBuffer(data, registry);
  factory ModelCallDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelCallDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelCallDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelCallDebug.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'provider')
    ..aOS(3, _omitFieldNames ? '' : 'model')
    ..aOB(4, _omitFieldNames ? '' : 'queued')
    ..aOS(5, _omitFieldNames ? '' : 'phase')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'sentTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aInt64(7, _omitFieldNames ? '' : 'idleMs')
    ..aInt64(8, _omitFieldNames ? '' : 'watchdogMs')
    ..aInt64(9, _omitFieldNames ? '' : 'bytes')
    ..aInt64(10, _omitFieldNames ? '' : 'streamedTokens')
    ..aInt64(11, _omitFieldNames ? '' : 'promptProcessed')
    ..aInt64(12, _omitFieldNames ? '' : 'promptTotal')
    ..aOS(13, _omitFieldNames ? '' : 'completionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelCallDebug copyWith(void Function(ModelCallDebug) updates) =>
      super.copyWith((message) => updates(message as ModelCallDebug))
          as ModelCallDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelCallDebug() / ModelCallDebug.new instead')
  static ModelCallDebug create() => ModelCallDebug._();
  static $pb.GeneratedMessage $_createMessage() => ModelCallDebug._();
  @$core.override
  ModelCallDebug createEmptyInstance() => ModelCallDebug._();
  @$core.pragma('dart2js:noInline')
  static ModelCallDebug getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelCallDebug>(
          ModelCallDebug.$_createMessage);
  static ModelCallDebug? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

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

  /// Waiting for flit's concurrency limit (not sent yet).
  @$pb.TagNumber(4)
  $core.bool get queued => $_getBF(3);
  @$pb.TagNumber(4)
  set queued($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQueued() => $_has(3);
  @$pb.TagNumber(4)
  void clearQueued() => $_clearField(4);

  /// Where the call is: "connecting", "waiting_for_first_byte",
  /// "processing_prompt", "waiting_for_first_token" or "streaming";
  /// "" while queued.
  @$pb.TagNumber(5)
  $core.String get phase => $_getSZ(4);
  @$pb.TagNumber(5)
  set phase($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPhase() => $_has(4);
  @$pb.TagNumber(5)
  void clearPhase() => $_clearField(5);

  @$pb.TagNumber(6)
  $0.Timestamp get sentTime => $_getN(5);
  @$pb.TagNumber(6)
  set sentTime($0.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSentTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearSentTime() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureSentTime() => $_ensure(5);

  /// Since the last sign of life (bytes, prompt progress), and the
  /// watchdog's limit for the current phase (0: off).
  @$pb.TagNumber(7)
  $fixnum.Int64 get idleMs => $_getI64(6);
  @$pb.TagNumber(7)
  set idleMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIdleMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearIdleMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get watchdogMs => $_getI64(7);
  @$pb.TagNumber(8)
  set watchdogMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWatchdogMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearWatchdogMs() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get bytes => $_getI64(8);
  @$pb.TagNumber(9)
  set bytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearBytes() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get streamedTokens => $_getI64(9);
  @$pb.TagNumber(10)
  set streamedTokens($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasStreamedTokens() => $_has(9);
  @$pb.TagNumber(10)
  void clearStreamedTokens() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get promptProcessed => $_getI64(10);
  @$pb.TagNumber(11)
  set promptProcessed($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPromptProcessed() => $_has(10);
  @$pb.TagNumber(11)
  void clearPromptProcessed() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get promptTotal => $_getI64(11);
  @$pb.TagNumber(12)
  set promptTotal($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPromptTotal() => $_has(11);
  @$pb.TagNumber(12)
  void clearPromptTotal() => $_clearField(12);

  /// The completion id, once the server named it.
  @$pb.TagNumber(13)
  $core.String get completionId => $_getSZ(12);
  @$pb.TagNumber(13)
  set completionId($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCompletionId() => $_has(12);
  @$pb.TagNumber(13)
  void clearCompletionId() => $_clearField(13);
}

/// ModelLimitDebug is one provider and model's concurrency slots.
class ModelLimitDebug extends $pb.GeneratedMessage {
  factory ModelLimitDebug({
    $core.String? provider,
    $core.String? model,
    $core.int? limit,
    $core.int? inUse,
    $core.int? waiting,
  }) {
    final result = ModelLimitDebug._();
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (limit != null) result.limit = limit;
    if (inUse != null) result.inUse = inUse;
    if (waiting != null) result.waiting = waiting;
    return result;
  }

  ModelLimitDebug._();

  factory ModelLimitDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelLimitDebug()..mergeFromBuffer(data, registry);
  factory ModelLimitDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelLimitDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelLimitDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ModelLimitDebug.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..aI(4, _omitFieldNames ? '' : 'inUse')
    ..aI(5, _omitFieldNames ? '' : 'waiting')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelLimitDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelLimitDebug copyWith(void Function(ModelLimitDebug) updates) =>
      super.copyWith((message) => updates(message as ModelLimitDebug))
          as ModelLimitDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelLimitDebug() / ModelLimitDebug.new instead')
  static ModelLimitDebug create() => ModelLimitDebug._();
  static $pb.GeneratedMessage $_createMessage() => ModelLimitDebug._();
  @$core.override
  ModelLimitDebug createEmptyInstance() => ModelLimitDebug._();
  @$core.pragma('dart2js:noInline')
  static ModelLimitDebug getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ModelLimitDebug>(
          ModelLimitDebug.$_createMessage);
  static ModelLimitDebug? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get inUse => $_getIZ(3);
  @$pb.TagNumber(4)
  set inUse($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInUse() => $_has(3);
  @$pb.TagNumber(4)
  void clearInUse() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get waiting => $_getIZ(4);
  @$pb.TagNumber(5)
  set waiting($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWaiting() => $_has(4);
  @$pb.TagNumber(5)
  void clearWaiting() => $_clearField(5);
}

/// SystemService reports on the flit server itself and manages the devices
/// allowed to use it. Every RPC requires a token, even on localhost, except
/// Pair, which takes a pairing code instead.
///
/// There are two kinds of token. The admin token is generated on the
/// server's first run (see "flit token"). Device tokens are issued by Pair,
/// one per device, and can be listed and revoked. Device management RPCs
/// need the admin token; everything else accepts either.
class SystemServiceApi {
  final $pb.RpcClient _client;

  SystemServiceApi(this._client);

  /// Version returns build and API version information for the server.
  $async.Future<VersionResponse> version(
          $pb.ClientContext? ctx, VersionRequest request) =>
      _client.invoke<VersionResponse>(
          ctx, 'SystemService', 'Version', request, VersionResponse());

  /// Health reports whether the server is able to serve requests.
  $async.Future<HealthResponse> health(
          $pb.ClientContext? ctx, HealthRequest request) =>
      _client.invoke<HealthResponse>(
          ctx, 'SystemService', 'Health', request, HealthResponse());

  /// CreatePairingCode returns a short-lived, single-use code a new device
  /// can trade for its own token with Pair. Admin only. "flit pair" calls
  /// this and shows the code as text and as a QR code.
  $async.Future<CreatePairingCodeResponse> createPairingCode(
          $pb.ClientContext? ctx, CreatePairingCodeRequest request) =>
      _client.invoke<CreatePairingCodeResponse>(ctx, 'SystemService',
          'CreatePairingCode', request, CreatePairingCodeResponse());

  /// Pair trades a pairing code for a device token. Needs no token. A code
  /// works once; too many wrong codes invalidate all outstanding codes.
  $async.Future<PairResponse> pair(
          $pb.ClientContext? ctx, PairRequest request) =>
      _client.invoke<PairResponse>(
          ctx, 'SystemService', 'Pair', request, PairResponse());

  /// ListDevices lists paired devices. Admin only.
  $async.Future<ListDevicesResponse> listDevices(
          $pb.ClientContext? ctx, ListDevicesRequest request) =>
      _client.invoke<ListDevicesResponse>(
          ctx, 'SystemService', 'ListDevices', request, ListDevicesResponse());

  /// RevokeDevice revokes a device's token immediately. Admin only.
  $async.Future<RevokeDeviceResponse> revokeDevice(
          $pb.ClientContext? ctx, RevokeDeviceRequest request) =>
      _client.invoke<RevokeDeviceResponse>(ctx, 'SystemService', 'RevokeDevice',
          request, RevokeDeviceResponse());

  /// DebugDump reports what the server is doing right now, for working out
  /// where a frozen turn is stuck: each loaded session's turn, lock and
  /// model call in flight, the model concurrency limits in use, and
  /// optionally every goroutine's stack. Admin only. "flit debug dump"
  /// calls this.
  $async.Future<DebugDumpResponse> debugDump(
          $pb.ClientContext? ctx, DebugDumpRequest request) =>
      _client.invoke<DebugDumpResponse>(
          ctx, 'SystemService', 'DebugDump', request, DebugDumpResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
