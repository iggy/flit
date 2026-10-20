package agent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/mcpclient"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/skills"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// progressInterval spaces out PromptProgress events.
const progressInterval = time.Second

// maxLiveToolOutput caps ToolOutput events per tool call. The model's result
// is truncated separately (config agent.tool_output_*).
const maxLiveToolOutput = 256 << 10

// end is how a turn finished.
type end struct {
	state  flitv1.TaskState
	reason string
}

var (
	endDone        = end{flitv1.TaskState_TASK_STATE_DONE, ""}
	endInterrupted = end{flitv1.TaskState_TASK_STATE_DONE, "interrupted"}
)

// runTurn calls the model and runs tools until the model stops asking for
// tools, the turn is interrupted (ctx), or something fails. The user message
// and the WORKING state are already recorded. The final state change and
// marking the session idle happen together, so a client that sees the turn
// end can Send right away.
func (s *session) runTurn(ctx context.Context, turnID string) {
	e, err := s.loop(ctx, turnID)
	if err != nil {
		s.m.log.Error("turn failed", "session", s.info.ID, "err", err)
		e = end{flitv1.TaskState_TASK_STATE_STUCK, "internal error: " + err.Error()}
	}
	// The turn is over: keep its llama.cpp prompt cache before anything
	// else on the server wipes it.
	if ref := s.lastSlot; ref != nil {
		s.lastSlot = nil
		s.m.saveAfterTurn(s, ref.provider, ref.router, ref.model, ref.slot)
	}
	s.endTurn(e)
}

// endTurn records how the turn (or compaction run) ended and marks the
// session idle, together, so a client that sees the end can Send right
// away. Then a compaction asked for too late in the turn runs, or else
// messages queued during it start the next turn.
func (s *session) endTurn(e end) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.cancelTurn = nil
	ask := s.compactAsk
	s.compactAsk = nil
	if _, err := s.appendLocked(stateChanged(e.state, e.reason)); err != nil {
		s.m.log.Error("could not record end of turn", "session", s.info.ID, "err", err)
		return
	}
	// An interrupted turn leaves queued messages for the next Send.
	if e == endInterrupted || s.m.closing.Load() {
		return
	}
	if ask != nil && e.state == flitv1.TaskState_TASK_STATE_DONE {
		if err := s.startCompactionLocked(*ask); err != nil {
			s.m.log.Error("could not start compaction", "session", s.info.ID, "err", err)
		}
		return
	}
	// Messages queued during a turn that ended without another model call
	// start the next one.
	if len(s.queue) == 0 {
		return
	}
	_, next, err := s.deliverQueuedLocked()
	if err == nil {
		err = s.startTurnLocked(next)
	}
	if err != nil {
		s.m.log.Error("could not start the queued turn", "session", s.info.ID, "err", err)
	}
}

// loop runs the turn and says how it ended. It returns an error only if the
// event log can't be written.
func (s *session) loop(ctx context.Context, turnID string) (end, error) {
	autoFailed := false
	for step := 0; ; step++ {
		cfg := s.m.cfg()
		if step >= cfg.Agent.MaxSteps {
			return s.stop(fmt.Sprintf("stopped after %d model calls (agent.max_steps)", step), true)
		}

		info := s.snapshot()
		provider, header, stopMsg := checkModel(cfg, info)
		if stopMsg != "" {
			return s.stop(stopMsg, false)
		}

		if step == 0 {
			s.m.touchModel(info)
		} else if err := s.deliverQueued(); err != nil {
			// A step boundary: messages sent meanwhile join the
			// conversation before the next model call.
			return end{}, err
		}
		cr, stopMsg, err := s.chatRequest(ctx, cfg, info)
		if err != nil {
			return end{}, err
		}
		if stopMsg != "" {
			return s.stop(stopMsg, false)
		}
		llama, router := s.m.isLlamaCpp(info.Provider)

		// Also a step boundary for compaction: asked for (Compact during
		// the turn), or the request is near the context limit.
		ask := s.takeCompactAsk()
		if ask != nil || (cfg.Agent.Compaction.AutoOn() && !autoFailed) {
			use := s.contextUse(ctx, cfg, info, provider, cr.req, ask != nil)
			if ask != nil || use.over(cfg.Agent.Compaction.Threshold) {
				o := compactOpts{auto: ask == nil, midTurn: true, minKeep: 1, turnID: turnID, before: use}
				if ask != nil {
					o.client, o.instructions = ask.client, ask.instructions
				}
				done, err := s.compact(ctx, cfg, info, cr, o)
				if err != nil {
					return end{}, err
				}
				if ctx.Err() != nil {
					return endInterrupted, nil
				}
				if done == nil && o.auto {
					// Don't try again on every step; the next turn will.
					autoFailed = true
				}
				if done != nil {
					cr.compaction = done
					cr.req.Messages = cr.messages(cr.history, done)
				}
			}
		}
		req, set, role, skillNames := cr.req, cr.set, cr.role, cr.skills

		msgID := newID("msg")
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{
			MessageId: msgID, Role: flitv1.Role_ROLE_ASSISTANT, Provider: info.Provider, Model: info.Model,
		}}}); err != nil {
			return end{}, err
		}

		var text, reasoning strings.Builder
		var appendErr error
		client := &llm.Client{
			BaseURL: provider.BaseURL, APIKey: provider.Key(), Header: header, HTTP: s.m.http,
			FirstTokenTimeout: cfg.Agent.ModelFirstTokenTimeout, StallTimeout: cfg.Agent.ModelStallTimeout,
		}
		var slot *int
		if llama {
			req.ReturnProgress = true
			prefs, _ := s.m.store.ModelPrefs(context.Background(), info.TeamID)
			req.ReasoningControl = !prefs[store.ModelKey{Provider: info.Provider, Model: info.Model}].NoReasoningEnd
			var restored *flitv1.Event
			slot, restored = s.m.prepareSlot(ctx, cfg, info, provider, router, msgID, step == 0)
			if restored != nil {
				if _, err := s.append(restored); err != nil {
					return end{}, err
				}
			}
			if slot != nil {
				cachePrompt := true
				req.IDSlot, req.CachePrompt = slot, &cachePrompt
				s.lastSlot = &slotRef{provider: provider, router: router, model: info.Model, slot: *slot}
			}
		}
		var res *llm.Result
		var lastTrace *llm.Trace
		autoRetries := 0
		for attempt := int32(1); ; attempt++ {
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{
				MessageId: msgID, Attempt: attempt,
				FirstByteTimeoutMs: cfg.Agent.ModelFirstTokenTimeout.Milliseconds(),
				StallTimeoutMs:     cfg.Agent.ModelStallTimeout.Milliseconds(),
			}}}); err != nil {
				return end{}, err
			}
			var trace *llm.Trace
			callCtx, cancelCall := context.WithCancelCause(ctx)
			live := &liveCall{msgID: msgID, provider: provider, model: info.Model, router: router}
			s.setCall(cancelCall, live)
			stopWait := func() {}
			if llama {
				stopWait = s.watchWait(callCtx, s.m.llamaClient(provider, router), live, attempt, slot)
			}
			res, trace, err = client.StreamTrace(callCtx, req, llm.Handler{
				ID: s.callID,
				Text: func(d string) {
					s.callActivity(len(d), 0)
					text.WriteString(d)
					if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: msgID, Text: d}}}); err != nil {
						appendErr = err
					}
				},
				Reasoning: func(d string) {
					s.callActivity(0, len(d))
					reasoning.WriteString(d)
					if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ReasoningDelta{ReasoningDelta: &flitv1.ReasoningDelta{MessageId: msgID, Text: d}}}); err != nil {
						appendErr = err
					}
				},
				Progress: s.progress(msgID, attempt, &appendErr),
			})
			stopWait()
			lastTrace = trace
			userRetry := err != nil && ctx.Err() == nil && errors.Is(context.Cause(callCtx), errUserRetry)
			s.setCall(nil, nil)
			cancelCall(nil)
			if appendErr != nil {
				return end{}, appendErr
			}
			// Only a call that produced nothing can be retried without the
			// log showing half a reply twice.
			autoRetry := err != nil && !userRetry && ctx.Err() == nil && llm.Retryable(err) &&
				text.Len() == 0 && reasoning.Len() == 0 && autoRetries < cfg.Agent.ModelRetries
			ended := callEnded(msgID, attempt, trace, res, err, ctx.Err() != nil, userRetry || autoRetry)
			if userRetry {
				e := ended.GetModelCallEnded()
				e.Outcome, e.Error = flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED, "retried by request"
			}
			if _, err := s.append(ended); err != nil {
				return end{}, err
			}
			if !userRetry && !autoRetry {
				break
			}
			if autoRetry {
				autoRetries++
			}
			s.m.log.Warn("model call failed before any output; retrying", "session", info.ID, "attempt", attempt, "by_request", userRetry, "err", err)
		}
		s.recordCall(info, turnID, msgID, role, skillNames, req, res, text.String(), reasoning.String(), err)
		if err != nil {
			finish := "error"
			if ctx.Err() != nil {
				finish = "interrupted"
			}
			if err := s.messageDone(msgID, text.String(), reasoning.String(), finish); err != nil {
				return end{}, err
			}
			if ctx.Err() != nil {
				return endInterrupted, nil
			}
			msg := err.Error()
			var stall *llm.StallError
			if errors.As(err, &stall) {
				setting := "agent.model_first_token_timeout"
				if stall.Started() {
					setting = "agent.model_stall_timeout"
				}
				msg += "; if the model is just slow, raise " + setting + " in the config"
			}
			return s.stop(msg, llm.Retryable(err))
		}

		if err := s.messageDone(msgID, res.Text, res.Reasoning, res.FinishReason); err != nil {
			return end{}, err
		}
		if res.Usage != nil || res.Metrics.Source != "" {
			u := &flitv1.Usage{
				MessageId:                 msgID,
				ContextLength:             s.m.contextLength(info.Provider, info.Model),
				TimeToFirstTokenMs:        res.Metrics.TimeToFirstToken.Milliseconds(),
				PromptTokensPerSecond:     res.Metrics.PromptPerSecond,
				GenerationTokensPerSecond: res.Metrics.GenerationPerSecond,
				TimingSource:              res.Metrics.Source,
			}
			if lastTrace != nil && lastTrace.Timings != nil {
				u.CachedTokens = lastTrace.Timings.CacheN
			}
			if res.Usage != nil {
				u.InputTokens, u.OutputTokens, u.TotalTokens = res.Usage.PromptTokens, res.Usage.CompletionTokens, res.Usage.TotalTokens
			}
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_Usage{Usage: u}}); err != nil {
				return end{}, err
			}
		}
		for _, tc := range res.ToolCalls {
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{
				MessageId: msgID, ToolCallId: tc.ID, Name: tc.Function.Name, Arguments: tc.Function.Arguments,
			}}}); err != nil {
				return end{}, err
			}
		}
		if len(res.ToolCalls) == 0 {
			return endDone, nil
		}

		for _, tc := range res.ToolCalls {
			if ctx.Err() != nil {
				if err := s.toolDone(tc.ID, tools.Result{Text: notRun, IsError: true}, cfg.Agent.ToolOutputMaxBytes, cfg.Agent.ToolOutputMaxLines); err != nil {
					return end{}, err
				}
				continue
			}
			res, err := s.runTool(ctx, turnID, set, tc)
			if err != nil {
				return end{}, err
			}
			cfg = s.m.cfg()
			if err := s.toolDone(tc.ID, res, cfg.Agent.ToolOutputMaxBytes, cfg.Agent.ToolOutputMaxLines); err != nil {
				return end{}, err
			}
		}
		if ctx.Err() != nil {
			return endInterrupted, nil
		}
	}
}

// checkModel finds the session's provider and its headers; stopMsg says
// what's missing when the session can't call its model.
func checkModel(cfg config.Config, info store.Session) (provider config.Provider, header http.Header, stopMsg string) {
	provider, ok := cfg.Provider(info.Provider)
	header, headerErr := provider.Header()
	switch {
	case info.Provider == "":
		return provider, nil, "no provider configured for this session; add one under providers in the config and call SetModel"
	case !ok:
		return provider, nil, fmt.Sprintf("provider %q is not in the config", info.Provider)
	case info.Model == "":
		return provider, nil, "no model chosen for this session; call SetModel or set agent.model in the config"
	case headerErr != nil:
		return provider, nil, headerErr.Error()
	}
	return provider, header, ""
}

// chatReq is the next chat model call, built from the log.
type chatReq struct {
	req    llm.Request
	set    []tools.Tool
	role   *roles.Role
	skills []string
	// history is the conversation's events (historyKinds), all of them;
	// compaction is the latest one in effect, if any.
	history    []*flitv1.Event
	compaction *flitv1.CompactionDone
	// system is the system prompt without the compaction summary.
	system string
}

// chatRequest builds the next model call: the system prompt, with the
// latest compaction's summary, and the conversation since. stopMsg is set
// when the session's role can't be loaded.
func (s *session) chatRequest(ctx context.Context, cfg config.Config, info store.Session) (*chatReq, string, error) {
	history, err := s.m.store.EventsOfKinds(context.Background(), info.ID, historyKinds...)
	if err != nil {
		return nil, "", err
	}
	cr := &chatReq{history: history, compaction: lastCompaction(history)}
	if info.Role != "" {
		if cr.role, err = s.m.role(info.Role); err != nil {
			return nil, fmt.Sprintf("role %q: %v", info.Role, err), nil
		}
	}
	set, extra, skillNames := s.toolSet(ctx, cfg, info)
	cr.set, cr.skills = set, skillNames
	cr.system = systemPrompt(info.WorkingDir, cr.role) + extra + promptAppends(cfg, info.Provider, info.Model)
	cr.req = llm.Request{
		Model:    info.Model,
		Messages: cr.messages(history, cr.compaction),
		Tools:    tools.Definitions(set),
	}
	s.m.applyReasoning(&cr.req, info.Provider, info.Model, info.Effort)
	return cr, "", nil
}

// messages is the system prompt and conversation as the model sees events
// after compaction c (nil: none).
func (cr *chatReq) messages(events []*flitv1.Event, c *flitv1.CompactionDone) []llm.Message {
	system := cr.system
	if c != nil {
		system += summarySection(c.Summary)
	}
	return append([]llm.Message{{Role: "system", Content: system}}, buildMessages(contextEvents(events, c))...)
}

// progress returns the Progress handler of a call's attempt: it logs
// PromptProgress events, about once a second plus the last one (llama.cpp
// reports every batch).
func (s *session) progress(msgID string, attempt int32, appendErr *error) func(llm.PromptProgress) {
	var last time.Time
	return func(p llm.PromptProgress) {
		s.callActivity(0, 0)
		if time.Since(last) < progressInterval && p.Processed < p.Total {
			return
		}
		last = time.Now()
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptProgress{PromptProgress: &flitv1.PromptProgress{
			MessageId: msgID, Attempt: attempt, Processed: p.Processed, Total: p.Total, Cached: p.Cached,
			ElapsedMs: p.Elapsed.Milliseconds(),
		}}}); err != nil {
			*appendErr = err
		}
	}
}

// callEnded is the ModelCallEnded event for one attempt.
func callEnded(msgID string, attempt int32, tr *llm.Trace, res *llm.Result, err error, cancelled, retry bool) *flitv1.Event {
	ms := func(t time.Time) int64 {
		if t.IsZero() || tr.Sent.IsZero() {
			return 0
		}
		return t.Sub(tr.Sent).Milliseconds()
	}
	e := &flitv1.ModelCallEnded{
		MessageId: msgID, Attempt: attempt, Outcome: flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_OK, WillRetry: retry,
		ResponseHeadersMs: ms(tr.Headers), FirstByteMs: ms(tr.FirstByte), FirstTokenMs: ms(tr.FirstToken),
		LastByteMs: ms(tr.LastByte), TotalMs: ms(time.Now()), Bytes: tr.Bytes,
	}
	var stall *llm.StallError
	switch {
	case err == nil:
	case cancelled:
		e.Outcome = flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_CANCELLED
	case errors.As(err, &stall):
		e.Outcome = flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED
	default:
		e.Outcome = flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_ERROR
	}
	if err != nil {
		e.Phase, e.Error = tr.Phase, err.Error()
	}
	if res != nil && res.Usage != nil {
		e.InputTokens, e.OutputTokens = res.Usage.PromptTokens, res.Usage.CompletionTokens
	}
	if t := tr.Timings; t != nil {
		e.PromptTokens, e.PromptMs, e.PredictedTokens, e.PredictedMs = t.PromptN, int64(t.PromptMS), t.PredictedN, int64(t.PredictedMS)
		e.CachedTokens = t.CacheN
	}
	return &flitv1.Event{Payload: &flitv1.Event_ModelCallEnded{ModelCallEnded: e}}
}

func (s *session) runTool(ctx context.Context, turnID string, set []tools.Tool, tc llm.ToolCall) (tools.Result, error) {
	var live int
	var appendErr error
	cfg, info := s.m.cfg(), s.snapshot()
	env := &tools.Env{
		Dir:   info.WorkingDir,
		Shell: cfg.Shell,
		Yolo:  info.Yolo,
		Output: func(out string) {
			if live >= maxLiveToolOutput {
				return
			}
			live += len(out)
			if live >= maxLiveToolOutput {
				out += "\n[live output stopped here; the full result follows when the command ends]\n"
			}
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ToolOutput{ToolOutput: &flitv1.ToolOutput{
				ToolCallId: tc.ID, Text: out,
			}}}); err != nil {
				appendErr = err
			}
		},
		Approve: func(ctx context.Context, a tools.Approval) (bool, error) {
			return s.approve(ctx, tc.ID, a)
		},
		SessionAllowed: s.sessionAllowed(),
		Assess:         s.assessor(cfg, turnID, tc.ID),
		Todo: func(items []tools.TodoItem) {
			ev := &flitv1.TodoUpdated{}
			for _, it := range items {
				ev.Items = append(ev.Items, &flitv1.TodoItem{Content: it.Content, Status: todoStatus(it.Status)})
			}
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_TodoUpdated{TodoUpdated: ev}}); err != nil {
				appendErr = err
			}
		},
	}
	res := tools.Run(ctx, env, set, tc.Function.Name, tc.Function.Arguments)
	if appendErr != nil && !errors.Is(appendErr, errInterrupted) {
		return res, appendErr
	}
	return res, nil
}

func (s *session) toolDone(id string, res tools.Result, maxBytes, maxLines int) error {
	text, omitted, cut := tools.Truncate(res.Text, maxBytes, maxLines)
	_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ToolCallDone{ToolCallDone: &flitv1.ToolCallDone{
		ToolCallId: id, Result: text, IsError: res.IsError, Truncated: cut, OmittedBytes: omitted,
	}}})
	return err
}

func (s *session) messageDone(msgID, text, reasoning, finish string) error {
	_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{
		MessageId: msgID, Text: text, Reasoning: reasoning, FinishReason: finish,
	}}})
	return err
}

// stop records an error; the turn ends stuck.
func (s *session) stop(msg string, canContinue bool) (end, error) {
	_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_Error{Error: &flitv1.TurnError{
		Message: msg, TurnCanContinue: canContinue,
	}}})
	return end{flitv1.TaskState_TASK_STATE_STUCK, msg}, err
}

func todoStatus(s string) flitv1.TodoStatus {
	switch s {
	case "pending":
		return flitv1.TodoStatus_TODO_STATUS_PENDING
	case "in_progress":
		return flitv1.TodoStatus_TODO_STATUS_IN_PROGRESS
	case "completed":
		return flitv1.TodoStatus_TODO_STATUS_COMPLETED
	}
	return flitv1.TodoStatus_TODO_STATUS_UNSPECIFIED
}

// toolSet is the tools offered this turn: the core tools, git and web tools
// as configured, the skill tool when there are skills, and the tools of the
// session's enabled MCP servers. extra is system prompt text that goes with
// them (the skill list, unavailable MCP servers).
func (s *session) toolSet(ctx context.Context, cfg config.Config, info store.Session) ([]tools.Tool, string, []string) {
	set := tools.All()
	var skillNames []string
	var extra strings.Builder
	if cfg.Git.IsEnabled() {
		set = append(set, tools.GitTools()...)
	}
	if cfg.Web.FetchEnabled() {
		set = append(set, tools.WebFetchTool())
	}
	if cfg.Web.Search.Provider == "searxng" {
		set = append(set, tools.WebSearchTool(cfg.Web.Search.URL))
	}
	var global []string
	if s.m.SkillsDirs != nil {
		global = s.m.SkillsDirs()
	}
	{
		list, problems := skills.Load(skills.SessionDirs(info.WorkingDir, global))
		list = skills.WithBuiltin(list)
		for _, p := range problems {
			s.m.log.Warn("skill skipped", "err", p)
		}
		if len(list) > 0 {
			set = append(set, tools.SkillTool(list))
			extra.WriteString(skills.PromptSection(list))
			for _, sk := range list {
				skillNames = append(skillNames, sk.Name)
			}
		}
	}
	if s.m.MCP != nil && len(info.MCPServers) > 0 {
		mcpTools, err := s.m.MCP.Tools(ctx, info.MCPServers)
		if err != nil {
			s.m.log.Warn("MCP servers unavailable", "session", info.ID, "err", err)
			fmt.Fprintf(&extra, "\nSome MCP servers could not be started this turn: %v\n", err)
		}
		for _, t := range mcpTools {
			set = append(set, mcpTool(s.m.MCP, t))
		}
	}
	return set, extra.String(), skillNames
}

// recordCall stores the exact request and response of one model call for
// the training corpus (see store.ModelCall). Failures are logged; they
// never fail the turn.
func (s *session) recordCall(info store.Session, turnID, msgID string, role *roles.Role, skillNames []string,
	req llm.Request, res *llm.Result, text, reasoning string, callErr error) {
	messages := make([][]byte, 0, len(req.Messages))
	for _, m := range req.Messages {
		b, err := json.Marshal(m)
		if err != nil {
			s.m.log.Warn("record model call", "err", err)
			return
		}
		messages = append(messages, b)
	}
	var toolsJSON []byte
	if len(req.Tools) > 0 {
		toolsJSON, _ = json.Marshal(req.Tools)
	}
	params := requestParams(req)
	resp := map[string]any{"role": "assistant", "content": text}
	if reasoning != "" {
		resp["reasoning_content"] = reasoning
	}
	c := &store.ModelCall{
		ID: msgID, SessionID: info.ID, TeamID: info.TeamID, ProjectID: info.ProjectID, TurnID: turnID,
		Provider: info.Provider, Model: info.Model, Effort: info.Effort, FlitVersion: buildinfo.Get().Version,
		Skills: skillNames, Params: params,
	}
	if role != nil {
		c.Role = role.Name
	}
	if res != nil {
		if len(res.ToolCalls) > 0 {
			resp["tool_calls"] = res.ToolCalls
		}
		c.FinishReason = res.FinishReason
		if res.Usage != nil {
			c.Usage, _ = json.Marshal(res.Usage)
		}
		c.Metrics, _ = json.Marshal(map[string]any{
			"time_to_first_token_ms":       res.Metrics.TimeToFirstToken.Milliseconds(),
			"prompt_tokens_per_second":     res.Metrics.PromptPerSecond,
			"generation_tokens_per_second": res.Metrics.GenerationPerSecond,
			"source":                       res.Metrics.Source,
		})
	}
	if callErr != nil {
		c.Error = callErr.Error()
		c.FinishReason = "error"
		if errors.Is(callErr, context.Canceled) {
			c.FinishReason = "interrupted"
		}
	}
	c.Response, _ = json.Marshal(resp)
	if err := s.m.store.RecordModelCall(context.Background(), c, messages, toolsJSON); err != nil {
		s.m.log.Warn("record model call", "session", info.ID, "err", err)
	}
}

func mcpTool(m *mcpclient.Manager, t mcpclient.Tool) tools.Tool {
	desc := t.Description
	if desc == "" {
		desc = t.Name
	}
	return tools.Tool{
		Name:        t.QualifiedName(),
		Description: fmt.Sprintf("[MCP server %s] %s", t.Server, desc),
		Schema:      string(t.Schema),
		Run: func(ctx context.Context, _ *tools.Env, args json.RawMessage) tools.Result {
			out, isErr, err := m.Call(ctx, t, args)
			if err != nil {
				return tools.Result{Text: err.Error(), IsError: true}
			}
			return tools.Result{Text: out, IsError: isErr}
		},
	}
}

// promptAppends is extra system prompt text configured for the provider
// (providers[].prompt_append) and the model (agent.model_prompt_appends).
func promptAppends(cfg config.Config, provider, model string) string {
	var parts []string
	if p, ok := cfg.Provider(provider); ok && strings.TrimSpace(p.PromptAppend) != "" {
		parts = append(parts, strings.TrimSpace(p.PromptAppend))
	}
	if t := strings.TrimSpace(cfg.Agent.ModelPromptAppends[provider+"/"+model]); t != "" {
		parts = append(parts, t)
	}
	if len(parts) == 0 {
		return ""
	}
	return "\n" + strings.Join(parts, "\n\n") + "\n"
}

// requestParams is the request apart from messages and tools, as recorded
// for export.
func requestParams(req llm.Request) json.RawMessage {
	p := map[string]any{
		"model":            req.Model,
		"reasoning_effort": req.ReasoningEffort,
		"stream":           true,
		// flit sends no sampling parameters; the provider's defaults apply.
		"sampling": "provider defaults",
	}
	if req.ChatTemplateKwargs != nil {
		p["chat_template_kwargs"] = req.ChatTemplateKwargs
	}
	b, _ := json.Marshal(p)
	return b
}
