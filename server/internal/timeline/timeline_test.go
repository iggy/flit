package timeline

import (
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
)

type log struct {
	t0  time.Time
	evs []*flitv1.Event
}

func (l *log) add(after time.Duration, ev *flitv1.Event) {
	ev.Seq = int64(len(l.evs) + 1)
	ev.Time = timestamppb.New(l.t0.Add(after))
	l.evs = append(l.evs, ev)
}

func TestTimeline(t *testing.T) {
	l := &log{t0: time.Date(2026, 10, 18, 17, 0, 0, 0, time.Local)}
	s := time.Second
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: "u1", Role: flitv1.Role_ROLE_USER}}})
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: "u1", Text: "fix the build"}}})
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_TaskStateChanged{TaskStateChanged: &flitv1.TaskStateChanged{State: flitv1.TaskState_TASK_STATE_WORKING}}})
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: "m1", Role: flitv1.Role_ROLE_ASSISTANT, Provider: "local", Model: "qwen"}}})
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{MessageId: "m1", Attempt: 1, FirstByteTimeoutMs: 600000, StallTimeoutMs: 120000}}})
	l.add(120*s, &flitv1.Event{Payload: &flitv1.Event_ModelCallEnded{ModelCallEnded: &flitv1.ModelCallEnded{
		MessageId: "m1", Attempt: 1, Outcome: flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_STALLED, Phase: "processing_prompt",
		Error: "the model server stopped reporting progress on the prompt for 2m0s", ResponseHeadersMs: 5, FirstByteMs: 10, TotalMs: 120000, WillRetry: true,
	}}})
	l.add(120*s, &flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{MessageId: "m1", Attempt: 2, FirstByteTimeoutMs: 600000, StallTimeoutMs: 120000}}})
	l.add(130*s, &flitv1.Event{Payload: &flitv1.Event_PromptProgress{PromptProgress: &flitv1.PromptProgress{MessageId: "m1", Attempt: 2, Processed: 48000, Total: 48000, Cached: 40000, ElapsedMs: 9500}}})
	l.add(131*s, &flitv1.Event{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: "m1", Text: "On it."}}})
	l.add(133*s, &flitv1.Event{Payload: &flitv1.Event_ModelCallEnded{ModelCallEnded: &flitv1.ModelCallEnded{
		MessageId: "m1", Attempt: 2, Outcome: flitv1.ModelCallOutcome_MODEL_CALL_OUTCOME_OK, FirstTokenMs: 11000, TotalMs: 13000, Bytes: 900,
		InputTokens: 48000, OutputTokens: 20, PromptTokens: 8000, PromptMs: 9500, PredictedTokens: 20, PredictedMs: 1500,
	}}})
	l.add(133*s, &flitv1.Event{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: "m1", Text: "On it.", FinishReason: "tool_calls"}}})
	l.add(133*s, &flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{MessageId: "m1", ToolCallId: "c1", Name: "shell", Arguments: `{"command":"go test ./..."}`}}})

	var b strings.Builder
	sess := store.Session{ID: "s1", Title: "Build", Provider: "local", Model: "qwen", State: flitv1.TaskState_TASK_STATE_WORKING, WorkingDir: "/src"}
	if err := Write(&b, sess, l.evs, l.t0.Add(10*time.Minute)); err != nil {
		t.Fatal(err)
	}
	out := b.String()
	for _, want := range []string{
		`Session s1  "Build"`,
		"12 events (seq 1-12)",
		"user message: fix the build",
		"model call attempt 1 sent (watchdog: first token 10m00s, stall 2m00s)",
		"model call attempt 1 STALLED while processing prompt after 2m00s (headers 5ms, first byte 10ms), 0 bytes; retrying",
		"stopped reporting progress",
		"prompt 48000/48000 tokens (40000 cached) after 9.5s",
		"model call attempt 2 ok after 13.0s (first token 11.0s), 900 bytes, 48000 in / 20 out; llama.cpp: prompt 8000 tok in 9.5s, generated 20 tok in 1.5s",
		"message done (tool_calls): 6 chars of text, 0 of reasoning, streamed over 0ms",
		"Still open:",
		`tool shell (c1) started 7m47s ago and never finished: {"command":"go test ./..."}`,
	} {
		if !strings.Contains(out, want) {
			t.Errorf("missing %q in:\n%s", want, out)
		}
	}
}

// A call with no end is reported with what it was last doing.
func TestTimelineOpenCall(t *testing.T) {
	l := &log{t0: time.Date(2026, 10, 18, 17, 0, 0, 0, time.Local)}
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: "m1", Role: flitv1.Role_ROLE_ASSISTANT}}})
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_ModelCallStarted{ModelCallStarted: &flitv1.ModelCallStarted{MessageId: "m1", Attempt: 1}}})
	l.add(5*time.Second, &flitv1.Event{Payload: &flitv1.Event_PromptProgress{PromptProgress: &flitv1.PromptProgress{MessageId: "m1", Attempt: 1, Processed: 1000, Total: 48000}}})
	var b strings.Builder
	if err := Write(&b, store.Session{ID: "s1"}, l.evs, l.t0.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	if want := "model call for m1 (attempt 1) sent 1h00m ago and never ended; no output yet, last prompt progress 1000/48000"; !strings.Contains(b.String(), want) {
		t.Fatalf("missing %q in:\n%s", want, b.String())
	}
}

func TestTimelineNothingOpenButWorking(t *testing.T) {
	l := &log{t0: time.Date(2026, 10, 18, 17, 0, 0, 0, time.Local)}
	l.add(0, &flitv1.Event{Payload: &flitv1.Event_TaskStateChanged{TaskStateChanged: &flitv1.TaskStateChanged{State: flitv1.TaskState_TASK_STATE_WORKING}}})
	var b strings.Builder
	_ = Write(&b, store.Session{ID: "s1", State: flitv1.TaskState_TASK_STATE_WORKING}, l.evs, l.t0.Add(3*time.Minute))
	if !strings.Contains(b.String(), "the harness itself may be stuck") {
		t.Fatal(b.String())
	}
}
