package agent

import (
	"context"
	"io"
	"log/slog"
	"strconv"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/models"
)

func callsEnded(evs []*flitv1.Event) []*flitv1.ModelCallEnded {
	var out []*flitv1.ModelCallEnded
	for _, ev := range evs {
		if e := ev.GetModelCallEnded(); e != nil {
			out = append(out, e)
		}
	}
	return out
}

// A call that stalls before any output is retried once (model_retries)
// and the log shows both attempts.
func TestStallBeforeOutputIsRetried(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.ModelRetries = 1
	h.cfg.Agent.ModelFirstTokenTimeout = 80 * time.Millisecond
	h.cfg.Agent.ModelStallTimeout = 80 * time.Millisecond
	sess := h.create()
	h.llm.Push(
		llmtest.Response{Chunks: append([]string{llmtest.Pause(5 * time.Second)}, llmtest.Text("late")...)},
		llmtest.Response{Chunks: llmtest.Text("hello")},
	)
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("end %v; events:\n%s", end, dump(w.snapshot()))
	}
	evs := w.snapshot()
	ended := callsEnded(evs)
	if len(ended) != 2 {
		t.Fatalf("calls %v", ended)
	}
	if e := ended[0]; e.Attempt != 1 || e.Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED ||
		e.Phase != "waiting_for_first_byte" || !e.WillRetry || e.TotalMs < 80 {
		t.Fatalf("first attempt %v", e)
	}
	if e := ended[1]; e.Attempt != 2 || e.Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_OK || e.WillRetry ||
		e.FirstTokenMs > e.TotalMs || e.Bytes == 0 || e.InputTokens != 10 {
		t.Fatalf("second attempt %v", e)
	}
	if done, _ := find(evs, (*flitv1.Event).GetMessageDone, func(m *flitv1.MessageDone) bool { return m != nil && m.Text == "hello" }); done == nil {
		t.Fatalf("no reply; events:\n%s", dump(evs))
	}
}

// A call that stalls mid-reply isn't retried: the turn ends stuck with an
// error that says where it stopped.
func TestStallMidReplyStopsTheTurn(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.ModelRetries = 1
	h.cfg.Agent.ModelStallTimeout = 80 * time.Millisecond
	sess := h.create()
	h.llm.Push(llmtest.Response{Chunks: []string{llmtest.Text("half a")[0], llmtest.Pause(5 * time.Second)}})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_STUCK {
		t.Fatalf("end %v", end)
	}
	evs := w.snapshot()
	ended := callsEnded(evs)
	if len(ended) != 1 || ended[0].Outcome != flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED || ended[0].Phase != "streaming" || ended[0].WillRetry {
		t.Fatalf("calls %v", ended)
	}
	e, _ := find(evs, (*flitv1.Event).GetError, notNil)
	if !e.TurnCanContinue || !strings.Contains(e.Message, "stopped mid-reply") || !strings.Contains(e.Message, "raise agent.model_stall_timeout") {
		t.Fatalf("error %v", e)
	}
	if len(h.llm.Requests()) != 1 {
		t.Fatalf("%d requests", len(h.llm.Requests()))
	}
}

// With llama.cpp, flit asks for prompt progress and logs it (throttled).
func TestPromptProgressFromLlamaCpp(t *testing.T) {
	h := newHarness(t)
	h.cfg.Providers[0].Kind = string(models.KindLlamaCpp)
	h.m.Catalog = models.NewCatalog(h.config, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	sess := h.create()
	chunks := []string{llmtest.Progress(0, 3000, 1000, 0), llmtest.Progress(1000, 3000, 1000, 10), llmtest.Progress(3000, 3000, 1000, 30)}
	h.llm.Push(llmtest.Response{Chunks: append(chunks, llmtest.Text("ok")...)})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	if !h.llm.Requests()[0].ReturnProgress {
		t.Fatal("return_progress not requested")
	}
	var got []string
	for _, ev := range w.snapshot() {
		if p := ev.GetPromptProgress(); p != nil {
			got = append(got, strings.Join([]string{itoa(p.Processed), itoa(p.Total), itoa(p.Cached)}, "/"))
		}
	}
	// The middle one comes within a second of the first and is dropped;
	// the last always gets through.
	if strings.Join(got, " ") != "0/3000/1000 3000/3000/1000" {
		t.Fatalf("progress %v", got)
	}
}

// Other providers don't get the llama.cpp-only parameter.
func TestNoProgressRequestForOtherProviders(t *testing.T) {
	h := newHarness(t)
	h.cfg.Providers[0].Kind = "openai"
	h.m.Catalog = models.NewCatalog(h.config, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	sess := h.create()
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	if h.llm.Requests()[0].ReturnProgress {
		t.Fatal("return_progress sent to a non-llama.cpp provider")
	}
}

func itoa(n int64) string { return strconv.FormatInt(n, 10) }
