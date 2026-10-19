// This is a generated file - do not edit.
//
// Generated from flit/v1/model.proto.

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

import 'model.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'model.pbenum.dart';

class Provider extends $pb.GeneratedMessage {
  factory Provider({
    $core.String? name,
    $core.String? baseUrl,
    ProviderKind? kind,
    $core.int? modelCount,
    $0.Timestamp? refreshTime,
    $core.String? error,
    $core.bool? canLoadModels,
  }) {
    final result = Provider._();
    if (name != null) result.name = name;
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (kind != null) result.kind = kind;
    if (modelCount != null) result.modelCount = modelCount;
    if (refreshTime != null) result.refreshTime = refreshTime;
    if (error != null) result.error = error;
    if (canLoadModels != null) result.canLoadModels = canLoadModels;
    return result;
  }

  Provider._();

  factory Provider.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Provider()..mergeFromBuffer(data, registry);
  factory Provider.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Provider()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Provider',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Provider.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'baseUrl')
    ..aE<ProviderKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: ProviderKind.values)
    ..aI(4, _omitFieldNames ? '' : 'modelCount')
    ..aOM<$0.Timestamp>(5, _omitFieldNames ? '' : 'refreshTime',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aOB(7, _omitFieldNames ? '' : 'canLoadModels')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Provider clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Provider copyWith(void Function(Provider) updates) =>
      super.copyWith((message) => updates(message as Provider)) as Provider;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Provider() / Provider.new instead')
  static Provider create() => Provider._();
  static $pb.GeneratedMessage $_createMessage() => Provider._();
  @$core.override
  Provider createEmptyInstance() => Provider._();
  @$core.pragma('dart2js:noInline')
  static Provider getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Provider>(Provider.$_createMessage);
  static Provider? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get baseUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set baseUrl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBaseUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearBaseUrl() => $_clearField(2);

  /// The kind discovery detected or the config set.
  @$pb.TagNumber(3)
  ProviderKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(ProviderKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get modelCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set modelCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasModelCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearModelCount() => $_clearField(4);

  /// When discovery last finished, and its error if it failed.
  @$pb.TagNumber(5)
  $0.Timestamp get refreshTime => $_getN(4);
  @$pb.TagNumber(5)
  set refreshTime($0.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRefreshTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearRefreshTime() => $_clearField(5);
  @$pb.TagNumber(5)
  $0.Timestamp ensureRefreshTime() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  /// Whether flit can load and unload this provider's models (a llama.cpp
  /// router).
  @$pb.TagNumber(7)
  $core.bool get canLoadModels => $_getBF(6);
  @$pb.TagNumber(7)
  set canLoadModels($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCanLoadModels() => $_has(6);
  @$pb.TagNumber(7)
  void clearCanLoadModels() => $_clearField(7);
}

class Model extends $pb.GeneratedMessage {
  factory Model({
    $core.String? provider,
    $core.String? id,
    $core.String? displayName,
    $fixnum.Int64? contextLength,
    $core.bool? supportsTools,
    $core.bool? supportsReasoning,
    $core.bool? supportsVision,
    $core.Iterable<$core.String>? efforts,
    $core.bool? loaded,
    $core.bool? discovered,
    $core.bool? overridden,
    $core.bool? favorite,
    $0.Timestamp? lastUsed,
    ModelState? state,
  }) {
    final result = Model._();
    if (provider != null) result.provider = provider;
    if (id != null) result.id = id;
    if (displayName != null) result.displayName = displayName;
    if (contextLength != null) result.contextLength = contextLength;
    if (supportsTools != null) result.supportsTools = supportsTools;
    if (supportsReasoning != null) result.supportsReasoning = supportsReasoning;
    if (supportsVision != null) result.supportsVision = supportsVision;
    if (efforts != null) result.efforts.addAll(efforts);
    if (loaded != null) result.loaded = loaded;
    if (discovered != null) result.discovered = discovered;
    if (overridden != null) result.overridden = overridden;
    if (favorite != null) result.favorite = favorite;
    if (lastUsed != null) result.lastUsed = lastUsed;
    if (state != null) result.state = state;
    return result;
  }

  Model._();

  factory Model.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Model()..mergeFromBuffer(data, registry);
  factory Model.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Model()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Model',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: Model.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aInt64(4, _omitFieldNames ? '' : 'contextLength')
    ..aOB(5, _omitFieldNames ? '' : 'supportsTools')
    ..aOB(6, _omitFieldNames ? '' : 'supportsReasoning')
    ..aOB(7, _omitFieldNames ? '' : 'supportsVision')
    ..pPS(8, _omitFieldNames ? '' : 'efforts')
    ..aOB(9, _omitFieldNames ? '' : 'loaded')
    ..aOB(10, _omitFieldNames ? '' : 'discovered')
    ..aOB(11, _omitFieldNames ? '' : 'overridden')
    ..aOB(12, _omitFieldNames ? '' : 'favorite')
    ..aOM<$0.Timestamp>(13, _omitFieldNames ? '' : 'lastUsed',
        subBuilder: $0.Timestamp.$_createMessage)
    ..aE<ModelState>(14, _omitFieldNames ? '' : 'state',
        enumValues: ModelState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Model clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Model copyWith(void Function(Model) updates) =>
      super.copyWith((message) => updates(message as Model)) as Model;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Model() / Model.new instead')
  static Model create() => Model._();
  static $pb.GeneratedMessage $_createMessage() => Model._();
  @$core.override
  Model createEmptyInstance() => Model._();
  @$core.pragma('dart2js:noInline')
  static Model getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Model>(Model.$_createMessage);
  static Model? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get provider => $_getSZ(0);
  @$pb.TagNumber(1)
  set provider($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// Context window in tokens; 0 if unknown.
  @$pb.TagNumber(4)
  $fixnum.Int64 get contextLength => $_getI64(3);
  @$pb.TagNumber(4)
  set contextLength($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContextLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearContextLength() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get supportsTools => $_getBF(4);
  @$pb.TagNumber(5)
  set supportsTools($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSupportsTools() => $_has(4);
  @$pb.TagNumber(5)
  void clearSupportsTools() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get supportsReasoning => $_getBF(5);
  @$pb.TagNumber(6)
  set supportsReasoning($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSupportsReasoning() => $_has(5);
  @$pb.TagNumber(6)
  void clearSupportsReasoning() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get supportsVision => $_getBF(6);
  @$pb.TagNumber(7)
  set supportsVision($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSupportsVision() => $_has(6);
  @$pb.TagNumber(7)
  void clearSupportsVision() => $_clearField(7);

  /// Reasoning effort levels the model accepts, e.g. ["low","medium","high"].
  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get efforts => $_getList(7);

  /// llama.cpp router: whether the model is loaded right now.
  @$pb.TagNumber(9)
  $core.bool get loaded => $_getBF(8);
  @$pb.TagNumber(9)
  set loaded($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLoaded() => $_has(8);
  @$pb.TagNumber(9)
  void clearLoaded() => $_clearField(9);

  /// Whether discovery found it and whether the override file touched it.
  @$pb.TagNumber(10)
  $core.bool get discovered => $_getBF(9);
  @$pb.TagNumber(10)
  set discovered($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDiscovered() => $_has(9);
  @$pb.TagNumber(10)
  void clearDiscovered() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.bool get overridden => $_getBF(10);
  @$pb.TagNumber(11)
  set overridden($core.bool value) => $_setBool(10, value);
  @$pb.TagNumber(11)
  $core.bool hasOverridden() => $_has(10);
  @$pb.TagNumber(11)
  void clearOverridden() => $_clearField(11);

  /// Starred (SetFavorite).
  @$pb.TagNumber(12)
  $core.bool get favorite => $_getBF(11);
  @$pb.TagNumber(12)
  set favorite($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasFavorite() => $_has(11);
  @$pb.TagNumber(12)
  void clearFavorite() => $_clearField(12);

  /// When a session last used it (set its model, or ran a turn on it);
  /// unset if never.
  @$pb.TagNumber(13)
  $0.Timestamp get lastUsed => $_getN(12);
  @$pb.TagNumber(13)
  set lastUsed($0.Timestamp value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasLastUsed() => $_has(12);
  @$pb.TagNumber(13)
  void clearLastUsed() => $_clearField(13);
  @$pb.TagNumber(13)
  $0.Timestamp ensureLastUsed() => $_ensure(12);

  @$pb.TagNumber(14)
  ModelState get state => $_getN(13);
  @$pb.TagNumber(14)
  set state(ModelState value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasState() => $_has(13);
  @$pb.TagNumber(14)
  void clearState() => $_clearField(14);
}

class ListProvidersRequest extends $pb.GeneratedMessage {
  factory ListProvidersRequest() => ListProvidersRequest._();

  ListProvidersRequest._();

  factory ListProvidersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProvidersRequest()..mergeFromBuffer(data, registry);
  factory ListProvidersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProvidersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProvidersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListProvidersRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProvidersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProvidersRequest copyWith(void Function(ListProvidersRequest) updates) =>
      super.copyWith((message) => updates(message as ListProvidersRequest))
          as ListProvidersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListProvidersRequest() / ListProvidersRequest.new instead')
  static ListProvidersRequest create() => ListProvidersRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListProvidersRequest._();
  @$core.override
  ListProvidersRequest createEmptyInstance() => ListProvidersRequest._();
  @$core.pragma('dart2js:noInline')
  static ListProvidersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProvidersRequest>(
          ListProvidersRequest.$_createMessage);
  static ListProvidersRequest? _defaultInstance;
}

class ListProvidersResponse extends $pb.GeneratedMessage {
  factory ListProvidersResponse({
    $core.Iterable<Provider>? providers,
  }) {
    final result = ListProvidersResponse._();
    if (providers != null) result.providers.addAll(providers);
    return result;
  }

  ListProvidersResponse._();

  factory ListProvidersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProvidersResponse()..mergeFromBuffer(data, registry);
  factory ListProvidersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListProvidersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListProvidersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListProvidersResponse.$_createMessage)
    ..pPM<Provider>(1, _omitFieldNames ? '' : 'providers',
        subBuilder: Provider.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProvidersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListProvidersResponse copyWith(
          void Function(ListProvidersResponse) updates) =>
      super.copyWith((message) => updates(message as ListProvidersResponse))
          as ListProvidersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListProvidersResponse() / ListProvidersResponse.new instead')
  static ListProvidersResponse create() => ListProvidersResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListProvidersResponse._();
  @$core.override
  ListProvidersResponse createEmptyInstance() => ListProvidersResponse._();
  @$core.pragma('dart2js:noInline')
  static ListProvidersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListProvidersResponse>(
          ListProvidersResponse.$_createMessage);
  static ListProvidersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Provider> get providers => $_getList(0);
}

class ListModelsRequest extends $pb.GeneratedMessage {
  factory ListModelsRequest({
    $core.String? provider,
  }) {
    final result = ListModelsRequest._();
    if (provider != null) result.provider = provider;
    return result;
  }

  ListModelsRequest._();

  factory ListModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsRequest()..mergeFromBuffer(data, registry);
  factory ListModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListModelsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest copyWith(void Function(ListModelsRequest) updates) =>
      super.copyWith((message) => updates(message as ListModelsRequest))
          as ListModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListModelsRequest() / ListModelsRequest.new instead')
  static ListModelsRequest create() => ListModelsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListModelsRequest._();
  @$core.override
  ListModelsRequest createEmptyInstance() => ListModelsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListModelsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListModelsRequest>(
          ListModelsRequest.$_createMessage);
  static ListModelsRequest? _defaultInstance;

  /// Empty means all providers.
  @$pb.TagNumber(1)
  $core.String get provider => $_getSZ(0);
  @$pb.TagNumber(1)
  set provider($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);
}

class ListModelsResponse extends $pb.GeneratedMessage {
  factory ListModelsResponse({
    $core.Iterable<Model>? models,
  }) {
    final result = ListModelsResponse._();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListModelsResponse._();

  factory ListModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsResponse()..mergeFromBuffer(data, registry);
  factory ListModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListModelsResponse.$_createMessage)
    ..pPM<Model>(1, _omitFieldNames ? '' : 'models',
        subBuilder: Model.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse copyWith(void Function(ListModelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListModelsResponse))
          as ListModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListModelsResponse() / ListModelsResponse.new instead')
  static ListModelsResponse create() => ListModelsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListModelsResponse._();
  @$core.override
  ListModelsResponse createEmptyInstance() => ListModelsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModelsResponse>(
          ListModelsResponse.$_createMessage);
  static ListModelsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Model> get models => $_getList(0);
}

class RefreshRequest extends $pb.GeneratedMessage {
  factory RefreshRequest({
    $core.String? provider,
  }) {
    final result = RefreshRequest._();
    if (provider != null) result.provider = provider;
    return result;
  }

  RefreshRequest._();

  factory RefreshRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshRequest()..mergeFromBuffer(data, registry);
  factory RefreshRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RefreshRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshRequest copyWith(void Function(RefreshRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshRequest))
          as RefreshRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RefreshRequest() / RefreshRequest.new instead')
  static RefreshRequest create() => RefreshRequest._();
  static $pb.GeneratedMessage $_createMessage() => RefreshRequest._();
  @$core.override
  RefreshRequest createEmptyInstance() => RefreshRequest._();
  @$core.pragma('dart2js:noInline')
  static RefreshRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshRequest>(
          RefreshRequest.$_createMessage);
  static RefreshRequest? _defaultInstance;

  /// Empty means all providers.
  @$pb.TagNumber(1)
  $core.String get provider => $_getSZ(0);
  @$pb.TagNumber(1)
  set provider($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProvider() => $_has(0);
  @$pb.TagNumber(1)
  void clearProvider() => $_clearField(1);
}

class RefreshResponse extends $pb.GeneratedMessage {
  factory RefreshResponse({
    $core.Iterable<Provider>? providers,
  }) {
    final result = RefreshResponse._();
    if (providers != null) result.providers.addAll(providers);
    return result;
  }

  RefreshResponse._();

  factory RefreshResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshResponse()..mergeFromBuffer(data, registry);
  factory RefreshResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RefreshResponse.$_createMessage)
    ..pPM<Provider>(1, _omitFieldNames ? '' : 'providers',
        subBuilder: Provider.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshResponse copyWith(void Function(RefreshResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshResponse))
          as RefreshResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RefreshResponse() / RefreshResponse.new instead')
  static RefreshResponse create() => RefreshResponse._();
  static $pb.GeneratedMessage $_createMessage() => RefreshResponse._();
  @$core.override
  RefreshResponse createEmptyInstance() => RefreshResponse._();
  @$core.pragma('dart2js:noInline')
  static RefreshResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshResponse>(
          RefreshResponse.$_createMessage);
  static RefreshResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Provider> get providers => $_getList(0);
}

class SetFavoriteRequest extends $pb.GeneratedMessage {
  factory SetFavoriteRequest({
    $core.String? provider,
    $core.String? model,
    $core.bool? favorite,
  }) {
    final result = SetFavoriteRequest._();
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (favorite != null) result.favorite = favorite;
    return result;
  }

  SetFavoriteRequest._();

  factory SetFavoriteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFavoriteRequest()..mergeFromBuffer(data, registry);
  factory SetFavoriteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFavoriteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetFavoriteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetFavoriteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..aOB(3, _omitFieldNames ? '' : 'favorite')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFavoriteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFavoriteRequest copyWith(void Function(SetFavoriteRequest) updates) =>
      super.copyWith((message) => updates(message as SetFavoriteRequest))
          as SetFavoriteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetFavoriteRequest() / SetFavoriteRequest.new instead')
  static SetFavoriteRequest create() => SetFavoriteRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetFavoriteRequest._();
  @$core.override
  SetFavoriteRequest createEmptyInstance() => SetFavoriteRequest._();
  @$core.pragma('dart2js:noInline')
  static SetFavoriteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetFavoriteRequest>(
          SetFavoriteRequest.$_createMessage);
  static SetFavoriteRequest? _defaultInstance;

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
  $core.bool get favorite => $_getBF(2);
  @$pb.TagNumber(3)
  set favorite($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFavorite() => $_has(2);
  @$pb.TagNumber(3)
  void clearFavorite() => $_clearField(3);
}

class SetFavoriteResponse extends $pb.GeneratedMessage {
  factory SetFavoriteResponse() => SetFavoriteResponse._();

  SetFavoriteResponse._();

  factory SetFavoriteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFavoriteResponse()..mergeFromBuffer(data, registry);
  factory SetFavoriteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetFavoriteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetFavoriteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: SetFavoriteResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFavoriteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetFavoriteResponse copyWith(void Function(SetFavoriteResponse) updates) =>
      super.copyWith((message) => updates(message as SetFavoriteResponse))
          as SetFavoriteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SetFavoriteResponse() / SetFavoriteResponse.new instead')
  static SetFavoriteResponse create() => SetFavoriteResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetFavoriteResponse._();
  @$core.override
  SetFavoriteResponse createEmptyInstance() => SetFavoriteResponse._();
  @$core.pragma('dart2js:noInline')
  static SetFavoriteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetFavoriteResponse>(
          SetFavoriteResponse.$_createMessage);
  static SetFavoriteResponse? _defaultInstance;
}

class LoadModelRequest extends $pb.GeneratedMessage {
  factory LoadModelRequest({
    $core.String? provider,
    $core.String? model,
  }) {
    final result = LoadModelRequest._();
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  LoadModelRequest._();

  factory LoadModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoadModelRequest()..mergeFromBuffer(data, registry);
  factory LoadModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoadModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: LoadModelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelRequest copyWith(void Function(LoadModelRequest) updates) =>
      super.copyWith((message) => updates(message as LoadModelRequest))
          as LoadModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoadModelRequest() / LoadModelRequest.new instead')
  static LoadModelRequest create() => LoadModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => LoadModelRequest._();
  @$core.override
  LoadModelRequest createEmptyInstance() => LoadModelRequest._();
  @$core.pragma('dart2js:noInline')
  static LoadModelRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoadModelRequest>(
          LoadModelRequest.$_createMessage);
  static LoadModelRequest? _defaultInstance;

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
}

class LoadModelResponse extends $pb.GeneratedMessage {
  factory LoadModelResponse({
    Model? model,
  }) {
    final result = LoadModelResponse._();
    if (model != null) result.model = model;
    return result;
  }

  LoadModelResponse._();

  factory LoadModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoadModelResponse()..mergeFromBuffer(data, registry);
  factory LoadModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoadModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoadModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: LoadModelResponse.$_createMessage)
    ..aOM<Model>(1, _omitFieldNames ? '' : 'model',
        subBuilder: Model.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoadModelResponse copyWith(void Function(LoadModelResponse) updates) =>
      super.copyWith((message) => updates(message as LoadModelResponse))
          as LoadModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoadModelResponse() / LoadModelResponse.new instead')
  static LoadModelResponse create() => LoadModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => LoadModelResponse._();
  @$core.override
  LoadModelResponse createEmptyInstance() => LoadModelResponse._();
  @$core.pragma('dart2js:noInline')
  static LoadModelResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoadModelResponse>(
          LoadModelResponse.$_createMessage);
  static LoadModelResponse? _defaultInstance;

  /// The model as it is after the provider was refreshed.
  @$pb.TagNumber(1)
  Model get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(Model value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  Model ensureModel() => $_ensure(0);
}

class UnloadModelRequest extends $pb.GeneratedMessage {
  factory UnloadModelRequest({
    $core.String? provider,
    $core.String? model,
  }) {
    final result = UnloadModelRequest._();
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  UnloadModelRequest._();

  factory UnloadModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnloadModelRequest()..mergeFromBuffer(data, registry);
  factory UnloadModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnloadModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnloadModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: UnloadModelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'provider')
    ..aOS(2, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnloadModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnloadModelRequest copyWith(void Function(UnloadModelRequest) updates) =>
      super.copyWith((message) => updates(message as UnloadModelRequest))
          as UnloadModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UnloadModelRequest() / UnloadModelRequest.new instead')
  static UnloadModelRequest create() => UnloadModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnloadModelRequest._();
  @$core.override
  UnloadModelRequest createEmptyInstance() => UnloadModelRequest._();
  @$core.pragma('dart2js:noInline')
  static UnloadModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnloadModelRequest>(
          UnloadModelRequest.$_createMessage);
  static UnloadModelRequest? _defaultInstance;

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
}

class UnloadModelResponse extends $pb.GeneratedMessage {
  factory UnloadModelResponse({
    Model? model,
  }) {
    final result = UnloadModelResponse._();
    if (model != null) result.model = model;
    return result;
  }

  UnloadModelResponse._();

  factory UnloadModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnloadModelResponse()..mergeFromBuffer(data, registry);
  factory UnloadModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnloadModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnloadModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: UnloadModelResponse.$_createMessage)
    ..aOM<Model>(1, _omitFieldNames ? '' : 'model',
        subBuilder: Model.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnloadModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnloadModelResponse copyWith(void Function(UnloadModelResponse) updates) =>
      super.copyWith((message) => updates(message as UnloadModelResponse))
          as UnloadModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use UnloadModelResponse() / UnloadModelResponse.new instead')
  static UnloadModelResponse create() => UnloadModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => UnloadModelResponse._();
  @$core.override
  UnloadModelResponse createEmptyInstance() => UnloadModelResponse._();
  @$core.pragma('dart2js:noInline')
  static UnloadModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnloadModelResponse>(
          UnloadModelResponse.$_createMessage);
  static UnloadModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Model get model => $_getN(0);
  @$pb.TagNumber(1)
  set model(Model value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);
  @$pb.TagNumber(1)
  Model ensureModel() => $_ensure(0);
}

/// ModelService lists the models flit can use. Models are discovered from
/// each configured provider's /models endpoint (there is no built-in model
/// database) and can be corrected or filled in by a YAML override file.
/// Discovery runs when the server starts and on Refresh.
class ModelServiceApi {
  final $pb.RpcClient _client;

  ModelServiceApi(this._client);

  /// ListProviders lists the configured providers and how discovery went.
  $async.Future<ListProvidersResponse> listProviders(
          $pb.ClientContext? ctx, ListProvidersRequest request) =>
      _client.invoke<ListProvidersResponse>(ctx, 'ModelService',
          'ListProviders', request, ListProvidersResponse());

  /// ListModels lists the discovered models, optionally for one provider.
  $async.Future<ListModelsResponse> listModels(
          $pb.ClientContext? ctx, ListModelsRequest request) =>
      _client.invoke<ListModelsResponse>(
          ctx, 'ModelService', 'ListModels', request, ListModelsResponse());

  /// Refresh re-runs discovery (and re-reads the override file).
  $async.Future<RefreshResponse> refresh(
          $pb.ClientContext? ctx, RefreshRequest request) =>
      _client.invoke<RefreshResponse>(
          ctx, 'ModelService', 'Refresh', request, RefreshResponse());

  /// SetFavorite stars or unstars a model. Favorites (and recently used
  /// models) are kept on the server, so every device sees the same ones.
  $async.Future<SetFavoriteResponse> setFavorite(
          $pb.ClientContext? ctx, SetFavoriteRequest request) =>
      _client.invoke<SetFavoriteResponse>(
          ctx, 'ModelService', 'SetFavorite', request, SetFavoriteResponse());

  /// LoadModel and UnloadModel ask a llama.cpp router (Provider
  /// can_load_models) to load or unload a model, then refresh that
  /// provider. Other providers return FAILED_PRECONDITION.
  $async.Future<LoadModelResponse> loadModel(
          $pb.ClientContext? ctx, LoadModelRequest request) =>
      _client.invoke<LoadModelResponse>(
          ctx, 'ModelService', 'LoadModel', request, LoadModelResponse());
  $async.Future<UnloadModelResponse> unloadModel(
          $pb.ClientContext? ctx, UnloadModelRequest request) =>
      _client.invoke<UnloadModelResponse>(
          ctx, 'ModelService', 'UnloadModel', request, UnloadModelResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
