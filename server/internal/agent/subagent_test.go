package agent

import (
	"context"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func agentCall(id, args string) llmtest.Response {
	return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{id, "agent", args})}
}

func sortedToolNames(req llm.Request) []string {
	var out []string
	for _, t := range req.Tools {
		out = append(out, t.Function.Name)
	}
	slices.Sort(out)
	return out
}

func subagentEvents(evs []*flitv1.Event) []*flitv1.Event {
	var out []*flitv1.Event
	for _, ev := range evs {
		if se := ev.GetSubagentEvent(); se != nil {
			out = append(out, se.Event)
		}
	}
	return out
}

func TestSubagentExplore(t *testing.T) {
	h := newHarness(t)
	ro := true
	h.cfg.Shell.ReadOnly = &ro
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("the answer is 42\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	h.llm.Push(
		agentCall("ag1", `{"kind":"explore","task":"What is the answer in a.txt?","files":["a.txt"]}`),
		// The subagent: tries to write, runs a command that would write,
		// reads, then reports.
		llmtest.Response{Chunks: llmtest.ToolCalls(
			[3]string{"c1", "write", `{"path":"b.txt","content":"x"}`},
			[3]string{"c2", "shell", `{"command":"echo hi > b.txt"}`},
			[3]string{"c3", "shell", `{"command":"cat a.txt"}`},
			[3]string{"c4", "agent", `{"kind":"explore","task":"nested"}`},
		)},
		llmtest.Response{Chunks: llmtest.Text("a.txt:1 says the answer is 42.")},
		// The agent again, with the report.
		llmtest.Response{Chunks: llmtest.Text("It's 42.")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "find the answer"); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("end %v\n%s", end, dump(w.snapshot()))
	}
	evs := w.snapshot()
	reqs := h.llm.Requests()
	if len(reqs) != 4 {
		t.Fatalf("%d model calls", len(reqs))
	}

	// The parent offers agent; the explore subagent only reading tools.
	if !slices.Contains(sortedToolNames(reqs[0]), "agent") {
		t.Fatalf("agent tool not offered: %v", sortedToolNames(reqs[0]))
	}
	want := []string{"git_diff", "git_log", "git_status", "grep", "list", "read", "shell", "web_fetch"}
	if got := sortedToolNames(reqs[1]); !slices.Equal(got, want) {
		t.Fatalf("explore tools = %v, want %v", got, want)
	}
	sub := reqs[1].Messages
	if len(sub) != 2 || sub[0].Role != "system" || !strings.Contains(sub[0].Content, "read-only") ||
		sub[1].Role != "user" || !strings.Contains(sub[1].Content, "What is the answer") || !strings.Contains(sub[1].Content, "a.txt") {
		t.Fatalf("subagent context: %+v", sub)
	}
	if strings.Contains(sub[1].Content, "find the answer") {
		t.Fatal("subagent saw the parent's conversation")
	}
	if _, err := os.Stat(filepath.Join(h.dir, "b.txt")); err == nil {
		t.Fatal("explore subagent wrote a file")
	}
	if _, ok := find(evs, (*flitv1.Event).GetPromptRequested, notNil); ok {
		t.Fatal("explore subagent asked the user")
	}

	started, _ := find(evs, (*flitv1.Event).GetSubagentStarted, notNil)
	if started == nil || started.ToolCallId != "ag1" || started.Kind != flitv1.SubagentKind_SUBAGENT_KIND_EXPLORE ||
		started.Provider != "fake" || started.Model != "test-model" || started.MaxSteps != 20 {
		t.Fatalf("started %v", started)
	}
	results := map[string]*flitv1.ToolCallDone{}
	for _, ev := range subagentEvents(evs) {
		if d := ev.GetToolCallDone(); d != nil {
			results[d.ToolCallId] = d
		}
	}
	if r := results["c1"]; r == nil || !r.IsError || !strings.Contains(r.Result, "unknown tool") {
		t.Fatalf("write: %v", r)
	}
	if r := results["c2"]; r == nil || !r.IsError || !strings.Contains(r.Result, "only read-only commands") {
		t.Fatalf("writing shell: %v", r)
	}
	if r := results["c3"]; r == nil || r.IsError || !strings.Contains(r.Result, "the answer is 42") {
		t.Fatalf("cat: %v", r)
	}
	if r := results["c4"]; r == nil || !r.IsError || !strings.Contains(r.Result, "unknown tool") {
		t.Fatalf("nested agent: %v", r)
	}
	doneEv, _ := find(evs, (*flitv1.Event).GetSubagentDone, notNil)
	if doneEv.Outcome != flitv1.SubagentOutcome_SUBAGENT_OUTCOME_DONE || doneEv.Steps != 2 || doneEv.Report != "a.txt:1 says the answer is 42." {
		t.Fatalf("done %v", doneEv)
	}

	// Only the report reaches the agent.
	tc, _ := find(evs, (*flitv1.Event).GetToolCallDone, func(d *flitv1.ToolCallDone) bool { return d != nil && d.ToolCallId == "ag1" })
	if tc == nil || tc.IsError || tc.Result != doneEv.Report {
		t.Fatalf("agent tool result %v", tc)
	}
	parent := reqs[3].Messages
	if n := len(parent); n != 4 || parent[3].Role != "tool" || parent[3].Content != doneEv.Report {
		t.Fatalf("parent context after the subagent: %+v", parent)
	}

	// The child transcript is in the log, so it replays.
	stored, err := h.st.Events(context.Background(), sess.ID, 1, 1<<30)
	if err != nil {
		t.Fatal(err)
	}
	if n := len(subagentEvents(stored)); n == 0 || n != len(subagentEvents(evs)) {
		t.Fatalf("stored %d subagent events, live %d", n, len(subagentEvents(evs)))
	}
}

func TestSubagentBuildUsesPermissionsAndTaskModel(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Tasks = map[string]config.TaskModel{"build": {Provider: "other", Model: "build-model"}}
	h.llm.Push(
		agentCall("ag1", `{"kind":"build","task":"say hi"}`),
		shellCall("echo built-it"),
		llmtest.Response{Chunks: llmtest.Text("ran echo")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	// The subagent's command is asked about in the session, naming its
	// own tool call.
	req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
	if req.ToolCallId != "sh1" || req.Detail != "echo built-it" {
		t.Fatalf("prompt %v", req)
	}
	w.waitState(flitv1.TaskState_TASK_STATE_WAITING)
	if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: true, Client: "c"}); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	reqs := h.llm.Requests()
	if reqs[1].Model != "build-model" || reqs[0].Model != "test-model" || reqs[3].Model != "test-model" {
		t.Fatalf("models %s %s %s", reqs[0].Model, reqs[1].Model, reqs[3].Model)
	}
	names := sortedToolNames(reqs[1])
	for _, n := range []string{"write", "patch", "shell", "git_commit"} {
		if !slices.Contains(names, n) {
			t.Fatalf("build tools %v lack %s", names, n)
		}
	}
	for _, n := range []string{"agent", "todo", "skill"} {
		if slices.Contains(names, n) {
			t.Fatalf("build tools %v include %s", names, n)
		}
	}
	if !strings.Contains(reqs[1].Messages[0].Content, "subagent") {
		t.Fatalf("build system prompt: %s", reqs[1].Messages[0].Content)
	}
	started, _ := find(evs, (*flitv1.Event).GetSubagentStarted, notNil)
	if started.Provider != "other" || started.Model != "build-model" || started.Kind != flitv1.SubagentKind_SUBAGENT_KIND_BUILD {
		t.Fatalf("started %v", started)
	}
	var out string
	for _, ev := range subagentEvents(evs) {
		if d := ev.GetToolCallDone(); d != nil && d.ToolCallId == "sh1" {
			out = d.Result
		}
	}
	if !strings.Contains(out, "built-it") {
		t.Fatalf("command result %q", out)
	}
	tc, _ := find(evs, (*flitv1.Event).GetToolCallDone, func(d *flitv1.ToolCallDone) bool { return d != nil && d.ToolCallId == "ag1" })
	if tc.Result != "ran echo" {
		t.Fatalf("report %v", tc)
	}
}

func TestSubagentYoloSkipsPrompt(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(
		agentCall("ag1", `{"kind":"build","task":"say hi"}`),
		shellCall("echo yolo-ran"),
		llmtest.Response{Chunks: llmtest.Text("ok")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	if _, err := h.m.SetYolo(context.Background(), sess.ID, true, "test"); err != nil {
		t.Fatal(err)
	}
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	if _, ok := find(evs, (*flitv1.Event).GetPromptRequested, notNil); ok {
		t.Fatal("prompted in yolo mode")
	}
}

func TestSubagentStepLimit(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Subagents.MaxSteps = 2
	if err := os.WriteFile(filepath.Join(h.dir, "a.txt"), []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	read := func(id string) llmtest.Response {
		return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{id, "read", `{"path":"a.txt"}`})}
	}
	h.llm.Push(
		agentCall("ag1", `{"kind":"explore","task":"read forever"}`),
		read("r1"), read("r2"),
		llmtest.Response{Chunks: llmtest.Text("partial findings")},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	reqs := h.llm.Requests()
	if len(reqs) != 5 {
		t.Fatalf("%d model calls", len(reqs))
	}
	final := reqs[3]
	if len(final.Tools) != 0 {
		t.Fatalf("the report call offered tools: %v", sortedToolNames(final))
	}
	if last := final.Messages[len(final.Messages)-1]; last.Role != "user" || last.Content != stepLimitNote {
		t.Fatalf("report call ends with %+v", last)
	}
	done, _ := find(evs, (*flitv1.Event).GetSubagentDone, notNil)
	if done.Outcome != flitv1.SubagentOutcome_SUBAGENT_OUTCOME_STEP_LIMIT || done.Steps != 3 || !strings.Contains(done.Report, "partial findings") {
		t.Fatalf("done %v", done)
	}
}

func TestSubagentInterrupt(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(
		agentCall("ag1", `{"kind":"explore","task":"think"}`),
		llmtest.Response{Chunks: []string{llmtest.Text("hmm ")[0]}, Hang: true},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("subagent text", func(ev *flitv1.Event) bool {
		return ev.GetSubagentEvent().GetEvent().GetTextDelta().GetText() == "hmm "
	})
	if _, err := h.m.Interrupt(context.Background(), sess.ID); err != nil {
		t.Fatal(err)
	}
	if end := w.waitTurnEnd().GetTaskStateChanged(); end.Reason != "interrupted" {
		t.Fatalf("end %v", end)
	}
	evs := w.snapshot()
	done, _ := find(evs, (*flitv1.Event).GetSubagentDone, notNil)
	if done == nil || done.Outcome != flitv1.SubagentOutcome_SUBAGENT_OUTCOME_CANCELLED {
		t.Fatalf("done %v\n%s", done, dump(evs))
	}
	tc, _ := find(evs, (*flitv1.Event).GetToolCallDone, func(d *flitv1.ToolCallDone) bool { return d != nil && d.ToolCallId == "ag1" })
	if tc == nil || !tc.IsError {
		t.Fatalf("agent tool result %v", tc)
	}
	if len(h.llm.Requests()) != 2 {
		t.Fatal("model called again after interrupt")
	}
}

func TestSubagentDisabled(t *testing.T) {
	h := newHarness(t)
	off := false
	h.cfg.Agent.Subagents.Enabled = &off
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("hi")})
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	if slices.Contains(sortedToolNames(h.llm.Requests()[0]), "agent") {
		t.Fatal("agent offered while disabled")
	}
}

func TestSubagentBadArguments(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(
		agentCall("ag1", `{"kind":"deploy","task":"x"}`),
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	tc, _ := find(evs, (*flitv1.Event).GetToolCallDone, notNil)
	if !tc.IsError || !strings.Contains(tc.Result, "explore or build") {
		t.Fatalf("result %v", tc)
	}
	if _, ok := find(evs, (*flitv1.Event).GetSubagentStarted, notNil); ok {
		t.Fatal("started a subagent of an unknown kind")
	}
}
