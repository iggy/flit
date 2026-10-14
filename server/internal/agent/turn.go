package agent

import (
	"context"
	"errors"
	"fmt"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm"
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
func (s *session) runTurn(ctx context.Context) {
	e, err := s.loop(ctx)
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
func (s *session) loop(ctx context.Context) (end, error) {
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
		req := llm.Request{
			Model:    info.Model,
			Messages: append([]llm.Message{{Role: "system", Content: systemPrompt(info.WorkingDir)}}, buildMessages(history)...),
			Tools:    tools.Definitions(),
		}

		msgID := newID("msg")
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{
			MessageId: msgID, Role: flitv1.Role_ROLE_ASSISTANT,
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
		if res.Usage != nil {
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_Usage{Usage: &flitv1.Usage{
				MessageId: msgID, InputTokens: res.Usage.PromptTokens, OutputTokens: res.Usage.CompletionTokens, TotalTokens: res.Usage.TotalTokens,
			}}}); err != nil {
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
			res, err := s.runTool(ctx, tc)
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

func (s *session) runTool(ctx context.Context, tc llm.ToolCall) (tools.Result, error) {
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
	}
	res := tools.Run(ctx, env, tc.Function.Name, tc.Function.Arguments)
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
