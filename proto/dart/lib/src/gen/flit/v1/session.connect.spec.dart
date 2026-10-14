//
//  Generated code. Do not modify.
//  source: flit/v1/session.proto
//

import "package:connectrpc/connect.dart" as connect;
import "session.pb.dart" as flitv1session;

/// SessionService runs agent sessions. A session is a conversation with the
/// agent in a working directory. Everything that happens in it is recorded as
/// an append-only, numbered event log, so a client can attach at any point,
/// replay from any sequence number and then follow live.
abstract final class SessionService {
  /// Fully-qualified name of the SessionService service.
  static const name = 'flit.v1.SessionService';

  /// CreateSession starts a new, idle session.
  static const createSession = connect.Spec(
    '/$name/CreateSession',
    connect.StreamType.unary,
    flitv1session.CreateSessionRequest.new,
    flitv1session.CreateSessionResponse.new,
  );

  /// ListSessions lists sessions, most recently updated first.
  static const listSessions = connect.Spec(
    '/$name/ListSessions',
    connect.StreamType.unary,
    flitv1session.ListSessionsRequest.new,
    flitv1session.ListSessionsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// GetSession returns one session.
  static const getSession = connect.Spec(
    '/$name/GetSession',
    connect.StreamType.unary,
    flitv1session.GetSessionRequest.new,
    flitv1session.GetSessionResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// Attach streams a session's events with seq >= from_seq, then follows new
  /// events live until the client disconnects. Replayed events are identical
  /// to what a live client saw, deltas included.
  static const attach = connect.Spec(
    '/$name/Attach',
    connect.StreamType.server,
    flitv1session.AttachRequest.new,
    flitv1session.AttachResponse.new,
  );

  /// Send adds a user message and starts a turn. Fails with
  /// FAILED_PRECONDITION while a turn is already running.
  static const send = connect.Spec(
    '/$name/Send',
    connect.StreamType.unary,
    flitv1session.SendRequest.new,
    flitv1session.SendResponse.new,
  );

  /// Interrupt stops the running turn, if any. Pending prompts are resolved
  /// as denied.
  static const interrupt = connect.Spec(
    '/$name/Interrupt',
    connect.StreamType.unary,
    flitv1session.InterruptRequest.new,
    flitv1session.InterruptResponse.new,
  );

  /// AnswerPrompt answers a prompt the agent is waiting on. The first answer
  /// wins; later answers fail with FAILED_PRECONDITION.
  static const answerPrompt = connect.Spec(
    '/$name/AnswerPrompt',
    connect.StreamType.unary,
    flitv1session.AnswerPromptRequest.new,
    flitv1session.AnswerPromptResponse.new,
  );

  /// SetModel changes the provider and model used from the next model call.
  static const setModel = connect.Spec(
    '/$name/SetModel',
    connect.StreamType.unary,
    flitv1session.SetModelRequest.new,
    flitv1session.SetModelResponse.new,
  );

  /// SetEffort changes the reasoning effort used from the next model call.
  static const setEffort = connect.Spec(
    '/$name/SetEffort',
    connect.StreamType.unary,
    flitv1session.SetEffortRequest.new,
    flitv1session.SetEffortResponse.new,
  );
}
