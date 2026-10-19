package agent

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"slices"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

// llamaHarness makes the fake provider a llama.cpp server with n slots.
func llamaHarness(t *testing.T, n int) *harness {
	t.Helper()
	h := newHarness(t)
	h.llm.Llama = &llmtest.Llama{NSlots: n, Saved: 1234}
	h.cfg.Providers[0].Kind = string(models.KindLlamaCpp)
	h.m.Catalog = models.NewCatalog(h.config, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	origWait, origGrace := waitCheckEvery, reasoningEndGrace
	t.Cleanup(func() { waitCheckEvery, reasoningEndGrace = origWait, origGrace })
	waitCheckEvery, reasoningEndGrace = 30*time.Millisecond, 150*time.Millisecond
	return h
}

func turn(t *testing.T, h *harness, id, text string, resp llmtest.Response) []*flitv1.Event {
	t.Helper()
	h.llm.Push(resp)
	w := h.watch(id, 0)
	defer w.stop()
	from, err := h.m.Send(context.Background(), id, text)
	if err != nil {
		t.Fatal(err)
	}
	end := w.waitFor("turn end", func(ev *flitv1.Event) bool {
		st := ev.GetTaskStateChanged().GetState()
		return ev.Seq > from && (st == flitv1.TaskState_TASK_STATE_DONE || st == flitv1.TaskState_TASK_STATE_STUCK)
	})
	var out []*flitv1.Event
	for _, ev := range w.snapshot() {
		if ev.Seq >= from && ev.Seq <= end.Seq {
			out = append(out, ev)
		}
	}
	return out
}

func waits(evs []*flitv1.Event) []string {
	var out []string
	for _, ev := range evs {
		if w := ev.GetModelCallWaiting(); w != nil {
			out = append(out, w.Reason.String())
		}
	}
	return out
}

// A call that hasn't started says why: all slots busy, then asleep.
func TestModelCallWaitingReasons(t *testing.T) {
	h := llamaHarness(t, 2)
	h.cfg.LlamaCpp.KVCache = new(bool) // no pinning: plain "all busy"
	h.llm.Llama.SetBusy(0, true)
	h.llm.Llama.SetBusy(1, true)
	sess := h.create()
	resp := llmtest.Response{Chunks: append([]string{llmtest.Pause(200 * time.Millisecond)}, llmtest.Text("ok")...)}
	go func() {
		time.Sleep(100 * time.Millisecond)
		h.llm.Llama.SetBusy(1, false)
		h.llm.Llama.SetState("sleeping")
	}()
	evs := turn(t, h, sess.ID, "hi", resp)
	got := strings.Join(waits(evs), ",")
	if got != "MODEL_WAIT_REASON_SLOTS_BUSY,MODEL_WAIT_REASON_SLEEPING" {
		t.Fatalf("waits %s", got)
	}
	if w, _ := find(evs, (*flitv1.Event).GetModelCallWaiting, notNil); w.TotalSlots != 2 {
		t.Fatalf("waiting %v", w)
	}

	// Once the server is on it (prompt progress), no more reports.
	h.llm.Llama.SetState("")
	resp = llmtest.Response{Chunks: append([]string{llmtest.Progress(0, 10, 0, 0), llmtest.Pause(150 * time.Millisecond)}, llmtest.Text("ok")...)}
	h.llm.Llama.SetBusy(0, true)
	h.llm.Llama.SetBusy(1, true)
	if got := waits(turn(t, h, sess.ID, "again", resp)); len(got) != 0 {
		t.Fatalf("waits after start %v", got)
	}
}

// llama.cpp's cache hits go into Usage and the call log.
func TestCachedTokens(t *testing.T) {
	h := llamaHarness(t, 1)
	sess := h.create()
	evs := turn(t, h, sess.ID, "hi", llmtest.Response{Chunks: append(llmtest.Text("ok"), llmtest.Timings(100, 20))})
	u, _ := find(evs, (*flitv1.Event).GetUsage, notNil)
	e, _ := find(evs, (*flitv1.Event).GetModelCallEnded, notNil)
	if u.CachedTokens != 30 || e.CachedTokens != 30 {
		t.Fatalf("usage %v, call %v", u, e)
	}
}

// Each turn's cache is saved when it ends and restored before the
// session's next turn, into the slot the call is pinned to.
func TestPromptCacheSaveAndRestore(t *testing.T) {
	h := llamaHarness(t, 1)
	a, b := h.create(), h.create()
	text := func(s string) llmtest.Response { return llmtest.Response{Chunks: llmtest.Text(s)} }

	turn(t, h, a.ID, "a1", text("x"))
	if r := h.llm.Requests(); r[0].IDSlot == nil || *r[0].IDSlot != 0 || r[0].CachePrompt == nil || !*r[0].CachePrompt {
		t.Fatalf("request not pinned: %+v", r[0])
	}
	turn(t, h, b.ID, "b1", text("y"))
	evsA := turn(t, h, a.ID, "a2", text("z"))
	calls := strings.Join(h.llm.Llama.Calls(), "\n")
	want := "POST /slots/0 save flit-kv-0.bin\nPOST /slots/0 save flit-kv-1.bin\nPOST /slots/0 restore flit-kv-0.bin\nPOST /slots/0 save flit-kv-0.bin"
	if calls != want {
		t.Fatalf("calls:\n%s\nwant:\n%s", calls, want)
	}
	r, _ := find(evsA, (*flitv1.Event).GetPromptCache, func(p *flitv1.PromptCache) bool {
		return p != nil && p.Action == flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_RESTORED
	})
	if r == nil || r.File != "flit-kv-0.bin" || r.Tokens != 1234 || r.Slot != 0 || r.MessageId == "" {
		t.Fatalf("restore event %v", r)
	}
	allA, err := h.st.Events(context.Background(), a.ID, 0, 1<<62)
	if err != nil {
		t.Fatal(err)
	}
	saved, _ := find(allA, (*flitv1.Event).GetPromptCache, func(p *flitv1.PromptCache) bool {
		return p != nil && p.Action == flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_SAVED
	})
	if saved == nil || saved.File != "flit-kv-0.bin" || saved.Tokens != 1234 {
		t.Fatalf("save event %v", saved)
	}
}

// Only a turn's first call restores; later calls in the turn reuse the
// warm slot.
func TestPromptCacheRestoresOncePerTurn(t *testing.T) {
	h := llamaHarness(t, 1)
	a := h.create()
	turn(t, h, a.ID, "a1", llmtest.Response{Chunks: llmtest.Text("x")})
	h.llm.Push(llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "list", `{}`})})
	turn(t, h, a.ID, "a2", llmtest.Response{Chunks: llmtest.Text("done")})
	restores := 0
	for _, c := range h.llm.Llama.Calls() {
		if strings.Contains(c, "restore") {
			restores++
		}
	}
	if restores != 1 {
		t.Fatalf("calls %v", h.llm.Llama.Calls())
	}
}

// A save that captured nothing (the cache was already gone) isn't restored.
func TestPromptCacheEmptySaveNotRestored(t *testing.T) {
	h := llamaHarness(t, 1)
	h.llm.Llama.Saved = 0
	a := h.create()
	turn(t, h, a.ID, "a1", llmtest.Response{Chunks: llmtest.Text("x")})
	turn(t, h, a.ID, "a2", llmtest.Response{Chunks: llmtest.Text("y")})
	for _, c := range h.llm.Llama.Calls() {
		if strings.Contains(c, "restore") {
			t.Fatalf("restored an empty save: %v", h.llm.Llama.Calls())
		}
	}
}

// With one save file, sessions take turns owning it.
func TestPromptCacheFilePool(t *testing.T) {
	h := llamaHarness(t, 1)
	h.cfg.LlamaCpp.KVCacheFiles = 1
	a, b, c := h.create(), h.create(), h.create()
	text := llmtest.Response{Chunks: llmtest.Text("x")}
	turn(t, h, a.ID, "a", text)
	turn(t, h, b.ID, "b", text) // b takes the file
	turn(t, h, c.ID, "c", text) // c takes it
	turn(t, h, a.ID, "a", text) // a's cache is gone: no restore
	for _, call := range h.llm.Llama.Calls() {
		if strings.Contains(call, "restore") || !strings.HasSuffix(call, "flit-kv-0.bin") {
			t.Fatalf("calls %v", h.llm.Llama.Calls())
		}
	}
	if n := len(h.llm.Llama.Calls()); n != 4 {
		t.Fatalf("calls %v", h.llm.Llama.Calls())
	}
}

// Servers without the slot API, or without a save path, are left alone.
func TestPromptCacheUnsupported(t *testing.T) {
	h := llamaHarness(t, 1)
	h.llm.Llama.NoSlots = true
	a, b := h.create(), h.create()
	turn(t, h, a.ID, "a", llmtest.Response{Chunks: llmtest.Text("x")})
	turn(t, h, b.ID, "b", llmtest.Response{Chunks: llmtest.Text("x")})
	if r := h.llm.Requests(); r[0].IDSlot != nil || len(h.llm.Llama.Calls()) != 0 {
		t.Fatalf("pinned or saved without slots: %+v %v", r[0], h.llm.Llama.Calls())
	}

	h2 := llamaHarness(t, 1)
	h2.llm.Llama.NoSave = true
	a, b = h2.create(), h2.create()
	turn(t, h2, a.ID, "a", llmtest.Response{Chunks: llmtest.Text("x")})
	evs := turn(t, h2, b.ID, "b", llmtest.Response{Chunks: llmtest.Text("x")})
	turn(t, h2, a.ID, "a", llmtest.Response{Chunks: llmtest.Text("x")})
	if got := h2.llm.Llama.Calls(); len(got) != 1 {
		t.Fatalf("kept trying after the server refused: %v", got)
	}
	if _, ok := find(evs, (*flitv1.Event).GetPromptCache, notNil); ok {
		t.Fatal("logged a refused save")
	}
	if _, ok := find(evs, (*flitv1.Event).GetError, notNil); ok {
		t.Fatal("a refused save failed the turn")
	}
}

// Answer now: the control request goes out; a model that keeps thinking
// is recorded as ignoring it.
func TestEndReasoningIgnored(t *testing.T) {
	h := llamaHarness(t, 1)
	sess := h.create()
	ctx := context.Background()
	var chunks []string
	for range 20 {
		chunks = append(chunks, llmtest.Reasoning("hmm "), llmtest.Pause(20*time.Millisecond))
	}
	h.llm.Push(llmtest.Response{Chunks: append(chunks, llmtest.Text("done")...)})
	w := h.watch(sess.ID, 0)
	if err := h.m.EndReasoning(ctx, sess.ID, "phone"); !errors.Is(err, ErrCantEndReasoning) {
		t.Fatalf("no call: %v", err)
	}
	if _, err := h.m.Send(ctx, sess.ID, "think"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("reasoning", func(ev *flitv1.Event) bool { return ev.GetReasoningDelta() != nil })
	if err := h.m.EndReasoning(ctx, sess.ID, "phone"); err != nil {
		t.Fatal(err)
	}
	if err := h.m.EndReasoning(ctx, sess.ID, "phone"); !errors.Is(err, ErrCantEndReasoning) {
		t.Fatalf("asked twice: %v", err)
	}
	if !h.llm.Requests()[0].ReasoningControl {
		t.Fatal("reasoning_control not armed")
	}
	w.waitFor("ignored", func(ev *flitv1.Event) bool { return ev.GetReasoningEndIgnored() != nil })
	w.waitTurnEnd()
	if got := h.llm.Llama.Calls(); !slices.Contains(got, "POST control reasoning_end "+llmtest.CompletionID) {
		t.Fatalf("calls %v", got)
	}
	if r, _ := find(w.snapshot(), (*flitv1.Event).GetReasoningEndRequested, notNil); r.Client != "phone" {
		t.Fatalf("requested %v", r)
	}
	prefs, _ := h.st.ModelPrefs(ctx, sess.TeamID)
	if !prefs[store.ModelKey{Provider: "fake", Model: "test-model"}].NoReasoningEnd {
		t.Fatalf("prefs %+v", prefs)
	}
	// From now on flit doesn't arm it for this model.
	turn(t, h, sess.ID, "again", llmtest.Response{Chunks: llmtest.Text("ok")})
	if r := h.llm.Requests(); r[len(r)-1].ReasoningControl {
		t.Fatal("reasoning_control still armed")
	}
}

// A model that answers after the request isn't marked.
func TestEndReasoningHonoured(t *testing.T) {
	h := llamaHarness(t, 1)
	sess := h.create()
	ctx := context.Background()
	chunks := []string{llmtest.Reasoning("hmm"), llmtest.Pause(100 * time.Millisecond)}
	h.llm.Push(llmtest.Response{Chunks: append(chunks, append(llmtest.Text("answer"), llmtest.Pause(300*time.Millisecond))...)})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "think"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("reasoning", func(ev *flitv1.Event) bool { return ev.GetReasoningDelta() != nil })
	if err := h.m.EndReasoning(ctx, sess.ID, ""); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	time.Sleep(200 * time.Millisecond)
	if _, ok := find(w.snapshot(), (*flitv1.Event).GetReasoningEndIgnored, notNil); ok {
		t.Fatal("marked as ignored")
	}
}
