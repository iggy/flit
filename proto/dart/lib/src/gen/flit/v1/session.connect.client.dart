//
//  Generated code. Do not modify.
//  source: flit/v1/session.proto
//

import "package:connectrpc/connect.dart" as connect;
import "session.pb.dart" as flitv1session;
import "session.connect.spec.dart" as specs;

/// SessionService runs agent sessions. A session is a conversation with the
/// agent in a working directory. Everything that happens in it is recorded as
/// an append-only, numbered event log, so a client can attach at any point,
/// replay from any sequence number and then follow live.
extension type SessionServiceClient (connect.Transport _transport) {
  /// CreateSession starts a new, idle session. Give working_dir, or a
  /// project_id whose project has a directory.
  Future<flitv1session.CreateSessionResponse> createSession(
    flitv1session.CreateSessionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.createSession,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListSessions lists sessions, most recently updated first.
  Future<flitv1session.ListSessionsResponse> listSessions(
    flitv1session.ListSessionsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.listSessions,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// GetSession returns one session.
  Future<flitv1session.GetSessionResponse> getSession(
    flitv1session.GetSessionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.getSession,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Attach streams a session's events with seq >= from_seq, then follows new
  /// events live until the client disconnects. Replayed events are identical
  /// to what a live client saw, deltas included.
  Stream<flitv1session.AttachResponse> attach(
    flitv1session.AttachRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).server(
      specs.SessionService.attach,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Send adds a user message and starts a turn. While a turn is running
  /// the message is queued instead (MessageQueued) and delivered at the
  /// turn's next step: after the current model call or tool, before the
  /// next model call; if the turn ends without another call, it starts the
  /// next turn. Messages still queued when a turn is interrupted wait for
  /// the next Send, which delivers them first; with an empty text, Send
  /// just delivers the queue.
  Future<flitv1session.SendResponse> send(
    flitv1session.SendRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.send,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// EditQueuedMessage changes, and CancelQueuedMessage withdraws, a queued
  /// message that hasn't been delivered yet. Once it has, they fail with
  /// FAILED_PRECONDITION.
  Future<flitv1session.EditQueuedMessageResponse> editQueuedMessage(
    flitv1session.EditQueuedMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.editQueuedMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1session.CancelQueuedMessageResponse> cancelQueuedMessage(
    flitv1session.CancelQueuedMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.cancelQueuedMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Interrupt stops the running turn, if any. Pending prompts are resolved
  /// as denied.
  Future<flitv1session.InterruptResponse> interrupt(
    flitv1session.InterruptRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.interrupt,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// RetryModelCall gives up on the model call in progress and sends it
  /// again, for when the model hasn't answered. Only while none of the reply
  /// has arrived: once it is streaming, the call fails with
  /// FAILED_PRECONDITION (interrupt instead).
  Future<flitv1session.RetryModelCallResponse> retryModelCall(
    flitv1session.RetryModelCallRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.retryModelCall,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// EndReasoning asks the model to stop thinking and answer now (llama.cpp
  /// only, for models where it can: ListModels' can_end_reasoning). Only
  /// while the model is thinking and hasn't started its answer; otherwise
  /// FAILED_PRECONDITION. If the model keeps thinking anyway, the log gets
  /// ReasoningEndIgnored and the model is marked as not supporting it.
  Future<flitv1session.EndReasoningResponse> endReasoning(
    flitv1session.EndReasoningRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.endReasoning,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Compact summarizes the older part of the conversation so it takes less
  /// of the model's context: from then on the model sees the summary plus
  /// the most recent turns instead of the whole log (nothing is deleted).
  /// The log gets CompactionStarted and then CompactionDone. While the
  /// session is idle it runs right away, as a turn of its own (messages
  /// sent meanwhile are queued); while a turn runs, it happens at the
  /// turn's next step (queued = true). flit also compacts on its own near
  /// the context limit (agent.compaction in the config).
  Future<flitv1session.CompactResponse> compact(
    flitv1session.CompactRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.compact,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// AnswerPrompt answers a prompt the agent is waiting on. The first answer
  /// wins; later answers fail with FAILED_PRECONDITION.
  Future<flitv1session.AnswerPromptResponse> answerPrompt(
    flitv1session.AnswerPromptRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.answerPrompt,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetModel changes the provider and model used from the next model call.
  Future<flitv1session.SetModelResponse> setModel(
    flitv1session.SetModelRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.setModel,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetEffort changes the reasoning effort used from the next model call.
  Future<flitv1session.SetEffortResponse> setEffort(
    flitv1session.SetEffortRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.setEffort,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetYolo turns yolo mode on or off for the session: every shell command
  /// runs unless a deny rule matches. Effective from the next command.
  Future<flitv1session.SetYoloResponse> setYolo(
    flitv1session.SetYoloRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.setYolo,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// MoveSession moves a session to another project. Its working directory
  /// stays the same.
  Future<flitv1session.MoveSessionResponse> moveSession(
    flitv1session.MoveSessionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.moveSession,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// Rate records whether a turn's result or the model choice was good or
  /// bad. Ratings are events in the session log.
  Future<flitv1session.RateResponse> rate(
    flitv1session.RateRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.rate,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListMcpServers lists the configured MCP servers and whether each is
  /// enabled for the session. Only enabled servers' tools reach the model.
  Future<flitv1session.ListMcpServersResponse> listMcpServers(
    flitv1session.ListMcpServersRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.listMcpServers,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SetMcpServer enables or disables an MCP server for the session, from
  /// its next model call.
  Future<flitv1session.SetMcpServerResponse> setMcpServer(
    flitv1session.SetMcpServerRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.setMcpServer,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// ListSkills lists the skills the session's agent can load: the repo's
  /// own (.agents/skills, .claude/skills) and the global ones.
  Future<flitv1session.ListSkillsResponse> listSkills(
    flitv1session.ListSkillsRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.listSkills,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// RetryFromMessage starts a new branch of the conversation that keeps
  /// user message message_id (on the active branch's path) and everything
  /// before it, drops what came after, and runs the turn again with the
  /// session's current model. EditMessage does the same but forks just
  /// before the message and sends text in its place. Both switch the
  /// session to the new branch (BranchCreated, BranchSwitched) and fail
  /// with FAILED_PRECONDITION while a turn is running (Interrupt first) or
  /// while messages are queued (send or cancel them first). Files the agent
  /// changed stay as they are: a branch only forks the conversation.
  Future<flitv1session.RetryFromMessageResponse> retryFromMessage(
    flitv1session.RetryFromMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.retryFromMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<flitv1session.EditMessageResponse> editMessage(
    flitv1session.EditMessageRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.editMessage,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// SwitchBranch makes another branch the active one: the next message
  /// continues it and the model sees its history. FAILED_PRECONDITION while
  /// a turn is running.
  Future<flitv1session.SwitchBranchResponse> switchBranch(
    flitv1session.SwitchBranchRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.switchBranch,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// GitStatus reports the git repository the session works in: branch,
  /// upstream, counts like git status, and the files changed since the
  /// session's base commit (Session.base_commit), committed or not. A
  /// working directory outside git is not an error: is_repo is false.
  /// Clients refresh it when a turn ends or a tool call finishes.
  Future<flitv1session.GitStatusResponse> gitStatus(
    flitv1session.GitStatusRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.gitStatus,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  /// GitDiff returns the unified diff of the session's changes: the base
  /// commit against the working tree, untracked files included as new
  /// files. The repository's index is left untouched.
  Future<flitv1session.GitDiffResponse> gitDiff(
    flitv1session.GitDiffRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.SessionService.gitDiff,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
