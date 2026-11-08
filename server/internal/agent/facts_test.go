package agent

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/llm/llmtest"
)

// A real session learns from its shell calls after each turn, and later
// sessions get the fact in their system prompt.
func TestFactsLearnedFromTurnsAndInjected(t *testing.T) {
	h := newHarness(t)
	h.mu.Lock()
	h.cfg.Shell.Default = "allow"
	h.mu.Unlock()
	script := func(name, body string) {
		p := filepath.Join(h.dir, name)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte("#!/bin/sh\n"+body+"\n"), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	script("bad/pytest", "echo \"ModuleNotFoundError: No module named 'pytest'\"; exit 1")
	script("good/pytest", "echo '3 passed'")

	for i := range 4 {
		h.llm.Push(
			llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"call_1", "shell", `{"command":"bad/pytest -q"}`})},
			llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"call_2", "shell", `{"command":"good/pytest -q"}`})},
			llmtest.Response{Chunks: llmtest.Text("done")},
		)
		sess := h.create()
		w := h.watch(sess.ID, 0)
		if _, err := h.m.Send(context.Background(), sess.ID, "run the tests"); err != nil {
			t.Fatal(err)
		}
		w.waitTurnEnd()
		// The observer runs just after the turn ends.
		waitFor(t, func() bool {
			rows, err := h.m.store.ListFacts(context.Background(), sess.ProjectID)
			if err != nil {
				t.Fatal(err)
			}
			return len(rows) == 1 && len(rows[0].Sessions) == i+1
		})
	}

	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	reqs := h.llm.Requests()
	sys := reqs[len(reqs)-1].Messages[0].Content
	want := "<project-facts>\n- **When running the tests:** use `good/pytest`; `bad/pytest` fails here with a missing module error.\n</project-facts>"
	if !strings.Contains(sys, want) {
		t.Fatalf("system prompt lacks the fact:\n%s", sys)
	}
	got, err := h.m.store.FactInjections(context.Background(), sess.ID)
	if err != nil || len(got) != 1 {
		t.Fatalf("injections: %v, %v", got, err)
	}
}

func waitFor(t *testing.T, cond func() bool) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for !cond() {
		if time.Now().After(deadline) {
			t.Fatal("timed out")
		}
		time.Sleep(10 * time.Millisecond)
	}
}
