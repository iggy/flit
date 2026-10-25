package agent

import (
	"context"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func isLimitWait(ev *flitv1.Event) bool {
	return ev.GetModelCallWaiting().GetReason() == flitv1.ModelWaitReason_MODEL_WAIT_REASON_CONCURRENCY_LIMIT
}

// Two sessions on a model with concurrency 1: the second one's call waits,
// says so in its log, and is sent only once the first one's ends.
func TestConcurrencyLimitAcrossSessions(t *testing.T) {
	h := newHarness(t)
	h.cfg.Providers[0].Concurrency = 1
	started, release := make(chan struct{}), make(chan struct{})
	h.llm.Push(
		llmtest.Response{Chunks: llmtest.Text("first"), Started: started, Release: release},
		llmtest.Response{Chunks: llmtest.Text("second")},
	)

	a, b := h.create(), h.create()
	wa, wb := h.watch(a.ID, 0), h.watch(b.ID, 0)
	if _, err := h.m.Send(context.Background(), a.ID, "go"); err != nil {
		t.Fatal(err)
	}
	<-started
	if _, err := h.m.Send(context.Background(), b.ID, "go too"); err != nil {
		t.Fatal(err)
	}
	waiting := wb.waitFor("a concurrency wait", isLimitWait).GetModelCallWaiting()
	if waiting.TotalSlots != 1 || waiting.Attempt != 1 {
		t.Fatalf("waiting = %v", waiting)
	}
	if n := len(h.llm.Requests()); n != 1 {
		t.Fatalf("%d requests sent while the limit is 1", n)
	}
	if in, w := h.m.Limiter().InUse("fake", "test-model"); in != 1 || w != 1 {
		t.Fatalf("InUse = %d, %d; want 1, 1", in, w)
	}

	close(release)
	for _, w := range []*watcher{wa, wb} {
		if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_DONE {
			t.Fatalf("turn ended %v\n%s", end, dump(w.snapshot()))
		}
	}
	if n := len(h.llm.Requests()); n != 2 {
		t.Fatalf("%d requests, want 2", n)
	}
	// B's log: the call started, waited, got its turn (UNSPECIFIED), then
	// the reply.
	var got []string
	for _, ev := range wb.snapshot() {
		switch {
		case ev.GetModelCallStarted() != nil:
			got = append(got, "started")
		case ev.GetModelCallWaiting() != nil:
			got = append(got, ev.GetModelCallWaiting().Reason.String())
		case ev.GetTextDelta() != nil && ev.GetTextDelta().Text == "second":
			got = append(got, "reply")
		}
	}
	want := []string{"started", "MODEL_WAIT_REASON_CONCURRENCY_LIMIT", "MODEL_WAIT_REASON_UNSPECIFIED", "reply"}
	if len(got) != len(want) {
		t.Fatalf("B's call events %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("B's call events %v, want %v", got, want)
		}
	}
	for _, ev := range wa.snapshot() {
		if ev.GetModelCallWaiting() != nil {
			t.Fatalf("A waited: %v", ev)
		}
	}
	if in, w := h.m.Limiter().InUse("fake", "test-model"); in != 0 || w != 0 {
		t.Fatalf("InUse after = %d, %d", in, w)
	}
}

// Interrupting a turn whose call waits for a slot stops the wait; the call
// is never sent.
func TestConcurrencyWaitInterrupted(t *testing.T) {
	h := newHarness(t)
	h.cfg.Providers[0].Models = map[string]config.ProviderModel{"test-model": {Concurrency: new(1)}}
	release := h.hold(t, "fake", "test-model")
	defer release()

	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("a concurrency wait", isLimitWait)
	if ok, err := h.m.Interrupt(context.Background(), sess.ID); err != nil || !ok {
		t.Fatalf("Interrupt = %v, %v", ok, err)
	}
	w.waitTurnEnd()
	if n := len(h.llm.Requests()); n != 0 {
		t.Fatalf("%d requests sent", n)
	}
	ended, ok := find(w.snapshot(), (*flitv1.Event).GetModelCallEnded, notNil)
	if !ok || ended.Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_CANCELLED {
		t.Fatalf("call ended %v\n%s", ended, dump(w.snapshot()))
	}
	if in, wt := h.m.Limiter().InUse("fake", "test-model"); in != 1 || wt != 0 {
		t.Fatalf("InUse = %d, %d; want only the held slot", in, wt)
	}
}

// Subagents go through the same limit as sessions.
func TestConcurrencyLimitSubagent(t *testing.T) {
	h := newHarness(t)
	h.cfg.Providers[0].Models = map[string]config.ProviderModel{"sub-model": {Concurrency: new(1)}}
	h.cfg.Agent.Tasks = map[string]config.TaskModel{"explore": {Provider: "fake", Model: "sub-model"}}
	release := h.hold(t, "fake", "sub-model")
	h.llm.Push(
		agentCall("ag1", `{"kind":"explore","task":"look around"}`),
		llmtest.Response{Chunks: llmtest.Text("nothing here")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("the subagent's concurrency wait", func(ev *flitv1.Event) bool {
		return ev.GetSubagentEvent() != nil && isLimitWait(ev.GetSubagentEvent().Event)
	})
	if n := len(h.llm.Requests()); n != 1 {
		t.Fatalf("%d requests; the subagent's call should wait", n)
	}
	release()
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("turn ended %v\n%s", end, dump(w.snapshot()))
	}
	reqs := h.llm.Requests()
	if len(reqs) != 3 || reqs[1].Model != "sub-model" {
		t.Fatalf("requests: %d, second model %q", len(reqs), reqs[1].Model)
	}
}

// hold takes a slot for provider/model as if another call were running.
func (h *harness) hold(t *testing.T, provider, model string) func() {
	t.Helper()
	release, err := h.m.Limiter().Acquire(context.Background(), provider, model, func(int) { t.Fatal("hold queued") })
	if err != nil {
		t.Fatal(err)
	}
	return release
}
