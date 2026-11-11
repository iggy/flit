package agent

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/notify"
)

// notes collects the notifications a Manager sends.
type notes struct {
	mu   sync.Mutex
	msgs []notify.Message
}

func (n *notes) send(_ context.Context, m notify.Message) {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.msgs = append(n.msgs, m)
}

// wait returns the notifications once there are want of them.
func (n *notes) wait(t *testing.T, want int) []notify.Message {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for {
		n.mu.Lock()
		got := append([]notify.Message(nil), n.msgs...)
		n.mu.Unlock()
		if len(got) >= want || time.Now().After(deadline) {
			if len(got) != want {
				t.Fatalf("%d notifications, want %d: %+v", len(got), want, got)
			}
			return got
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func longTurns(evs []*flitv1.Event) []*flitv1.LongTurn {
	var out []*flitv1.LongTurn
	for _, ev := range evs {
		if lt := ev.GetLongTurn(); lt != nil {
			out = append(out, lt)
		}
	}
	return out
}

func readCall(id string) llmtest.Response {
	return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{id, "read", `{"path":"a.txt"}`})}
}

// A long turn isn't stopped: every agent.long_turn_steps model calls it
// records a LongTurn event and sends a notification, and goes on.
func TestLongTurnNotifiesAndContinues(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.LongTurnSteps = 2
	var n notes
	h.m.Notify = n.send
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	h.llm.Push(
		readCall("r1"), readCall("r2"), readCall("r3"), readCall("r4"), readCall("r5"),
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	endEv := w.waitTurnEnd()
	if st := endEv.GetTaskStateChanged().GetState(); st != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("turn ended %v", st)
	}
	if got := len(h.llm.Requests()); got != 6 {
		t.Fatalf("%d model calls, want 6", got)
	}
	evs := w.snapshot()
	lts := longTurns(evs)
	if len(lts) != 2 || lts[0].Steps != 2 || lts[1].Steps != 4 || lts[0].SubagentToolCallId != "" {
		t.Fatalf("long turn events %v", lts)
	}
	if _, ok := find(evs, (*flitv1.Event).GetError, notNil); ok {
		t.Fatal("the turn reported an error")
	}
	msgs := n.wait(t, 2)
	if !strings.HasPrefix(msgs[0].Title, "Long turn: ") || !strings.Contains(msgs[1].Body, "The turn has made 4 model calls") {
		t.Fatalf("notifications %+v", msgs)
	}
}

// Subagents have no step cap either: they note a long run the same way.
func TestSubagentLongRun(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.LongTurnSteps = 100
	h.cfg.Agent.Subagents.LongTurnSteps = 2
	var n notes
	h.m.Notify = n.send
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	h.llm.Push(
		agentCall("ag1", `{"kind":"explore","task":"read a lot"}`),
		readCall("r1"), readCall("r2"), readCall("r3"),
		llmtest.Response{Chunks: llmtest.Text("findings")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	reqs := h.llm.Requests()
	if len(reqs) != 6 {
		t.Fatalf("%d model calls", len(reqs))
	}
	for i, req := range reqs[1:5] {
		if len(req.Tools) == 0 {
			t.Fatalf("subagent call %d offered no tools", i+1)
		}
	}
	evs := w.snapshot()
	lts := longTurns(evs)
	if len(lts) != 1 || lts[0].Steps != 2 || lts[0].SubagentToolCallId != "ag1" {
		t.Fatalf("long turn events %v", lts)
	}
	done, _ := find(evs, (*flitv1.Event).GetSubagentDone, notNil)
	if done.Outcome != flitv1.SubagentOutcome_SUBAGENT_OUTCOME_DONE || done.Steps != 4 || done.Report != "findings" {
		t.Fatalf("done %v", done)
	}
	if msgs := n.wait(t, 1); !strings.Contains(msgs[0].Body, "A subagent has made 2 model calls") {
		t.Fatalf("notification %+v", msgs[0])
	}
}
