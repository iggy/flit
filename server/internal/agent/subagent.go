package agent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// Subagent system prompts. They are short on purpose: a subagent starts
// with an empty context, and on local models every prompt token costs
// time.
const (
	explorePrompt = `You are a read-only research subagent of a coding agent. Use your tools to do the task below; you cannot change anything, and nobody can answer questions.

When you're done, reply with only your report for the agent: what you found, with file paths and line numbers where they help. Be concise and stick to what the task asks.`

	buildPrompt = `You are a subagent of a coding agent. Do the task below in the working directory with your tools. Look before you change anything; prefer patch for edits. Shell commands may need the user's approval; if one is denied, don't retry it unchanged.

When you're done, reply with only your report for the agent: what you changed (files), how you checked it, and anything left undone. Be concise.`

	// stepLimitNote is sent when a subagent hits its step cap; it then
	// gets one more call, without tools, to write its report.
	stepLimitNote = "You have used all your steps. Stop now and write your report: what you found or did, and what is left undone."
)

// subagentKind reads the agent tool's kind argument.
func subagentKind(kind string) (flitv1.SubagentKind, bool) {
	switch kind {
	case "explore":
		return flitv1.SubagentKind_SUBAGENT_KIND_EXPLORE, true
	case "build":
		return flitv1.SubagentKind_SUBAGENT_KIND_BUILD, true
	}
	return 0, false
}

// subagentModel is the model a subagent of kind runs on: agent.tasks.<kind>,
// else the session's.
func subagentModel(cfg config.Config, info store.Session, kind string) config.TaskModel {
	if t, ok := cfg.Task(kind); ok {
		return t
	}
	return config.TaskModel{Provider: info.Provider, Model: info.Model, Effort: info.Effort}
}

// subagentTools is what a subagent of kind may use. explore gets only the
// tools that read, shell limited to the read-only list, and nothing that
// could ask the user; build gets the session's tools. Neither gets agent
// (no nesting), todo (the session's list is the agent's) or skills (to keep
// the prompt short).
func (s *session) subagentTools(ctx context.Context, cfg config.Config, info store.Session, kind flitv1.SubagentKind) []tools.Tool {
	set := tools.All()
	if cfg.Git.IsEnabled() {
		set = append(set, tools.GitTools()...)
	}
	if cfg.Web.FetchEnabled() {
		set = append(set, tools.WebFetchTool())
	}
	if cfg.Web.Search.Provider == "searxng" {
		set = append(set, tools.WebSearchTool(cfg.Web.Search.URL))
	}
	if kind == flitv1.SubagentKind_SUBAGENT_KIND_EXPLORE {
		return tools.ReadOnlySet(set, cfg.Shell.ReadOnlyEnabled())
	}
	out := set[:0]
	for _, t := range set {
		if t.Name != "todo" {
			out = append(out, t)
		}
	}
	if s.m.MCP != nil && len(info.MCPServers) > 0 {
		mcpTools, err := s.m.MCP.Tools(ctx, info.MCPServers)
		if err != nil {
			s.m.log.Warn("MCP servers unavailable to subagent", "session", info.ID, "err", err)
		}
		for _, t := range mcpTools {
			out = append(out, mcpTool(s.m.MCP, t))
		}
	}
	return out
}

// subagentRun is one subagent's run for the agent tool call callID.
type subagentRun struct {
	s      *session
	turnID string
	callID string
	kind   flitv1.SubagentKind
	// events are its own events, unwrapped, in order: the model's context
	// is rebuilt from them, as the session's is from its log.
	events []*flitv1.Event
}

// append records ev as one of the subagent's events.
func (r *subagentRun) append(ev *flitv1.Event) error {
	if _, err := r.s.append(&flitv1.Event{Payload: &flitv1.Event_SubagentEvent{SubagentEvent: &flitv1.SubagentEvent{
		ToolCallId: r.callID, Event: ev,
	}}}); err != nil {
		return err
	}
	r.events = append(r.events, ev)
	return nil
}

// runSubagent runs the agent tool call callID: a one-shot subagent with a
// fresh context that works until it answers without tool calls, hits
// agent.subagents.max_steps, or ctx ends. Its report is the tool result.
// The error is only for an event log that can't be written.
func (s *session) runSubagent(ctx context.Context, turnID, callID string, raw json.RawMessage) (tools.Result, error) {
	args, err := tools.DecodeAgentArgs(raw)
	if err != nil {
		return tools.Result{Text: err.Error(), IsError: true}, nil
	}
	kind, ok := subagentKind(args.Kind)
	if !ok {
		return tools.Result{Text: fmt.Sprintf("kind must be explore or build, not %q", args.Kind), IsError: true}, nil
	}
	if strings.TrimSpace(args.Task) == "" {
		return tools.Result{Text: "task is empty", IsError: true}, nil
	}

	cfg, info := s.m.cfg(), s.snapshot()
	task := subagentModel(cfg, info, args.Kind)
	maxSteps := cfg.Agent.Subagents.MaxSteps
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_SubagentStarted{SubagentStarted: &flitv1.SubagentStarted{
		ToolCallId: callID, Kind: kind, Provider: task.Provider, Model: task.Model, Effort: task.Effort,
		Task: args.Task, MaxSteps: int32(maxSteps),
	}}}); err != nil {
		return tools.Result{}, err
	}
	r := &subagentRun{s: s, turnID: turnID, callID: callID, kind: kind}
	done := &flitv1.SubagentDone{ToolCallId: callID}
	finish := func(res tools.Result) (tools.Result, error) {
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_SubagentDone{SubagentDone: done}}); err != nil {
			return tools.Result{}, err
		}
		return res, nil
	}
	fail := func(msg string) (tools.Result, error) {
		done.Outcome, done.Error = flitv1.SubagentOutcome_SUBAGENT_OUTCOME_ERROR, msg
		return finish(tools.Result{Text: "the subagent failed: " + msg, IsError: true})
	}

	modelInfo := info
	modelInfo.Provider, modelInfo.Model = task.Provider, task.Model
	provider, header, stopMsg := checkModel(cfg, modelInfo)
	if stopMsg != "" {
		return fail(stopMsg)
	}
	set := s.subagentTools(ctx, cfg, info, kind)
	system := explorePrompt
	var b strings.Builder
	if kind == flitv1.SubagentKind_SUBAGENT_KIND_BUILD {
		system = buildPrompt
	}
	b.WriteString(system)
	writeEnvironment(&b, info.WorkingDir)
	if kind == flitv1.SubagentKind_SUBAGENT_KIND_BUILD {
		// It changes the project, so it needs the project's rules.
		writeInstructions(&b, info.WorkingDir)
	}
	system = b.String()

	if err := r.appendUser(subagentTaskText(args)); err != nil {
		return tools.Result{}, err
	}
	report := ""
	for step := 0; ; step++ {
		last := step >= maxSteps
		if last {
			if err := r.appendUser(stepLimitNote); err != nil {
				return tools.Result{}, err
			}
		}
		cfg = s.m.cfg()
		req := llm.Request{
			Model:    task.Model,
			Messages: append([]llm.Message{{Role: "system", Content: system}}, buildMessages(r.events)...),
		}
		if !last {
			req.Tools = tools.Definitions(set)
		}
		s.m.applyReasoning(&req, task.Provider, task.Model, task.Effort)
		client := &llm.Client{
			BaseURL: provider.BaseURL, APIKey: provider.Key(), Header: header, HTTP: s.m.http,
			FirstTokenTimeout: cfg.Agent.ModelFirstTokenTimeout, StallTimeout: cfg.Agent.ModelStallTimeout,
			Limiter: s.m.limiter, Provider: provider.Name,
		}
		res, err := r.call(ctx, cfg, info, task, client, req)
		done.Steps = int32(step + 1)
		if err != nil {
			if errors.Is(err, errLog) {
				return tools.Result{}, errors.Unwrap(err)
			}
			if ctx.Err() != nil {
				done.Outcome = flitv1.SubagentOutcome_SUBAGENT_OUTCOME_CANCELLED
				return finish(tools.Result{Text: "[the subagent was stopped: the turn was interrupted]", IsError: true})
			}
			return fail(err.Error())
		}
		report = strings.TrimSpace(res.Text)
		if last || len(res.ToolCalls) == 0 {
			done.Outcome = flitv1.SubagentOutcome_SUBAGENT_OUTCOME_DONE
			if last {
				done.Outcome = flitv1.SubagentOutcome_SUBAGENT_OUTCOME_STEP_LIMIT
			}
			break
		}
		for _, tc := range res.ToolCalls {
			out := tools.Result{Text: notRun, IsError: true}
			if ctx.Err() == nil {
				if out, err = r.runTool(ctx, set, tc); err != nil {
					return tools.Result{}, err
				}
			}
			cfg = s.m.cfg()
			text, omitted, cut := tools.Truncate(out.Text, cfg.Agent.ToolOutputMaxBytes, cfg.Agent.ToolOutputMaxLines)
			if err := r.append(&flitv1.Event{Payload: &flitv1.Event_ToolCallDone{ToolCallDone: &flitv1.ToolCallDone{
				ToolCallId: tc.ID, Result: text, IsError: out.IsError, Truncated: cut, OmittedBytes: omitted,
			}}}); err != nil {
				return tools.Result{}, err
			}
		}
		if ctx.Err() != nil {
			done.Outcome = flitv1.SubagentOutcome_SUBAGENT_OUTCOME_CANCELLED
			return finish(tools.Result{Text: "[the subagent was stopped: the turn was interrupted]", IsError: true})
		}
	}
	if report == "" {
		report = "(the subagent finished without a report)"
	}
	if done.Outcome == flitv1.SubagentOutcome_SUBAGENT_OUTCOME_STEP_LIMIT {
		report = fmt.Sprintf("[stopped at its step limit (%d model calls)]\n%s", maxSteps, report)
	}
	done.Report = report
	return finish(tools.Result{Text: report})
}

// subagentTaskText is the subagent's first message.
func subagentTaskText(a tools.AgentArgs) string {
	var b strings.Builder
	b.WriteString(strings.TrimSpace(a.Task))
	if c := strings.TrimSpace(a.Context); c != "" {
		b.WriteString("\n\nContext:\n" + c)
	}
	if len(a.Files) > 0 {
		b.WriteString("\n\nStart with: " + strings.Join(a.Files, ", "))
	}
	return b.String()
}

// appendUser records a user message to the subagent.
func (r *subagentRun) appendUser(text string) error {
	id := newID("msg")
	for _, ev := range []*flitv1.Event{
		{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: id, Role: flitv1.Role_ROLE_USER}}},
		{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: id, Text: text, FinishReason: "stop"}}},
	} {
		if err := r.append(ev); err != nil {
			return err
		}
	}
	return nil
}

// errLog wraps an event log write failure in call, to tell it from a
// failed model call.
var errLog = errors.New("event log")

// call makes one model call for the subagent and records it: the message,
// its attempts, usage and tool calls. A call that fails before any output
// is retried like the agent's (agent.model_retries).
func (r *subagentRun) call(ctx context.Context, cfg config.Config, info store.Session, task config.TaskModel,
	client *llm.Client, req llm.Request) (*llm.Result, error) {
	logErr := func(err error) error { return fmt.Errorf("%w: %w", errLog, err) }
	msgID := newID("msg")
	if err := r.append(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{
		MessageId: msgID, Role: flitv1.Role_ROLE_ASSISTANT, Provider: task.Provider, Model: task.Model,
	}}}); err != nil {
		return nil, logErr(err)
	}
	var text, reasoning strings.Builder
	var appendErr error
	var res *llm.Result
	var err error
	for attempt := int32(1); ; attempt++ {
		if err := r.append(&flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{
			MessageId: msgID, Attempt: attempt,
			FirstByteTimeoutMs: cfg.Agent.ModelFirstTokenTimeout.Milliseconds(),
			StallTimeoutMs:     cfg.Agent.ModelStallTimeout.Milliseconds(),
		}}}); err != nil {
			return nil, logErr(err)
		}
		var trace *llm.Trace
		prov, _ := cfg.Provider(task.Provider)
		llama, router := r.s.m.isLlamaCpp(task.Provider)
		live := &liveCall{msgID: msgID, provider: prov, model: task.Model, router: router, llama: llama}
		removeLive := r.s.addSubCall(live)
		client.OnStall = r.s.stallProbe(ctx, live)
		queued, admitted := r.s.limitHandlers(msgID, attempt, task.Provider, task.Model, live, r.append, &appendErr)
		res, trace, err = client.StreamTrace(ctx, req, llm.Handler{
			Queued:   queued,
			Admitted: admitted,
			Live:     func(snap func() llm.Trace) { r.s.setLive(live, snap) },
			Text: func(d string) {
				text.WriteString(d)
				if err := r.append(&flitv1.Event{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: msgID, Text: d}}}); err != nil {
					appendErr = err
				}
			},
			Reasoning: func(d string) {
				reasoning.WriteString(d)
				if err := r.append(&flitv1.Event{Payload: &flitv1.Event_ReasoningDelta{ReasoningDelta: &flitv1.ReasoningDelta{MessageId: msgID, Text: d}}}); err != nil {
					appendErr = err
				}
			},
		})
		removeLive()
		if appendErr != nil {
			return nil, logErr(appendErr)
		}
		retry := err != nil && ctx.Err() == nil && llm.Retryable(err) &&
			text.Len() == 0 && reasoning.Len() == 0 && int(attempt) <= cfg.Agent.ModelRetries
		ended := callEnded(msgID, attempt, trace, res, err, ctx.Err() != nil, retry)
		r.s.diagnoseEnd(ctx, ended, err, live)
		if err := r.append(ended); err != nil {
			return nil, logErr(err)
		}
		if !retry {
			break
		}
	}
	r.s.recordTaskCall(info, r.turnID, msgID, subagentTask(r.kind), task, req, res, err)
	if err != nil {
		finish := "error"
		if ctx.Err() != nil {
			finish = "interrupted"
		}
		if err := r.append(messageDoneEvent(msgID, text.String(), reasoning.String(), finish)); err != nil {
			return nil, logErr(err)
		}
		return nil, err
	}
	if err := r.append(messageDoneEvent(msgID, res.Text, res.Reasoning, res.FinishReason)); err != nil {
		return nil, logErr(err)
	}
	if res.Usage != nil {
		if err := r.append(&flitv1.Event{Payload: &flitv1.Event_Usage{Usage: &flitv1.Usage{
			MessageId: msgID, ContextLength: r.s.m.contextLength(task.Provider, task.Model),
			InputTokens: res.Usage.PromptTokens, OutputTokens: res.Usage.CompletionTokens, TotalTokens: res.Usage.TotalTokens,
			TimeToFirstTokenMs:        res.Metrics.TimeToFirstToken.Milliseconds(),
			PromptTokensPerSecond:     res.Metrics.PromptPerSecond,
			GenerationTokensPerSecond: res.Metrics.GenerationPerSecond,
			TimingSource:              res.Metrics.Source,
		}}}); err != nil {
			return nil, logErr(err)
		}
	}
	for _, tc := range res.ToolCalls {
		if err := r.append(&flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{
			MessageId: msgID, ToolCallId: tc.ID, Name: tc.Function.Name, Arguments: tc.Function.Arguments,
		}}}); err != nil {
			return nil, logErr(err)
		}
	}
	return res, nil
}

// subagentTask is the task name model calls of a subagent are recorded
// under (and agent.tasks key).
func subagentTask(kind flitv1.SubagentKind) string {
	if kind == flitv1.SubagentKind_SUBAGENT_KIND_BUILD {
		return "build"
	}
	return "explore"
}

func messageDoneEvent(msgID, text, reasoning, finish string) *flitv1.Event {
	return &flitv1.Event{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{
		MessageId: msgID, Text: text, Reasoning: reasoning, FinishReason: finish,
	}}}
}

// runTool runs one of the subagent's tool calls. A build subagent's
// commands go through the session's rules, safety check and prompts, which
// name the subagent's tool call; an explore subagent has no way to ask.
func (r *subagentRun) runTool(ctx context.Context, set []tools.Tool, tc llm.ToolCall) (tools.Result, error) {
	var live int
	var appendErr error
	cfg, info := r.s.m.cfg(), r.s.snapshot()
	env := &tools.Env{
		Dir:   info.WorkingDir,
		Shell: cfg.Shell,
		Output: func(out string) {
			if live >= maxLiveToolOutput {
				return
			}
			live += len(out)
			if err := r.append(&flitv1.Event{Payload: &flitv1.Event_ToolOutput{ToolOutput: &flitv1.ToolOutput{
				ToolCallId: tc.ID, Text: out,
			}}}); err != nil {
				appendErr = err
			}
		},
	}
	if r.kind == flitv1.SubagentKind_SUBAGENT_KIND_BUILD {
		env.Yolo = info.Yolo
		env.SessionAllowed = r.s.sessionAllowed()
		env.Approve = func(ctx context.Context, a tools.Approval) (bool, error) {
			return r.s.approve(ctx, tc.ID, a)
		}
		env.Assess = r.s.assessor(cfg, r.turnID, tc.ID)
		env.Diagnose = r.s.m.LSP.Checker(info.WorkingDir)
	}
	res := tools.Run(ctx, env, set, tc.Function.Name, tc.Function.Arguments)
	if appendErr != nil && !errors.Is(appendErr, errInterrupted) {
		return res, appendErr
	}
	return res, nil
}
