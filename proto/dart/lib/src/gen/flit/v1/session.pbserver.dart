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

import 'session.pb.dart' as $2;
import 'session.pbjson.dart';

export 'session.pb.dart';

abstract class SessionServiceBase extends $pb.GeneratedService {
  $async.Future<$2.CreateSessionResponse> createSession(
      $pb.ServerContext ctx, $2.CreateSessionRequest request);
  $async.Future<$2.ListSessionsResponse> listSessions(
      $pb.ServerContext ctx, $2.ListSessionsRequest request);
  $async.Future<$2.GetSessionResponse> getSession(
      $pb.ServerContext ctx, $2.GetSessionRequest request);
  $async.Future<$2.AttachResponse> attach(
      $pb.ServerContext ctx, $2.AttachRequest request);
  $async.Future<$2.SendResponse> send(
      $pb.ServerContext ctx, $2.SendRequest request);
  $async.Future<$2.EditQueuedMessageResponse> editQueuedMessage(
      $pb.ServerContext ctx, $2.EditQueuedMessageRequest request);
  $async.Future<$2.CancelQueuedMessageResponse> cancelQueuedMessage(
      $pb.ServerContext ctx, $2.CancelQueuedMessageRequest request);
  $async.Future<$2.InterruptResponse> interrupt(
      $pb.ServerContext ctx, $2.InterruptRequest request);
  $async.Future<$2.RetryModelCallResponse> retryModelCall(
      $pb.ServerContext ctx, $2.RetryModelCallRequest request);
  $async.Future<$2.EndReasoningResponse> endReasoning(
      $pb.ServerContext ctx, $2.EndReasoningRequest request);
  $async.Future<$2.CompactResponse> compact(
      $pb.ServerContext ctx, $2.CompactRequest request);
  $async.Future<$2.AnswerPromptResponse> answerPrompt(
      $pb.ServerContext ctx, $2.AnswerPromptRequest request);
  $async.Future<$2.SetModelResponse> setModel(
      $pb.ServerContext ctx, $2.SetModelRequest request);
  $async.Future<$2.SetEffortResponse> setEffort(
      $pb.ServerContext ctx, $2.SetEffortRequest request);
  $async.Future<$2.SetYoloResponse> setYolo(
      $pb.ServerContext ctx, $2.SetYoloRequest request);
  $async.Future<$2.MoveSessionResponse> moveSession(
      $pb.ServerContext ctx, $2.MoveSessionRequest request);
  $async.Future<$2.RateResponse> rate(
      $pb.ServerContext ctx, $2.RateRequest request);
  $async.Future<$2.ListMcpServersResponse> listMcpServers(
      $pb.ServerContext ctx, $2.ListMcpServersRequest request);
  $async.Future<$2.SetMcpServerResponse> setMcpServer(
      $pb.ServerContext ctx, $2.SetMcpServerRequest request);
  $async.Future<$2.ListSkillsResponse> listSkills(
      $pb.ServerContext ctx, $2.ListSkillsRequest request);
  $async.Future<$2.RetryFromMessageResponse> retryFromMessage(
      $pb.ServerContext ctx, $2.RetryFromMessageRequest request);
  $async.Future<$2.EditMessageResponse> editMessage(
      $pb.ServerContext ctx, $2.EditMessageRequest request);
  $async.Future<$2.SwitchBranchResponse> switchBranch(
      $pb.ServerContext ctx, $2.SwitchBranchRequest request);
  $async.Future<$2.GitStatusResponse> gitStatus(
      $pb.ServerContext ctx, $2.GitStatusRequest request);
  $async.Future<$2.GitDiffResponse> gitDiff(
      $pb.ServerContext ctx, $2.GitDiffRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'CreateSession':
        return $2.CreateSessionRequest();
      case 'ListSessions':
        return $2.ListSessionsRequest();
      case 'GetSession':
        return $2.GetSessionRequest();
      case 'Attach':
        return $2.AttachRequest();
      case 'Send':
        return $2.SendRequest();
      case 'EditQueuedMessage':
        return $2.EditQueuedMessageRequest();
      case 'CancelQueuedMessage':
        return $2.CancelQueuedMessageRequest();
      case 'Interrupt':
        return $2.InterruptRequest();
      case 'RetryModelCall':
        return $2.RetryModelCallRequest();
      case 'EndReasoning':
        return $2.EndReasoningRequest();
      case 'Compact':
        return $2.CompactRequest();
      case 'AnswerPrompt':
        return $2.AnswerPromptRequest();
      case 'SetModel':
        return $2.SetModelRequest();
      case 'SetEffort':
        return $2.SetEffortRequest();
      case 'SetYolo':
        return $2.SetYoloRequest();
      case 'MoveSession':
        return $2.MoveSessionRequest();
      case 'Rate':
        return $2.RateRequest();
      case 'ListMcpServers':
        return $2.ListMcpServersRequest();
      case 'SetMcpServer':
        return $2.SetMcpServerRequest();
      case 'ListSkills':
        return $2.ListSkillsRequest();
      case 'RetryFromMessage':
        return $2.RetryFromMessageRequest();
      case 'EditMessage':
        return $2.EditMessageRequest();
      case 'SwitchBranch':
        return $2.SwitchBranchRequest();
      case 'GitStatus':
        return $2.GitStatusRequest();
      case 'GitDiff':
        return $2.GitDiffRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'CreateSession':
        return createSession(ctx, request as $2.CreateSessionRequest);
      case 'ListSessions':
        return listSessions(ctx, request as $2.ListSessionsRequest);
      case 'GetSession':
        return getSession(ctx, request as $2.GetSessionRequest);
      case 'Attach':
        return attach(ctx, request as $2.AttachRequest);
      case 'Send':
        return send(ctx, request as $2.SendRequest);
      case 'EditQueuedMessage':
        return editQueuedMessage(ctx, request as $2.EditQueuedMessageRequest);
      case 'CancelQueuedMessage':
        return cancelQueuedMessage(
            ctx, request as $2.CancelQueuedMessageRequest);
      case 'Interrupt':
        return interrupt(ctx, request as $2.InterruptRequest);
      case 'RetryModelCall':
        return retryModelCall(ctx, request as $2.RetryModelCallRequest);
      case 'EndReasoning':
        return endReasoning(ctx, request as $2.EndReasoningRequest);
      case 'Compact':
        return compact(ctx, request as $2.CompactRequest);
      case 'AnswerPrompt':
        return answerPrompt(ctx, request as $2.AnswerPromptRequest);
      case 'SetModel':
        return setModel(ctx, request as $2.SetModelRequest);
      case 'SetEffort':
        return setEffort(ctx, request as $2.SetEffortRequest);
      case 'SetYolo':
        return setYolo(ctx, request as $2.SetYoloRequest);
      case 'MoveSession':
        return moveSession(ctx, request as $2.MoveSessionRequest);
      case 'Rate':
        return rate(ctx, request as $2.RateRequest);
      case 'ListMcpServers':
        return listMcpServers(ctx, request as $2.ListMcpServersRequest);
      case 'SetMcpServer':
        return setMcpServer(ctx, request as $2.SetMcpServerRequest);
      case 'ListSkills':
        return listSkills(ctx, request as $2.ListSkillsRequest);
      case 'RetryFromMessage':
        return retryFromMessage(ctx, request as $2.RetryFromMessageRequest);
      case 'EditMessage':
        return editMessage(ctx, request as $2.EditMessageRequest);
      case 'SwitchBranch':
        return switchBranch(ctx, request as $2.SwitchBranchRequest);
      case 'GitStatus':
        return gitStatus(ctx, request as $2.GitStatusRequest);
      case 'GitDiff':
        return gitDiff(ctx, request as $2.GitDiffRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SessionServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SessionServiceBase$messageJson;
}
