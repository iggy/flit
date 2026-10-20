/// flit.v1 protobuf messages → app domain models. The only place the app
/// looks at generated protobuf types.
library;

import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit_api/flit_api.dart' as pb;

FlitTaskState taskStateFromProto(pb.TaskState state) {
  return switch (state) {
    pb.TaskState.TASK_STATE_IDLE => FlitTaskState.idle,
    pb.TaskState.TASK_STATE_WORKING => FlitTaskState.working,
    pb.TaskState.TASK_STATE_WAITING => FlitTaskState.waiting,
    pb.TaskState.TASK_STATE_STUCK => FlitTaskState.stuck,
    pb.TaskState.TASK_STATE_DONE => FlitTaskState.done,
    _ => FlitTaskState.unknown,
  };
}

FlitSession sessionFromProto(pb.Session s) {
  return FlitSession(
    id: s.id,
    title: s.title,
    workingDir: s.workingDir,
    provider: s.provider,
    model: s.model,
    state: taskStateFromProto(s.state),
    lastSeq: s.lastSeq.toInt(),
    teamId: s.teamId,
    projectId: s.projectId,
    createdAt: s.hasCreateTime() ? s.createTime.toDateTime() : null,
    updatedAt: s.hasUpdateTime() ? s.updateTime.toDateTime() : null,
    effort: s.effort,
    role: s.role,
    contextTokens: s.contextTokens.toInt(),
    contextLength: s.contextLength.toInt(),
    mcpServers: List<String>.unmodifiable(s.mcpServers),
    yolo: s.yolo,
  );
}

FlitProject projectFromProto(pb.Project p) {
  return FlitProject(
    id: p.id,
    name: p.name,
    directory: p.directory,
    sessionCount: p.sessionCount,
    exportEnabled: p.exportEnabled,
  );
}

FlitMcpServer mcpServerFromProto(pb.McpServer s) {
  return FlitMcpServer(
    name: s.name,
    enabled: s.enabled,
    running: s.running,
    toolCount: s.toolCount,
    error: s.error,
  );
}

FlitModel modelFromProto(pb.Model m) {
  return FlitModel(
    provider: m.provider,
    id: m.id,
    displayName: m.displayName,
    contextLength: m.contextLength.toInt(),
    supportsTools: m.supportsTools,
    supportsReasoning: m.supportsReasoning,
    supportsVision: m.supportsVision,
    efforts: List<String>.unmodifiable(m.efforts),
    loaded: m.loaded,
    favorite: m.favorite,
    canEndReasoning: m.canEndReasoning,
    lastUsed: m.hasLastUsed() ? m.lastUsed.toDateTime() : null,
    state: switch (m.state) {
      pb.ModelState.MODEL_STATE_UNLOADED => FlitModelState.unloaded,
      pb.ModelState.MODEL_STATE_LOADING => FlitModelState.loading,
      pb.ModelState.MODEL_STATE_LOADED => FlitModelState.loaded,
      pb.ModelState.MODEL_STATE_SLEEPING => FlitModelState.sleeping,
      pb.ModelState.MODEL_STATE_FAILED => FlitModelState.failed,
      _ => FlitModelState.none,
    },
  );
}

FlitAgentRole roleFromProto(pb.AgentRole r) {
  return FlitAgentRole(
    name: r.name,
    description: r.description,
    provider: r.provider,
    model: r.model,
    effort: r.effort,
    error: r.error,
  );
}

FlitTodoStatus _todoStatus(pb.TodoStatus s) {
  return switch (s) {
    pb.TodoStatus.TODO_STATUS_IN_PROGRESS => FlitTodoStatus.inProgress,
    pb.TodoStatus.TODO_STATUS_COMPLETED => FlitTodoStatus.completed,
    _ => FlitTodoStatus.pending,
  };
}

FlitEvent eventFromProto(pb.Event e) {
  final seq = e.seq.toInt();
  final time = e.hasTime() ? e.time.toDateTime() : null;
  switch (e.whichPayload()) {
    case pb.Event_Payload.messageStarted:
      final p = e.messageStarted;
      return FlitMessageStarted(
        seq: seq,
        time: time,
        messageId: p.messageId,
        role: switch (p.role) {
          pb.Role.ROLE_USER => FlitRole.user,
          pb.Role.ROLE_ASSISTANT => FlitRole.assistant,
          _ => FlitRole.unknown,
        },
        provider: p.provider,
        model: p.model,
      );
    case pb.Event_Payload.textDelta:
      return FlitTextDelta(
        seq: seq,
        time: time,
        messageId: e.textDelta.messageId,
        text: e.textDelta.text,
      );
    case pb.Event_Payload.reasoningDelta:
      return FlitReasoningDelta(
        seq: seq,
        time: time,
        messageId: e.reasoningDelta.messageId,
        text: e.reasoningDelta.text,
      );
    case pb.Event_Payload.messageDone:
      final p = e.messageDone;
      return FlitMessageDone(
        seq: seq,
        time: time,
        messageId: p.messageId,
        text: p.text,
        reasoning: p.reasoning,
        finishReason: p.finishReason,
      );
    case pb.Event_Payload.toolCallStarted:
      final p = e.toolCallStarted;
      return FlitToolCallStarted(
        seq: seq,
        time: time,
        messageId: p.messageId,
        toolCallId: p.toolCallId,
        name: p.name,
        arguments: p.arguments,
      );
    case pb.Event_Payload.toolOutput:
      return FlitToolOutput(
        seq: seq,
        time: time,
        toolCallId: e.toolOutput.toolCallId,
        text: e.toolOutput.text,
      );
    case pb.Event_Payload.toolCallDone:
      final p = e.toolCallDone;
      return FlitToolCallDone(
        seq: seq,
        time: time,
        toolCallId: p.toolCallId,
        result: p.result,
        isError: p.isError,
        truncated: p.truncated,
      );
    case pb.Event_Payload.promptRequested:
      final p = e.promptRequested;
      return FlitPromptRequested(
        seq: seq,
        time: time,
        promptId: p.promptId,
        toolCallId: p.toolCallId,
        title: p.title,
        detail: p.detail,
        sessionPatterns: List<String>.unmodifiable(p.sessionPatterns),
        safetyReason: p.safetyReason,
      );
    case pb.Event_Payload.promptResolved:
      final p = e.promptResolved;
      return FlitPromptResolved(
        seq: seq,
        time: time,
        promptId: p.promptId,
        allowed:
            p.decision == pb.PromptDecision.PROMPT_DECISION_ALLOW ||
            p.decision == pb.PromptDecision.PROMPT_DECISION_ALLOW_SESSION,
        forSession:
            p.decision == pb.PromptDecision.PROMPT_DECISION_ALLOW_SESSION,
        client: p.client,
        reason: p.reason,
      );
    case pb.Event_Payload.taskStateChanged:
      return FlitTaskStateChanged(
        seq: seq,
        time: time,
        state: taskStateFromProto(e.taskStateChanged.state),
        reason: e.taskStateChanged.reason,
      );
    case pb.Event_Payload.modelChanged:
      return FlitModelChanged(
        seq: seq,
        time: time,
        provider: e.modelChanged.provider,
        model: e.modelChanged.model,
        effort: e.modelChanged.effort,
        contextLength: e.modelChanged.contextLength.toInt(),
      );
    case pb.Event_Payload.usage:
      final u = e.usage;
      return FlitUsage(
        seq: seq,
        time: time,
        messageId: u.messageId,
        inputTokens: u.inputTokens.toInt(),
        outputTokens: u.outputTokens.toInt(),
        contextLength: u.contextLength.toInt(),
        timeToFirstTokenMs: u.timeToFirstTokenMs.toInt(),
        promptTokensPerSecond: u.promptTokensPerSecond,
        generationTokensPerSecond: u.generationTokensPerSecond,
        timingSource: u.timingSource,
        cachedTokens: u.cachedTokens.toInt(),
      );
    case pb.Event_Payload.todoUpdated:
      return FlitTodoUpdated(
        seq: seq,
        time: time,
        items: List<FlitTodo>.unmodifiable(
          e.todoUpdated.items.map(
            (i) => FlitTodo(content: i.content, status: _todoStatus(i.status)),
          ),
        ),
      );
    case pb.Event_Payload.error:
      return FlitTurnError(
        seq: seq,
        time: time,
        message: e.error.message,
        canContinue: e.error.turnCanContinue,
      );
    case pb.Event_Payload.feedback:
      final f = e.feedback;
      return FlitFeedback(
        seq: seq,
        time: time,
        target: f.target == pb.RatingTarget.RATING_TARGET_MODEL
            ? FlitRatingTarget.model
            : FlitRatingTarget.turn,
        good: f.rating == pb.Rating.RATING_GOOD,
        messageId: f.messageId,
        provider: f.provider,
        model: f.model,
        client: f.client,
        note: f.note,
      );
    case pb.Event_Payload.mcpServersChanged:
      return FlitMcpServersChanged(
        seq: seq,
        time: time,
        enabled: List<String>.unmodifiable(e.mcpServersChanged.enabled),
      );
    case pb.Event_Payload.sessionMoved:
      return FlitSessionMoved(
        seq: seq,
        time: time,
        projectId: e.sessionMoved.projectId,
      );
    case pb.Event_Payload.yoloChanged:
      return FlitYoloChanged(
        seq: seq,
        time: time,
        yolo: e.yoloChanged.yolo,
        client: e.yoloChanged.client,
      );
    case pb.Event_Payload.messageQueued:
      return FlitMessageQueued(
        seq: seq,
        time: time,
        queueId: e.messageQueued.queueId,
        text: e.messageQueued.text,
        client: e.messageQueued.client,
      );
    case pb.Event_Payload.queuedMessageUpdated:
      return FlitQueuedMessageUpdated(
        seq: seq,
        time: time,
        queueId: e.queuedMessageUpdated.queueId,
        text: e.queuedMessageUpdated.text,
        cancelled: e.queuedMessageUpdated.cancelled,
      );
    case pb.Event_Payload.queuedMessageDelivered:
      return FlitQueuedMessageDelivered(
        seq: seq,
        time: time,
        queueId: e.queuedMessageDelivered.queueId,
        messageId: e.queuedMessageDelivered.messageId,
      );
    case pb.Event_Payload.modelCallWaiting:
      final w = e.modelCallWaiting;
      return FlitModelCallWaiting(
        seq: seq,
        time: time,
        messageId: w.messageId,
        totalSlots: w.totalSlots,
        reason: switch (w.reason) {
          pb.ModelWaitReason.MODEL_WAIT_REASON_SLOTS_BUSY =>
            FlitWaitReason.slotsBusy,
          pb.ModelWaitReason.MODEL_WAIT_REASON_SLEEPING =>
            FlitWaitReason.sleeping,
          pb.ModelWaitReason.MODEL_WAIT_REASON_LOADING =>
            FlitWaitReason.loading,
          _ => FlitWaitReason.unknown,
        },
      );
    case pb.Event_Payload.reasoningEndRequested:
      return FlitReasoningEndRequested(
        seq: seq,
        time: time,
        messageId: e.reasoningEndRequested.messageId,
        client: e.reasoningEndRequested.client,
      );
    case pb.Event_Payload.reasoningEndIgnored:
      return FlitReasoningEndIgnored(
        seq: seq,
        time: time,
        messageId: e.reasoningEndIgnored.messageId,
      );
    case pb.Event_Payload.compactionStarted:
      final c = e.compactionStarted;
      return FlitCompactionStarted(
        seq: seq,
        time: time,
        compactionId: c.compactionId,
        auto: c.auto,
        client: c.client,
        tokens: c.tokens.toInt(),
        contextLength: c.contextLength.toInt(),
        provider: c.provider,
        model: c.model,
      );
    case pb.Event_Payload.compactionDone:
      final c = e.compactionDone;
      return FlitCompactionDone(
        seq: seq,
        time: time,
        compactionId: c.compactionId,
        auto: c.auto,
        summary: c.summary,
        coveredSeq: c.coveredSeq.toInt(),
        tokensBefore: c.tokensBefore.toInt(),
        tokensAfter: c.tokensAfter.toInt(),
        tokensExact: c.tokensExact,
        contextLength: c.contextLength.toInt(),
        provider: c.provider,
        model: c.model,
        keptTurns: c.keptTurns,
        error: c.error,
      );
    case pb.Event_Payload.modelCallStarted:
      return FlitModelCallStarted(
        seq: seq,
        time: time,
        messageId: e.modelCallStarted.messageId,
        attempt: e.modelCallStarted.attempt,
      );
    case pb.Event_Payload.promptProgress:
      final p = e.promptProgress;
      return FlitPromptProgress(
        seq: seq,
        time: time,
        messageId: p.messageId,
        processed: p.processed.toInt(),
        total: p.total.toInt(),
        cached: p.cached.toInt(),
      );
    case pb.Event_Payload.modelCallEnded:
      final c = e.modelCallEnded;
      return FlitModelCallEnded(
        seq: seq,
        time: time,
        messageId: c.messageId,
        attempt: c.attempt,
        outcome: switch (c.outcome) {
          pb.ModelCallOutcome.MODEL_CALL_OUTCOME_OK => FlitCallOutcome.ok,
          pb.ModelCallOutcome.MODEL_CALL_OUTCOME_STALLED =>
            FlitCallOutcome.stalled,
          pb.ModelCallOutcome.MODEL_CALL_OUTCOME_ERROR => FlitCallOutcome.error,
          pb.ModelCallOutcome.MODEL_CALL_OUTCOME_CANCELLED =>
            FlitCallOutcome.cancelled,
          pb.ModelCallOutcome.MODEL_CALL_OUTCOME_RETRIED =>
            FlitCallOutcome.retried,
          _ => FlitCallOutcome.unknown,
        },
        phase: c.phase,
        willRetry: c.willRetry,
      );
    case pb.Event_Payload.permissionCheck:
      final c = e.permissionCheck;
      return FlitPermissionCheck(
        seq: seq,
        time: time,
        toolCallId: c.toolCallId,
        command: c.command,
        verdict: switch (c.verdict) {
          pb.PermissionVerdict.PERMISSION_VERDICT_SAFE =>
            FlitPermissionVerdict.safe,
          pb.PermissionVerdict.PERMISSION_VERDICT_ASK =>
            FlitPermissionVerdict.ask,
          pb.PermissionVerdict.PERMISSION_VERDICT_BLOCK =>
            FlitPermissionVerdict.block,
          _ => FlitPermissionVerdict.error,
        },
        reason: c.reason,
        provider: c.provider,
        model: c.model,
      );
    // Prompt cache saves and restores are for flit debug session; the chat
    // has nothing to show for them.
    case pb.Event_Payload.promptCache:
    case pb.Event_Payload.notSet:
      return FlitUnknownEvent(seq: seq, time: time);
  }
}
