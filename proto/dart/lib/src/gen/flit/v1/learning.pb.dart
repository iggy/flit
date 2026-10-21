// This is a generated file - do not edit.
//
// Generated from flit/v1/learning.proto.

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

import 'learning.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'learning.pbenum.dart';

class LearnProposal extends $pb.GeneratedMessage {
  factory LearnProposal({
    $core.String? id,
    $core.String? sessionId,
    $core.String? projectId,
    LearnAction? action,
    LearnTarget? target,
    $core.String? skill,
    $core.String? cue,
    $core.String? lesson,
    $core.String? evidence,
    $core.String? oldText,
    $core.String? newText,
    $core.String? path,
    $core.String? provider,
    $core.String? model,
    LearnStatus? status,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? decidedAtMs,
  }) {
    final result = LearnProposal._();
    if (id != null) result.id = id;
    if (sessionId != null) result.sessionId = sessionId;
    if (projectId != null) result.projectId = projectId;
    if (action != null) result.action = action;
    if (target != null) result.target = target;
    if (skill != null) result.skill = skill;
    if (cue != null) result.cue = cue;
    if (lesson != null) result.lesson = lesson;
    if (evidence != null) result.evidence = evidence;
    if (oldText != null) result.oldText = oldText;
    if (newText != null) result.newText = newText;
    if (path != null) result.path = path;
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    if (status != null) result.status = status;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (decidedAtMs != null) result.decidedAtMs = decidedAtMs;
    return result;
  }

  LearnProposal._();

  factory LearnProposal.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnProposal()..mergeFromBuffer(data, registry);
  factory LearnProposal.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnProposal()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LearnProposal',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: LearnProposal.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOS(3, _omitFieldNames ? '' : 'projectId')
    ..aE<LearnAction>(4, _omitFieldNames ? '' : 'action',
        enumValues: LearnAction.values)
    ..aE<LearnTarget>(5, _omitFieldNames ? '' : 'target',
        enumValues: LearnTarget.values)
    ..aOS(6, _omitFieldNames ? '' : 'skill')
    ..aOS(7, _omitFieldNames ? '' : 'cue')
    ..aOS(8, _omitFieldNames ? '' : 'lesson')
    ..aOS(9, _omitFieldNames ? '' : 'evidence')
    ..aOS(10, _omitFieldNames ? '' : 'oldText')
    ..aOS(11, _omitFieldNames ? '' : 'newText')
    ..aOS(12, _omitFieldNames ? '' : 'path')
    ..aOS(13, _omitFieldNames ? '' : 'provider')
    ..aOS(14, _omitFieldNames ? '' : 'model')
    ..aE<LearnStatus>(15, _omitFieldNames ? '' : 'status',
        enumValues: LearnStatus.values)
    ..aInt64(16, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(17, _omitFieldNames ? '' : 'decidedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnProposal clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnProposal copyWith(void Function(LearnProposal) updates) =>
      super.copyWith((message) => updates(message as LearnProposal))
          as LearnProposal;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LearnProposal() / LearnProposal.new instead')
  static LearnProposal create() => LearnProposal._();
  static $pb.GeneratedMessage $_createMessage() => LearnProposal._();
  @$core.override
  LearnProposal createEmptyInstance() => LearnProposal._();
  @$core.pragma('dart2js:noInline')
  static LearnProposal getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LearnProposal>(
          LearnProposal.$_createMessage);
  static LearnProposal? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get projectId => $_getSZ(2);
  @$pb.TagNumber(3)
  set projectId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProjectId() => $_has(2);
  @$pb.TagNumber(3)
  void clearProjectId() => $_clearField(3);

  @$pb.TagNumber(4)
  LearnAction get action => $_getN(3);
  @$pb.TagNumber(4)
  set action(LearnAction value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAction() => $_has(3);
  @$pb.TagNumber(4)
  void clearAction() => $_clearField(4);

  @$pb.TagNumber(5)
  LearnTarget get target => $_getN(4);
  @$pb.TagNumber(5)
  set target(LearnTarget value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTarget() => $_has(4);
  @$pb.TagNumber(5)
  void clearTarget() => $_clearField(5);

  /// The skill's name, for LEARN_TARGET_SKILL.
  @$pb.TagNumber(6)
  $core.String get skill => $_getSZ(5);
  @$pb.TagNumber(6)
  set skill($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSkill() => $_has(5);
  @$pb.TagNumber(6)
  void clearSkill() => $_clearField(6);

  /// The lesson as the model gave it: when it applies, what to do, and the
  /// turns it comes from ("T2, T5").
  @$pb.TagNumber(7)
  $core.String get cue => $_getSZ(6);
  @$pb.TagNumber(7)
  set cue($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCue() => $_has(6);
  @$pb.TagNumber(7)
  void clearCue() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get lesson => $_getSZ(7);
  @$pb.TagNumber(8)
  set lesson($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLesson() => $_has(7);
  @$pb.TagNumber(8)
  void clearLesson() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get evidence => $_getSZ(8);
  @$pb.TagNumber(9)
  set evidence($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasEvidence() => $_has(8);
  @$pb.TagNumber(9)
  void clearEvidence() => $_clearField(9);

  /// The memory entry or SKILL.md being updated or removed; empty for add.
  @$pb.TagNumber(10)
  $core.String get oldText => $_getSZ(9);
  @$pb.TagNumber(10)
  set oldText($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOldText() => $_has(9);
  @$pb.TagNumber(10)
  void clearOldText() => $_clearField(10);

  /// What will be written: a Markdown list item, or a whole SKILL.md.
  /// Empty for remove. Once accepted, what was written.
  @$pb.TagNumber(11)
  $core.String get newText => $_getSZ(10);
  @$pb.TagNumber(11)
  set newText($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasNewText() => $_has(10);
  @$pb.TagNumber(11)
  void clearNewText() => $_clearField(11);

  /// The file the change goes to.
  @$pb.TagNumber(12)
  $core.String get path => $_getSZ(11);
  @$pb.TagNumber(12)
  set path($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPath() => $_has(11);
  @$pb.TagNumber(12)
  void clearPath() => $_clearField(12);

  /// The model that proposed it.
  @$pb.TagNumber(13)
  $core.String get provider => $_getSZ(12);
  @$pb.TagNumber(13)
  set provider($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasProvider() => $_has(12);
  @$pb.TagNumber(13)
  void clearProvider() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get model => $_getSZ(13);
  @$pb.TagNumber(14)
  set model($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasModel() => $_has(13);
  @$pb.TagNumber(14)
  void clearModel() => $_clearField(14);

  @$pb.TagNumber(15)
  LearnStatus get status => $_getN(14);
  @$pb.TagNumber(15)
  set status(LearnStatus value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasStatus() => $_has(14);
  @$pb.TagNumber(15)
  void clearStatus() => $_clearField(15);

  @$pb.TagNumber(16)
  $fixnum.Int64 get createdAtMs => $_getI64(15);
  @$pb.TagNumber(16)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCreatedAtMs() => $_has(15);
  @$pb.TagNumber(16)
  void clearCreatedAtMs() => $_clearField(16);

  /// 0 while pending.
  @$pb.TagNumber(17)
  $fixnum.Int64 get decidedAtMs => $_getI64(16);
  @$pb.TagNumber(17)
  set decidedAtMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasDecidedAtMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearDecidedAtMs() => $_clearField(17);
}

class LearnRequest extends $pb.GeneratedMessage {
  factory LearnRequest({
    $core.String? sessionId,
  }) {
    final result = LearnRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  LearnRequest._();

  factory LearnRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnRequest()..mergeFromBuffer(data, registry);
  factory LearnRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LearnRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: LearnRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnRequest copyWith(void Function(LearnRequest) updates) =>
      super.copyWith((message) => updates(message as LearnRequest))
          as LearnRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LearnRequest() / LearnRequest.new instead')
  static LearnRequest create() => LearnRequest._();
  static $pb.GeneratedMessage $_createMessage() => LearnRequest._();
  @$core.override
  LearnRequest createEmptyInstance() => LearnRequest._();
  @$core.pragma('dart2js:noInline')
  static LearnRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LearnRequest>(
          LearnRequest.$_createMessage);
  static LearnRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class LearnResponse extends $pb.GeneratedMessage {
  factory LearnResponse({
    $core.Iterable<LearnProposal>? proposals,
    $core.Iterable<$core.String>? dropped,
    $core.String? provider,
    $core.String? model,
  }) {
    final result = LearnResponse._();
    if (proposals != null) result.proposals.addAll(proposals);
    if (dropped != null) result.dropped.addAll(dropped);
    if (provider != null) result.provider = provider;
    if (model != null) result.model = model;
    return result;
  }

  LearnResponse._();

  factory LearnResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnResponse()..mergeFromBuffer(data, registry);
  factory LearnResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LearnResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LearnResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: LearnResponse.$_createMessage)
    ..pPM<LearnProposal>(1, _omitFieldNames ? '' : 'proposals',
        subBuilder: LearnProposal.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'dropped')
    ..aOS(3, _omitFieldNames ? '' : 'provider')
    ..aOS(4, _omitFieldNames ? '' : 'model')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LearnResponse copyWith(void Function(LearnResponse) updates) =>
      super.copyWith((message) => updates(message as LearnResponse))
          as LearnResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LearnResponse() / LearnResponse.new instead')
  static LearnResponse create() => LearnResponse._();
  static $pb.GeneratedMessage $_createMessage() => LearnResponse._();
  @$core.override
  LearnResponse createEmptyInstance() => LearnResponse._();
  @$core.pragma('dart2js:noInline')
  static LearnResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LearnResponse>(
          LearnResponse.$_createMessage);
  static LearnResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LearnProposal> get proposals => $_getList(0);

  /// Why proposals the model made were left out (invalid, duplicates, ...).
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get dropped => $_getList(1);

  /// The model that ran the pass.
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

class ListLearnProposalsRequest extends $pb.GeneratedMessage {
  factory ListLearnProposalsRequest({
    $core.String? sessionId,
    $core.bool? includeDecided,
  }) {
    final result = ListLearnProposalsRequest._();
    if (sessionId != null) result.sessionId = sessionId;
    if (includeDecided != null) result.includeDecided = includeDecided;
    return result;
  }

  ListLearnProposalsRequest._();

  factory ListLearnProposalsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListLearnProposalsRequest()..mergeFromBuffer(data, registry);
  factory ListLearnProposalsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListLearnProposalsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListLearnProposalsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListLearnProposalsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aOB(2, _omitFieldNames ? '' : 'includeDecided')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListLearnProposalsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListLearnProposalsRequest copyWith(
          void Function(ListLearnProposalsRequest) updates) =>
      super.copyWith((message) => updates(message as ListLearnProposalsRequest))
          as ListLearnProposalsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListLearnProposalsRequest() / ListLearnProposalsRequest.new instead')
  static ListLearnProposalsRequest create() => ListLearnProposalsRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListLearnProposalsRequest._();
  @$core.override
  ListLearnProposalsRequest createEmptyInstance() =>
      ListLearnProposalsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListLearnProposalsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListLearnProposalsRequest>(
          ListLearnProposalsRequest.$_createMessage);
  static ListLearnProposalsRequest? _defaultInstance;

  /// Empty means every session's.
  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  /// Include accepted and rejected ones.
  @$pb.TagNumber(2)
  $core.bool get includeDecided => $_getBF(1);
  @$pb.TagNumber(2)
  set includeDecided($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIncludeDecided() => $_has(1);
  @$pb.TagNumber(2)
  void clearIncludeDecided() => $_clearField(2);
}

class ListLearnProposalsResponse extends $pb.GeneratedMessage {
  factory ListLearnProposalsResponse({
    $core.Iterable<LearnProposal>? proposals,
  }) {
    final result = ListLearnProposalsResponse._();
    if (proposals != null) result.proposals.addAll(proposals);
    return result;
  }

  ListLearnProposalsResponse._();

  factory ListLearnProposalsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListLearnProposalsResponse()..mergeFromBuffer(data, registry);
  factory ListLearnProposalsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListLearnProposalsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListLearnProposalsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: ListLearnProposalsResponse.$_createMessage)
    ..pPM<LearnProposal>(1, _omitFieldNames ? '' : 'proposals',
        subBuilder: LearnProposal.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListLearnProposalsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListLearnProposalsResponse copyWith(
          void Function(ListLearnProposalsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListLearnProposalsResponse))
          as ListLearnProposalsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListLearnProposalsResponse() / ListLearnProposalsResponse.new instead')
  static ListLearnProposalsResponse create() => ListLearnProposalsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListLearnProposalsResponse._();
  @$core.override
  ListLearnProposalsResponse createEmptyInstance() =>
      ListLearnProposalsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListLearnProposalsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListLearnProposalsResponse>(
          ListLearnProposalsResponse.$_createMessage);
  static ListLearnProposalsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LearnProposal> get proposals => $_getList(0);
}

class AcceptLearnProposalRequest extends $pb.GeneratedMessage {
  factory AcceptLearnProposalRequest({
    $core.String? id,
    $core.String? text,
  }) {
    final result = AcceptLearnProposalRequest._();
    if (id != null) result.id = id;
    if (text != null) result.text = text;
    return result;
  }

  AcceptLearnProposalRequest._();

  factory AcceptLearnProposalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcceptLearnProposalRequest()..mergeFromBuffer(data, registry);
  factory AcceptLearnProposalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcceptLearnProposalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcceptLearnProposalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AcceptLearnProposalRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptLearnProposalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptLearnProposalRequest copyWith(
          void Function(AcceptLearnProposalRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AcceptLearnProposalRequest))
          as AcceptLearnProposalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AcceptLearnProposalRequest() / AcceptLearnProposalRequest.new instead')
  static AcceptLearnProposalRequest create() => AcceptLearnProposalRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      AcceptLearnProposalRequest._();
  @$core.override
  AcceptLearnProposalRequest createEmptyInstance() =>
      AcceptLearnProposalRequest._();
  @$core.pragma('dart2js:noInline')
  static AcceptLearnProposalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcceptLearnProposalRequest>(
          AcceptLearnProposalRequest.$_createMessage);
  static AcceptLearnProposalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Replaces the proposal's new_text when set.
  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class AcceptLearnProposalResponse extends $pb.GeneratedMessage {
  factory AcceptLearnProposalResponse({
    LearnProposal? proposal,
  }) {
    final result = AcceptLearnProposalResponse._();
    if (proposal != null) result.proposal = proposal;
    return result;
  }

  AcceptLearnProposalResponse._();

  factory AcceptLearnProposalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcceptLearnProposalResponse()..mergeFromBuffer(data, registry);
  factory AcceptLearnProposalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcceptLearnProposalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcceptLearnProposalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: AcceptLearnProposalResponse.$_createMessage)
    ..aOM<LearnProposal>(1, _omitFieldNames ? '' : 'proposal',
        subBuilder: LearnProposal.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptLearnProposalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcceptLearnProposalResponse copyWith(
          void Function(AcceptLearnProposalResponse) updates) =>
      super.copyWith(
              (message) => updates(message as AcceptLearnProposalResponse))
          as AcceptLearnProposalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AcceptLearnProposalResponse() / AcceptLearnProposalResponse.new instead')
  static AcceptLearnProposalResponse create() =>
      AcceptLearnProposalResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      AcceptLearnProposalResponse._();
  @$core.override
  AcceptLearnProposalResponse createEmptyInstance() =>
      AcceptLearnProposalResponse._();
  @$core.pragma('dart2js:noInline')
  static AcceptLearnProposalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcceptLearnProposalResponse>(
          AcceptLearnProposalResponse.$_createMessage);
  static AcceptLearnProposalResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LearnProposal get proposal => $_getN(0);
  @$pb.TagNumber(1)
  set proposal(LearnProposal value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProposal() => $_has(0);
  @$pb.TagNumber(1)
  void clearProposal() => $_clearField(1);
  @$pb.TagNumber(1)
  LearnProposal ensureProposal() => $_ensure(0);
}

class RejectLearnProposalRequest extends $pb.GeneratedMessage {
  factory RejectLearnProposalRequest({
    $core.String? id,
  }) {
    final result = RejectLearnProposalRequest._();
    if (id != null) result.id = id;
    return result;
  }

  RejectLearnProposalRequest._();

  factory RejectLearnProposalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejectLearnProposalRequest()..mergeFromBuffer(data, registry);
  factory RejectLearnProposalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejectLearnProposalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejectLearnProposalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RejectLearnProposalRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectLearnProposalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectLearnProposalRequest copyWith(
          void Function(RejectLearnProposalRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RejectLearnProposalRequest))
          as RejectLearnProposalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RejectLearnProposalRequest() / RejectLearnProposalRequest.new instead')
  static RejectLearnProposalRequest create() => RejectLearnProposalRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      RejectLearnProposalRequest._();
  @$core.override
  RejectLearnProposalRequest createEmptyInstance() =>
      RejectLearnProposalRequest._();
  @$core.pragma('dart2js:noInline')
  static RejectLearnProposalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RejectLearnProposalRequest>(
          RejectLearnProposalRequest.$_createMessage);
  static RejectLearnProposalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class RejectLearnProposalResponse extends $pb.GeneratedMessage {
  factory RejectLearnProposalResponse({
    LearnProposal? proposal,
  }) {
    final result = RejectLearnProposalResponse._();
    if (proposal != null) result.proposal = proposal;
    return result;
  }

  RejectLearnProposalResponse._();

  factory RejectLearnProposalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejectLearnProposalResponse()..mergeFromBuffer(data, registry);
  factory RejectLearnProposalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejectLearnProposalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejectLearnProposalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'flit.v1'),
      createEmptyInstance: RejectLearnProposalResponse.$_createMessage)
    ..aOM<LearnProposal>(1, _omitFieldNames ? '' : 'proposal',
        subBuilder: LearnProposal.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectLearnProposalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejectLearnProposalResponse copyWith(
          void Function(RejectLearnProposalResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RejectLearnProposalResponse))
          as RejectLearnProposalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RejectLearnProposalResponse() / RejectLearnProposalResponse.new instead')
  static RejectLearnProposalResponse create() =>
      RejectLearnProposalResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      RejectLearnProposalResponse._();
  @$core.override
  RejectLearnProposalResponse createEmptyInstance() =>
      RejectLearnProposalResponse._();
  @$core.pragma('dart2js:noInline')
  static RejectLearnProposalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RejectLearnProposalResponse>(
          RejectLearnProposalResponse.$_createMessage);
  static RejectLearnProposalResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LearnProposal get proposal => $_getN(0);
  @$pb.TagNumber(1)
  set proposal(LearnProposal value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProposal() => $_has(0);
  @$pb.TagNumber(1)
  void clearProposal() => $_clearField(1);
  @$pb.TagNumber(1)
  LearnProposal ensureProposal() => $_ensure(0);
}

/// LearningService is manual self-learning: a pass over a finished session
/// proposes lessons for the memory files (user, project, role) and skills,
/// and nothing is written until a proposal is accepted. See
/// docs/learning.md.
class LearningServiceApi {
  final $pb.RpcClient _client;

  LearningServiceApi(this._client);

  /// Learn runs the learning pass (the learning task's model) on a session
  /// and returns its proposals, stored as pending. They replace the
  /// session's earlier pending proposals. An empty list is a normal
  /// answer: most sessions teach nothing new.
  $async.Future<LearnResponse> learn(
          $pb.ClientContext? ctx, LearnRequest request) =>
      _client.invoke<LearnResponse>(
          ctx, 'LearningService', 'Learn', request, LearnResponse());
  $async.Future<ListLearnProposalsResponse> listLearnProposals(
          $pb.ClientContext? ctx, ListLearnProposalsRequest request) =>
      _client.invoke<ListLearnProposalsResponse>(ctx, 'LearningService',
          'ListLearnProposals', request, ListLearnProposalsResponse());

  /// AcceptLearnProposal writes a pending proposal, optionally with edited
  /// text, and marks it accepted. FAILED_PRECONDITION when it was already
  /// decided or the file changed underneath it.
  $async.Future<AcceptLearnProposalResponse> acceptLearnProposal(
          $pb.ClientContext? ctx, AcceptLearnProposalRequest request) =>
      _client.invoke<AcceptLearnProposalResponse>(ctx, 'LearningService',
          'AcceptLearnProposal', request, AcceptLearnProposalResponse());
  $async.Future<RejectLearnProposalResponse> rejectLearnProposal(
          $pb.ClientContext? ctx, RejectLearnProposalRequest request) =>
      _client.invoke<RejectLearnProposalResponse>(ctx, 'LearningService',
          'RejectLearnProposal', request, RejectLearnProposalResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
