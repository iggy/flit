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
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/store"
)

// Compaction: when a conversation gets long, its older part is summarized
// by a model and from then on the model sees the summary (in the system
// prompt) plus the latest turns instead of the whole log. It happens at a
// step boundary, before a model call: on its own near the context limit
// (agent.compaction), or because someone asked (Compact). The log keeps
// everything; CompactionDone says where the summary ends (covered_seq),
// and the context is rebuilt from the latest one (see contextEvents).

// compactPrompt asks for the summary, after the conversation it covers.
// Short and plain, for small local models.
const compactPrompt = `The conversation above is too long for your context window, so it will be replaced by a summary. Write that summary now. It is all you will have of the conversation so far, so include what you need to carry on.

Write plain text under these headings:
Goal: what the user wants overall, and their latest request.
Progress: what has been done: files read or changed, commands run and what they showed, decisions made.
Current state: what is in progress, open problems, and what to do next.
Details: exact names, paths, values, errors and user preferences worth keeping.

Be brief and factual. Do not call tools, do not continue the task, and write nothing but the summary.`

// summarySection is the summary as it goes in the system prompt.
func summarySection(summary string) string {
	return "\n# Earlier in this session\n\nThe start of this conversation was replaced by this summary to save context:\n\n" +
		strings.TrimSpace(summary) + "\n"
}

// compactAsk is a Compact request waiting for the running turn's next step.
type compactAsk struct {
	client, instructions string
}

// ctxUse is how much of the model's context a request takes.
type ctxUse struct {
	tokens, length int64
	// exact: counted by the server (llama.cpp), not estimated.
	exact bool
}

// over reports whether the request fills threshold of a known window.
func (u ctxUse) over(threshold float64) bool {
	return u.length > 0 && float64(u.tokens) >= threshold*float64(u.length)
}

// estimateTokens guesses a request's prompt size: a token per 4 bytes.
func estimateTokens(req llm.Request) int64 {
	n := 0
	for _, m := range req.Messages {
		n += len(m.Content) + len(m.Role) + 8
		for _, tc := range m.ToolCalls {
			n += len(tc.Function.Name) + len(tc.Function.Arguments) + 16
		}
	}
	if len(req.Tools) > 0 {
		b, _ := json.Marshal(req.Tools)
		n += len(b)
	}
	return int64(n / 4)
}

// contextUse measures req against the session's model's context window:
// the catalog's, or on llama.cpp the slots' real n_ctx. llama.cpp counts
// tokens exactly when the estimate gets anywhere near the threshold (or
// always, with exact); elsewhere it's the estimate.
func (s *session) contextUse(ctx context.Context, cfg config.Config, info store.Session, p config.Provider, req llm.Request, exact bool) ctxUse {
	u := ctxUse{tokens: estimateTokens(req), length: s.m.contextLength(info.Provider, info.Model)}
	llama, router := s.m.isLlamaCpp(info.Provider)
	if !llama {
		return u
	}
	c := s.m.llamaClient(p, router)
	if slots, err := c.Slots(ctx, info.Model); err == nil && len(slots) > 0 && slots[0].NCtx > 0 {
		u.length = int64(slots[0].NCtx)
	}
	if u.length > 0 && (exact || float64(u.tokens) >= 0.5*cfg.Agent.Compaction.Threshold*float64(u.length)) {
		if n, err := c.InputTokens(ctx, req); err == nil {
			u.tokens, u.exact = n, true
		}
	}
	return u
}

// cut is where a compaction's summary ends.
type cut struct {
	// covered is the last event the summary covers.
	covered int64
	// kept is how many user messages stay verbatim after it.
	kept int
}

// chooseCut picks what to summarize among the events after the previous
// summary (seq > after): everything before the last keep turns. If there
// aren't that many and midTurn allows it, the running turn is cut before
// its last step (its user message is kept; see contextEvents). Failing
// both, fewer turns are kept, down to minKeep. ok is false when nothing
// would be summarized.
func chooseCut(events []*flitv1.Event, after int64, keep, minKeep int, midTurn bool) (c cut, ok bool) {
	var users, steps []int64 // starts of user messages, and of the last turn's model calls
	var last int64
	for _, ev := range events {
		if ev.Seq <= after {
			continue
		}
		last = ev.Seq
		if ms := ev.GetMessageStarted(); ms != nil {
			if ms.Role == flitv1.Role_ROLE_USER {
				users, steps = append(users, ev.Seq), nil
			} else {
				steps = append(steps, ev.Seq)
			}
		}
	}
	if len(users) > keep {
		return cut{covered: users[len(users)-keep] - 1, kept: keep}, true
	}
	if midTurn && len(steps) >= 2 {
		return cut{covered: steps[len(steps)-1] - 1, kept: 1}, true
	}
	for k := keep - 1; k >= minKeep; k-- {
		if len(users) > k {
			if k == 0 {
				return cut{covered: last}, true
			}
			return cut{covered: users[len(users)-k] - 1, kept: k}, true
		}
	}
	return cut{}, false
}

// compactOpts are the inputs to compact.
type compactOpts struct {
	auto                 bool
	client, instructions string
	// midTurn allows cutting the running turn; minKeep is the fewest turns
	// to keep (see chooseCut).
	midTurn bool
	minKeep int
	// turnID is the turn it happens in ("" between turns), for the record.
	turnID string
	// before is the context use now.
	before ctxUse
}

// compact summarizes the conversation in cr up to a cut and records it. It
// returns the compaction that took effect: nil when it failed (the
// failure is in the log) or there was nothing to do. err is set only when
// the log can't be written.
func (s *session) compact(ctx context.Context, cfg config.Config, info store.Session, cr *chatReq, o compactOpts) (*flitv1.CompactionDone, error) {
	var after int64
	if cr.compaction != nil {
		after = cr.compaction.CoveredSeq
	}
	cp := cfg.Agent.Compaction
	c, ok := chooseCut(cr.history, after, cp.KeepTurns, o.minKeep, o.midTurn)
	if !ok {
		if o.auto {
			return nil, nil
		}
		_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_CompactionDone{CompactionDone: &flitv1.CompactionDone{
			CompactionId: newID("cmp"), Error: "nothing to compact yet",
		}}})
		return nil, err
	}

	// The compaction task model, else the session's own.
	task, ok := cfg.Task("compaction")
	if !ok {
		task = config.TaskModel{Provider: info.Provider, Model: info.Model, Effort: info.Effort}
	}
	id, callID := newID("cmp"), newID("msg")
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_CompactionStarted{CompactionStarted: &flitv1.CompactionStarted{
		CompactionId: id, Auto: o.auto, Client: o.client, Tokens: o.before.tokens, ContextLength: o.before.length,
		Provider: task.Provider, Model: task.Model,
	}}}); err != nil {
		return nil, err
	}
	start := time.Now()
	done := &flitv1.CompactionDone{
		CompactionId: id, Auto: o.auto, CoveredSeq: c.covered, KeptTurns: int32(c.kept),
		TokensBefore: o.before.tokens, ContextLength: o.before.length,
		Provider: task.Provider, Model: task.Model, ModelCallId: callID,
	}
	fail := func(msg string) (*flitv1.CompactionDone, error) {
		done.Summary, done.CoveredSeq, done.KeptTurns, done.TokensAfter = "", 0, 0, 0
		done.Error, done.ElapsedMs = msg, time.Since(start).Milliseconds()
		_, err := s.append(&flitv1.Event{Payload: &flitv1.Event_CompactionDone{CompactionDone: done}})
		return nil, err
	}

	// The same system prompt, tools and conversation as the chat call, up
	// to the cut, so a server's prompt cache of it still applies; then the
	// request for the summary.
	instr := compactPrompt
	if cr.compaction != nil {
		instr += "\n\nThe system prompt holds a summary of what came before; keep what still matters from it."
	}
	if o.instructions != "" {
		instr += "\n\nAlso: " + o.instructions
	}
	req := llm.Request{
		Model:     task.Model,
		Messages:  append(cr.messages(upTo(cr.history, c.covered), cr.compaction), llm.Message{Role: "user", Content: instr}),
		Tools:     cr.req.Tools,
		MaxTokens: cp.MaxSummaryTokens,
	}
	if len(req.Tools) > 0 {
		req.ToolChoice = "none"
	}
	s.m.applyReasoning(&req, task.Provider, task.Model, task.Effort)
	provider, ok := cfg.Provider(task.Provider)
	if !ok {
		return fail(fmt.Sprintf("provider %q is not in the config", task.Provider))
	}
	header, err := provider.Header()
	if err != nil {
		return fail(err.Error())
	}
	res, callErr, err := s.summaryCall(ctx, cfg, provider, header, task.Model, req, callID)
	if err != nil {
		return nil, err
	}
	s.recordTaskCall(info, o.turnID, callID, "compaction", task, req, res, callErr)
	summary := ""
	if res != nil {
		summary = strings.TrimSpace(res.Text)
	}
	switch {
	case ctx.Err() != nil:
		return fail("interrupted")
	case callErr != nil:
		return fail("the summary model call failed: " + callErr.Error())
	case res.FinishReason == "length":
		return fail(fmt.Sprintf("the summary was cut off at agent.compaction.max_summary_tokens (%d)", cp.MaxSummaryTokens))
	case summary == "":
		return fail("the model wrote no summary")
	}

	done.Summary = summary
	next := cr.req
	next.Messages = cr.messages(cr.history, done)
	after2 := s.contextUse(ctx, cfg, info, mustProvider(cfg, info.Provider), next, true)
	done.TokensAfter, done.TokensExact = after2.tokens, after2.exact && o.before.exact
	done.ElapsedMs = time.Since(start).Milliseconds()
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_CompactionDone{CompactionDone: done}}); err != nil {
		return nil, err
	}
	// The prompt now starts differently: a saved llama.cpp cache of the
	// old one must not be restored.
	s.m.discardKV(s)
	return done, nil
}

func mustProvider(cfg config.Config, name string) config.Provider {
	p, _ := cfg.Provider(name)
	return p
}

// summaryCall makes the summarization call, with ModelCallStarted/Ended
// (and llama.cpp progress and waiting) events under callID, the watchdog,
// automatic retries of calls that failed before any output, and
// RetryModelCall. callErr is the call's failure; err is set only when the
// log can't be written.
func (s *session) summaryCall(ctx context.Context, cfg config.Config, p config.Provider, header http.Header, model string, req llm.Request, callID string) (res *llm.Result, callErr, err error) {
	llama, router := s.m.isLlamaCpp(p.Name)
	if llama {
		req.ReturnProgress = true
	}
	client := &llm.Client{
		BaseURL: p.BaseURL, APIKey: p.Key(), Header: header, HTTP: s.m.http,
		FirstTokenTimeout: cfg.Agent.ModelFirstTokenTimeout, StallTimeout: cfg.Agent.ModelStallTimeout,
	}
	autoRetries := 0
	for attempt := int32(1); ; attempt++ {
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{
			MessageId: callID, Attempt: attempt,
			FirstByteTimeoutMs: cfg.Agent.ModelFirstTokenTimeout.Milliseconds(),
			StallTimeoutMs:     cfg.Agent.ModelStallTimeout.Milliseconds(),
		}}}); err != nil {
			return nil, nil, err
		}
		var appendErr error
		output := 0
		callCtx, cancelCall := context.WithCancelCause(ctx)
		live := &liveCall{msgID: callID, provider: p, model: model, router: router}
		s.setCall(cancelCall, live)
		stopWait := func() {}
		if llama {
			stopWait = s.watchWait(callCtx, s.m.llamaClient(p, router), live, attempt, nil)
		}
		var trace *llm.Trace
		res, trace, callErr = client.StreamTrace(callCtx, req, llm.Handler{
			ID:        s.callID,
			Text:      func(d string) { s.callActivity(len(d), 0); output += len(d) },
			Reasoning: func(d string) { s.callActivity(0, len(d)); output += len(d) },
			Progress:  s.progress(callID, attempt, &appendErr),
		})
		stopWait()
		userRetry := callErr != nil && ctx.Err() == nil && errors.Is(context.Cause(callCtx), errUserRetry)
		s.setCall(nil, nil)
		cancelCall(nil)
		if appendErr != nil {
			return nil, nil, appendErr
		}
		autoRetry := callErr != nil && !userRetry && ctx.Err() == nil && llm.Retryable(callErr) &&
			output == 0 && autoRetries < cfg.Agent.ModelRetries
		ended := callEnded(callID, attempt, trace, res, callErr, ctx.Err() != nil, userRetry || autoRetry)
		if userRetry {
			e := ended.GetModelCallEnded()
			e.Outcome, e.Error = flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED, "retried by request"
		}
		if _, err := s.append(ended); err != nil {
			return nil, nil, err
		}
		if !userRetry && !autoRetry {
			return res, callErr, nil
		}
		if autoRetry {
			autoRetries++
		}
		s.m.log.Warn("compaction call failed before any output; retrying", "session", s.info.ID, "attempt", attempt, "by_request", userRetry, "err", callErr)
	}
}

// takeCompactAsk returns and clears a pending Compact request.
func (s *session) takeCompactAsk() *compactAsk {
	s.mu.Lock()
	defer s.mu.Unlock()
	a := s.compactAsk
	s.compactAsk = nil
	return a
}

// requestCompact compacts the session now, as a run of its own, or while
// a turn runs, at the turn's next step (queued).
func (s *session) requestCompact(client, instructions string) (queued bool, err error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ask := compactAsk{client: client, instructions: instructions}
	if s.cancelTurn != nil {
		s.compactAsk = &ask
		return true, nil
	}
	if s.info.Provider == "" || s.info.Model == "" {
		return false, invalid("no model chosen for this session")
	}
	history, err := s.m.store.EventsOfKinds(context.Background(), s.info.ID, historyKinds...)
	if err != nil {
		return false, err
	}
	var after int64
	if c := lastCompaction(history); c != nil {
		after = c.CoveredSeq
	}
	if _, ok := chooseCut(history, after, s.m.cfg().Agent.Compaction.KeepTurns, 0, false); !ok {
		return false, invalid("nothing to compact yet")
	}
	return false, s.startCompactionLocked(ask)
}

// startCompactionLocked marks the session working and compacts it. Like
// a turn, it can be interrupted, and messages sent meanwhile are queued.
func (s *session) startCompactionLocked(ask compactAsk) error {
	if _, err := s.appendLocked(stateChanged(flitv1.TaskState_TASK_STATE_WORKING, "compacting")); err != nil {
		return err
	}
	ctx, cancel := context.WithCancel(context.Background())
	s.cancelTurn = cancel
	s.m.turns.Add(1)
	go func() {
		defer s.m.turns.Done()
		defer cancel()
		s.endTurn(s.runCompaction(ctx, ask))
	}()
	return nil
}

// runCompaction compacts between turns: everything but the latest turns,
// down to all of it.
func (s *session) runCompaction(ctx context.Context, ask compactAsk) end {
	cfg, info := s.m.cfg(), s.snapshot()
	e, err := func() (end, error) {
		provider, _, stopMsg := checkModel(cfg, info)
		if stopMsg != "" {
			return s.stop(stopMsg, false)
		}
		cr, stopMsg, err := s.chatRequest(ctx, cfg, info)
		if err != nil {
			return end{}, err
		}
		if stopMsg != "" {
			return s.stop(stopMsg, false)
		}
		o := compactOpts{client: ask.client, instructions: ask.instructions, minKeep: 0,
			before: s.contextUse(ctx, cfg, info, provider, cr.req, true)}
		if _, err := s.compact(ctx, cfg, info, cr, o); err != nil {
			return end{}, err
		}
		if ctx.Err() != nil {
			return endInterrupted, nil
		}
		return endDone, nil
	}()
	if err != nil {
		s.m.log.Error("compaction failed", "session", info.ID, "err", err)
		return end{flitv1.TaskState_TASK_STATE_STUCK, "internal error: " + err.Error()}
	}
	return e
}
