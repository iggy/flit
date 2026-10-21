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

  /// CreateSession starts a new, idle session. Give working_dir, or a
  /// project_id whose project has a directory.
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

  /// Send adds a user message and starts a turn. While a turn is running
  /// the message is queued instead (MessageQueued) and delivered at the
  /// turn's next step: after the current model call or tool, before the
  /// next model call; if the turn ends without another call, it starts the
  /// next turn. Messages still queued when a turn is interrupted wait for
  /// the next Send, which delivers them first; with an empty text, Send
  /// just delivers the queue.
  static const send = connect.Spec(
    '/$name/Send',
    connect.StreamType.unary,
    flitv1session.SendRequest.new,
    flitv1session.SendResponse.new,
  );

  /// EditQueuedMessage changes, and CancelQueuedMessage withdraws, a queued
  /// message that hasn't been delivered yet. Once it has, they fail with
  /// FAILED_PRECONDITION.
  static const editQueuedMessage = connect.Spec(
    '/$name/EditQueuedMessage',
    connect.StreamType.unary,
    flitv1session.EditQueuedMessageRequest.new,
    flitv1session.EditQueuedMessageResponse.new,
  );

  static const cancelQueuedMessage = connect.Spec(
    '/$name/CancelQueuedMessage',
    connect.StreamType.unary,
    flitv1session.CancelQueuedMessageRequest.new,
    flitv1session.CancelQueuedMessageResponse.new,
  );

  /// Interrupt stops the running turn, if any. Pending prompts are resolved
  /// as denied.
  static const interrupt = connect.Spec(
    '/$name/Interrupt',
    connect.StreamType.unary,
    flitv1session.InterruptRequest.new,
    flitv1session.InterruptResponse.new,
  );

  /// RetryModelCall gives up on the model call in progress and sends it
  /// again, for when the model hasn't answered. Only while none of the reply
  /// has arrived: once it is streaming, the call fails with
  /// FAILED_PRECONDITION (interrupt instead).
  static const retryModelCall = connect.Spec(
    '/$name/RetryModelCall',
    connect.StreamType.unary,
    flitv1session.RetryModelCallRequest.new,
    flitv1session.RetryModelCallResponse.new,
  );

  /// EndReasoning asks the model to stop thinking and answer now (llama.cpp
  /// only, for models where it can: ListModels' can_end_reasoning). Only
  /// while the model is thinking and hasn't started its answer; otherwise
  /// FAILED_PRECONDITION. If the model keeps thinking anyway, the log gets
  /// ReasoningEndIgnored and the model is marked as not supporting it.
  static const endReasoning = connect.Spec(
    '/$name/EndReasoning',
    connect.StreamType.unary,
    flitv1session.EndReasoningRequest.new,
    flitv1session.EndReasoningResponse.new,
  );

  /// Compact summarizes the older part of the conversation so it takes less
  /// of the model's context: from then on the model sees the summary plus
  /// the most recent turns instead of the whole log (nothing is deleted).
  /// The log gets CompactionStarted and then CompactionDone. While the
  /// session is idle it runs right away, as a turn of its own (messages
  /// sent meanwhile are queued); while a turn runs, it happens at the
  /// turn's next step (queued = true). flit also compacts on its own near
  /// the context limit (agent.compaction in the config).
  static const compact = connect.Spec(
    '/$name/Compact',
    connect.StreamType.unary,
    flitv1session.CompactRequest.new,
    flitv1session.CompactResponse.new,
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

  /// SetYolo turns yolo mode on or off for the session: every shell command
  /// runs unless a deny rule matches. Effective from the next command.
  static const setYolo = connect.Spec(
    '/$name/SetYolo',
    connect.StreamType.unary,
    flitv1session.SetYoloRequest.new,
    flitv1session.SetYoloResponse.new,
  );

  /// MoveSession moves a session to another project. Its working directory
  /// stays the same.
  static const moveSession = connect.Spec(
    '/$name/MoveSession',
    connect.StreamType.unary,
    flitv1session.MoveSessionRequest.new,
    flitv1session.MoveSessionResponse.new,
  );

  /// Rate records whether a turn's result or the model choice was good or
  /// bad. Ratings are events in the session log.
  static const rate = connect.Spec(
    '/$name/Rate',
    connect.StreamType.unary,
    flitv1session.RateRequest.new,
    flitv1session.RateResponse.new,
  );

  /// ListMcpServers lists the configured MCP servers and whether each is
  /// enabled for the session. Only enabled servers' tools reach the model.
  static const listMcpServers = connect.Spec(
    '/$name/ListMcpServers',
    connect.StreamType.unary,
    flitv1session.ListMcpServersRequest.new,
    flitv1session.ListMcpServersResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// SetMcpServer enables or disables an MCP server for the session, from
  /// its next model call.
  static const setMcpServer = connect.Spec(
    '/$name/SetMcpServer',
    connect.StreamType.unary,
    flitv1session.SetMcpServerRequest.new,
    flitv1session.SetMcpServerResponse.new,
  );

  /// ListSkills lists the skills the session's agent can load: the repo's
  /// own (.agents/skills, .claude/skills) and the global ones.
  static const listSkills = connect.Spec(
    '/$name/ListSkills',
    connect.StreamType.unary,
    flitv1session.ListSkillsRequest.new,
    flitv1session.ListSkillsResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// RetryFromMessage starts a new branch of the conversation that keeps
  /// user message message_id (on the active branch's path) and everything
  /// before it, drops what came after, and runs the turn again with the
  /// session's current model. EditMessage does the same but forks just
  /// before the message and sends text in its place. Both switch the
  /// session to the new branch (BranchCreated, BranchSwitched) and fail
  /// with FAILED_PRECONDITION while a turn is running (Interrupt first) or
  /// while messages are queued (send or cancel them first). Files the agent
  /// changed stay as they are: a branch only forks the conversation.
  static const retryFromMessage = connect.Spec(
    '/$name/RetryFromMessage',
    connect.StreamType.unary,
    flitv1session.RetryFromMessageRequest.new,
    flitv1session.RetryFromMessageResponse.new,
  );

  static const editMessage = connect.Spec(
    '/$name/EditMessage',
    connect.StreamType.unary,
    flitv1session.EditMessageRequest.new,
    flitv1session.EditMessageResponse.new,
  );

  /// SwitchBranch makes another branch the active one: the next message
  /// continues it and the model sees its history. FAILED_PRECONDITION while
  /// a turn is running.
  static const switchBranch = connect.Spec(
    '/$name/SwitchBranch',
    connect.StreamType.unary,
    flitv1session.SwitchBranchRequest.new,
    flitv1session.SwitchBranchResponse.new,
  );

  /// GitStatus reports the git repository the session works in: branch,
  /// upstream, counts like git status, and the files changed since the
  /// session's base commit (Session.base_commit), committed or not. A
  /// working directory outside git is not an error: is_repo is false.
  /// Clients refresh it when a turn ends or a tool call finishes.
  static const gitStatus = connect.Spec(
    '/$name/GitStatus',
    connect.StreamType.unary,
    flitv1session.GitStatusRequest.new,
    flitv1session.GitStatusResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// GitDiff returns the unified diff of the session's changes: the base
  /// commit against the working tree, untracked files included as new
  /// files. The repository's index is left untouched.
  static const gitDiff = connect.Spec(
    '/$name/GitDiff',
    connect.StreamType.unary,
    flitv1session.GitDiffRequest.new,
    flitv1session.GitDiffResponse.new,
    idempotency: connect.Idempotency.noSideEffects,
  );

  /// RemoveWorktree deletes the session's own git worktree (see
  /// ProjectService.SetProjectWorktrees) without losing history: its
  /// branch stays when it has commits no other branch, tag or remote has.
  /// FAILED_PRECONDITION if the worktree has uncommitted changes (commit or
  /// discard them first), while a turn is running, or if the session has no
  /// worktree. Afterwards the session can't run turns. The log gets
  /// WorktreeRemoved.
  static const removeWorktree = connect.Spec(
    '/$name/RemoveWorktree',
    connect.StreamType.unary,
    flitv1session.RemoveWorktreeRequest.new,
    flitv1session.RemoveWorktreeResponse.new,
  );
}
