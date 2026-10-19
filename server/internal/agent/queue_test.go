package agent

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

// slowText streams "first", waits, then finishes: time to queue messages
// while the turn runs.
func slowText(final string) llmtest.Response {
	chunks := llmtest.Text(final)
	return llmtest.Response{Chunks: append([]string{chunks[0], llmtest.Pause(300 * time.Millisecond)}, chunks[1:]...)}
}

func requestUsers(h *harness, i int) []string {
	var out []string
	for _, m := range h.llm.Requests()[i].Messages {
		if m.Role == "user" {
			out = append(out, m.Content)
		}
	}
	return out
}

// A message sent while a tool waits joins the conversation after the tool
// result, before the next model call, in the same turn.
func TestQueuedMessageDeliveredAtStepBoundary(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	h.llm.Push(shellCall("echo hi"), llmtest.Response{Chunks: llmtest.Text("done")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "run it"); err != nil {
		t.Fatal(err)
	}
	prompt := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
	res, err := h.m.SendMessage(ctx, sess.ID, "also check the logs", "phone")
	if err != nil || res.QueueID == "" {
		t.Fatalf("queue = %+v, %v", res, err)
	}
	if err := h.m.AnswerPrompt(ctx, sess.ID, prompt.PromptId, Answer{Allow: true, Client: "desk"}); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("end %v", end)
	}
	msgs := h.llm.Requests()[1].Messages
	last := msgs[len(msgs)-1]
	if last.Role != "user" || last.Content != "also check the logs" || msgs[len(msgs)-2].Role != "tool" {
		t.Fatalf("second request %+v", msgs)
	}
	evs := w.snapshot()
	k := strings.Join(kinds(evs), ",")
	if !strings.Contains(k, "message_queued") || !strings.Contains(k, "tool_call_done,queued_message_delivered,message_started,text_delta,message_done,message_started") {
		t.Fatalf("events %s", k)
	}
	if q, _ := find(evs, (*flitv1.Event).GetMessageQueued, notNil); q.Client != "phone" || q.QueueId != res.QueueID {
		t.Fatalf("queued %v", q)
	}
	// One turn: it ended once.
	dones := 0
	for _, ev := range evs {
		if ev.GetTaskStateChanged().GetState() == flitv1.TaskState_TASK_STATE_DONE {
			dones++
		}
	}
	if dones != 1 {
		t.Fatalf("%d turn ends: %s", dones, k)
	}
}

// A message queued during a turn that ends with a final answer starts the
// next turn.
func TestQueuedMessageStartsNextTurn(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	h.llm.Push(slowText("first answer"), llmtest.Response{Chunks: llmtest.Text("second answer")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "one"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("streaming", func(ev *flitv1.Event) bool { return ev.GetTextDelta().GetText() == "first answer" })
	if _, err := h.m.SendMessage(ctx, sess.ID, "two", ""); err != nil {
		t.Fatal(err)
	}
	answer := w.waitFor("second answer", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "second answer" })
	w.waitFor("second end", func(ev *flitv1.Event) bool {
		return ev.Seq > answer.Seq && ev.GetTaskStateChanged().GetState() == flitv1.TaskState_TASK_STATE_DONE
	})
	if got := requestUsers(h, 1); strings.Join(got, "|") != "one|two" {
		t.Fatalf("second request users %v", got)
	}
	var states []string
	for _, ev := range w.snapshot() {
		if st := ev.GetTaskStateChanged(); st != nil {
			states = append(states, st.State.String())
		}
	}
	if strings.Join(states, ",") != "TASK_STATE_WORKING,TASK_STATE_DONE,TASK_STATE_WORKING,TASK_STATE_DONE" {
		t.Fatalf("states %v", states)
	}
}

func TestEditAndCancelQueuedMessages(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	h.llm.Push(slowText("a"), llmtest.Response{Chunks: llmtest.Text("b")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "start"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("streaming", func(ev *flitv1.Event) bool { return ev.GetTextDelta().GetText() == "a" })
	keep, _ := h.m.SendMessage(ctx, sess.ID, "typo here", "")
	drop, _ := h.m.SendMessage(ctx, sess.ID, "never mind", "")
	if err := h.m.EditQueuedMessage(ctx, sess.ID, keep.QueueID, "fixed"); err != nil {
		t.Fatal(err)
	}
	if err := h.m.CancelQueuedMessage(ctx, sess.ID, drop.QueueID); err != nil {
		t.Fatal(err)
	}
	if err := h.m.EditQueuedMessage(ctx, sess.ID, keep.QueueID, " "); !errors.Is(err, ErrInvalid) {
		t.Fatalf("empty edit: %v", err)
	}
	w.waitFor("b", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "b" })
	if got := requestUsers(h, 1); strings.Join(got, "|") != "start|fixed" {
		t.Fatalf("users %v", got)
	}
	if err := h.m.CancelQueuedMessage(ctx, sess.ID, keep.QueueID); !errors.Is(err, ErrQueueGone) {
		t.Fatalf("cancel after delivery: %v", err)
	}
	if err := h.m.EditQueuedMessage(ctx, sess.ID, drop.QueueID, "x"); !errors.Is(err, ErrQueueGone) {
		t.Fatalf("edit after cancel: %v", err)
	}
}

// Stop leaves the queue; it survives a restart and the next Send (even an
// empty one) delivers it first.
func TestQueueAfterInterruptAndRestart(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	started := make(chan struct{})
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("x")[:1], Hang: true, Started: started})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	<-started
	if _, err := h.m.SendMessage(ctx, sess.ID, "queued one", ""); err != nil {
		t.Fatal(err)
	}
	if _, err := h.m.Interrupt(ctx, sess.ID); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	time.Sleep(50 * time.Millisecond)
	if n := len(h.llm.Requests()); n != 1 {
		t.Fatalf("the queue started a turn after Stop (%d requests)", n)
	}
	w.stop()
	h.m.Close()

	// A new manager over the same store finds the queue in the log.
	m2, err := NewManager(ctx, h.st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	h.m = m2
	if _, err := m2.Send(ctx, sess.ID, ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("Send rejects empty text: %v", err)
	}
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	w2 := h.watch(sess.ID, 0)
	if _, err := m2.SendMessage(ctx, sess.ID, "", ""); err != nil {
		t.Fatalf("empty Send with a queue: %v", err)
	}
	w2.waitFor("ok", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "ok" })
	if got := requestUsers(h, 1); got[len(got)-1] != "queued one" {
		t.Fatalf("users %v", got)
	}
	if _, err := m2.SendMessage(ctx, sess.ID, "", ""); err == nil {
		// The turn may still be running (then empty text is refused as a
		// queue entry) or done with an empty queue; either way it's invalid.
		t.Fatal("empty Send with nothing queued succeeded")
	}
}
