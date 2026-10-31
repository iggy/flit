package agent

import (
	"context"
	"errors"
	"sync"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llamacpp"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/timeline"
)

// Debugging frozen turns: which layer is stuck, the model, llama.cpp, the
// network between, or flit itself. Each model call's ModelCallEnded
// carries its phase timestamps and, when it went wrong on llama.cpp, what
// the server said it was doing right after (diagnoseEnd). Debug reports a
// running server's live state (SystemService.DebugDump).

// Timings for asking a llama.cpp server what it is doing; vars for tests.
var (
	// serverAskTimeout bounds each request; serverSampleGap is how far
	// apart the two slot samples are.
	serverAskTimeout = 4 * time.Second
	serverSampleGap  = 2 * time.Second
	// debugLockWait is how long Debug waits for a session's lock before
	// reporting it held.
	debugLockWait = 2 * time.Second
)

// stallProbe is the llm.Client OnStall hook of llama.cpp call c: it asks
// the server what it is doing while it still has the request, for
// diagnoseEnd. nil for other providers.
func (s *session) stallProbe(ctx context.Context, c *liveCall) func(llm.Trace) {
	if !c.llama {
		return nil
	}
	return func(llm.Trace) {
		st := s.m.serverState(ctx, c.provider, c.router, c.model, c.slot)
		s.mu.Lock()
		defer s.mu.Unlock()
		c.server = st
	}
}

// diagnoseEnd completes the ModelCallEnded event ev of call c when it
// stalled, failed or was retried: for llama.cpp it adds the server's state
// (sampled before the call was given up on, or now for a failure), and it
// logs what happened with a diagnosis. ctx is the turn's: no sampling once
// it ends.
func (s *session) diagnoseEnd(ctx context.Context, ev *flitv1.Event, err error, c *liveCall) {
	e := ev.GetModelCallEnded()
	if e == nil {
		return
	}
	switch e.Outcome {
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED, flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED:
	case flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_ERROR:
		if !llm.Retryable(err) {
			return // the server answered with an error; nothing hangs
		}
	default:
		return
	}
	if c.llama {
		s.mu.Lock()
		e.Server = c.server
		s.mu.Unlock()
		if e.Server == nil && ctx.Err() == nil {
			e.Server = s.m.serverState(ctx, c.provider, c.router, c.model, c.slot)
		}
	}
	attrs := []any{"session", s.snapshot().ID, "message", e.MessageId, "attempt", e.Attempt, "provider", c.provider.Name, "model", c.model,
		"phase", e.Phase, "after_ms", e.TotalMs, "last_byte_ms", e.LastByteMs, "bytes", e.Bytes, "streamed_tokens", e.StreamedTokens}
	if e.PromptTotal > 0 {
		attrs = append(attrs, "prompt_processed", e.PromptProcessed, "prompt_total", e.PromptTotal)
	}
	if err != nil {
		attrs = append(attrs, "err", err)
	}
	if d := timeline.Diagnose(e); d != "" {
		attrs = append(attrs, "diagnosis", d)
	}
	s.m.log.Warn("model call "+timeline.Outcome(e.Outcome), attrs...)
}

// serverState asks a llama.cpp server about model: its state and its
// slots, sampled twice serverSampleGap apart when one is busy, to see
// whether it is getting anywhere.
func (m *Manager) serverState(ctx context.Context, p config.Provider, router bool, model string, slot *int) *flitv1.ModelServerState {
	c := m.llamaClient(p, router)
	st := &flitv1.ModelServerState{}
	if slot != nil {
		v := int32(*slot)
		st.PinnedSlot = &v
	}
	ask := func(f func(ctx context.Context) error) error {
		ctx, cancel := context.WithTimeout(ctx, serverAskTimeout)
		defer cancel()
		return f(ctx)
	}
	if err := ask(func(ctx context.Context) (err error) {
		st.ModelState, err = c.State(ctx, model)
		return err
	}); err != nil {
		st.Error = askError(err)
	}
	var first []llamacpp.Slot
	if err := ask(func(ctx context.Context) (err error) {
		first, err = c.Slots(ctx, model)
		return err
	}); err != nil {
		st.SlotsError = askError(err)
		return st
	}
	busy := false
	for _, sl := range first {
		busy = busy || sl.IsProcessing
	}
	if !busy {
		st.Slots = slotsProto(first, nil)
		return st
	}
	start := time.Now()
	select {
	case <-ctx.Done():
		st.Slots = slotsProto(first, nil)
		return st
	case <-time.After(serverSampleGap):
	}
	var second []llamacpp.Slot
	if err := ask(func(ctx context.Context) (err error) {
		second, err = c.Slots(ctx, model)
		return err
	}); err != nil {
		st.SlotsError = "second sample: " + askError(err)
		st.Slots = slotsProto(first, nil)
		return st
	}
	st.SampleMs = time.Since(start).Milliseconds()
	st.Slots = slotsProto(second, first)
	return st
}

func askError(err error) string {
	if errors.Is(err, context.DeadlineExceeded) {
		return "no answer within " + serverAskTimeout.String()
	}
	return err.Error()
}

// slotsProto converts slots, with how far each got since before (nil: no
// earlier sample).
func slotsProto(slots, before []llamacpp.Slot) []*flitv1.LlamaSlot {
	prev := map[int]llamacpp.Slot{}
	for _, sl := range before {
		prev[sl.ID] = sl
	}
	out := make([]*flitv1.LlamaSlot, 0, len(slots))
	for _, sl := range slots {
		ls := &flitv1.LlamaSlot{
			Id: int32(sl.ID), IsProcessing: sl.IsProcessing, IdTask: sl.IDTask, NCtx: int64(sl.NCtx),
			PromptTokens: sl.NPromptTokens, PromptProcessed: sl.NPromptTokensProcessed, PromptCached: sl.NPromptTokensCache,
			Decoded: sl.NDecoded,
		}
		if p, ok := prev[sl.ID]; ok && p.IDTask == sl.IDTask {
			ls.PromptProcessedDelta = max(0, sl.NPromptTokensProcessed-p.NPromptTokensProcessed)
			ls.DecodedDelta = max(0, sl.NDecoded-p.NDecoded)
		}
		out = append(out, ls)
	}
	return out
}

// --- Live state ---

// setLive gives the call in flight its live trace.
func (s *session) setLive(c *liveCall, snap func() llm.Trace) {
	s.mu.Lock()
	defer s.mu.Unlock()
	c.snap = snap
}

// liveTool is the tool a turn is running.
type liveTool struct {
	id, name string
	start    time.Time
}

func (s *session) setTool(t *liveTool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.tool = t
}

// addSubCall registers a subagent's model call in flight; the returned
// func removes it.
func (s *session) addSubCall(c *liveCall) (remove func()) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.subCalls == nil {
		s.subCalls = map[*liveCall]struct{}{}
	}
	s.subCalls[c] = struct{}{}
	return func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		delete(s.subCalls, c)
	}
}

// lockWithin takes mu, waiting at most d; it reports whether it did.
func lockWithin(mu *sync.Mutex, d time.Duration) bool {
	deadline := time.Now().Add(d)
	for {
		if mu.TryLock() {
			return true
		}
		if time.Now().After(deadline) {
			return false
		}
		time.Sleep(5 * time.Millisecond)
	}
}

// Debug reports the live state of the loaded sessions and of the model
// concurrency limits. It never blocks on a stuck lock for longer than
// debugLockWait: a lock it can't take is reported as held.
func (m *Manager) Debug() *flitv1.DebugDumpResponse {
	res := &flitv1.DebugDumpResponse{Time: timestamppb.Now()}
	cfg := m.cfg()
	for _, l := range m.limiter.Snapshot() {
		res.Limits = append(res.Limits, &flitv1.ModelLimitDebug{Provider: l.Provider, Model: l.Model,
			Limit: int32(cfg.Concurrency(l.Provider, l.Model)), InUse: int32(l.InUse), Waiting: int32(l.Waiting)})
	}
	if !lockWithin(&m.mu, debugLockWait) {
		return res
	}
	res.SessionsLockFree = true
	type loaded struct {
		id string
		s  *session
	}
	list := make([]loaded, 0, len(m.sessions))
	for id, s := range m.sessions {
		list = append(list, loaded{id, s})
	}
	m.mu.Unlock()

	// In parallel, so one stuck session doesn't hold up the rest.
	out := make([]*flitv1.SessionDebug, len(list))
	var wg sync.WaitGroup
	for i, l := range list {
		wg.Add(1)
		go func() {
			defer wg.Done()
			out[i] = l.s.debug(l.id)
		}()
	}
	wg.Wait()
	res.Sessions = out
	return res
}

// debug is the session's live state; id is its id (s.info needs the
// lock).
func (s *session) debug(id string) *flitv1.SessionDebug {
	d := &flitv1.SessionDebug{SessionId: id}
	if !lockWithin(&s.mu, debugLockWait) {
		return d
	}
	d.LockFree = true
	d.Title, d.State, d.TurnRunning, d.LastSeq = s.info.Title, s.info.State, s.cancelTurn != nil, s.info.LastSeq
	if !s.info.UpdatedAt.IsZero() {
		d.LastEventTime = timestamppb.New(s.info.UpdatedAt)
	}
	d.QueuedMessages, d.PendingPrompts = int32(len(s.queue)), int32(len(s.prompts))
	call := s.call
	subs := make([]*liveCall, 0, len(s.subCalls))
	for c := range s.subCalls {
		subs = append(subs, c)
	}
	if t := s.tool; t != nil {
		d.Tool = &flitv1.ToolDebug{ToolCallId: t.id, Name: t.name, StartTime: timestamppb.New(t.start)}
	}
	// Copy the calls' fields under the lock; their traces have locks of
	// their own.
	var main *liveCall
	if call != nil {
		c := *call
		main = &c
	}
	copies := make([]liveCall, len(subs))
	for i, c := range subs {
		copies[i] = *c
	}
	s.mu.Unlock()

	if main != nil {
		d.Call = main.debug()
	}
	for i := range copies {
		d.SubagentCalls = append(d.SubagentCalls, copies[i].debug())
	}
	return d
}

func (c *liveCall) debug() *flitv1.ModelCallDebug {
	d := &flitv1.ModelCallDebug{MessageId: c.msgID, Provider: c.provider.Name, Model: c.model, Queued: c.queued, CompletionId: c.id}
	if c.snap == nil {
		return d
	}
	t := c.snap()
	if t.Sent.IsZero() {
		return d // not sent yet
	}
	d.Phase = t.Phase
	d.SentTime = timestamppb.New(t.Sent)
	if !t.LastActivity.IsZero() {
		d.IdleMs = time.Since(t.LastActivity).Milliseconds()
	}
	d.WatchdogMs, d.Bytes, d.StreamedTokens = t.Watchdog.Milliseconds(), t.Bytes, t.Tokens
	d.PromptProcessed, d.PromptTotal = t.PromptProcessed, t.PromptTotal
	return d
}
