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

import 'package:protobuf/protobuf.dart' as $pb;

import 'learning.pb.dart' as $0;
import 'learning.pbjson.dart';

export 'learning.pb.dart';

abstract class LearningServiceBase extends $pb.GeneratedService {
  $async.Future<$0.LearnResponse> learn(
      $pb.ServerContext ctx, $0.LearnRequest request);
  $async.Future<$0.ListLearnProposalsResponse> listLearnProposals(
      $pb.ServerContext ctx, $0.ListLearnProposalsRequest request);
  $async.Future<$0.AcceptLearnProposalResponse> acceptLearnProposal(
      $pb.ServerContext ctx, $0.AcceptLearnProposalRequest request);
  $async.Future<$0.RejectLearnProposalResponse> rejectLearnProposal(
      $pb.ServerContext ctx, $0.RejectLearnProposalRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Learn':
        return $0.LearnRequest();
      case 'ListLearnProposals':
        return $0.ListLearnProposalsRequest();
      case 'AcceptLearnProposal':
        return $0.AcceptLearnProposalRequest();
      case 'RejectLearnProposal':
        return $0.RejectLearnProposalRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Learn':
        return learn(ctx, request as $0.LearnRequest);
      case 'ListLearnProposals':
        return listLearnProposals(ctx, request as $0.ListLearnProposalsRequest);
      case 'AcceptLearnProposal':
        return acceptLearnProposal(
            ctx, request as $0.AcceptLearnProposalRequest);
      case 'RejectLearnProposal':
        return rejectLearnProposal(
            ctx, request as $0.RejectLearnProposalRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => LearningServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => LearningServiceBase$messageJson;
}
