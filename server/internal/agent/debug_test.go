package agent

import (
	"context"
	"strings"
	"sync"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/timeline"
)

// fastProbes shortens the llama.cpp sampling for tests.
func fastProbes(t *testing.T) {
	t.Helper()
	gap, ask, lock := serverSampleGap, serverAskTimeout, debugLockWait
	t.Cleanup(func() { serverSampleGap, serverAskTimeout, debugLockWait = gap, ask, lock })
	serverSampleGap, serverAskTimeout, debugLockWait = 50*time.Millisecond, 300*time.Millisecond, 50*time.Millisecond
}

// probeLog records, for each GET /slots, whether the chat request was
// still open on the server.
type probeLog struct {
	mu   sync.Mutex
	open []int
}

func (p *probeLog) watch(h *harness) {
	h.llm.Llama.OnSlots = func() {
		p.mu.Lock()
		defer p.mu.Unlock()
		p.open = append(p.open, h.llm.Open())
	}
}

func (p *probeLog) all() []int {
	p.mu.Lock()
	defer p.mu.Unlock()
	return append([]int(nil), p.open...)
}

// A llama.cpp call that stalls mid-reply while llama.cpp keeps generating
// is logged with the server's state, sampled while it still had the
// request, and a diagnosis that the output isn't reaching flit.
func TestStallRecordsLlamaCppState(t *testing.T) {
	fastProbes(t)
	h := llamaHarness(t, 1)
	h.cfg.LlamaCpp.KVCache = new(bool)
	h.cfg.Agent.ModelStallTimeout = 100 * time.Millisecond
	h.llm.Llama.SetBusy(0, true)
	h.llm.Llama.DecodePerPoll, h.llm.Llama.PromptTokens = 7, 48000
	var probes probeLog
	probes.watch(h)
	sess := h.create()
	evs := turn(t, h, sess.ID, "hi", llmtest.Response{Chunks: []string{llmtest.Text("half")[0], llmtest.Pause(5 * time.Second)}})
	ended := callsEnded(evs)
	if len(ended) != 1 || ended[0].Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED {
		t.Fatalf("calls %v", ended)
	}
	e := ended[0]
	st := e.Server
	if e.StreamedTokens != 1 || st == nil || st.ModelState != "loaded" || st.SampleMs < 50 || len(st.Slots) != 1 ||
		!st.Slots[0].IsProcessing || st.Slots[0].DecodedDelta != 7 || st.Slots[0].PromptTokens != 48000 {
		t.Fatalf("ended %v", e)
	}
	if d := timeline.Diagnose(e); !strings.Contains(d, "isn't reaching flit") {
		t.Fatalf("diagnosis %q", d)
	}
	// The last two polls are the two samples (the model catalog reads
	// n_ctx from /slots before the call).
	if got := probes.all(); len(got) < 2 || got[len(got)-1] != 1 || got[len(got)-2] != 1 {
		t.Fatalf("slots polled after the request was given up: %v", got)
	}
}

// RetryModelCall on llama.cpp samples the server before giving up on the
// call; a busy slot that gets nowhere reads as llama.cpp being stuck.
func TestRetrySamplesLlamaCppFirst(t *testing.T) {
	fastProbes(t)
	h := llamaHarness(t, 1)
	h.cfg.LlamaCpp.KVCache = new(bool)
	h.llm.Llama.SetBusy(0, true)
	var probes probeLog
	sess := h.create()
	waiting := make(chan struct{})
	h.llm.Push(llmtest.Response{Hang: true, Started: waiting}, llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(sess.ID, 0)
	ctx := context.Background()
	if _, err := h.m.Send(ctx, sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	<-waiting
	probes.watch(h)
	if err := h.m.RetryModelCall(ctx, sess.ID); err != nil {
		t.Fatal(err)
	}
	if err := h.m.RetryModelCall(ctx, sess.ID); err != nil { // a second press while sampling is fine
		t.Fatal(err)
	}
	w.waitTurnEnd()
	ended := callsEnded(w.snapshot())
	if len(ended) != 2 || ended[0].Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_RETRIED || ended[0].Server == nil {
		t.Fatalf("calls %v", ended)
	}
	if d := timeline.Diagnose(ended[0]); !strings.Contains(d, "llama.cpp or the model itself is stuck") {
		t.Fatalf("diagnosis %q", d)
	}
	if got := probes.all(); len(got) < 2 || got[0] != 1 || got[1] != 1 {
		t.Fatalf("slot polls while the request was open: %v", got)
	}
	if len(h.llm.Requests()) != 2 {
		t.Fatalf("%d requests", len(h.llm.Requests()))
	}
}

// When /slots doesn't answer but the router does, llama.cpp's main loop
// is stuck.
func TestStallWithSlotsNotAnswering(t *testing.T) {
	fastProbes(t)
	h := llamaHarness(t, 1)
	h.cfg.LlamaCpp.KVCache = new(bool)
	h.cfg.Agent.ModelFirstTokenTimeout = 100 * time.Millisecond
	sess := h.create()
	resp := llmtest.Response{Chunks: []string{llmtest.Pause(5 * time.Second)}}
	// watchWait polls /slots too; only slow it down once the call is out.
	go func() {
		time.Sleep(60 * time.Millisecond)
		h.llm.Llama.SetSlotsDelay(time.Second)
	}()
	evs := turn(t, h, sess.ID, "hi", resp)
	e := callsEnded(evs)[0]
	if e.Server == nil || !strings.HasPrefix(e.Server.SlotsError, "no answer") || e.Server.Error != "" {
		t.Fatalf("ended %v", e)
	}
	if d := timeline.Diagnose(e); !strings.Contains(d, "main loop is stuck") {
		t.Fatalf("diagnosis %q", d)
	}
}

// Other providers' failures carry no server state.
func TestStallOnOtherProvidersHasNoServerState(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.ModelStallTimeout = 80 * time.Millisecond
	sess := h.create()
	evs := turn(t, h, sess.ID, "hi", llmtest.Response{Chunks: []string{llmtest.Text("half")[0], llmtest.Pause(5 * time.Second)}})
	if e := callsEnded(evs)[0]; e.Server != nil || e.StreamedTokens != 1 {
		t.Fatalf("ended %v", e)
	}
}

// Debug reports the call in flight and its phase, and a session whose lock
// is held without waiting on it.
func TestDebugReportsLiveState(t *testing.T) {
	fastProbes(t)
	h := newHarness(t)
	sess := h.create()
	started := make(chan struct{})
	h.llm.Push(llmtest.Response{Chunks: []string{llmtest.Progress(10, 100, 0, 1)}, Hang: true, Started: started})
	w := h.watch(sess.ID, 0)
	ctx := context.Background()
	if _, err := h.m.Send(ctx, sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	<-started
	time.Sleep(30 * time.Millisecond)
	d := h.m.Debug()
	if !d.SessionsLockFree || len(d.Sessions) != 1 {
		t.Fatalf("dump %v", d)
	}
	s := d.Sessions[0]
	if !s.LockFree || !s.TurnRunning || s.Call == nil || s.Call.Phase != "processing_prompt" || s.Call.PromptTotal != 100 ||
		s.Call.SentTime == nil || s.Call.WatchdogMs == 0 {
		t.Fatalf("session %v", s)
	}

	live := h.m.sessions[sess.ID]
	live.mu.Lock()
	start := time.Now()
	d = h.m.Debug()
	live.mu.Unlock()
	if s := d.Sessions[0]; s.LockFree || s.SessionId != sess.ID || time.Since(start) > time.Second {
		t.Fatalf("held lock: %v", s)
	}
	h.m.Interrupt(ctx, sess.ID)
	w.waitTurnEnd()
	if s := h.m.Debug().Sessions[0]; s.TurnRunning || s.Call != nil {
		t.Fatalf("after the turn: %v", s)
	}
}
