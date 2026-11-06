package agent

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func toolResults(evs []*flitv1.Event) map[string]*flitv1.ToolCallDone {
	out := map[string]*flitv1.ToolCallDone{}
	for _, ev := range evs {
		if d := ev.GetToolCallDone(); d != nil {
			out[d.ToolCallId] = d
		}
	}
	return out
}

func TestLongToolOutputIsSaved(t *testing.T) {
	h := newHarness(t)
	h.m.DataDir = t.TempDir()
	h.cfg.Agent.ToolOutputMaxLines = 20
	var big strings.Builder
	for i := 1; i <= 200; i++ {
		fmt.Fprintf(&big, "line %d\n", i)
	}
	if err := os.WriteFile(filepath.Join(h.dir, "big.txt"), []byte(big.String()), 0o644); err != nil {
		t.Fatal(err)
	}
	sess := h.create()
	outDir := filepath.Join(h.m.DataDir, "sessions", sess.ID, "tool-output")
	saved := filepath.Join(outDir, "c1.txt")
	subSaved := filepath.Join(outDir, "ag1", "s1.txt")

	evs := sendTurn(t, h, sess.ID, "look at big.txt",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "read", `{"path":"big.txt"}`})},
		// The model reads the middle back from the saved file.
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c2", "read", `{"path":"` + filepath.ToSlash(saved) + `","offset":100,"limit":1}`})},
		// A subagent's long output is saved too, under its call.
		agentCall("ag1", `{"kind":"explore","task":"read big.txt"}`),
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"s1", "read", `{"path":"big.txt"}`})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"s2", "grep", `{"pattern":"line 150$","path":"` + filepath.ToSlash(subSaved) + `"}`})},
		llmtest.Response{Chunks: llmtest.Text("found it")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	res := toolResults(evs)
	if r := res["c1"]; r == nil || !r.Truncated || !strings.Contains(r.Result, "full output is saved in "+saved) || strings.Contains(r.Result, "line 100\n") {
		t.Fatalf("c1 = %v", r)
	}
	b, err := os.ReadFile(saved)
	if err != nil || !strings.Contains(string(b), "   100\tline 100\n") || !strings.Contains(string(b), "   200\tline 200") {
		t.Fatalf("saved file: %v\n%s", err, b)
	}
	if r := res["c2"]; r == nil || r.IsError || !strings.Contains(r.Result, "line 100") {
		t.Fatalf("c2 = %v", r)
	}
	sub := toolResults(subagentEvents(evs))
	if r := sub["s1"]; r == nil || !strings.Contains(r.Result, "saved in "+subSaved) {
		t.Fatalf("s1 = %v", r)
	}
	if r := sub["s2"]; r == nil || r.IsError || !strings.Contains(r.Result, "line 150") {
		t.Fatalf("s2 = %v", r)
	}

	// A provider that reuses call ids doesn't overwrite earlier output.
	sendTurn(t, h, sess.ID, "again",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "read", `{"path":"big.txt"}`})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	if _, err := os.Stat(filepath.Join(outDir, "c1-2.txt")); err != nil {
		t.Fatal(err)
	}
}

func TestSaveToolOutputCleansNames(t *testing.T) {
	dir := t.TempDir()
	p, err := saveToolOutput(dir, "../../etc/pass wd", "x")
	if err != nil {
		t.Fatal(err)
	}
	if r, err := filepath.Rel(dir, p); err != nil || strings.Contains(r, "..") || !strings.HasSuffix(p, "pass_wd.txt") {
		t.Fatalf("saved to %s", p)
	}
}

func TestRepeatCallNudge(t *testing.T) {
	h := newHarness(t)
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	h.cfg.Agent.RepeatCallNudges = []int{2, 3}
	sess := h.create()
	evs := sendTurn(t, h, sess.ID, "read a",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "read", `{"path":"a.txt"}`})},
		// Same call, different spelling: still the same call.
		llmtest.Response{Chunks: llmtest.ToolCalls(
			[3]string{"c2", "read", `{ "path" : "a.txt" }`},
			[3]string{"c3", "read", `{"path":"a.txt","limit":5}`},
		)},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c4", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	res := toolResults(evs)
	const note = "[flit: you have now made this exact call"
	if strings.Contains(res["c1"].Result, note) || strings.Contains(res["c3"].Result, note) {
		t.Fatalf("nudged too early: %v %v", res["c1"], res["c3"])
	}
	if !strings.Contains(res["c2"].Result, "2 times") || !strings.Contains(res["c4"].Result, "3 times") || res["c4"].IsError {
		t.Fatalf("not nudged: %v %v", res["c2"], res["c4"])
	}
	// The model sees it too.
	if msgs := h.llm.Requests()[2].Messages; !strings.Contains(msgs[len(msgs)-2].Content, note) {
		t.Fatalf("model context: %+v", msgs)
	}

	// A new user message starts the count again; an empty list turns it off.
	evs = sendTurn(t, h, sess.ID, "again",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c5", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	if r := toolResults(evs)["c5"]; strings.Contains(r.Result, note) {
		t.Fatalf("count not reset: %v", r)
	}
	h.mu.Lock()
	h.cfg.Agent.RepeatCallNudges = nil
	h.mu.Unlock()
	evs = sendTurn(t, h, sess.ID, "again",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c6", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c7", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	if r := toolResults(evs)["c7"]; strings.Contains(r.Result, note) {
		t.Fatalf("nudged with nudges off: %v", r)
	}
}

func TestReadBeforeWriteInSession(t *testing.T) {
	h := newHarness(t)
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("one\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	sess := h.create()
	edit := `{"path":"a.txt","edits":[{"old_string":"one","new_string":"two"}]}`
	evs := sendTurn(t, h, sess.ID, "edit a",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"p1", "patch", edit})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"r1", "read", `{"path":"a.txt"}`})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"p2", "patch", edit})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	res := toolResults(evs)
	if r := res["p1"]; !r.IsError || !strings.Contains(r.Result, "read the file first") {
		t.Fatalf("p1 = %v", r)
	}
	if r := res["p2"]; r.IsError {
		t.Fatalf("p2 = %v", r)
	}

	// The next turn remembers the read; a build subagent doesn't share it.
	back := `{"path":"a.txt","edits":[{"old_string":"two","new_string":"three"}]}`
	evs = sendTurn(t, h, sess.ID, "edit again",
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"p3", "patch", back})},
		agentCall("ag1", `{"kind":"build","task":"edit a.txt"}`),
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"s1", "patch", `{"path":"a.txt","edits":[{"old_string":"three","new_string":"four"}]}`})},
		llmtest.Response{Chunks: llmtest.Text("could not")},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	if r := toolResults(evs)["p3"]; r.IsError {
		t.Fatalf("p3 = %v", r)
	}
	if r := toolResults(subagentEvents(evs))["s1"]; !r.IsError || !strings.Contains(r.Result, "read the file first") {
		t.Fatalf("subagent patch = %v", r)
	}

	// Another branch starts with nothing read; turning the check off
	// drops it.
	s, err := h.m.session(context.Background(), sess.ID)
	if err != nil {
		t.Fatal(err)
	}
	first := s.fileTracker()
	if s.fileTracker() != first {
		t.Fatal("tracker not kept")
	}
	s.mu.Lock()
	s.info.BranchID = "br_other"
	s.mu.Unlock()
	if s.fileTracker() == first {
		t.Fatal("tracker kept across branches")
	}
	h.mu.Lock()
	h.cfg.Agent.ReadBeforeWrite = ptrBool(false)
	h.mu.Unlock()
	if s.fileTracker() != nil {
		t.Fatal("tracker with the check off")
	}
}

func TestCanonicalArgs(t *testing.T) {
	if a, b := canonicalArgs(`{"b":1, "a":[1, 2]}`), canonicalArgs(`{"a":[1,2],"b":1}`); a != b {
		t.Fatalf("%s != %s", a, b)
	}
	if canonicalArgs(" not json ") != "not json" {
		t.Fatal("non-JSON args")
	}
}
