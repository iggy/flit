package agent

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"slices"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/export"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

// userIDs returns the session's user message ids by text, from the log.
func userIDs(t *testing.T, h *harness, id string) map[string]string {
	t.Helper()
	evs, err := h.st.EventsOfKinds(context.Background(), id, "message_started", "message_done")
	if err != nil {
		t.Fatal(err)
	}
	users := map[string]bool{}
	out := map[string]string{}
	for _, ev := range evs {
		if ms := ev.GetMessageStarted(); ms != nil && ms.Role == flitv1.Role_ROLE_USER {
			users[ms.MessageId] = true
		}
		if d := ev.GetMessageDone(); d != nil && users[d.MessageId] {
			out[d.Text] = d.MessageId
		}
	}
	return out
}

// assistantIDs returns the session's assistant message ids by text.
func assistantIDs(t *testing.T, h *harness, id string) map[string]string {
	t.Helper()
	evs, err := h.st.EventsOfKinds(context.Background(), id, "message_done")
	if err != nil {
		t.Fatal(err)
	}
	out := map[string]string{}
	for _, ev := range evs {
		out[ev.GetMessageDone().Text] = ev.GetMessageDone().MessageId
	}
	return out
}

// forked runs fork (a RetryFromMessage or EditMessage) with resp queued
// and waits for the turn it starts to end. It returns the events from the
// new branch's BranchCreated on.
func forked(t *testing.T, h *harness, id string, resp llmtest.Response, fork func() (ForkResult, error)) (ForkResult, []*flitv1.Event) {
	t.Helper()
	h.llm.Push(resp)
	w := h.watch(id, 0)
	defer w.stop()
	res, err := fork()
	if err != nil {
		t.Fatal(err)
	}
	end := w.waitFor("turn end", func(ev *flitv1.Event) bool {
		st := ev.GetTaskStateChanged().GetState()
		return ev.Seq > res.Seq && (st == flitv1.TaskState_TASK_STATE_DONE || st == flitv1.TaskState_TASK_STATE_STUCK)
	})
	var out []*flitv1.Event
	for _, ev := range w.snapshot() {
		if ev.Seq >= res.Seq && ev.Seq <= end.Seq {
			out = append(out, ev)
		}
	}
	return res, out
}

// lastConversation is the user and assistant texts of the last request.
func lastConversation(h *harness) []string {
	reqs := h.llm.Requests()
	var out []string
	for _, m := range reqs[len(reqs)-1].Messages {
		if m.Role == "user" || m.Role == "assistant" {
			out = append(out, m.Role[:1]+":"+m.Content)
		}
	}
	return out
}

func wantConversation(t *testing.T, h *harness, want ...string) {
	t.Helper()
	if got := lastConversation(h); !slices.Equal(got, want) {
		t.Fatalf("model saw %q, want %q", got, want)
	}
}

// Retry keeps the user message and answers it again on a new branch; the
// model sees only that branch's history, and switching back continues the
// original.
func TestRetryFromMessage(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	turn(t, h, sess.ID, "u2", text("a2"))
	u2 := userIDs(t, h, sess.ID)["u2"]

	res, evs := forked(t, h, sess.ID, text("a2 again"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, u2, "phone")
	})
	wantConversation(t, h, "u:u1", "a:a1", "u:u2")
	k := strings.Join(kinds(evs), ",")
	if !strings.HasPrefix(k, "branch_created,branch_switched,task_state_changed,message_started") {
		t.Fatalf("events %s", k)
	}
	c := evs[0].GetBranchCreated()
	if c.BranchId != res.BranchID || c.ParentBranchId != "" || c.Kind != flitv1.BranchKind_BRANCH_KIND_RETRY ||
		c.MessageId != u2 || c.Client != "phone" {
		t.Fatalf("created %v", c)
	}
	// Everything after the switch is recorded on the new branch.
	for _, ev := range evs[1:] {
		if ev.BranchId != res.BranchID {
			t.Fatalf("event on branch %q: %v", ev.BranchId, ev)
		}
	}
	if got, _ := h.m.Get(ctx, sess.ID); got.BranchID != res.BranchID {
		t.Fatalf("active branch %q", got.BranchID)
	}

	turn(t, h, sess.ID, "u3", text("a3"))
	wantConversation(t, h, "u:u1", "a:a1", "u:u2", "a:a2 again", "u:u3")

	// Back to the root: its own reply, not the retry's.
	if _, err := h.m.SwitchBranch(ctx, sess.ID, "", "desk"); err != nil {
		t.Fatal(err)
	}
	turn(t, h, sess.ID, "u3 on root", text("ok"))
	wantConversation(t, h, "u:u1", "a:a1", "u:u2", "a:a2", "u:u3 on root")

	// The active branch and the tree survive a restart.
	if _, err := h.m.SwitchBranch(ctx, sess.ID, res.BranchID, ""); err != nil {
		t.Fatal(err)
	}
	h.m.Close()
	m2, err := NewManager(ctx, h.st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	h.m = m2
	turn(t, h, sess.ID, "u4", text("a4"))
	wantConversation(t, h, "u:u1", "a:a1", "u:u2", "a:a2 again", "u:u3", "a:a3", "u:u4")
}

// Edit forks just before the message and sends the new text; editing a
// message on an ancestor branch forks from that branch.
func TestEditMessage(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	turn(t, h, sess.ID, "u2", text("a2"))
	ids := userIDs(t, h, sess.ID)

	res, evs := forked(t, h, sess.ID, text("a2b"), func() (ForkResult, error) {
		return h.m.EditMessage(ctx, sess.ID, ids["u2"], "u2 edited", "")
	})
	wantConversation(t, h, "u:u1", "a:a1", "u:u2 edited")
	c := evs[0].GetBranchCreated()
	if c.Kind != flitv1.BranchKind_BRANCH_KIND_EDIT || c.ParentBranchId != "" || c.MessageId != ids["u2"] {
		t.Fatalf("created %v", c)
	}
	// The edited message is a new message on the new branch.
	if um, _ := find(evs, (*flitv1.Event).GetMessageDone, func(d *flitv1.MessageDone) bool { return d.GetText() == "u2 edited" }); um == nil {
		t.Fatalf("no edited message: %s", dump(evs))
	}

	// The original u2 isn't on this branch any more.
	if _, err := h.m.RetryFromMessage(ctx, sess.ID, ids["u2"], ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("retry of a message off the branch: %v", err)
	}
	// u1 is, on the root: editing it forks from the root.
	res2, evs := forked(t, h, sess.ID, text("a1b"), func() (ForkResult, error) {
		return h.m.EditMessage(ctx, sess.ID, ids["u1"], "u1 edited", "")
	})
	wantConversation(t, h, "u:u1 edited")
	if c := evs[0].GetBranchCreated(); c.ParentBranchId != "" || res2.BranchID == res.BranchID {
		t.Fatalf("created %v", c)
	}
	if _, err := h.m.EditMessage(ctx, sess.ID, ids["u1"], "  ", ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("empty edit: %v", err)
	}
}

// A branch of a branch: its parent is the branch the message is on.
func TestForkOfAFork(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	b1, _ := forked(t, h, sess.ID, text("a1b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u1"], "")
	})
	turn(t, h, sess.ID, "u2", text("a2"))
	_, evs := forked(t, h, sess.ID, text("a2b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u2"], "")
	})
	if c := evs[0].GetBranchCreated(); c.ParentBranchId != b1.BranchID {
		t.Fatalf("parent %q, want %q", c.ParentBranchId, b1.BranchID)
	}
	wantConversation(t, h, "u:u1", "a:a1b", "u:u2")
}

// Forks and switches need an idle session and an empty queue; only user
// messages fork.
func TestForkPreconditions(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	u1 := userIDs(t, h, sess.ID)["u1"]
	if _, err := h.m.RetryFromMessage(ctx, sess.ID, assistantIDs(t, h, sess.ID)["a1"], ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("retry of an assistant message: %v", err)
	}
	if _, err := h.m.RetryFromMessage(ctx, sess.ID, "msg_nope", ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("retry of an unknown message: %v", err)
	}
	if _, err := h.m.SwitchBranch(ctx, sess.ID, "br_nope", ""); !errors.Is(err, ErrInvalid) {
		t.Fatalf("switch to an unknown branch: %v", err)
	}

	started := make(chan struct{})
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("x")[:1], Hang: true, Started: started})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "u2"); err != nil {
		t.Fatal(err)
	}
	<-started
	if _, err := h.m.RetryFromMessage(ctx, sess.ID, u1, ""); !errors.Is(err, ErrBusy) {
		t.Fatalf("retry while running: %v", err)
	}
	if _, err := h.m.SwitchBranch(ctx, sess.ID, "", ""); !errors.Is(err, ErrBusy) {
		t.Fatalf("switch while running: %v", err)
	}
	if _, err := h.m.SendMessage(ctx, sess.ID, "queued", ""); err != nil {
		t.Fatal(err)
	}
	if _, err := h.m.Interrupt(ctx, sess.ID); err != nil {
		t.Fatal(err)
	}
	w.waitFor("interrupted", func(ev *flitv1.Event) bool { return ev.GetTaskStateChanged().GetReason() == "interrupted" })
	if _, err := h.m.EditMessage(ctx, sess.ID, u1, "new", ""); !errors.Is(err, ErrQueued) {
		t.Fatalf("edit with a queue: %v", err)
	}
}

// Ratings stay with the reply they rate, on its branch; export writes each
// branch's turns once, marks each branch's last turn as its whole
// conversation, and doesn't mix the branches' ratings.
func TestBranchRatingsAndExport(t *testing.T) {
	h := newHarness(t)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	turn(t, h, sess.ID, "u2", text("a2"))
	ids := userIDs(t, h, sess.ID)
	br, _ := forked(t, h, sess.ID, text("a2 again"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, ids["u2"], "")
	})
	replies := assistantIDs(t, h, sess.ID)
	for _, r := range []Rating{
		{Target: flitv1.RatingTarget_RATING_TARGET_TURN, Good: true, MessageID: replies["a2"]},
		{Target: flitv1.RatingTarget_RATING_TARGET_TURN, Good: false, MessageID: replies["a2 again"]},
		{Target: flitv1.RatingTarget_RATING_TARGET_TURN, Good: true, MessageID: replies["a1"]},
	} {
		if err := h.m.Rate(ctx, sess.ID, r); err != nil {
			t.Fatal(err)
		}
	}
	ratings, err := h.st.RatingsFor(ctx, []string{sess.ID})
	if err != nil {
		t.Fatal(err)
	}
	// By rated reply: ratings made in the same clock tick (Windows) may
	// come back in any order.
	byCall := map[string][2]string{}
	for _, r := range ratings {
		byCall[r.ModelCallID] = [2]string{r.TurnID, r.BranchID}
	}
	if byCall[replies["a2"]] != [2]string{ids["u2"], ""} || byCall[replies["a2 again"]] != [2]string{ids["u2"], br.BranchID} ||
		byCall[replies["a1"]] != [2]string{ids["u1"], ""} {
		t.Fatalf("ratings %+v", ratings)
	}

	var out bytes.Buffer
	if _, err := export.Write(ctx, h.st, &out, export.Options{}); err != nil {
		t.Fatal(err)
	}
	type rec struct {
		Type, TurnID, BranchID string
		BranchHead             bool `json:"branch_head"`
		Ratings                []struct{ Rating string }
		TurnRatings            []struct{ Rating string } `json:"turn_ratings"`
		Messages               []struct{ Role, Content string }
		Branches               []struct {
			ID, Kind     string
			HeadTurnID   string `json:"head_turn_id"`
			HeadBranchID string `json:"head_branch_id"`
		}
	}
	var turns, calls []rec
	var session rec
	sc := bufio.NewScanner(&out)
	sc.Buffer(nil, 1<<20)
	for sc.Scan() {
		var r rec
		if err := json.Unmarshal(sc.Bytes(), &r); err != nil {
			t.Fatal(err)
		}
		// encoding/json matches turn_id and branch_id case-insensitively
		// only without underscores; read them by hand.
		var ids struct {
			TurnID   string `json:"turn_id"`
			BranchID string `json:"branch_id"`
		}
		_ = json.Unmarshal(sc.Bytes(), &ids)
		r.TurnID, r.BranchID = ids.TurnID, ids.BranchID
		switch r.Type {
		case "turn":
			turns = append(turns, r)
		case "model_call":
			calls = append(calls, r)
		case "session":
			session = r
		}
	}
	if len(turns) != 3 {
		t.Fatalf("turns %+v", turns)
	}
	conv := func(r rec) string {
		var s []string
		for _, m := range r.Messages {
			if m.Role != "system" {
				s = append(s, m.Content)
			}
		}
		return strings.Join(s, "|")
	}
	// u1 (shared, once), u2 on the root, u2 on the retry branch.
	want := []struct {
		turn, branch, conv, rating string
		head                       bool
	}{
		{ids["u1"], "", "u1|a1", "good", false},
		{ids["u2"], "", "u1|a1|u2|a2", "good", true},
		{ids["u2"], br.BranchID, "u1|a1|u2|a2 again", "bad", true},
	}
	for i, w := range want {
		var tr rec
		for _, x := range turns {
			if x.TurnID == w.turn && x.BranchID == w.branch {
				tr = x
			}
		}
		if tr.TurnID != w.turn || tr.BranchID != w.branch || conv(tr) != w.conv || tr.BranchHead != w.head ||
			len(tr.Ratings) != 1 || tr.Ratings[0].Rating != w.rating {
			t.Errorf("turn %d = %+v (%s), want %+v", i, tr, conv(tr), w)
		}
	}
	for _, c := range calls {
		if c.TurnID == ids["u2"] && len(c.TurnRatings) != 1 {
			t.Errorf("call on %q has turn ratings %+v", c.BranchID, c.TurnRatings)
		}
	}
	if len(session.Branches) != 2 || session.Branches[1].ID != br.BranchID || session.Branches[1].Kind != "retry" ||
		session.Branches[1].HeadTurnID != ids["u2"] || session.Branches[1].HeadBranchID != br.BranchID ||
		session.Branches[0].HeadBranchID != "" || session.Branches[0].HeadTurnID != ids["u2"] {
		t.Fatalf("session branches %+v", session.Branches)
	}
}

// Each branch keeps its own llama.cpp prompt cache; a new branch starts
// from its parent's.
func TestPromptCachePerBranch(t *testing.T) {
	h := llamaHarness(t, 1)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	br, evs := forked(t, h, sess.ID, text("a1b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u1"], "")
	})
	if r, _ := find(evs, (*flitv1.Event).GetPromptCache, notNil); r == nil || r.File != "flit-kv-0.bin" {
		t.Fatalf("new branch didn't start from its parent's cache: %s", dump(evs))
	}
	if _, err := h.m.SwitchBranch(ctx, sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	turn(t, h, sess.ID, "u2", text("a2"))
	if _, err := h.m.SwitchBranch(ctx, sess.ID, br.BranchID, ""); err != nil {
		t.Fatal(err)
	}
	turn(t, h, sess.ID, "u2b", text("a2b"))
	want := []string{
		"POST /slots/0 save flit-kv-0.bin",    // root
		"POST /slots/0 restore flit-kv-0.bin", // the branch starts from the root's
		"POST /slots/0 save flit-kv-1.bin",    // and saves its own
		"POST /slots/0 restore flit-kv-0.bin", // root again: its own
		"POST /slots/0 save flit-kv-0.bin",
		"POST /slots/0 restore flit-kv-1.bin", // the branch: its own
		"POST /slots/0 save flit-kv-1.bin",
	}
	// Saves are logged after the turn's end; give the last one a moment.
	deadline := time.Now().Add(5 * time.Second)
	for len(h.llm.Llama.Calls()) < len(want) && time.Now().Before(deadline) {
		time.Sleep(10 * time.Millisecond)
	}
	if got := h.llm.Llama.Calls(); !slices.Equal(got, want) {
		t.Fatalf("calls:\n%s\nwant:\n%s", strings.Join(got, "\n"), strings.Join(want, "\n"))
	}
}

// A compaction belongs to its branch: the other branches keep their full
// history, and a branch forked after it inherits it.
func TestCompactionPerBranch(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Compaction.KeepTurns = 1
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text(strings.Repeat("a1 ", 100)))
	turn(t, h, sess.ID, "u2", text("a2"))
	b1, _ := forked(t, h, sess.ID, text("a2b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u2"], "")
	})

	h.llm.Push(text("Goal: B1 summary."))
	w := h.watch(sess.ID, lastSeq(h, sess.ID)+1)
	if _, err := h.m.Compact(ctx, sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	if done := compactionDone(w.snapshot()); done == nil || done.Error != "" {
		t.Fatalf("compaction: %s", dump(w.snapshot()))
	}
	w.stop()
	system := func() string { reqs := h.llm.Requests(); return reqs[len(reqs)-1].Messages[0].Content }

	turn(t, h, sess.ID, "u3", text("a3"))
	if !strings.Contains(system(), "B1 summary") {
		t.Fatalf("no summary on the compacted branch: %s", system())
	}
	wantConversation(t, h, "u:u2", "a:a2b", "u:u3")

	// The root never compacted.
	if _, err := h.m.SwitchBranch(ctx, sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	turn(t, h, sess.ID, "u3 root", text("ok"))
	if strings.Contains(system(), "B1 summary") {
		t.Fatalf("the root got the branch's summary: %s", system())
	}
	wantConversation(t, h, "u:u1", "a:"+strings.Repeat("a1 ", 100), "u:u2", "a:a2", "u:u3 root")

	// Forked from b1 after its compaction: inherits it.
	if _, err := h.m.SwitchBranch(ctx, sess.ID, b1.BranchID, ""); err != nil {
		t.Fatal(err)
	}
	forked(t, h, sess.ID, text("a3b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u3"], "")
	})
	if !strings.Contains(system(), "B1 summary") {
		t.Fatalf("a fork after the compaction lost it: %s", system())
	}
	wantConversation(t, h, "u:u2", "a:a2b", "u:u3")
}

// Compacting a branch drops only that branch's saved prompt cache.
func TestCompactionDiscardsOnlyItsBranchCache(t *testing.T) {
	h := llamaHarness(t, 1)
	ctx := context.Background()
	sess := h.create()
	turn(t, h, sess.ID, "u1", text("a1"))
	turn(t, h, sess.ID, "u2", text("a2"))
	forked(t, h, sess.ID, text("a2b"), func() (ForkResult, error) {
		return h.m.RetryFromMessage(ctx, sess.ID, userIDs(t, h, sess.ID)["u2"], "")
	})
	h.llm.Push(text("Goal: count."))
	w := h.watch(sess.ID, lastSeq(h, sess.ID)+1)
	if _, err := h.m.Compact(ctx, sess.ID, "", ""); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	var dropped []string
	for _, ev := range w.snapshot() {
		if pc := ev.GetPromptCache(); pc != nil && pc.Action == flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_DISCARDED {
			dropped = append(dropped, pc.File)
		}
	}
	// flit-kv-0.bin is the root's, flit-kv-1.bin the branch's.
	if !slices.Equal(dropped, []string{"flit-kv-1.bin"}) {
		t.Fatalf("dropped %v:\n%s", dropped, dump(w.snapshot()))
	}
}
