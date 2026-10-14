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
  );
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
      );
    case pb.Event_Payload.usage:
      return FlitUsage(
        seq: seq,
        time: time,
        messageId: e.usage.messageId,
        inputTokens: e.usage.inputTokens.toInt(),
        outputTokens: e.usage.outputTokens.toInt(),
      );
    case pb.Event_Payload.error:
      return FlitTurnError(
        seq: seq,
        time: time,
        message: e.error.message,
        canContinue: e.error.turnCanContinue,
      );
    case pb.Event_Payload.notSet:
      return FlitUnknownEvent(seq: seq, time: time);
  }
}
