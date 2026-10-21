//
//  Generated code. Do not modify.
//  source: flit/v1/learning.proto
//

import "package:connectrpc/connect.dart" as connect;
import "learning.pb.dart" as flitv1learning;

/// LearningService is manual self-learning: a pass over a finished session
/// proposes lessons for the memory files (user, project, role) and skills,
/// and nothing is written until a proposal is accepted. See
/// docs/learning.md.
abstract final class LearningService {
  /// Fully-qualified name of the LearningService service.
  static const name = 'flit.v1.LearningService';

  /// Learn runs the learning pass (the learning task's model) on a session
  /// and returns its proposals, stored as pending. They replace the
  /// session's earlier pending proposals. An empty list is a normal
  /// answer: most sessions teach nothing new.
  static const learn = connect.Spec(
    '/$name/Learn',
    connect.StreamType.unary,
    flitv1learning.LearnRequest.new,
    flitv1learning.LearnResponse.new,
  );

  static const listLearnProposals = connect.Spec(
    '/$name/ListLearnProposals',
    connect.StreamType.unary,
    flitv1learning.ListLearnProposalsRequest.new,
    flitv1learning.ListLearnProposalsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// AcceptLearnProposal writes a pending proposal, optionally with edited
  /// text, and marks it accepted. FAILED_PRECONDITION when it was already
  /// decided or the file changed underneath it.
  static const acceptLearnProposal = connect.Spec(
    '/$name/AcceptLearnProposal',
    connect.StreamType.unary,
    flitv1learning.AcceptLearnProposalRequest.new,
    flitv1learning.AcceptLearnProposalResponse.new,
  );

  static const rejectLearnProposal = connect.Spec(
    '/$name/RejectLearnProposal',
    connect.StreamType.unary,
    flitv1learning.RejectLearnProposalRequest.new,
    flitv1learning.RejectLearnProposalResponse.new,
  );
}
