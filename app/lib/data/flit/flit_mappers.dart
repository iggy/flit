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
  );
}

FlitProject projectFromProto(pb.Project p) {
  return FlitProject(
    id: p.id,
    name: p.name,
    directory: p.directory,
    sessionCount: p.sessionCount,
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
      );
    case pb.Event_Payload.promptResolved:
      final p = e.promptResolved;
      return FlitPromptResolved(
        seq: seq,
        time: time,
        promptId: p.promptId,
        allowed: p.decision == pb.PromptDecision.PROMPT_DECISION_ALLOW,
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
    case pb.Event_Payload.notSet:
      return FlitUnknownEvent(seq: seq, time: time);
  }
}
