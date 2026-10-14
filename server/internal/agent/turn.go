package agent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

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
	s.mu.Lock()
	defer s.mu.Unlock()
	s.cancelTurn = nil
	if _, err := s.appendLocked(stateChanged(e.state, e.reason)); err != nil {
		s.m.log.Error("could not record end of turn", "session", s.info.ID, "err", err)
	}
}

// loop runs the turn and says how it ended. It returns an error only if the
// event log can't be written.
func (s *session) loop(ctx context.Context, turnID string) (end, error) {
	for step := 0; ; step++ {
		cfg := s.m.cfg()
		if step >= cfg.Agent.MaxSteps {
			return s.stop(fmt.Sprintf("stopped after %d model calls (agent.max_steps)", step), true)
		}

		info := s.snapshot()
		provider, ok := cfg.Provider(info.Provider)
		switch {
		case info.Provider == "":
			return s.stop("no provider configured for this session; add one under providers in the config and call SetModel", false)
		case !ok:
			return s.stop(fmt.Sprintf("provider %q is not in the config", info.Provider), false)
		case info.Model == "":
			return s.stop("no model chosen for this session; call SetModel or set agent.model in the config", false)
		}

		history, err := s.m.store.EventsOfKinds(context.Background(), info.ID, historyKinds...)
		if err != nil {
			return end{}, err
		}
		var role *roles.Role
		if info.Role != "" {
			if role, err = s.m.role(info.Role); err != nil {
				return s.stop(fmt.Sprintf("role %q: %v", info.Role, err), false)
			}
		}
		set, extra, skillNames := s.toolSet(ctx, cfg, info)
		system := systemPrompt(info.WorkingDir, role) + extra + promptAppends(cfg, info.Provider, info.Model)
		req := llm.Request{
			Model:           info.Model,
			Messages:        append([]llm.Message{{Role: "system", Content: system}}, buildMessages(history)...),
			Tools:           tools.Definitions(set),
			ReasoningEffort: info.Effort,
		}

		msgID := newID("msg")
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{
			MessageId: msgID, Role: flitv1.Role_ROLE_ASSISTANT, Provider: info.Provider, Model: info.Model,
		}}}); err != nil {
			return end{}, err
		}

		var text, reasoning strings.Builder
		var appendErr error
		client := &llm.Client{BaseURL: provider.BaseURL, APIKey: provider.Key(), HTTP: s.m.http}
		res, err := client.Stream(ctx, req, llm.Handler{
			Text: func(d string) {
				text.WriteString(d)
				if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: msgID, Text: d}}}); err != nil {
					appendErr = err
				}
			},
			Reasoning: func(d string) {
				reasoning.WriteString(d)
				if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ReasoningDelta{ReasoningDelta: &flitv1.ReasoningDelta{MessageId: msgID, Text: d}}}); err != nil {
					appendErr = err
				}
			},
		})
		if appendErr != nil {
			return end{}, appendErr
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
			return s.stop(err.Error(), llm.Retryable(err))
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
			res, err := s.runTool(ctx, set, tc)
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

func (s *session) runTool(ctx context.Context, set []tools.Tool, tc llm.ToolCall) (tools.Result, error) {
	var live int
	var appendErr error
	env := &tools.Env{
		Dir:   s.snapshot().WorkingDir,
		Shell: s.m.cfg().Shell,
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
		Approve: func(ctx context.Context, title, detail string) (bool, error) {
			return s.approve(ctx, tc.ID, title, detail)
		},
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
	params, _ := json.Marshal(map[string]any{
		"model":            req.Model,
		"reasoning_effort": req.ReasoningEffort,
		"stream":           true,
		// flit sends no sampling parameters; the provider's defaults apply.
		"sampling": "provider defaults",
	})
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
