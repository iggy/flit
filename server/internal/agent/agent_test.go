package agent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"testing"
	"time"

	"google.golang.org/protobuf/proto"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/mcpclient"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

type harness struct {
	t   *testing.T
	m   *Manager
	st  *store.Store
	llm *llmtest.Server
	dir string

	mu  sync.Mutex
	cfg config.Config
}

func newHarness(t *testing.T) *harness {
	t.Helper()
	h := &harness{t: t, llm: llmtest.New(t), dir: t.TempDir()}
	h.cfg = config.Default()
	h.cfg.Providers = []config.Provider{
		{Name: "fake", BaseURL: h.llm.BaseURL()},
		{Name: "other", BaseURL: h.llm.BaseURL()},
	}
	h.cfg.Agent.Provider, h.cfg.Agent.Model = "fake", "test-model"
	// Tests use echo (read-only, and portable to cmd.exe) as a command that
	// needs approval.
	h.cfg.Shell.ReadOnly = new(bool)
	// Scripted failures happen once; tests of retries turn them back on.
	h.cfg.Agent.ModelRetries = 0

	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	h.st = st
	h.m, err = NewManager(context.Background(), st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		h.m.Close()
		st.Close()
	})
	return h
}

func (h *harness) config() config.Config {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.cfg
}

func (h *harness) create() store.Session {
	h.t.Helper()
	s, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir})
	if err != nil {
		h.t.Fatal(err)
	}
	return s
}

// watcher attaches to a session and collects events.
type watcher struct {
	t      *testing.T
	cancel context.CancelFunc
	done   chan error
	mu     sync.Mutex
	events []*flitv1.Event
	notify chan struct{}
}

func (h *harness) watch(id string, from int64) *watcher {
	ctx, cancel := context.WithCancel(context.Background())
	w := &watcher{t: h.t, cancel: cancel, done: make(chan error, 1), notify: make(chan struct{}, 1)}
	go func() {
		w.done <- h.m.Attach(ctx, id, from, func(ev *flitv1.Event) error {
			w.mu.Lock()
			w.events = append(w.events, ev)
			w.mu.Unlock()
			select {
			case w.notify <- struct{}{}:
			default:
			}
			return nil
		})
	}()
	h.t.Cleanup(func() { w.stop() })
	return w
}

func (w *watcher) stop() []*flitv1.Event {
	w.cancel()
	<-w.done
	w.done <- nil // allow stop to be called again
	return w.snapshot()
}

func (w *watcher) snapshot() []*flitv1.Event {
	w.mu.Lock()
	defer w.mu.Unlock()
	return append([]*flitv1.Event(nil), w.events...)
}

// waitFor waits until an event satisfies match and returns it.
func (w *watcher) waitFor(what string, match func(*flitv1.Event) bool) *flitv1.Event {
	w.t.Helper()
	deadline := time.After(10 * time.Second)
	seen := 0
	for {
		evs := w.snapshot()
		for _, ev := range evs[seen:] {
			if match(ev) {
				return ev
			}
		}
		seen = len(evs)
		select {
		case <-w.notify:
		case <-deadline:
			w.t.Fatalf("timed out waiting for %s; events:\n%s", what, dump(evs))
		}
	}
}

func (w *watcher) waitState(state flitv1.TaskState) *flitv1.Event {
	w.t.Helper()
	return w.waitFor(state.String(), func(ev *flitv1.Event) bool {
		return ev.GetTaskStateChanged().GetState() == state
	})
}

func (w *watcher) waitTurnEnd() *flitv1.Event {
	w.t.Helper()
	return w.waitFor("end of turn", func(ev *flitv1.Event) bool {
		st := ev.GetTaskStateChanged().GetState()
		return st == flitv1.TaskState_TASK_STATE_DONE || st == flitv1.TaskState_TASK_STATE_STUCK
	})
}

func dump(evs []*flitv1.Event) string {
	var b strings.Builder
	for _, ev := range evs {
		b.WriteString("  " + kinds([]*flitv1.Event{ev})[0] + " " + strings.TrimSpace(ev.String()) + "\n")
	}
	return b.String()
}

func kinds(evs []*flitv1.Event) []string {
	var out []string
	for _, ev := range evs {
		out = append(out, store.Kind(ev))
	}
	return out
}

func find[T any](evs []*flitv1.Event, get func(*flitv1.Event) T, ok func(T) bool) (T, bool) {
	for _, ev := range evs {
		if v := get(ev); ok(v) {
			return v, true
		}
	}
	var zero T
	return zero, false
}

func notNil[T any](v *T) bool { return v != nil }

func TestTurnWithToolCall(t *testing.T) {
	h := newHarness(t)
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("hello from a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(h.dir, "AGENTS.md"), []byte("Always say please."), 0o644); err != nil {
		t.Fatal(err)
	}
	h.llm.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"call_1", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: append([]string{llmtest.Reasoning("easy")}, llmtest.Text("It says ", "hello.")...)},
	)

	sess := h.create()
	if sess.TeamID != store.DefaultTeamID || sess.ProjectID != store.DefaultProjectID || sess.Provider != "fake" || sess.Model != "test-model" {
		t.Fatalf("created %+v", sess)
	}
	w := h.watch(sess.ID, 0)
	seq, err := h.m.Send(context.Background(), sess.ID, "What is in a.txt?")
	if err != nil || seq != 1 {
		t.Fatalf("Send = %d, %v", seq, err)
	}
	end := w.waitTurnEnd()
	evs := w.snapshot()
	if end.GetTaskStateChanged().State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("turn ended %v; events:\n%s", end, dump(evs))
	}

	want := []string{
		"message_started", "text_delta", "message_done", "task_state_changed", // user message, WORKING
		"message_started", "model_call_started", "model_call_ended", "message_done", "usage", "tool_call_started", "tool_call_done", // tool call
		"message_started", "model_call_started", "reasoning_delta", "text_delta", "text_delta", "model_call_ended", "message_done", "usage",
		"task_state_changed", // DONE
	}
	if got := kinds(evs); strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("event kinds:\n got %v\nwant %v", got, want)
	}
	for i, ev := range evs {
		if ev.Seq != int64(i+1) || ev.SessionId != sess.ID {
			t.Fatalf("event %d has seq %d session %s", i, ev.Seq, ev.SessionId)
		}
	}
	done, _ := find(evs, (*flitv1.Event).GetToolCallDone, notNil)
	if done.IsError || !strings.Contains(done.Result, "hello from a") {
		t.Fatalf("tool result %+v", done)
	}
	last := evs[len(evs)-3].GetMessageDone()
	if last.Text != "It says hello." || last.Reasoning != "easy" || last.FinishReason != "stop" {
		t.Fatalf("final message %+v", last)
	}

	reqs := h.llm.Requests()
	if len(reqs) != 2 {
		t.Fatalf("%d model calls", len(reqs))
	}
	sys := reqs[0].Messages[0]
	if sys.Role != "system" || !strings.Contains(sys.Content, "Always say please.") || !strings.Contains(sys.Content, h.dir) {
		t.Fatalf("system prompt: %s", sys.Content)
	}
	// The built-ins plus skill (flit's own /init skill is always there) and agent.
	if len(reqs[0].Tools) != 14 || reqs[0].Model != "test-model" {
		t.Fatalf("first request tools=%d model=%s", len(reqs[0].Tools), reqs[0].Model)
	}
	second := reqs[1].Messages
	if n := len(second); n != 4 || second[1].Role != "user" || second[2].Role != "assistant" || len(second[2].ToolCalls) != 1 ||
		second[3].Role != "tool" || second[3].ToolCallID != "call_1" || !strings.Contains(second[3].Content, "hello from a") {
		t.Fatalf("second request messages: %+v", second)
	}

	got, err := h.m.Get(context.Background(), sess.ID)
	if err != nil || got.LastSeq != int64(len(evs)) || got.State != flitv1.TaskState_TASK_STATE_DONE || got.Title != "What is in a.txt?" {
		t.Fatalf("Get = %+v, %v", got, err)
	}
	stored, err := h.st.GetSession(context.Background(), sess.ID)
	if err != nil || stored.LastSeq != got.LastSeq || stored.State != got.State {
		t.Fatalf("stored = %+v, %v", stored, err)
	}
}

func TestReplayFromN(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "list", `{}`})},
		llmtest.Response{Chunks: llmtest.Text("a", "b", "c")},
	)
	sess := h.create()
	live := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	live.waitTurnEnd()
	liveEvs := live.stop()

	for _, from := range []int64{0, 1, 5, int64(len(liveEvs))} {
		w := h.watch(sess.ID, from)
		w.waitFor("last event", func(ev *flitv1.Event) bool { return ev.Seq == int64(len(liveEvs)) })
		replayed := w.stop()
		want := liveEvs[max(from, 1)-1:]
		if len(replayed) != len(want) {
			t.Fatalf("from %d: %d events, want %d", from, len(replayed), len(want))
		}
		for i := range want {
			if !proto.Equal(replayed[i], want[i]) {
				t.Fatalf("from %d: event %d differs:\n got %v\nwant %v", from, i, replayed[i], want[i])
			}
		}
	}

	// Attaching mid-session then continuing live: a second turn shows up
	// after the replayed events with no gaps.
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("again")})
	w := h.watch(sess.ID, int64(len(liveEvs)-2))
	if _, err := h.m.Send(context.Background(), sess.ID, "more"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("second turn end", func(ev *flitv1.Event) bool {
		return ev.Seq > int64(len(liveEvs)) && ev.GetTaskStateChanged().GetState() == flitv1.TaskState_TASK_STATE_DONE
	})
	evs := w.stop()
	for i, ev := range evs {
		if ev.Seq != int64(len(liveEvs)-2+i) {
			t.Fatalf("gap or repeat at %d: seq %d", i, ev.Seq)
		}
	}
}

func TestInterruptDuringStream(t *testing.T) {
	h := newHarness(t)
	started := make(chan struct{})
	h.llm.Push(llmtest.Response{Chunks: []string{llmtest.Text("partial ")[0]}, Hang: true, Started: started})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "write a novel"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("assistant text", func(ev *flitv1.Event) bool { return ev.GetTextDelta().GetText() == "partial " })

	// Sent mid-turn: queued. The interrupt leaves it for the next Send.
	if res, err := h.m.SendMessage(context.Background(), sess.ID, "again", "phone"); err != nil || res.QueueID == "" {
		t.Fatalf("Send while busy: %+v, %v", res, err)
	}
	ok, err := h.m.Interrupt(context.Background(), sess.ID)
	if err != nil || !ok {
		t.Fatalf("Interrupt = %v, %v", ok, err)
	}
	end := w.waitTurnEnd().GetTaskStateChanged()
	if end.State != flitv1.TaskState_TASK_STATE_DONE || end.Reason != "interrupted" {
		t.Fatalf("end = %v", end)
	}
	evs := w.snapshot()
	md, _ := find(evs, (*flitv1.Event).GetMessageDone, func(d *flitv1.MessageDone) bool { return d != nil && d.FinishReason == "interrupted" })
	if md == nil || md.Text != "partial " {
		t.Fatalf("interrupted message: %v\n%s", md, dump(evs))
	}
	if _, ok := find(evs, (*flitv1.Event).GetError, notNil); ok {
		t.Fatal("interrupt recorded an error")
	}
	if ok, _ := h.m.Interrupt(context.Background(), sess.ID); ok {
		t.Fatal("second Interrupt reported a running turn")
	}

	// The session carries on, and the model sees the partial reply.
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	if _, err := h.m.Send(context.Background(), sess.ID, "short version"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("second turn", func(ev *flitv1.Event) bool {
		return ev.GetMessageDone().GetText() == "ok"
	})
	msgs := h.llm.Requests()[1].Messages
	if msgs[2].Role != "assistant" || msgs[2].Content != "partial " || msgs[3].Content != "again" || msgs[4].Content != "short version" {
		t.Fatalf("history after interrupt: %+v", msgs)
	}
}

func shellCall(cmd string) llmtest.Response {
	return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"sh1", "shell", `{"command":"` + cmd + `"}`})}
}

func TestPromptAllowAndDeny(t *testing.T) {
	for _, allow := range []bool{true, false} {
		t.Run(map[bool]string{true: "allow", false: "deny"}[allow], func(t *testing.T) {
			h := newHarness(t)
			h.llm.Push(shellCall("echo flit-was-here"), llmtest.Response{Chunks: llmtest.Text("done")})
			sess := h.create()
			w := h.watch(sess.ID, 0)
			if _, err := h.m.Send(context.Background(), sess.ID, "run it"); err != nil {
				t.Fatal(err)
			}
			req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
			w.waitState(flitv1.TaskState_TASK_STATE_WAITING)
			if req.ToolCallId != "sh1" || req.Detail != "echo flit-was-here" {
				t.Fatalf("prompt %+v", req)
			}
			if got, _ := h.m.Get(context.Background(), sess.ID); got.State != flitv1.TaskState_TASK_STATE_WAITING {
				t.Fatalf("state while waiting = %v", got.State)
			}

			if err := h.m.AnswerPrompt(context.Background(), sess.ID, "prm_bogus", Answer{Allow: true, Client: "x"}); !errors.Is(err, ErrPromptGone) {
				t.Fatalf("bogus prompt: %v", err)
			}
			if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: allow, Client: "test-client"}); err != nil {
				t.Fatal(err)
			}
			if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: allow, Client: "late-client"}); !errors.Is(err, ErrPromptGone) {
				t.Fatalf("second answer: %v", err)
			}
			w.waitTurnEnd()
			evs := w.snapshot()

			res, _ := find(evs, (*flitv1.Event).GetPromptResolved, notNil)
			wantDecision := flitv1.PromptDecision_PROMPT_DECISION_DENY
			if allow {
				wantDecision = flitv1.PromptDecision_PROMPT_DECISION_ALLOW
			}
			if res.Client != "test-client" || res.Decision != wantDecision || res.PromptId != req.PromptId {
				t.Fatalf("resolved %+v", res)
			}
			done, _ := find(evs, (*flitv1.Event).GetToolCallDone, notNil)
			if allow && (done.IsError || !strings.Contains(done.Result, "flit-was-here")) {
				t.Fatalf("allowed result %+v", done)
			}
			if !allow && (!done.IsError || !strings.Contains(done.Result, "denied")) {
				t.Fatalf("denied result %+v", done)
			}
			if allow {
				if _, ok := find(evs, (*flitv1.Event).GetToolOutput, notNil); !ok {
					t.Fatal("no live tool output")
				}
			}
		})
	}
}

func TestInterruptWhileWaitingForPrompt(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(shellCall("echo never"))
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "run it"); err != nil {
		t.Fatal(err)
	}
	req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
	if _, err := h.m.Interrupt(context.Background(), sess.ID); err != nil {
		t.Fatal(err)
	}
	end := w.waitTurnEnd().GetTaskStateChanged()
	if end.Reason != "interrupted" {
		t.Fatalf("end %v", end)
	}
	evs := w.snapshot()
	res, _ := find(evs, (*flitv1.Event).GetPromptResolved, notNil)
	if res.Decision != flitv1.PromptDecision_PROMPT_DECISION_DENY || res.Reason != "interrupted" || res.Client != "" {
		t.Fatalf("resolved %+v", res)
	}
	if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: true, Client: "c"}); !errors.Is(err, ErrPromptGone) {
		t.Fatalf("answer after interrupt: %v", err)
	}
	if _, ok := find(evs, (*flitv1.Event).GetToolCallDone, notNil); !ok {
		t.Fatal("tool call left without a result")
	}
	if len(h.llm.Requests()) != 1 {
		t.Fatal("model called again after interrupt")
	}
}

func TestShellRulesSkipPrompt(t *testing.T) {
	h := newHarness(t)
	h.cfg.Shell.Allow = []string{"echo *"}
	h.llm.Push(shellCall("echo auto"), llmtest.Response{Chunks: llmtest.Text("ok")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	if _, ok := find(evs, (*flitv1.Event).GetPromptRequested, notNil); ok {
		t.Fatal("allowed command prompted")
	}
	if done, _ := find(evs, (*flitv1.Event).GetToolCallDone, notNil); !strings.Contains(done.Result, "auto") {
		t.Fatalf("result %+v", done)
	}
}

func TestProviderErrors(t *testing.T) {
	for _, tc := range []struct {
		status      int
		canContinue bool
	}{{401, false}, {503, true}} {
		h := newHarness(t)
		h.llm.Push(llmtest.Response{Status: tc.status, Body: `{"error":{"message":"nope"}}`})
		sess := h.create()
		w := h.watch(sess.ID, 0)
		if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
			t.Fatal(err)
		}
		end := w.waitTurnEnd().GetTaskStateChanged()
		if end.State != flitv1.TaskState_TASK_STATE_STUCK {
			t.Fatalf("%d: end %v", tc.status, end)
		}
		e, _ := find(w.snapshot(), (*flitv1.Event).GetError, notNil)
		if e.TurnCanContinue != tc.canContinue || !strings.Contains(e.Message, "nope") {
			t.Fatalf("%d: error %+v", tc.status, e)
		}
	}
}

func TestSetModel(t *testing.T) {
	h := newHarness(t)
	sess := h.create()
	if _, err := h.m.SetModel(context.Background(), sess.ID, "missing", "m"); !errors.Is(err, ErrInvalid) {
		t.Fatalf("unknown provider: %v", err)
	}
	got, err := h.m.SetModel(context.Background(), sess.ID, "other", "bigger-model")
	if err != nil || got.Provider != "other" || got.Model != "bigger-model" {
		t.Fatalf("SetModel = %+v, %v", got, err)
	}
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("hi")})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hello"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	if mc := w.snapshot()[0].GetModelChanged(); mc.GetModel() != "bigger-model" {
		t.Fatalf("first event %v", w.snapshot()[0])
	}
	if m := h.llm.Requests()[0].Model; m != "bigger-model" {
		t.Fatalf("request model %s", m)
	}
}

// Re-selecting the current model after its context window changed in the
// catalog logs a fresh ModelChanged; re-selecting it unchanged does not.
func TestSetSameModelRefreshesContextLength(t *testing.T) {
	h := newHarness(t)
	overrides := filepath.Join(h.dir, "models.yaml")
	writeOverride := func(n int) {
		t.Helper()
		data := fmt.Sprintf("other:\n  bigger-model:\n    context_length: %d\n", n)
		if err := os.WriteFile(overrides, []byte(data), 0o600); err != nil {
			t.Fatal(err)
		}
		if err := h.m.Catalog.Refresh(context.Background(), "other"); err != nil {
			t.Fatal(err)
		}
	}
	h.m.Catalog = models.NewCatalog(h.config, func() string { return overrides },
		slog.New(slog.NewTextHandler(io.Discard, nil)))
	writeOverride(1000)
	sess := h.create()
	ctx := context.Background()
	if _, err := h.m.SetModel(ctx, sess.ID, "other", "bigger-model"); err != nil {
		t.Fatal(err)
	}
	modelChanges := func() []int64 {
		t.Helper()
		evs, err := h.st.Events(ctx, sess.ID, 0, 1<<62)
		if err != nil {
			t.Fatal(err)
		}
		var out []int64
		for _, ev := range evs {
			if mc := ev.GetModelChanged(); mc != nil {
				out = append(out, mc.ContextLength)
			}
		}
		return out
	}
	if _, err := h.m.SetModel(ctx, sess.ID, "other", "bigger-model"); err != nil {
		t.Fatal(err)
	}
	if got := modelChanges(); !slices.Equal(got, []int64{1000}) {
		t.Fatalf("unchanged re-select: %v", got)
	}
	writeOverride(2000)
	got, err := h.m.SetModel(ctx, sess.ID, "other", "bigger-model")
	if err != nil || got.ContextLength != 2000 {
		t.Fatalf("SetModel = %+v, %v", got, err)
	}
	if got := modelChanges(); !slices.Equal(got, []int64{1000, 2000}) {
		t.Fatalf("after refresh: %v", got)
	}
}

func TestNoModelConfigured(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Model = ""
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_STUCK {
		t.Fatalf("end %v", end)
	}
	if e, _ := find(w.snapshot(), (*flitv1.Event).GetError, notNil); e.TurnCanContinue {
		t.Fatalf("error %+v", e)
	}
}

func TestCreateValidation(t *testing.T) {
	h := newHarness(t)
	for _, o := range []CreateOptions{
		{},
		{WorkingDir: "relative"},
		{WorkingDir: filepath.Join(h.dir, "missing")},
		{WorkingDir: h.dir, Provider: "nope"},
	} {
		if _, err := h.m.Create(context.Background(), o); !errors.Is(err, ErrInvalid) {
			t.Errorf("%+v: err = %v", o, err)
		}
	}
	if _, err := h.m.Get(context.Background(), "ses_missing"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("Get missing: %v", err)
	}
}

func TestRestartMarksStuck(t *testing.T) {
	h := newHarness(t)
	sess := h.create()
	s, _ := h.m.session(context.Background(), sess.ID)
	if _, err := s.append(stateChanged(flitv1.TaskState_TASK_STATE_WORKING, "")); err != nil {
		t.Fatal(err)
	}
	m2, err := NewManager(context.Background(), h.st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	defer m2.Close()
	got, err := m2.Get(context.Background(), sess.ID)
	if err != nil || got.State != flitv1.TaskState_TASK_STATE_STUCK {
		t.Fatalf("after restart: %+v, %v", got, err)
	}
}

func TestBuildMessagesFillsMissingToolResults(t *testing.T) {
	ev := func(p any) *flitv1.Event {
		e := &flitv1.Event{}
		switch v := p.(type) {
		case *flitv1.MessageStarted:
			e.Payload = &flitv1.Event_MessageStarted{MessageStarted: v}
		case *flitv1.MessageDone:
			e.Payload = &flitv1.Event_MessageDone{MessageDone: v}
		case *flitv1.ToolCallStarted:
			e.Payload = &flitv1.Event_ToolCallStarted{ToolCallStarted: v}
		case *flitv1.ToolCallDone:
			e.Payload = &flitv1.Event_ToolCallDone{ToolCallDone: v}
		}
		return e
	}
	msgs := buildMessages([]*flitv1.Event{
		ev(&flitv1.MessageStarted{MessageId: "u1", Role: flitv1.Role_ROLE_USER}),
		ev(&flitv1.MessageDone{MessageId: "u1", Text: "hi"}),
		ev(&flitv1.MessageStarted{MessageId: "a1", Role: flitv1.Role_ROLE_ASSISTANT}),
		ev(&flitv1.MessageDone{MessageId: "a1"}),
		ev(&flitv1.ToolCallStarted{MessageId: "a1", ToolCallId: "t1", Name: "read", Arguments: "{}"}),
		ev(&flitv1.ToolCallStarted{MessageId: "a1", ToolCallId: "t2", Name: "read", Arguments: "{}"}),
		ev(&flitv1.ToolCallDone{ToolCallId: "t1", Result: "r1"}),
		ev(&flitv1.MessageStarted{MessageId: "a2", Role: flitv1.Role_ROLE_ASSISTANT}),
		ev(&flitv1.MessageDone{MessageId: "a2", FinishReason: "interrupted"}), // empty: dropped
		ev(&flitv1.MessageStarted{MessageId: "u2", Role: flitv1.Role_ROLE_USER}),
		ev(&flitv1.MessageDone{MessageId: "u2", Text: "again"}),
	})
	var got []string
	for _, m := range msgs {
		got = append(got, m.Role+":"+m.ToolCallID+":"+m.Content)
	}
	want := []string{"user::hi", "assistant::", "tool:t1:r1", "tool:t2:" + notRun, "user::again"}
	if strings.Join(got, "|") != strings.Join(want, "|") {
		t.Fatalf("got %q\nwant %q", got, want)
	}
}

func TestSystemPromptInstructionFiles(t *testing.T) {
	dir := t.TempDir()
	if p := systemPrompt(dir, nil); strings.Contains(p, "Project instructions") {
		t.Fatal("instructions without files")
	}
	os.WriteFile(filepath.Join(dir, "AGENTS.md"), []byte("rule one"), 0o644)
	os.WriteFile(filepath.Join(dir, "CLAUDE.md"), []byte("rule one\n"), 0o644)
	p := systemPrompt(dir, nil)
	if strings.Count(p, "rule one") != 1 || !strings.Contains(p, "CLAUDE.md has the same content as AGENTS.md") {
		t.Fatalf("duplicate files: %s", p)
	}
	os.WriteFile(filepath.Join(dir, "CLAUDE.md"), []byte("rule two"), 0o644)
	if p := systemPrompt(dir, nil); !strings.Contains(p, "rule one") || !strings.Contains(p, "rule two") {
		t.Fatalf("both files: %s", p)
	}
}

func TestRolesEffortTodoAndMetrics(t *testing.T) {
	h := newHarness(t)
	rolesDir := t.TempDir()
	os.WriteFile(filepath.Join(rolesDir, "reviewer.md"), []byte(
		"---\ndescription: Reviews\nprovider: other\nmodel: review-model\neffort: high\nmemory_file: MEMORY.md\n---\nReview carefully."), 0o600)
	os.WriteFile(filepath.Join(h.dir, "MEMORY.md"), []byte("The user likes tests."), 0o600)
	h.m.RolesDir = func() string { return rolesDir }

	if _, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Role: "nope"}); !errors.Is(err, ErrInvalid) {
		t.Fatalf("unknown role: %v", err)
	}
	sess, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Role: "reviewer"})
	if err != nil {
		t.Fatal(err)
	}
	if sess.Provider != "other" || sess.Model != "review-model" || sess.Effort != "high" || sess.Role != "reviewer" {
		t.Fatalf("session from role = %+v", sess)
	}

	h.llm.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "todo", `{"items":[{"content":"read code","status":"in_progress"},{"content":"report","status":"pending"}]}`})},
		llmtest.Response{Chunks: append(llmtest.Text("ok")[:1], llmtest.Finish("stop"), llmtest.Timings(100, 40))},
	)
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "review"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()

	reqs := h.llm.Requests()
	sys := reqs[0].Messages[0].Content
	if !strings.Contains(sys, "Review carefully.") || !strings.Contains(sys, "The user likes tests.") {
		t.Fatalf("system prompt lacks role/memory:\n%s", sys)
	}
	if reqs[0].ReasoningEffort != "high" || reqs[0].Model != "review-model" {
		t.Fatalf("request effort/model = %q/%q", reqs[0].ReasoningEffort, reqs[0].Model)
	}
	todo, ok := find(evs, (*flitv1.Event).GetTodoUpdated, notNil)
	if !ok || len(todo.Items) != 2 || todo.Items[0].Status != flitv1.TodoStatus_TODO_STATUS_IN_PROGRESS {
		t.Fatalf("todo event = %v", todo)
	}
	var last *flitv1.Usage
	for _, ev := range evs {
		if u := ev.GetUsage(); u != nil {
			last = u
		}
	}
	if last == nil || last.TimingSource != "llama.cpp" || last.PromptTokensPerSecond != 100 || last.GenerationTokensPerSecond != 40 {
		t.Fatalf("usage = %v", last)
	}
	got, _ := h.m.Get(context.Background(), sess.ID)
	if got.ContextTokens != 48 {
		t.Fatalf("context tokens = %d", got.ContextTokens)
	}

	// Effort can change mid-session.
	got, err = h.m.SetEffort(context.Background(), sess.ID, "low")
	if err != nil || got.Effort != "low" {
		t.Fatalf("SetEffort = %+v, %v", got, err)
	}
	mc := w.waitFor("effort change", func(ev *flitv1.Event) bool { return ev.GetModelChanged().GetEffort() == "low" })
	if mc.GetModelChanged().Model != "review-model" {
		t.Fatalf("model changed = %v", mc)
	}
	stored, _ := h.st.GetSession(context.Background(), sess.ID)
	if stored.Effort != "low" || stored.Role != "reviewer" {
		t.Fatalf("stored = %+v", stored)
	}
}

func TestChatTaskDefaults(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Tasks = map[string]config.TaskModel{"chat": {Provider: "other", Model: "chat-model", Effort: "medium"}}
	sess := h.create()
	if sess.Provider != "other" || sess.Model != "chat-model" || sess.Effort != "medium" {
		t.Fatalf("session = %+v", sess)
	}
}

func toolNames(req llm.Request) []string {
	var out []string
	for _, t := range req.Tools {
		out = append(out, t.Function.Name)
	}
	return out
}

func TestProjectsMoveAndRate(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	if _, err := h.m.CreateProject(ctx, "relative", ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("relative dir: %v", err)
	}
	p, err := h.m.CreateProject(ctx, h.dir, "")
	if err != nil || p.Name != filepath.Base(h.dir) || p.Directory != h.dir {
		t.Fatalf("project = %+v, %v", p, err)
	}
	if _, err := h.m.CreateProject(ctx, h.dir, "again"); !errors.Is(err, ErrInvalid) {
		t.Fatalf("duplicate project: %v", err)
	}

	// A session in a project with a directory needs no working_dir.
	sess, err := h.m.Create(ctx, CreateOptions{ProjectID: p.ID})
	if err != nil || sess.WorkingDir != h.dir || sess.ProjectID != p.ID {
		t.Fatalf("session in project = %+v, %v", sess, err)
	}
	if _, err := h.m.Create(ctx, CreateOptions{}); !errors.Is(err, ErrInvalid) {
		t.Fatalf("scratch without dir: %v", err)
	}
	scratch := h.create()
	if scratch.ProjectID != store.DefaultProjectID {
		t.Fatalf("scratch session = %+v", scratch)
	}
	w := h.watch(scratch.ID, 0)
	moved, err := h.m.MoveSession(ctx, scratch.ID, p.ID)
	if err != nil || moved.ProjectID != p.ID {
		t.Fatalf("move = %+v, %v", moved, err)
	}
	w.waitFor("moved", func(ev *flitv1.Event) bool { return ev.GetSessionMoved().GetProjectId() == p.ID })
	if list, _ := h.m.List(ctx, p.ID, 10, 0); len(list) != 2 {
		t.Fatalf("project sessions = %d", len(list))
	}
	if list, _ := h.m.Projects(ctx); len(list) != 2 || list[1].SessionCount != 2 {
		t.Fatalf("projects = %+v", list)
	}

	// Ratings name the model that wrote the message, even after a switch.
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("answer")})
	if _, err := h.m.Send(ctx, scratch.ID, "q"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	var msgID string
	for _, ev := range w.snapshot() {
		if ms := ev.GetMessageStarted(); ms != nil && ms.Role == flitv1.Role_ROLE_ASSISTANT {
			msgID = ms.MessageId
			if ms.Model != "test-model" || ms.Provider != "fake" {
				t.Fatalf("message started = %v", ms)
			}
		}
	}
	if _, err := h.m.SetModel(ctx, scratch.ID, "other", "newer"); err != nil {
		t.Fatal(err)
	}
	if err := h.m.Rate(ctx, scratch.ID, Rating{Target: flitv1.RatingTarget_RATING_TARGET_TURN, Good: true, MessageID: msgID, Note: "nice", Client: "phone"}); err != nil {
		t.Fatal(err)
	}
	fb := w.waitFor("feedback", func(ev *flitv1.Event) bool { return ev.GetFeedback() != nil }).GetFeedback()
	if fb.Rating != flitv1.Rating_RATING_GOOD || fb.Model != "test-model" || fb.Client != "phone" || fb.Note != "nice" {
		t.Fatalf("feedback = %v", fb)
	}
	if err := h.m.Rate(ctx, scratch.ID, Rating{Target: flitv1.RatingTarget_RATING_TARGET_MODEL}); err != nil {
		t.Fatalf("model rating: %v", err)
	}
	for _, bad := range []Rating{
		{Target: flitv1.RatingTarget_RATING_TARGET_TURN},
		{Target: flitv1.RatingTarget_RATING_TARGET_TURN, MessageID: "msg_nope"},
		{},
	} {
		if err := h.m.Rate(ctx, scratch.ID, bad); !errors.Is(err, ErrInvalid) {
			t.Errorf("rating %+v: %v", bad, err)
		}
	}
}

func TestToolSetSkillsAppendsAndMCPToggle(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	skillsDir := t.TempDir()
	os.MkdirAll(filepath.Join(skillsDir, "deploy"), 0o755)
	os.WriteFile(filepath.Join(skillsDir, "deploy", "SKILL.md"), []byte("---\nname: deploy\ndescription: How to deploy this app.\n---\nRun make deploy."), 0o644)
	h.m.SkillsDirs = func() []string { return []string{skillsDir} }
	h.cfg.Providers[0].PromptAppend = "Provider note."
	h.cfg.Agent.ModelPromptAppends = map[string]string{"fake/test-model": "Model note."}
	h.cfg.Web.Search = config.WebSearch{Provider: "searxng", URL: "http://127.0.0.1:1"}
	h.cfg.MCPServers = []config.MCPServer{{Name: "off", Command: "/nonexistent", Enabled: ptrBool(false)}, {Name: "on", Command: "/nonexistent"}}
	h.m.MCP = mcpclient.New(h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer h.m.MCP.Close()

	sess := h.create()
	if len(sess.MCPServers) != 1 || sess.MCPServers[0] != "on" {
		t.Fatalf("default MCP servers = %v", sess.MCPServers)
	}
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	req := h.llm.Requests()[0]
	names := strings.Join(toolNames(req), ",")
	for _, want := range []string{"git_commit", "web_fetch", "web_search", "skill"} {
		if !strings.Contains(names, want) {
			t.Errorf("tools lack %s: %s", want, names)
		}
	}
	sys := req.Messages[0].Content
	for _, want := range []string{"- deploy: How to deploy this app.", "- init: ", "/<name>", "Provider note.", "Model note.", "could not be started"} {
		if !strings.Contains(sys, want) {
			t.Errorf("system prompt lacks %q", want)
		}
	}
	if strings.Contains(sys, "Run make deploy.") {
		t.Error("skill body in the prompt; it should load on demand")
	}

	// Toggle servers per session.
	if _, err := h.m.SetMCPServer(ctx, sess.ID, "missing", true); !errors.Is(err, ErrInvalid) {
		t.Fatalf("unknown server: %v", err)
	}
	got, err := h.m.SetMCPServer(ctx, sess.ID, "on", false)
	if err != nil || len(got.MCPServers) != 0 {
		t.Fatalf("disable = %+v, %v", got, err)
	}
	got, _ = h.m.SetMCPServer(ctx, sess.ID, "off", true)
	if len(got.MCPServers) != 1 || got.MCPServers[0] != "off" {
		t.Fatalf("enable = %v", got.MCPServers)
	}
	st, err := h.m.MCPServers(ctx, sess.ID)
	if err != nil || len(st) != 2 || !st[0].Enabled || st[1].Enabled {
		t.Fatalf("status = %+v, %v", st, err)
	}
	w.waitFor("mcp change", func(ev *flitv1.Event) bool {
		c := ev.GetMcpServersChanged()
		return c != nil && len(c.Enabled) == 1 && c.Enabled[0] == "off"
	})
}

func ptrBool(b bool) *bool { return &b }

func TestModelCallsRecordedForCorpus(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	h.llm.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "list", `{}`})},
		llmtest.Response{Chunks: llmtest.Text("listed")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "list files"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	var userID string
	var assistant []string
	for _, ev := range w.snapshot() {
		if ms := ev.GetMessageStarted(); ms != nil {
			if ms.Role == flitv1.Role_ROLE_USER {
				userID = ms.MessageId
			} else {
				assistant = append(assistant, ms.MessageId)
			}
		}
	}
	if len(assistant) != 2 {
		t.Fatalf("assistant messages = %v", assistant)
	}

	// The second call's exact request is stored: system, user, the
	// assistant tool call and the tool result, plus the tool schemas.
	msgs, tools, err := h.st.ModelCallRequest(ctx, assistant[1])
	if err != nil || len(msgs) != 4 || !json.Valid(tools) {
		t.Fatalf("stored request = %d messages, tools %s, %v", len(msgs), tools, err)
	}
	var tool llm.Message
	json.Unmarshal(msgs[3], &tool)
	if tool.Role != "tool" || tool.ToolCallID != "c1" {
		t.Fatalf("stored tool message = %+v", tool)
	}
	if turn, err := h.st.ModelCallTurn(ctx, assistant[1]); err != nil || turn != userID {
		t.Fatalf("turn = %q, %v (user message %s)", turn, err, userID)
	}

	// A rating names the turn and the call, and lands in the ratings table.
	if err := h.m.Rate(ctx, sess.ID, Rating{Target: flitv1.RatingTarget_RATING_TARGET_TURN, Good: true, MessageID: assistant[1], Note: "right files"}); err != nil {
		t.Fatal(err)
	}
	fb := w.waitFor("feedback", func(ev *flitv1.Event) bool { return ev.GetFeedback() != nil }).GetFeedback()
	if fb.TurnId != userID {
		t.Fatalf("feedback turn = %q, want %q", fb.TurnId, userID)
	}
	rs, err := h.st.RatingsFor(ctx, []string{sess.ID})
	if err != nil || len(rs) != 1 || rs[0].ModelCallID != assistant[1] || rs[0].TurnID != userID || rs[0].Note != "right files" || !rs[0].Good {
		t.Fatalf("ratings = %+v, %v", rs, err)
	}
}

func TestAllowForSession(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	h.llm.Push(
		shellCall("cd sub && go version"),
		shellCall("go version"),
		shellCall("go env GOOS"),
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	if err := os.MkdirAll(filepath.Join(h.dir, "sub"), 0o755); err != nil {
		t.Fatal(err)
	}
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
	if strings.Join(req.SessionPatterns, ",") != "go version *" {
		t.Fatalf("offered patterns = %v", req.SessionPatterns)
	}
	if err := h.m.AnswerPrompt(ctx, sess.ID, req.PromptId, Answer{ForSession: true, Client: "laptop"}); err != nil {
		t.Fatal(err)
	}
	second := w.waitFor("second prompt", func(ev *flitv1.Event) bool {
		p := ev.GetPromptRequested()
		return p != nil && p.PromptId != req.PromptId
	}).GetPromptRequested()
	if err := h.m.AnswerPrompt(ctx, sess.ID, second.PromptId, Answer{Allow: false}); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()

	// The second "go version" ran without asking; "go env" asked again.
	var prompts []*flitv1.PromptRequested
	for _, ev := range evs {
		if p := ev.GetPromptRequested(); p != nil {
			prompts = append(prompts, p)
		}
	}
	if len(prompts) != 2 || prompts[1].Detail != "go env GOOS" {
		t.Fatalf("prompts = %v", prompts)
	}
	res, _ := find(evs, (*flitv1.Event).GetPromptResolved, notNil)
	if res.Decision != flitv1.PromptDecision_PROMPT_DECISION_ALLOW_SESSION || strings.Join(res.SessionPatterns, ",") != "go version *" {
		t.Fatalf("resolved = %v", res)
	}

	// After a restart the allowance comes back from the log.
	m2, err := NewManager(ctx, h.st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	defer m2.Close()
	s2, err := m2.session(ctx, sess.ID)
	if err != nil {
		t.Fatal(err)
	}
	if got := s2.sessionAllowed(); len(got) != 1 || got[0] != "go version *" {
		t.Fatalf("reloaded allowances = %v", got)
	}
}
