package agent

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/export"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/models"
)

// userEv and asstEv are a message's start and done events.
func userEv(seq int64, id, text string) []*flitv1.Event {
	return []*flitv1.Event{
		{Seq: seq, Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: id, Role: flitv1.Role_ROLE_USER}}},
		{Seq: seq + 1, Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: id, Text: text}}},
	}
}

func asstEv(seq int64, id, text string) []*flitv1.Event {
	return []*flitv1.Event{
		{Seq: seq, Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: id, Role: flitv1.Role_ROLE_ASSISTANT}}},
		{Seq: seq + 1, Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: id, Text: text}}},
	}
}

func cat(parts ...[]*flitv1.Event) []*flitv1.Event { return slices.Concat(parts...) }

func TestChooseCut(t *testing.T) {
	// Three turns: u1 a1 | u2 a2 | u3 a3 a3b (the last with two steps).
	evs := cat(userEv(1, "u1", "one"), asstEv(3, "a1", "1"), userEv(5, "u2", "two"), asstEv(7, "a2", "2"),
		userEv(9, "u3", "three"), asstEv(11, "a3", "3"), asstEv(13, "a3b", "3b"))
	for _, tc := range []struct {
		name          string
		after         int64
		keep, minKeep int
		mid           bool
		want          cut
		ok            bool
	}{
		{"keep two turns", 0, 2, 1, true, cut{covered: 4, kept: 2}, true},
		{"keep one turn", 0, 1, 1, true, cut{covered: 8, kept: 1}, true},
		{"not enough turns: cut the running one", 0, 3, 1, true, cut{covered: 12, kept: 1}, true},
		{"not enough turns, between turns: keep fewer", 0, 3, 0, false, cut{covered: 4, kept: 2}, true},
		{"after an earlier summary", 4, 2, 1, true, cut{covered: 12, kept: 1}, true},
		{"everything", 8, 1, 0, false, cut{covered: 14}, true},
		{"nothing new", 14, 2, 0, false, cut{}, false},
	} {
		got, ok := chooseCut(evs, tc.after, tc.keep, tc.minKeep, tc.mid)
		if got != tc.want || ok != tc.ok {
			t.Errorf("%s: got %+v %v, want %+v %v", tc.name, got, ok, tc.want, tc.ok)
		}
	}
	// One turn with a single step: nothing to summarize that isn't kept.
	if c, ok := chooseCut(cat(userEv(1, "u1", "x"), asstEv(3, "a1", "y")), 0, 2, 1, true); ok {
		t.Fatalf("single step cut %+v", c)
	}
}

func TestContextEventsAfterCompaction(t *testing.T) {
	evs := cat(userEv(1, "u1", "one"), asstEv(3, "a1", "1"), userEv(5, "u2", "two"), asstEv(7, "a2", "2"), asstEv(9, "a2b", "2b"))
	texts := func(c *flitv1.CompactionDone) []string {
		var out []string
		for _, m := range buildMessages(contextEvents(evs, c)) {
			out = append(out, m.Role+":"+m.Content)
		}
		return out
	}
	if got := texts(nil); len(got) != 5 {
		t.Fatalf("no compaction: %v", got)
	}
	if got := texts(&flitv1.CompactionDone{CoveredSeq: 4}); !slices.Equal(got, []string{"user:two", "assistant:2", "assistant:2b"}) {
		t.Fatalf("turn cut: %v", got)
	}
	// A cut inside the second turn keeps the request it is working on.
	if got := texts(&flitv1.CompactionDone{CoveredSeq: 8}); !slices.Equal(got, []string{"user:two", "assistant:2b"}) {
		t.Fatalf("mid-turn cut: %v", got)
	}
	if got := texts(&flitv1.CompactionDone{CoveredSeq: 10}); len(got) != 0 {
		t.Fatalf("all covered: %v", got)
	}
}

// sendTurn sends text with the model's responses queued and waits for the
// turn to end.
func sendTurn(t *testing.T, h *harness, id, text string, resps ...llmtest.Response) []*flitv1.Event {
	t.Helper()
	h.llm.Push(resps...)
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
	if end.GetTaskStateChanged().State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("turn ended %v:\n%s", end, dump(w.snapshot()))
	}
	var out []*flitv1.Event
	for _, ev := range w.snapshot() {
		if ev.Seq >= from && ev.Seq <= end.Seq {
			out = append(out, ev)
		}
	}
	return out
}

// waitEndAfter waits for a turn (or compaction run) to end after seq.
func (w *watcher) waitEndAfter(seq int64) *flitv1.Event {
	w.t.Helper()
	return w.waitFor("end after", func(ev *flitv1.Event) bool {
		st := ev.GetTaskStateChanged().GetState()
		return ev.Seq > seq && (st == flitv1.TaskState_TASK_STATE_DONE || st == flitv1.TaskState_TASK_STATE_STUCK)
	})
}

func lastSeq(h *harness, id string) int64 {
	info, _ := h.m.Get(context.Background(), id)
	return info.LastSeq
}

func text(s string) llmtest.Response { return llmtest.Response{Chunks: llmtest.Text(s)} }

func compactionDone(evs []*flitv1.Event) *flitv1.CompactionDone {
	d, _ := find(evs, (*flitv1.Event).GetCompactionDone, notNil)
	return d
}

// /compact between turns: the summary call sees the conversation up to the
// cut, and the next turn's request is the summary (in the system prompt)
// plus the kept turns. Nothing leaves the log.
func TestCompactRebuildsContext(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Compaction.KeepTurns = 1
	ctx := context.Background()
	sess := h.create()
	sendTurn(t, h, sess.ID, "first question", text(strings.Repeat("first answer ", 100)))
	sendTurn(t, h, sess.ID, "second question", text("second answer"))

	h.llm.Push(text("Goal: answer questions. Progress: answered the first."))
	from := lastSeq(h, sess.ID)
	w := h.watch(sess.ID, from+1)
	queued, err := h.m.Compact(ctx, sess.ID, "phone", "mention the first answer")
	if err != nil || queued {
		t.Fatalf("Compact = %v, %v", queued, err)
	}
	end := w.waitEndAfter(from)
	evs := w.snapshot()
	if end.GetTaskStateChanged().State != flitv1.TaskState_TASK_STATE_DONE {
		t.Fatalf("compaction ended %v:\n%s", end, dump(evs))
	}
	started, _ := find(evs, (*flitv1.Event).GetCompactionStarted, notNil)
	done := compactionDone(evs)
	if started == nil || started.Auto || started.Client != "phone" || started.Model != "test-model" ||
		done == nil || done.Error != "" || done.CompactionId != started.CompactionId || done.KeptTurns != 1 ||
		!strings.HasPrefix(done.Summary, "Goal:") || done.TokensBefore <= done.TokensAfter || done.ModelCallId == "" {
		t.Fatalf("started %v done %v", started, done)
	}
	k := strings.Join(kinds(evs), ",")
	if !strings.Contains(k, "task_state_changed,compaction_started,model_call_started,model_call_ended,compaction_done,task_state_changed") {
		t.Fatalf("events %s", k)
	}

	// The summary request: same system prompt and tools, the first turn,
	// then the ask (with the extra instructions); tools can't be called.
	reqs := h.llm.Requests()
	sum := reqs[2]
	var roles []string
	for _, m := range sum.Messages {
		roles = append(roles, m.Role)
	}
	ask := sum.Messages[len(sum.Messages)-1].Content
	if strings.Join(roles, ",") != "system,user,assistant,user" || sum.Messages[1].Content != "first question" ||
		!strings.Contains(ask, "summary") || !strings.Contains(ask, "Also: mention the first answer") ||
		sum.ToolChoice != "none" || len(sum.Tools) != len(reqs[1].Tools) || sum.MaxTokens != 4096 ||
		sum.Messages[0].Content != reqs[1].Messages[0].Content {
		t.Fatalf("summary request %+v", sum)
	}

	sendTurn(t, h, sess.ID, "third question", text("third answer"))
	next := h.llm.Requests()[3].Messages
	var got []string
	for _, m := range next[1:] {
		got = append(got, m.Role+":"+m.Content)
	}
	if !strings.Contains(next[0].Content, "Earlier in this session") || !strings.Contains(next[0].Content, done.Summary) ||
		!slices.Equal(got, []string{"user:second question", "assistant:second answer", "user:third question"}) {
		t.Fatalf("after compaction: system %q, messages %v", next[0].Content, got)
	}
	all, err := h.st.Events(ctx, sess.ID, 0, 1<<62)
	if err != nil || !strings.Contains(dump(all), "first question") {
		t.Fatalf("old events gone: %v", err)
	}
	info, _ := h.m.Get(ctx, sess.ID)
	if info.ContextTokens == 0 {
		t.Fatalf("context tokens not updated")
	}

	// The summary call is exported as its own record, task "compaction";
	// later chat calls carry the summary exactly as sent.
	msgs, _, err := h.st.ModelCallRequest(ctx, done.ModelCallId)
	if err != nil || len(msgs) != 4 || !strings.Contains(string(msgs[3]), "summary") {
		t.Fatalf("recorded summary call = %d messages, %v", len(msgs), err)
	}
	var out bytes.Buffer
	if _, err := export.Write(ctx, h.st, &out, export.Options{}); err != nil {
		t.Fatal(err)
	}
	var tasks []string
	var lastChat, turnMsgs []json.RawMessage
	for _, line := range strings.Split(strings.TrimSpace(out.String()), "\n") {
		var rec struct {
			Type, Task string
			Messages   []json.RawMessage
		}
		if err := json.Unmarshal([]byte(line), &rec); err != nil {
			t.Fatal(err)
		}
		switch rec.Type {
		case "model_call":
			tasks = append(tasks, rec.Task)
			if rec.Task == "chat" {
				lastChat = rec.Messages
			}
		case "turn":
			turnMsgs = rec.Messages
		}
	}
	if !slices.Equal(tasks, []string{"chat", "chat", "compaction", "chat"}) {
		t.Fatalf("exported tasks %v", tasks)
	}
	if !strings.Contains(string(lastChat[0]), "Earlier in this session") || len(lastChat) != 4 {
		t.Fatalf("last chat call as exported: %s", lastChat)
	}
	if len(turnMsgs) != 5 || strings.Contains(string(turnMsgs[len(turnMsgs)-1]), "Goal:") {
		t.Fatalf("last turn as exported: %s", turnMsgs)
	}
}

// overrideContext gives the fake provider's test-model a context window.
func overrideContext(t *testing.T, h *harness, n int) {
	t.Helper()
	overrides := filepath.Join(h.dir, "models.yaml")
	if err := os.WriteFile(overrides, []byte(fmt.Sprintf("fake:\n  test-model:\n    context_length: %d\n", n)), 0o600); err != nil {
		t.Fatal(err)
	}
	h.m.Catalog = models.NewCatalog(h.config, func() string { return overrides }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err := h.m.Catalog.Refresh(context.Background(), "fake"); err != nil {
		t.Fatal(err)
	}
}

// Near the threshold flit compacts on its own before the model call, with
// the compaction task model when one is set.
func TestAutoCompactionAtThreshold(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Tasks = map[string]config.TaskModel{"compaction": {Provider: "other", Model: "small", Effort: "low"}}
	sess := h.create()
	sendTurn(t, h, sess.ID, "hi", text("hello"))
	base := estimateTokens(h.llm.Requests()[0])
	// The next request (base plus about 1000 tokens) crosses 80%.
	overrideContext(t, h, int(float64(base+700)/0.8))

	long := strings.Repeat("word ", 800)
	evs := sendTurn(t, h, sess.ID, long, text("Goal: chat."), text("ok"))
	done := compactionDone(evs)
	if done == nil || !done.Auto || done.Error != "" || done.Provider != "other" || done.Model != "small" || done.TokensExact {
		t.Fatalf("auto compaction %v:\n%s", done, dump(evs))
	}
	reqs := h.llm.Requests()
	if reqs[1].Model != "small" || reqs[1].ReasoningEffort != "low" || reqs[2].Model != "test-model" {
		t.Fatalf("models %s %s %s", reqs[1].Model, reqs[1].ReasoningEffort, reqs[2].Model)
	}
	// It happened before the model call: compaction, then the assistant
	// message.
	k := strings.Join(kinds(evs), ",")
	if !strings.Contains(k, "task_state_changed,compaction_started") || !strings.Contains(k, "compaction_done,message_started") {
		t.Fatalf("events %s", k)
	}

	// Below the threshold nothing happens.
	h.mu.Lock()
	h.cfg.Agent.Compaction.Threshold = 1
	h.mu.Unlock()
	if evs := sendTurn(t, h, sess.ID, "short", text("fine")); compactionDone(evs) != nil {
		t.Fatalf("compacted below the threshold")
	}
}

// A turn that alone fills the context is cut between its steps; its user
// message stays.
func TestAutoCompactionMidTurn(t *testing.T) {
	h := newHarness(t)
	if err := os.WriteFile(filepath.Join(h.dir, "big.txt"), []byte(strings.Repeat("data ", 1000)), 0o644); err != nil {
		t.Fatal(err)
	}
	sess := h.create()
	sendTurn(t, h, sess.ID, "hi", text("hello"))
	base := estimateTokens(h.llm.Requests()[0])
	overrideContext(t, h, int(float64(base+2000)/0.8))
	read := func(id string) llmtest.Response {
		return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{id, "read", `{"path":"big.txt"}`})}
	}
	// Each read adds about 1250 tokens; the third call crosses.
	evs := sendTurn(t, h, sess.ID, "read it twice", read("c1"), read("c2"), text("Goal: read big.txt twice."), text("done"))
	done := compactionDone(evs)
	if done == nil || done.Error != "" || done.KeptTurns != 1 {
		t.Fatalf("compaction %v:\n%s", done, dump(evs))
	}
	reqs := h.llm.Requests()
	last := reqs[len(reqs)-1].Messages
	var roles []string
	for _, m := range last {
		roles = append(roles, m.Role)
	}
	// system(summary), the turn's request, the last step's call and result.
	if strings.Join(roles, ",") != "system,user,assistant,tool" || last[1].Content != "read it twice" || last[2].ToolCalls[0].ID != "c2" {
		t.Fatalf("after mid-turn compaction: %v", roles)
	}
}

// A failed summary is logged and the turn goes on with the full history,
// without trying again on every step.
func TestCompactionFailureKeepsWorking(t *testing.T) {
	h := newHarness(t)
	sess := h.create()
	sendTurn(t, h, sess.ID, "hi", text("hello"))
	sendTurn(t, h, sess.ID, "again", text("hello again"))
	base := estimateTokens(h.llm.Requests()[1])
	overrideContext(t, h, int(float64(base)/0.8)) // already over

	fail := llmtest.Response{Status: 400, Body: `{"error":{"message":"no"}}`}
	evs := sendTurn(t, h, sess.ID, "third", fail, llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "list", `{}`})}, text("ok"))
	dones := 0
	var failed *flitv1.CompactionDone
	for _, ev := range evs {
		if d := ev.GetCompactionDone(); d != nil {
			dones++
			failed = d
		}
	}
	if dones != 1 || !strings.Contains(failed.Error, "summary model call failed") || failed.Summary != "" || failed.CoveredSeq != 0 {
		t.Fatalf("%d compactions, %v:\n%s", dones, failed, dump(evs))
	}
	reqs := h.llm.Requests()
	if n := len(reqs[len(reqs)-1].Messages); n != 8 {
		t.Fatalf("full history expected, got %d messages", n)
	}
	if strings.Contains(reqs[len(reqs)-1].Messages[0].Content, "Earlier in this session") {
		t.Fatalf("summary in the prompt after a failure")
	}
}

// Compact during a turn waits for its next step; messages sent while an
// idle compaction runs are queued and start the next turn after it.
func TestCompactDuringTurnAndQueue(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	sendTurn(t, h, sess.ID, "one", text("1"))
	sendTurn(t, h, sess.ID, "two", text("2"))

	slowCall := llmtest.Response{Chunks: append([]string{llmtest.Pause(300 * time.Millisecond)}, llmtest.ToolCalls([3]string{"c1", "list", `{}`})...)}
	h.llm.Push(slowCall, text("Goal: count."), text("3"))
	w := h.watch(sess.ID, lastSeq(h, sess.ID)+1)
	if _, err := h.m.Send(ctx, sess.ID, "three"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("call", func(ev *flitv1.Event) bool { return ev.GetModelCallStarted() != nil })
	queued, err := h.m.Compact(ctx, sess.ID, "desk", "")
	if err != nil || !queued {
		t.Fatalf("Compact during turn = %v, %v", queued, err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	done := compactionDone(evs)
	if done == nil || done.Error != "" || done.Auto {
		t.Fatalf("compaction %v:\n%s", done, dump(evs))
	}
	k := strings.Join(kinds(evs), ",")
	if !strings.Contains(k, "tool_call_done,compaction_started") {
		t.Fatalf("not at the step boundary: %s", k)
	}

	// Idle compaction with a message sent meanwhile.
	slowSummary := llmtest.Response{Chunks: append([]string{llmtest.Pause(300 * time.Millisecond)}, llmtest.Text("Goal: count more.")...)}
	h.llm.Push(slowSummary, text("4"))
	from := w.snapshot()[len(w.snapshot())-1].Seq
	if _, err := h.m.Compact(ctx, sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	res, err := h.m.SendMessage(ctx, sess.ID, "four", "phone")
	if err != nil || res.QueueID == "" {
		t.Fatalf("send during compaction = %+v, %v", res, err)
	}
	w.waitFor("next turn's answer", func(ev *flitv1.Event) bool {
		return ev.Seq > from && ev.GetMessageDone().GetText() == "4"
	})
	reqs := h.llm.Requests()
	lastMsgs := reqs[len(reqs)-1].Messages
	if lastMsgs[len(lastMsgs)-1].Content != "four" || !strings.Contains(lastMsgs[0].Content, "count more") {
		t.Fatalf("queued turn request %+v", lastMsgs)
	}
}

// After compaction the prompt starts differently, so the session's saved
// llama.cpp prompt cache is dropped, never restored onto the new prompt.
func TestCompactionDiscardsSavedPromptCache(t *testing.T) {
	h := llamaHarness(t, 2)
	sess := h.create()
	sendTurn(t, h, sess.ID, "one", text("1"))
	sendTurn(t, h, sess.ID, "two", text("2"))
	restores := func() int {
		n := 0
		for _, c := range h.llm.Llama.Calls() {
			if strings.Contains(c, "restore") {
				n++
			}
		}
		return n
	}
	if restores() != 1 {
		t.Fatalf("expected a restore before compaction: %v", h.llm.Llama.Calls())
	}

	h.llm.Push(text("Goal: count."))
	w := h.watch(sess.ID, lastSeq(h, sess.ID)+1)
	if _, err := h.m.Compact(context.Background(), sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	pc, _ := find(evs, (*flitv1.Event).GetPromptCache, func(p *flitv1.PromptCache) bool {
		return p != nil && p.Action == flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_DISCARDED
	})
	done := compactionDone(evs)
	if pc == nil || pc.File != "flit-kv-0.bin" || done == nil || !done.TokensExact || h.llm.Llama.TokenCounts() == 0 {
		t.Fatalf("discard %v, done %v:\n%s", pc, done, dump(evs))
	}

	sendTurn(t, h, sess.ID, "three", text("3"))
	if restores() != 1 {
		t.Fatalf("restored a cache from before compaction: %v", h.llm.Llama.Calls())
	}
	// The turn after saves the new prompt, which the next one restores.
	sendTurn(t, h, sess.ID, "four", text("4"))
	if restores() != 2 {
		t.Fatalf("no restore of the new cache: %v", h.llm.Llama.Calls())
	}
}

// On llama.cpp the window is the slots' n_ctx and counts are exact.
func TestContextUseLlamaCpp(t *testing.T) {
	h := llamaHarness(t, 1)
	h.llm.Llama.NCtx = 1000
	h.llm.Llama.InputTokens = func(req llm.Request) int { return 900 }
	sess := h.create()
	info, _ := h.m.Get(context.Background(), sess.ID)
	s, _ := h.m.session(context.Background(), sess.ID)
	p, _ := h.config().Provider("fake")
	req := llm.Request{Model: "test-model", Messages: []llm.Message{{Role: "user", Content: strings.Repeat("x", 2000)}}}
	u := s.contextUse(context.Background(), h.config(), info, p, req, false)
	if u.length != 1000 || u.tokens != 900 || !u.exact || !u.over(0.8) {
		t.Fatalf("use %+v", u)
	}
	// Far below the threshold, no counting call.
	req.Messages[0].Content = "x"
	before := h.llm.Llama.TokenCounts()
	if u := s.contextUse(context.Background(), h.config(), info, p, req, false); u.exact || h.llm.Llama.TokenCounts() != before {
		t.Fatalf("counted a small request: %+v", u)
	}
}

func TestCompactNothingToDo(t *testing.T) {
	h := newHarness(t)
	sess := h.create()
	if _, err := h.m.Compact(context.Background(), sess.ID, "", ""); err == nil || !strings.Contains(err.Error(), "nothing to compact") {
		t.Fatalf("empty session: %v", err)
	}
}
