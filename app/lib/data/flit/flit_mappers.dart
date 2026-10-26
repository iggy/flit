/// flit.v1 protobuf messages → app domain models. The only place the app
/// looks at generated protobuf types.
library;

import 'package:flit/domain/models/flit_cron.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flit/domain/models/flit_learning.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/domain/models/subagent.dart';
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
    cronJob: s.cronJob,
    sourceDir: s.sourceDir,
    worktreePath: s.worktreePath,
    worktreeBranch: s.worktreeBranch,
    worktreeRemoved: s.worktreeRemoved,
  );
}

FlitCronRunState cronRunStateFromProto(pb.CronRunState s) => switch (s) {
  pb.CronRunState.CRON_RUN_STATE_RUNNING => FlitCronRunState.running,
  pb.CronRunState.CRON_RUN_STATE_OK => FlitCronRunState.ok,
  pb.CronRunState.CRON_RUN_STATE_NEEDS_ATTENTION =>
    FlitCronRunState.needsAttention,
  pb.CronRunState.CRON_RUN_STATE_FAILED => FlitCronRunState.failed,
  pb.CronRunState.CRON_RUN_STATE_SKIPPED => FlitCronRunState.skipped,
  _ => FlitCronRunState.unknown,
};

FlitCronTrigger cronTriggerFromProto(pb.CronTrigger t) => switch (t) {
  pb.CronTrigger.CRON_TRIGGER_SCHEDULE => FlitCronTrigger.schedule,
  pb.CronTrigger.CRON_TRIGGER_CATCH_UP => FlitCronTrigger.catchUp,
  pb.CronTrigger.CRON_TRIGGER_MANUAL => FlitCronTrigger.manual,
  _ => FlitCronTrigger.unknown,
};

FlitCronRun cronRunFromProto(pb.CronRun r) {
  return FlitCronRun(
    id: r.id,
    job: r.job,
    sessionId: r.sessionId,
    state: cronRunStateFromProto(r.state),
    trigger: cronTriggerFromProto(r.trigger),
    scheduledAt: r.hasScheduledTime() ? r.scheduledTime.toDateTime() : null,
    startedAt: r.hasStartTime() ? r.startTime.toDateTime() : null,
    finishedAt: r.hasFinishTime() ? r.finishTime.toDateTime() : null,
    summary: r.summary,
    refusedCommands: List<String>.unmodifiable(r.refusedCommands),
    quiet: r.quiet,
  );
}

FlitCronJob cronJobFromProto(pb.CronJob j) {
  return FlitCronJob(
    name: j.name,
    schedule: j.schedule,
    scheduleText: j.scheduleText,
    oneShot: j.oneShot,
    enabled: j.enabled,
    projectId: j.projectId,
    projectName: j.projectName,
    dir: j.dir,
    role: j.role,
    provider: j.provider,
    model: j.model,
    askWait: j.ask == pb.CronAsk.CRON_ASK_WAIT,
    yolo: j.yolo,
    timezone: j.timezone,
    prompt: j.prompt,
    path: j.path,
    nextRunAt: j.hasNextRunTime() ? j.nextRunTime.toDateTime() : null,
    lastRun: j.hasLastRun() ? cronRunFromProto(j.lastRun) : null,
    error: j.error,
    runningSessionId: j.runningSessionId,
  );
}

FlitDiffBase diffBaseFromProto(pb.GitDiffBase b) {
  return switch (b) {
    pb.GitDiffBase.GIT_DIFF_BASE_SESSION_START => FlitDiffBase.sessionStart,
    pb.GitDiffBase.GIT_DIFF_BASE_HEAD_NO_BASE => FlitDiffBase.headNoBase,
    pb.GitDiffBase.GIT_DIFF_BASE_HEAD_BASE_MISSING =>
      FlitDiffBase.headBaseMissing,
    pb.GitDiffBase.GIT_DIFF_BASE_EMPTY_TREE => FlitDiffBase.emptyTree,
    _ => FlitDiffBase.unknown,
  };
}

FlitFileStatus _fileStatus(pb.GitFileStatus s) {
  return switch (s) {
    pb.GitFileStatus.GIT_FILE_STATUS_MODIFIED => FlitFileStatus.modified,
    pb.GitFileStatus.GIT_FILE_STATUS_ADDED => FlitFileStatus.added,
    pb.GitFileStatus.GIT_FILE_STATUS_DELETED => FlitFileStatus.deleted,
    pb.GitFileStatus.GIT_FILE_STATUS_RENAMED => FlitFileStatus.renamed,
    pb.GitFileStatus.GIT_FILE_STATUS_COPIED => FlitFileStatus.copied,
    pb.GitFileStatus.GIT_FILE_STATUS_TYPE_CHANGED => FlitFileStatus.typeChanged,
    pb.GitFileStatus.GIT_FILE_STATUS_UNMERGED => FlitFileStatus.unmerged,
    _ => FlitFileStatus.unknown,
  };
}

FlitGitStatus gitStatusFromProto(pb.GitStatusResponse r) {
  if (!r.isRepo) {
    return FlitGitStatus.none;
  }
  return FlitGitStatus(
    isRepo: true,
    root: r.root,
    branch: r.branch,
    head: r.head,
    detached: r.detached,
    upstream: r.upstream,
    ahead: r.ahead,
    behind: r.behind,
    stagedCount: r.stagedCount,
    unstagedCount: r.unstagedCount,
    untrackedCount: r.untrackedCount,
    conflictedCount: r.conflictedCount,
    baseCommit: r.baseCommit,
    diffBase: r.diffBase,
    diffBaseKind: diffBaseFromProto(r.diffBaseKind),
    files: List<FlitGitFile>.unmodifiable(
      r.files.map(
        (f) => FlitGitFile(
          path: f.path,
          oldPath: f.oldPath,
          status: _fileStatus(f.status),
          additions: f.additions,
          deletions: f.deletions,
          binary: f.binary,
          staged: f.staged,
          unstaged: f.unstaged,
          untracked: f.untracked,
        ),
      ),
    ),
    filesTruncated: r.filesTruncated,
  );
}

FlitGitDiff gitDiffFromProto(pb.GitDiffResponse r) {
  return FlitGitDiff(
    isRepo: r.isRepo,
    text: r.diff,
    diffBase: r.diffBase,
    diffBaseKind: diffBaseFromProto(r.diffBaseKind),
    truncated: r.truncated,
  );
}

FlitProject projectFromProto(pb.Project p) {
  return FlitProject(
    id: p.id,
    name: p.name,
    directory: p.directory,
    sessionCount: p.sessionCount,
    exportEnabled: p.exportEnabled,
    worktrees: p.worktreesEnabled,
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
    builtin: r.builtin,
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
  final branch = e.branchId;
  switch (e.whichPayload()) {
    case pb.Event_Payload.messageStarted:
      final p = e.messageStarted;
      return FlitMessageStarted(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
        messageId: e.textDelta.messageId,
        text: e.textDelta.text,
      );
    case pb.Event_Payload.reasoningDelta:
      return FlitReasoningDelta(
        seq: seq,
        time: time,
        branchId: branch,
        messageId: e.reasoningDelta.messageId,
        text: e.reasoningDelta.text,
      );
    case pb.Event_Payload.messageDone:
      final p = e.messageDone;
      return FlitMessageDone(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
        messageId: p.messageId,
        toolCallId: p.toolCallId,
        name: p.name,
        arguments: p.arguments,
      );
    case pb.Event_Payload.toolOutput:
      return FlitToolOutput(
        seq: seq,
        time: time,
        branchId: branch,
        toolCallId: e.toolOutput.toolCallId,
        text: e.toolOutput.text,
      );
    case pb.Event_Payload.toolCallDone:
      final p = e.toolCallDone;
      return FlitToolCallDone(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
        state: taskStateFromProto(e.taskStateChanged.state),
        reason: e.taskStateChanged.reason,
      );
    case pb.Event_Payload.modelChanged:
      return FlitModelChanged(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
        message: e.error.message,
        canContinue: e.error.turnCanContinue,
      );
    case pb.Event_Payload.feedback:
      final f = e.feedback;
      return FlitFeedback(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
        enabled: List<String>.unmodifiable(e.mcpServersChanged.enabled),
      );
    case pb.Event_Payload.sessionMoved:
      return FlitSessionMoved(
        seq: seq,
        time: time,
        branchId: branch,
        projectId: e.sessionMoved.projectId,
      );
    case pb.Event_Payload.yoloChanged:
      return FlitYoloChanged(
        seq: seq,
        time: time,
        branchId: branch,
        yolo: e.yoloChanged.yolo,
        client: e.yoloChanged.client,
      );
    case pb.Event_Payload.messageQueued:
      return FlitMessageQueued(
        seq: seq,
        time: time,
        branchId: branch,
        queueId: e.messageQueued.queueId,
        text: e.messageQueued.text,
        client: e.messageQueued.client,
      );
    case pb.Event_Payload.queuedMessageUpdated:
      return FlitQueuedMessageUpdated(
        seq: seq,
        time: time,
        branchId: branch,
        queueId: e.queuedMessageUpdated.queueId,
        text: e.queuedMessageUpdated.text,
        cancelled: e.queuedMessageUpdated.cancelled,
      );
    case pb.Event_Payload.queuedMessageDelivered:
      return FlitQueuedMessageDelivered(
        seq: seq,
        time: time,
        branchId: branch,
        queueId: e.queuedMessageDelivered.queueId,
        messageId: e.queuedMessageDelivered.messageId,
      );
    case pb.Event_Payload.modelCallWaiting:
      final w = e.modelCallWaiting;
      return FlitModelCallWaiting(
        seq: seq,
        time: time,
        branchId: branch,
        messageId: w.messageId,
        totalSlots: w.totalSlots,
        reason: switch (w.reason) {
          pb.ModelWaitReason.MODEL_WAIT_REASON_SLOTS_BUSY =>
            FlitWaitReason.slotsBusy,
          pb.ModelWaitReason.MODEL_WAIT_REASON_SLEEPING =>
            FlitWaitReason.sleeping,
          pb.ModelWaitReason.MODEL_WAIT_REASON_LOADING =>
            FlitWaitReason.loading,
          pb.ModelWaitReason.MODEL_WAIT_REASON_CONCURRENCY_LIMIT =>
            FlitWaitReason.concurrencyLimit,
          _ => FlitWaitReason.unknown,
        },
      );
    case pb.Event_Payload.reasoningEndRequested:
      return FlitReasoningEndRequested(
        seq: seq,
        time: time,
        branchId: branch,
        messageId: e.reasoningEndRequested.messageId,
        client: e.reasoningEndRequested.client,
      );
    case pb.Event_Payload.reasoningEndIgnored:
      return FlitReasoningEndIgnored(
        seq: seq,
        time: time,
        branchId: branch,
        messageId: e.reasoningEndIgnored.messageId,
      );
    case pb.Event_Payload.compactionStarted:
      final c = e.compactionStarted;
      return FlitCompactionStarted(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
        messageId: e.modelCallStarted.messageId,
        attempt: e.modelCallStarted.attempt,
      );
    case pb.Event_Payload.promptProgress:
      final p = e.promptProgress;
      return FlitPromptProgress(
        seq: seq,
        time: time,
        branchId: branch,
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
        branchId: branch,
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
        branchId: branch,
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
    case pb.Event_Payload.branchCreated:
      final b = e.branchCreated;
      return FlitBranchCreated(
        seq: seq,
        time: time,
        branchId: branch,
        newBranchId: b.branchId,
        parentBranchId: b.parentBranchId,
        forkSeq: b.forkSeq.toInt(),
        kind: switch (b.kind) {
          pb.BranchKind.BRANCH_KIND_RETRY => FlitBranchKind.retry,
          pb.BranchKind.BRANCH_KIND_EDIT => FlitBranchKind.edit,
          _ => FlitBranchKind.unknown,
        },
        messageId: b.messageId,
        client: b.client,
      );
    case pb.Event_Payload.branchSwitched:
      final b = e.branchSwitched;
      return FlitBranchSwitched(
        seq: seq,
        time: time,
        branchId: branch,
        newBranchId: b.branchId,
        client: b.client,
      );
    case pb.Event_Payload.subagentStarted:
      final a = e.subagentStarted;
      return FlitSubagentStarted(
        seq: seq,
        time: time,
        branchId: branch,
        toolCallId: a.toolCallId,
        kind: switch (a.kind) {
          pb.SubagentKind.SUBAGENT_KIND_EXPLORE => SubagentKind.explore,
          pb.SubagentKind.SUBAGENT_KIND_BUILD => SubagentKind.build,
          _ => SubagentKind.unknown,
        },
        provider: a.provider,
        model: a.model,
        task: a.task,
        maxSteps: a.maxSteps,
      );
    case pb.Event_Payload.subagentEvent:
      final a = e.subagentEvent;
      // The inner event carries only its payload.
      final inner = a.event.deepCopy()
        ..seq = e.seq
        ..branchId = e.branchId;
      if (e.hasTime()) {
        inner.time = e.time;
      }
      return FlitSubagentEvent(
        seq: seq,
        time: time,
        branchId: branch,
        toolCallId: a.toolCallId,
        event: eventFromProto(inner),
      );
    case pb.Event_Payload.subagentDone:
      final a = e.subagentDone;
      return FlitSubagentDone(
        seq: seq,
        time: time,
        branchId: branch,
        toolCallId: a.toolCallId,
        status: switch (a.outcome) {
          pb.SubagentOutcome.SUBAGENT_OUTCOME_DONE => SubagentStatus.done,
          pb.SubagentOutcome.SUBAGENT_OUTCOME_STEP_LIMIT =>
            SubagentStatus.stepLimit,
          pb.SubagentOutcome.SUBAGENT_OUTCOME_CANCELLED =>
            SubagentStatus.cancelled,
          _ => SubagentStatus.error,
        },
        report: a.report,
        error: a.error,
        steps: a.steps,
      );
    case pb.Event_Payload.promptCache:
    // Which cron job started the session; the app shows that from
    // FlitSession.cronJob instead.
    case pb.Event_Payload.cronRun:
    // Which webhook delivery started the session; the app doesn't show
    // webhook runs yet.
    case pb.Event_Payload.webhookRun:
    // The session's worktree; the app shows it from FlitSession.
    case pb.Event_Payload.worktreeCreated:
    case pb.Event_Payload.worktreeSkipped:
    case pb.Event_Payload.worktreeRemoved:
    case pb.Event_Payload.worktreeKept:
    case pb.Event_Payload.notSet:
      return FlitUnknownEvent(seq: seq, time: time, branchId: branch);
  }
}

FlitLearnProposal learnProposalFromProto(pb.LearnProposal p) {
  return FlitLearnProposal(
    id: p.id,
    sessionId: p.sessionId,
    action: switch (p.action) {
      pb.LearnAction.LEARN_ACTION_UPDATE => FlitLearnAction.update,
      pb.LearnAction.LEARN_ACTION_REMOVE => FlitLearnAction.remove,
      _ => FlitLearnAction.add,
    },
    target: switch (p.target) {
      pb.LearnTarget.LEARN_TARGET_USER => FlitLearnTarget.user,
      pb.LearnTarget.LEARN_TARGET_ROLE => FlitLearnTarget.role,
      pb.LearnTarget.LEARN_TARGET_SKILL => FlitLearnTarget.skill,
      _ => FlitLearnTarget.project,
    },
    status: switch (p.status) {
      pb.LearnStatus.LEARN_STATUS_ACCEPTED => FlitLearnStatus.accepted,
      pb.LearnStatus.LEARN_STATUS_REJECTED => FlitLearnStatus.rejected,
      _ => FlitLearnStatus.pending,
    },
    skill: p.skill,
    cue: p.cue,
    lesson: p.lesson,
    evidence: p.evidence,
    oldText: p.oldText,
    newText: p.newText,
    path: p.path,
    provider: p.provider,
    model: p.model,
  );
}
