package agent

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strings"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// permissionTimeout bounds one safety check. When it runs out the user is
// asked, as if there were no check.
const permissionTimeout = 60 * time.Second

const permissionPrompt = `You are the safety check of a coding agent. The agent wants to run a shell command in a software project, and the user will be asked to approve it unless you rate it safe.

Rate the command:
- "safe": it only reads, builds or tests, or changes files inside the project in an ordinary, easily undone way (formatting, code generation, installing the project's own dependencies).
- "ask": the user should decide: it deletes or overwrites things, touches files outside the project, changes git history or remotes, installs software system-wide, sends data over the network, starts long-running services, or you aren't sure.
- "block": it is clearly destructive or malicious: wiping disks or home directories, exfiltrating secrets or credentials, disabling security, fork bombs, piping downloaded scripts into a shell from unknown sources.

Answer with only a JSON object, no other text: {"verdict": "safe" | "ask" | "block", "reason": "<one short sentence>"}`

// assessor returns the safety check for shell commands in this turn, or
// nil when no permission model is configured.
func (s *session) assessor(cfg config.Config, turnID, toolCallID string) func(context.Context, string, string) tools.Assessment {
	task, ok := cfg.Task("permission")
	if !ok {
		return nil
	}
	provider, ok := cfg.Provider(task.Provider)
	if !ok {
		return nil
	}
	return func(ctx context.Context, command, workdir string) tools.Assessment {
		info := s.snapshot()
		ctx, cancel := context.WithTimeout(ctx, permissionTimeout)
		defer cancel()
		user := fmt.Sprintf("Project directory: %s\nWorking directory for the command: %s\nCommand:\n%s", info.WorkingDir, workdir, command)
		req := llm.Request{
			Model:    task.Model,
			Messages: []llm.Message{{Role: "system", Content: permissionPrompt}, {Role: "user", Content: user}},
		}
		s.m.applyReasoning(&req, task.Provider, task.Model, task.EffortLevel())
		client := &llm.Client{BaseURL: provider.BaseURL, APIKey: provider.Key(), HTTP: s.m.http}
		res, err := client.Stream(ctx, req, llm.Handler{})

		a := tools.Assessment{Verdict: tools.VerdictError}
		switch {
		case err != nil:
			a.Reason = "the safety check failed: " + err.Error()
		default:
			a = parseVerdict(res.Text)
		}
		callID := newID("msg")
		s.recordPermissionCall(info, turnID, callID, task, req, res, err)
		check := &flitv1.PermissionCheck{
			ToolCallId: toolCallID, Command: command, Verdict: verdictProto(a.Verdict), Reason: a.Reason,
			Provider: task.Provider, Model: task.Model, ModelCallId: callID, TurnId: turnID,
		}
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PermissionCheck{PermissionCheck: check}}); err != nil {
			s.m.log.Error("could not record permission check", "session", info.ID, "err", err)
			// Not in the log, so it must not take effect.
			return tools.Assessment{Verdict: tools.VerdictError, Reason: "the safety check could not be recorded"}
		}
		return a
	}
}

var jsonObject = regexp.MustCompile(`(?s)\{.*\}`)

// parseVerdict reads the model's answer. Anything unreadable is an error
// verdict, so the user is asked.
func parseVerdict(text string) tools.Assessment {
	var v struct {
		Verdict string `json:"verdict"`
		Reason  string `json:"reason"`
	}
	raw := jsonObject.FindString(text)
	if raw == "" || json.Unmarshal([]byte(raw), &v) != nil {
		return tools.Assessment{Verdict: tools.VerdictError, Reason: "the safety check gave no readable answer"}
	}
	reason := strings.TrimSpace(v.Reason)
	switch strings.ToLower(strings.TrimSpace(v.Verdict)) {
	case "safe":
		return tools.Assessment{Verdict: tools.VerdictSafe, Reason: reason}
	case "ask":
		return tools.Assessment{Verdict: tools.VerdictAsk, Reason: reason}
	case "block":
		if reason == "" {
			reason = "it looks dangerous"
		}
		return tools.Assessment{Verdict: tools.VerdictBlock, Reason: reason}
	}
	return tools.Assessment{Verdict: tools.VerdictError, Reason: fmt.Sprintf("the safety check answered %q", v.Verdict)}
}

func verdictProto(v tools.Verdict) flitv1.PermissionVerdict {
	switch v {
	case tools.VerdictSafe:
		return flitv1.PermissionVerdict_PERMISSION_VERDICT_SAFE
	case tools.VerdictAsk:
		return flitv1.PermissionVerdict_PERMISSION_VERDICT_ASK
	case tools.VerdictBlock:
		return flitv1.PermissionVerdict_PERMISSION_VERDICT_BLOCK
	}
	return flitv1.PermissionVerdict_PERMISSION_VERDICT_ERROR
}

// recordPermissionCall stores the safety check's model call for export,
// as task "permission".
func (s *session) recordPermissionCall(info store.Session, turnID, callID string, task config.TaskModel, req llm.Request, res *llm.Result, callErr error) {
	var messages [][]byte
	for _, m := range req.Messages {
		b, _ := json.Marshal(m)
		messages = append(messages, b)
	}
	c := &store.ModelCall{
		ID: callID, SessionID: info.ID, TeamID: info.TeamID, ProjectID: info.ProjectID, TurnID: turnID, Task: "permission",
		Provider: task.Provider, Model: task.Model, Effort: task.EffortLevel(), FlitVersion: buildinfo.Get().Version, Params: requestParams(req),
	}
	resp := map[string]any{"role": "assistant", "content": ""}
	if res != nil {
		resp["content"] = res.Text
		if res.Reasoning != "" {
			resp["reasoning_content"] = res.Reasoning
		}
		c.FinishReason = res.FinishReason
		if res.Usage != nil {
			c.Usage, _ = json.Marshal(res.Usage)
		}
	}
	if callErr != nil {
		c.Error, c.FinishReason = callErr.Error(), "error"
	}
	c.Response, _ = json.Marshal(resp)
	if err := s.m.store.RecordModelCall(context.Background(), c, messages, nil); err != nil {
		s.m.log.Warn("record permission call", "session", info.ID, "err", err)
	}
}

// applyReasoning sets how much the model thinks. effort is "off", a level
// (low, medium, high, or one the provider names), or empty for the model's
// default. "off" turns thinking off on llama.cpp (chat_template_kwargs
// enable_thinking=false) and is ignored elsewhere; a level is sent as
// reasoning_effort unless the catalog knows the model doesn't reason
// (llama.cpp gets it anyway: it ignores what it can't use, and often
// can't say whether a model reasons).
func (m *Manager) applyReasoning(req *llm.Request, provider, model, effort string) {
	if effort == "" {
		return
	}
	var kind models.Kind
	if m.Catalog != nil {
		kind = m.Catalog.Kind(provider)
	}
	if effort == "off" {
		if kind == models.KindLlamaCpp {
			req.ChatTemplateKwargs = map[string]any{"enable_thinking": false}
		}
		return
	}
	if m.Catalog != nil && kind != models.KindLlamaCpp {
		if info, ok := m.Catalog.Lookup(provider, model); ok && !info.SupportsReasoning {
			return
		}
	}
	req.ReasoningEffort = effort
}
