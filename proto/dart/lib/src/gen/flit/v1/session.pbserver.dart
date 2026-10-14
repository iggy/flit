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
  $async.Future<$1.InterruptResponse> interrupt(
      $pb.ServerContext ctx, $1.InterruptRequest request);
  $async.Future<$1.AnswerPromptResponse> answerPrompt(
      $pb.ServerContext ctx, $1.AnswerPromptRequest request);
  $async.Future<$1.SetModelResponse> setModel(
      $pb.ServerContext ctx, $1.SetModelRequest request);

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
      case 'Interrupt':
        return $1.InterruptRequest();
      case 'AnswerPrompt':
        return $1.AnswerPromptRequest();
      case 'SetModel':
        return $1.SetModelRequest();
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
      case 'Interrupt':
        return interrupt(ctx, request as $1.InterruptRequest);
      case 'AnswerPrompt':
        return answerPrompt(ctx, request as $1.AnswerPromptRequest);
      case 'SetModel':
        return setModel(ctx, request as $1.SetModelRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SessionServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SessionServiceBase$messageJson;
}
