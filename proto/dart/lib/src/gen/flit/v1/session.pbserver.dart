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

import 'package:protobuf/protobuf.dart' as $pb;

import 'session.pb.dart' as $1;
import 'session.pbjson.dart';

export 'session.pb.dart';

abstract class SessionServiceBase extends $pb.GeneratedService {
  $async.Future<$1.CreateSessionResponse> createSession(
      $pb.ServerContext ctx, $1.CreateSessionRequest request);
  $async.Future<$1.ListSessionsResponse> listSessions(
      $pb.ServerContext ctx, $1.ListSessionsRequest request);
  $async.Future<$1.GetSessionResponse> getSession(
      $pb.ServerContext ctx, $1.GetSessionRequest request);
  $async.Future<$1.AttachResponse> attach(
      $pb.ServerContext ctx, $1.AttachRequest request);
  $async.Future<$1.SendResponse> send(
      $pb.ServerContext ctx, $1.SendRequest request);
  $async.Future<$1.EditQueuedMessageResponse> editQueuedMessage(
      $pb.ServerContext ctx, $1.EditQueuedMessageRequest request);
  $async.Future<$1.CancelQueuedMessageResponse> cancelQueuedMessage(
      $pb.ServerContext ctx, $1.CancelQueuedMessageRequest request);
  $async.Future<$1.InterruptResponse> interrupt(
      $pb.ServerContext ctx, $1.InterruptRequest request);
  $async.Future<$1.RetryModelCallResponse> retryModelCall(
      $pb.ServerContext ctx, $1.RetryModelCallRequest request);
  $async.Future<$1.EndReasoningResponse> endReasoning(
      $pb.ServerContext ctx, $1.EndReasoningRequest request);
  $async.Future<$1.CompactResponse> compact(
      $pb.ServerContext ctx, $1.CompactRequest request);
  $async.Future<$1.AnswerPromptResponse> answerPrompt(
      $pb.ServerContext ctx, $1.AnswerPromptRequest request);
  $async.Future<$1.SetModelResponse> setModel(
      $pb.ServerContext ctx, $1.SetModelRequest request);
  $async.Future<$1.SetEffortResponse> setEffort(
      $pb.ServerContext ctx, $1.SetEffortRequest request);
  $async.Future<$1.SetYoloResponse> setYolo(
      $pb.ServerContext ctx, $1.SetYoloRequest request);
  $async.Future<$1.MoveSessionResponse> moveSession(
      $pb.ServerContext ctx, $1.MoveSessionRequest request);
  $async.Future<$1.RateResponse> rate(
      $pb.ServerContext ctx, $1.RateRequest request);
  $async.Future<$1.ListMcpServersResponse> listMcpServers(
      $pb.ServerContext ctx, $1.ListMcpServersRequest request);
  $async.Future<$1.SetMcpServerResponse> setMcpServer(
      $pb.ServerContext ctx, $1.SetMcpServerRequest request);
  $async.Future<$1.ListSkillsResponse> listSkills(
      $pb.ServerContext ctx, $1.ListSkillsRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'CreateSession':
        return $1.CreateSessionRequest();
      case 'ListSessions':
        return $1.ListSessionsRequest();
      case 'GetSession':
        return $1.GetSessionRequest();
      case 'Attach':
        return $1.AttachRequest();
      case 'Send':
        return $1.SendRequest();
      case 'EditQueuedMessage':
        return $1.EditQueuedMessageRequest();
      case 'CancelQueuedMessage':
        return $1.CancelQueuedMessageRequest();
      case 'Interrupt':
        return $1.InterruptRequest();
      case 'RetryModelCall':
        return $1.RetryModelCallRequest();
      case 'EndReasoning':
        return $1.EndReasoningRequest();
      case 'Compact':
        return $1.CompactRequest();
      case 'AnswerPrompt':
        return $1.AnswerPromptRequest();
      case 'SetModel':
        return $1.SetModelRequest();
      case 'SetEffort':
        return $1.SetEffortRequest();
      case 'SetYolo':
        return $1.SetYoloRequest();
      case 'MoveSession':
        return $1.MoveSessionRequest();
      case 'Rate':
        return $1.RateRequest();
      case 'ListMcpServers':
        return $1.ListMcpServersRequest();
      case 'SetMcpServer':
        return $1.SetMcpServerRequest();
      case 'ListSkills':
        return $1.ListSkillsRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'CreateSession':
        return createSession(ctx, request as $1.CreateSessionRequest);
      case 'ListSessions':
        return listSessions(ctx, request as $1.ListSessionsRequest);
      case 'GetSession':
        return getSession(ctx, request as $1.GetSessionRequest);
      case 'Attach':
        return attach(ctx, request as $1.AttachRequest);
      case 'Send':
        return send(ctx, request as $1.SendRequest);
      case 'EditQueuedMessage':
        return editQueuedMessage(ctx, request as $1.EditQueuedMessageRequest);
      case 'CancelQueuedMessage':
        return cancelQueuedMessage(
            ctx, request as $1.CancelQueuedMessageRequest);
      case 'Interrupt':
        return interrupt(ctx, request as $1.InterruptRequest);
      case 'RetryModelCall':
        return retryModelCall(ctx, request as $1.RetryModelCallRequest);
      case 'EndReasoning':
        return endReasoning(ctx, request as $1.EndReasoningRequest);
      case 'Compact':
        return compact(ctx, request as $1.CompactRequest);
      case 'AnswerPrompt':
        return answerPrompt(ctx, request as $1.AnswerPromptRequest);
      case 'SetModel':
        return setModel(ctx, request as $1.SetModelRequest);
      case 'SetEffort':
        return setEffort(ctx, request as $1.SetEffortRequest);
      case 'SetYolo':
        return setYolo(ctx, request as $1.SetYoloRequest);
      case 'MoveSession':
        return moveSession(ctx, request as $1.MoveSessionRequest);
      case 'Rate':
        return rate(ctx, request as $1.RateRequest);
      case 'ListMcpServers':
        return listMcpServers(ctx, request as $1.ListMcpServersRequest);
      case 'SetMcpServer':
        return setMcpServer(ctx, request as $1.SetMcpServerRequest);
      case 'ListSkills':
        return listSkills(ctx, request as $1.ListSkillsRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SessionServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SessionServiceBase$messageJson;
}
