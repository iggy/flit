package agent

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"runtime"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func jobHarness(t *testing.T) *harness {
	t.Helper()
	if runtime.GOOS == "windows" {
		t.Skip("uses sh")
	}
	h := newHarness(t)
	h.cfg.Shell.Default = "allow"
	return h
}

func bgCall(id, cmd string) llmtest.Response {
	return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{id, "shell", `{"command":"` + cmd + `","background":true}`})}
}

func lastUser(h *harness, i int) string {
	u := requestUsers(h, i)
	return u[len(u)-1]
}

// A job that ends while the session is idle starts a turn with a notice.
func TestJobNoticeStartsTurn(t *testing.T) {
	h := jobHarness(t)
	ctx := context.Background()
	h.llm.Push(
		bgCall("sh1", "sleep 0.3; echo built"),
		llmtest.Response{Chunks: llmtest.Text("started it")},
		llmtest.Response{Chunks: llmtest.Text("saw it")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "build in the background"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("started it", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "started it" })
	w.waitFor("saw it", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "saw it" })
	w.waitTurnEnd()

	evs := w.snapshot()
	st, _ := find(evs, (*flitv1.Event).GetJobStarted, notNil)
	if st.GetToolCallId() != "sh1" || st.Detached || st.TimeoutMs != h.cfg.Shell.MaxTimeout.Milliseconds() {
		t.Fatalf("JobStarted %v", st)
	}
	done, _ := find(evs, (*flitv1.Event).GetJobDone, notNil)
	if done.GetOutcome() != flitv1.JobOutcome_JOB_OUTCOME_EXITED || strings.TrimSpace(done.GetOutputTail()) != "built" {
		t.Fatalf("JobDone %v", done)
	}
	out, _ := find(evs, (*flitv1.Event).GetJobOutput, notNil)
	if strings.TrimSpace(out.GetText()) != "built" {
		t.Fatalf("JobOutput %v", out)
	}
	nd, _ := find(evs, (*flitv1.Event).GetJobNoticeDelivered, notNil)
	if nd.GetMessageId() == "" || len(nd.JobIds) != 1 || nd.JobIds[0] != st.JobId {
		t.Fatalf("JobNoticeDelivered %v", nd)
	}
	notice := lastUser(h, 2)
	if !strings.Contains(notice, "[flit notice]") || !strings.Contains(notice, "exited with code 0") || !strings.Contains(notice, "built") {
		t.Fatalf("notice %q", notice)
	}
}

// Seeing the end through the job tool means no notice and no new turn.
func TestJobWaitSkipsNotice(t *testing.T) {
	h := jobHarness(t)
	ctx := context.Background()
	h.llm.Push(
		bgCall("sh1", "sleep 0.2; echo built"),
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"j1", "job", `{"action":"wait","job_id":"job_1"}`})},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "build"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	time.Sleep(300 * time.Millisecond)
	evs := w.snapshot()
	nd, ok := find(evs, (*flitv1.Event).GetJobNoticeDelivered, notNil)
	if !ok || nd.MessageId != "" || len(nd.JobIds) != 1 || nd.JobIds[0] != "job_1" {
		t.Fatalf("JobNoticeDelivered %v:\n%s", nd, dump(evs))
	}
	if n := len(h.llm.Requests()); n != 3 {
		t.Fatalf("%d model calls; a notice started a turn?", n)
	}
	tr, _ := find(evs, (*flitv1.Event).GetToolCallDone, func(d *flitv1.ToolCallDone) bool { return d != nil && d.ToolCallId == "j1" })
	if !strings.Contains(tr.GetResult(), "built") || !strings.Contains(tr.GetResult(), "exited with code 0") {
		t.Fatalf("wait result %v", tr)
	}
}

// A job that ends during a turn is delivered at its next step, without a
// turn of its own.
func TestJobNoticeAtStepBoundary(t *testing.T) {
	h := jobHarness(t)
	ctx := context.Background()
	h.llm.Push(
		bgCall("sh1", "echo fast"),
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"sh2", "shell", `{"command":"sleep 0.3"}`})},
		llmtest.Response{Chunks: llmtest.Text("ok")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	time.Sleep(300 * time.Millisecond)
	if n := len(h.llm.Requests()); n != 3 {
		t.Fatalf("%d model calls", n)
	}
	if got := lastUser(h, 2); !strings.Contains(got, "[flit notice]") || !strings.Contains(got, "fast") {
		t.Fatalf("users %v", requestUsers(h, 2))
	}
}

// CancelJob kills a job and the agent hears about it; jobs flit loses
// (stopped or crashed) are reported at the next message.
func TestCancelJobAndRestart(t *testing.T) {
	h := jobHarness(t)
	ctx := context.Background()
	h.llm.Push(
		bgCall("sh1", "sleep 30"),
		llmtest.Response{Chunks: llmtest.Text("running")},
		llmtest.Response{Chunks: llmtest.Text("noted")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(ctx, sess.ID, "serve"); err != nil {
		t.Fatal(err)
	}
	st := w.waitFor("job start", func(ev *flitv1.Event) bool { return ev.GetJobStarted() != nil }).GetJobStarted()
	w.waitTurnEnd()
	if err := h.m.CancelJob(ctx, sess.ID, st.JobId, "phone"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("noted", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "noted" })
	if got := lastUser(h, 2); !strings.Contains(got, "cancelled by the user") {
		t.Fatalf("notice %q", got)
	}
	done, _ := find(w.snapshot(), (*flitv1.Event).GetJobDone, notNil)
	if done.GetOutcome() != flitv1.JobOutcome_JOB_OUTCOME_CANCELLED || done.GetCancelledBy() != "phone" {
		t.Fatalf("JobDone %v", done)
	}
	if err := h.m.CancelJob(ctx, sess.ID, st.JobId, "phone"); !errors.Is(err, ErrJobEnded) {
		t.Fatalf("cancel again: %v", err)
	}
	if err := h.m.CancelJob(ctx, sess.ID, "job_nope", ""); !errors.Is(err, ErrNotFound) {
		t.Fatalf("cancel unknown: %v", err)
	}
	w.waitTurnEnd()

	// A job still running when flit stops is killed and reported next time.
	h.llm.Push(bgCall("sh2", "sleep 30"), llmtest.Response{Chunks: llmtest.Text("again")})
	if _, err := h.m.Send(ctx, sess.ID, "serve again"); err != nil {
		t.Fatal(err)
	}
	w.waitFor("again", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "again" })
	w.waitTurnEnd()
	w.stop()
	h.m.Close()

	// And one flit never saw end (a crash) is recorded as lost on load.
	info, err := h.st.GetSession(ctx, sess.ID)
	if err != nil {
		t.Fatal(err)
	}
	crash := &flitv1.Event{SessionId: sess.ID, BranchId: info.BranchID, Seq: info.LastSeq + 1, Payload: &flitv1.Event_JobStarted{JobStarted: &flitv1.JobStarted{
		JobId: "job_crashed", ToolCallId: "sh3", Command: "make watch", Workdir: ".",
	}}}
	if err := h.st.AppendEvent(ctx, info, crash); err != nil {
		t.Fatal(err)
	}

	m2, err := NewManager(ctx, h.st, h.config, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatal(err)
	}
	h.m = m2
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	w2 := h.watch(sess.ID, 0)
	if _, err := m2.Send(ctx, sess.ID, "status?"); err != nil {
		t.Fatal(err)
	}
	w2.waitFor("ok", func(ev *flitv1.Event) bool { return ev.GetMessageDone().GetText() == "ok" })
	users := requestUsers(h, len(h.llm.Requests())-1)
	notice := users[len(users)-2]
	if !strings.Contains(notice, "because flit stopped") || !strings.Contains(notice, "make watch") || users[len(users)-1] != "status?" {
		t.Fatalf("users %q", users)
	}
}
