//
//  Generated code. Do not modify.
//  source: flit/v1/learning.proto
//

import "package:connectrpc/connect.dart" as connect;
import "learning.pb.dart" as flitv1learning;
import "learning.connect.spec.dart" as specs;

/// LearningService is manual self-learning: a pass over a finished session
/// proposes lessons for the memory files (user, project, role) and skills,
/// and nothing is written until a proposal is accepted. See
/// docs/learning.md.
extension type LearningServiceClient (connect.Transport _transport) {
  /// Learn runs the learning pass (the learning task's model) on a session
  /// and returns its proposals, stored as pending. They replace the
  /// session's earlier pending proposals. An empty list is a normal
  /// answer: most sessions teach nothing new.
  Future<flitv1learning.LearnResponse> learn(
    flitv1learning.LearnRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LearningService.learn,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1learning.ListLearnProposalsResponse> listLearnProposals(
    flitv1learning.ListLearnProposalsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LearningService.listLearnProposals,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// AcceptLearnProposal writes a pending proposal, optionally with edited
  /// text, and marks it accepted. FAILED_PRECONDITION when it was already
  /// decided or the file changed underneath it.
  Future<flitv1learning.AcceptLearnProposalResponse> acceptLearnProposal(
    flitv1learning.AcceptLearnProposalRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LearningService.acceptLearnProposal,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1learning.RejectLearnProposalResponse> rejectLearnProposal(
    flitv1learning.RejectLearnProposalRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.LearningService.rejectLearnProposal,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
