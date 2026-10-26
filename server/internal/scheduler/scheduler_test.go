package scheduler

import (
	"context"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/notify"
	"github.com/iggy/flit/server/internal/store"
)

type clock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *clock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.t
}

func (c *clock) Set(t time.Time) {
	c.mu.Lock()
	c.t = t
	c.mu.Unlock()
}

type harness struct {
	t      *testing.T
	s      *Scheduler
	st     *store.Store
	m      *agent.Manager
	llm    *llmtest.Server
	clock  *clock
	dir    string
	ctx    context.Context
	cancel context.CancelFunc

	mu       sync.Mutex
	notified []notify.Message
}

// start is 2026-10-21 10:00:30 local time (a Wednesday).
var start = time.Date(2026, 10, 21, 10, 0, 30, 0, time.Local)

func newHarness(t *testing.T) *harness {
	t.Helper()
	h := &harness{t: t, llm: llmtest.New(t), clock: &clock{t: start}, dir: filepath.Join(t.TempDir(), "crons")}
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "fake", BaseURL: h.llm.BaseURL()}}
	cfg.Agent.Provider, cfg.Agent.Model = "fake", "test-model"
	cfg.Agent.ModelRetries = 0
	cfg.Shell.ReadOnly = new(bool)
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	m, err := agent.NewManager(context.Background(), st, func() config.Config { return cfg }, log)
	if err != nil {
		t.Fatal(err)
	}
	h.st, h.m = st, m
	h.s = &Scheduler{
		M: m, Store: st, CronsDir: func() string { return h.dir }, DataDir: t.TempDir(), Log: log, Now: h.clock.Now,
		Notify: func(_ context.Context, msg notify.Message) {
			h.mu.Lock()
			h.notified = append(h.notified, msg)
			h.mu.Unlock()
		},
	}
	m.Crons = h.s
	h.ctx, h.cancel = context.WithCancel(context.Background())
	t.Cleanup(func() {
		h.cancel()
		m.Close()
		h.s.Wait()
		st.Close()
	})
	return h
}

func (h *harness) write(name, file string) string {
	h.t.Helper()
	path, err := cron.Write(h.dir, name, []byte(file))
	if err != nil {
		h.t.Fatal(err)
	}
	// Written "now" on the test's clock.
	if err := os.Chtimes(path, h.clock.Now(), h.clock.Now()); err != nil {
		h.t.Fatal(err)
	}
	return path
}

func (h *harness) startScheduler() {
	h.t.Helper()
	if err := h.s.Start(h.ctx); err != nil {
		h.t.Fatal(err)
	}
}

// advance moves the clock and lets the scheduler look.
func (h *harness) advance(t time.Time) {
	h.clock.Set(t)
	h.s.poke()
}

// waitRuns waits until job's runs satisfy ok and returns them, newest
// first.
func (h *harness) waitRuns(job string, what string, ok func([]store.CronRun) bool) []store.CronRun {
	h.t.Helper()
	deadline := time.Now().Add(10 * time.Second)
	for {
		runs, err := h.st.ListCronRuns(context.Background(), store.DefaultTeamID, job, 100, 0)
		if err != nil {
			h.t.Fatal(err)
		}
		if ok(runs) {
			return runs
		}
		if time.Now().After(deadline) {
			h.t.Fatalf("timed out waiting for %s; runs: %+v", what, runs)
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func finished(n int) func([]store.CronRun) bool {
	return func(runs []store.CronRun) bool {
		if len(runs) < n {
			return false
		}
		for _, r := range runs {
			if r.State == store.CronRunning {
				return false
			}
		}
		return true
	}
}

func (h *harness) notifications() []notify.Message {
	h.mu.Lock()
	defer h.mu.Unlock()
	return append([]notify.Message(nil), h.notified...)
}

func TestScheduledRunsAndSkip(t *testing.T) {
	h := newHarness(t)
	h.write("tick", "---\nschedule: every 1m\n---\nLook around.\n")
	h.startScheduler()
	if runs := h.waitRuns("tick", "nothing", func([]store.CronRun) bool { return true }); len(runs) != 0 {
		t.Fatalf("ran before its slot: %+v", runs)
	}
	st, err := h.s.Job(context.Background(), "tick")
	if err != nil {
		t.Fatal(err)
	}
	if want := start.Truncate(time.Minute).Add(time.Minute); !st.Next.Equal(want) {
		t.Fatalf("next = %v, want %v", st.Next, want)
	}

	// The first run hangs, so the next slot is skipped.
	started := make(chan struct{})
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("thinking"), Hang: true, Started: started})
	h.advance(start.Add(30 * time.Second))
	runs := h.waitRuns("tick", "a running run", func(r []store.CronRun) bool { return len(r) == 1 && r[0].SessionID != "" })
	first := runs[0]
	if first.Cause != store.CronCauseSchedule || first.State != store.CronRunning || !first.ScheduledAt.Equal(start.Add(30*time.Second)) {
		t.Fatalf("first run %+v", first)
	}
	sess, err := h.m.Get(context.Background(), first.SessionID)
	if err != nil {
		t.Fatal(err)
	}
	if sess.CronID != "tick" || !strings.HasPrefix(sess.Title, "tick · 2026-10-21 10:01") ||
		sess.WorkingDir != filepath.Join(h.s.DataDir, "cron", "tick") || sess.ProjectID != store.DefaultProjectID {
		t.Fatalf("session %+v", sess)
	}
	h.advance(start.Add(90 * time.Second))
	runs = h.waitRuns("tick", "a skipped run", func(r []store.CronRun) bool { return len(r) == 2 })
	if runs[0].State != store.CronSkipped || !strings.Contains(runs[0].Summary, "still going") {
		t.Fatalf("skipped run %+v", runs[0])
	}
	if _, err := h.s.Run(context.Background(), "tick"); err == nil || !strings.Contains(err.Error(), "still going") {
		t.Fatalf("RunNow while running: %v", err)
	}
	<-started
	if _, err := h.m.Interrupt(context.Background(), first.SessionID); err != nil {
		t.Fatal(err)
	}
	runs = h.waitRuns("tick", "the first run to fail", finished(2))
	if runs[1].State != store.CronFailed || runs[1].Summary != "interrupted" {
		t.Fatalf("interrupted run %+v", runs[1])
	}
	if n := h.notifications(); len(n) != 1 || n[0].Title != "tick failed" || !n[0].High {
		t.Fatalf("notifications %+v", n)
	}

	// Asleep for an hour: one run, not sixty.
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("All quiet.")})
	h.advance(start.Add(time.Hour))
	runs = h.waitRuns("tick", "one run after sleeping", finished(3))
	if len(runs) != 3 || runs[0].State != store.CronOK || runs[0].Summary != "All quiet." {
		t.Fatalf("runs %+v", runs)
	}
	if st, _ := h.s.Job(context.Background(), "tick"); !st.Next.Equal(start.Truncate(time.Minute).Add(61*time.Minute)) || st.Last.ID != runs[0].ID {
		t.Fatalf("after sleep: next %v last %+v", st.Next, st.Last)
	}
}

func TestRunNowAttentionQuietAndArchive(t *testing.T) {
	h := newHarness(t)
	h.write("check", "---\nschedule: daily at 3:00\nenabled: false\nkeep_runs: 2\n---\nCheck things.\n")
	h.startScheduler()
	if st, _ := h.s.Job(context.Background(), "check"); !st.Next.IsZero() || st.Job.IsEnabled() {
		t.Fatalf("disabled job %+v", st)
	}

	// A refused command: needs attention, and a notification listing it.
	h.llm.Push(llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"sh1", "shell", `{"command":"echo hi"}`})},
		llmtest.Response{Chunks: llmtest.Text("**Couldn't check**: echo was refused.\nMore.")})
	run, err := h.s.Run(context.Background(), "check")
	if err != nil {
		t.Fatal(err)
	}
	if run.Cause != store.CronCauseManual || run.SessionID == "" {
		t.Fatalf("run %+v", run)
	}
	runs := h.waitRuns("check", "needs attention", finished(1))
	if r := runs[0]; r.State != store.CronNeedsAttention || r.Summary != "Couldn't check: echo was refused." ||
		len(r.Refused) != 1 || r.Refused[0] != "echo hi" {
		t.Fatalf("run %+v", r)
	}
	n := h.notifications()
	if len(n) != 1 || n[0].Title != "check needs attention" || !strings.Contains(n[0].Body, "Refused: echo hi") {
		t.Fatalf("notifications %+v", n)
	}

	// Nothing to report: ok, quiet, no notification.
	for i := range 2 {
		h.clock.Set(start.Add(time.Duration(i+1) * time.Minute))
		h.llm.Push(llmtest.Response{Chunks: llmtest.Text("Nothing to report.")})
		if _, err := h.s.Run(context.Background(), "check"); err != nil {
			t.Fatal(err)
		}
		runs = h.waitRuns("check", "a quiet run", func(r []store.CronRun) bool { return finished(len(runs) + 1)(r) })
	}
	if r := runs[0]; r.State != store.CronOK || !r.Quiet {
		t.Fatalf("quiet run %+v", r)
	}
	if n := h.notifications(); len(n) != 1 {
		t.Fatalf("quiet runs notified: %+v", n)
	}

	// keep_runs 2: the oldest run's session is archived, not deleted.
	list, _ := h.m.List(context.Background(), "", false, 100, 0)
	all, _ := h.m.List(context.Background(), "", true, 100, 0)
	if len(list) != 2 || len(all) != 3 {
		t.Fatalf("sessions listed %d, all %d", len(list), len(all))
	}
	oldest, err := h.m.Get(context.Background(), runs[2].SessionID)
	if err != nil || !oldest.Archived {
		t.Fatalf("oldest session %+v %v", oldest, err)
	}
	if p, _ := h.st.GetProject(context.Background(), store.DefaultProjectID); p.SessionCount != 2 {
		t.Errorf("project session count %d", p.SessionCount)
	}
}

func TestCatchUpOnStart(t *testing.T) {
	for _, tc := range []struct {
		name    string
		catchUp string
		ran     time.Time // a run recorded for this slot already
		want    bool
	}{
		{"missed within window", "", time.Time{}, true},
		{"catch_up 0", "catch_up: 0\n", time.Time{}, false},
		{"window too short", "catch_up: 20m\n", time.Time{}, false},
		{"already ran", "", time.Date(2026, 10, 21, 10, 0, 0, 0, time.Local), false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h := newHarness(t)
			path := h.write("daily", "---\nschedule: daily at 10:00\n"+tc.catchUp+"---\nMorning check.\n")
			old := start.Add(-24 * time.Hour)
			if err := os.Chtimes(path, old, old); err != nil {
				t.Fatal(err)
			}
			if !tc.ran.IsZero() {
				if err := h.st.CreateCronRun(context.Background(), &store.CronRun{ID: "cron_old", TeamID: store.DefaultTeamID, Job: "daily",
					Cause: store.CronCauseSchedule, State: store.CronOK, ScheduledAt: tc.ran, StartedAt: tc.ran, FinishedAt: tc.ran}); err != nil {
					t.Fatal(err)
				}
			}
			// 10:30: the 10:00 slot was missed while flit was down.
			h.clock.Set(start.Add(30 * time.Minute))
			h.llm.Push(llmtest.Response{Chunks: llmtest.Text("Morning: fine.")})
			h.startScheduler()
			if !tc.want {
				time.Sleep(100 * time.Millisecond)
				runs, _ := h.st.ListCronRuns(context.Background(), store.DefaultTeamID, "daily", 10, 0)
				if len(runs) != 0 && (len(runs) != 1 || runs[0].ID != "cron_old") {
					t.Fatalf("caught up: %+v", runs)
				}
				return
			}
			runs := h.waitRuns("daily", "a catch-up run", finished(1))
			if r := runs[0]; r.Cause != store.CronCauseCatchUp || !r.ScheduledAt.Equal(time.Date(2026, 10, 21, 10, 0, 0, 0, time.Local)) {
				t.Fatalf("run %+v", r)
			}
			if st, _ := h.s.Job(context.Background(), "daily"); !st.Next.Equal(time.Date(2026, 10, 22, 10, 0, 0, 0, time.Local)) {
				t.Fatalf("next %v", st.Next)
			}
		})
	}
}

func TestOneShotDisablesItself(t *testing.T) {
	h := newHarness(t)
	path := h.write("once", "---\n# a reminder\nschedule: at 2026-10-21 10:05\n---\nRemind me.\n")
	h.startScheduler()
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("Reminder sent.")})
	h.advance(time.Date(2026, 10, 21, 10, 5, 0, 0, time.Local))
	h.waitRuns("once", "the run", finished(1))
	j := cron.Load(path)
	if j.Err != nil || j.IsEnabled() {
		t.Fatalf("one-shot after running: %+v", j)
	}
	if data, _ := os.ReadFile(path); !strings.Contains(string(data), "# a reminder") {
		t.Errorf("comment lost: %s", data)
	}
	if st, _ := h.s.Job(context.Background(), "once"); !st.Next.IsZero() {
		t.Fatalf("still scheduled at %v", st.Next)
	}
}

func TestBrokenJobsAndProjects(t *testing.T) {
	h := newHarness(t)
	h.write("bad", "---\nschedule: sometimes\n---\nx\n")
	h.write("lost", "---\nschedule: every 2h\nproject: nowhere\n---\nx\n")
	projDir := t.TempDir()
	p, err := h.m.CreateProject(context.Background(), projDir, "flit")
	if err != nil {
		t.Fatal(err)
	}
	h.write("proj", "---\nschedule: every 2h\nproject: FLIT\n---\nx\n")
	h.startScheduler()
	list, err := h.s.Jobs(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(list) != 3 || list[0].Job.Err == nil || !list[0].Next.IsZero() || list[1].ProjectErr == nil || list[2].Project.ID != p.ID {
		t.Fatalf("jobs %+v", list)
	}
	if _, err := h.s.Run(context.Background(), "bad"); err == nil {
		t.Fatal("ran a broken job")
	}
	if _, err := h.s.Run(context.Background(), "missing"); err == nil {
		t.Fatal("ran a missing job")
	}
	// A run whose project can't be found fails and says why.
	if _, err := h.s.Run(context.Background(), "lost"); err != nil {
		t.Fatal(err)
	}
	runs := h.waitRuns("lost", "the failed run", finished(1))
	if runs[0].State != store.CronFailed || !strings.Contains(runs[0].Summary, "no project") {
		t.Fatalf("run %+v", runs[0])
	}
	// One in a project works in its directory.
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	run, err := h.s.Run(context.Background(), "proj")
	if err != nil {
		t.Fatal(err)
	}
	h.waitRuns("proj", "the run", finished(1))
	sess, _ := h.m.Get(context.Background(), run.SessionID)
	if sess.ProjectID != p.ID || sess.WorkingDir != projDir {
		t.Fatalf("session %+v", sess)
	}
	text, err := h.s.Describe(context.Background())
	if err != nil || !strings.Contains(text, "BROKEN") || !strings.Contains(text, "every 2 hours") {
		t.Fatalf("describe: %v\n%s", err, text)
	}
}

func TestRestartFailsUnfinishedRuns(t *testing.T) {
	h := newHarness(t)
	if err := h.st.CreateCronRun(context.Background(), &store.CronRun{ID: "cron_x", TeamID: store.DefaultTeamID, Job: "j",
		Cause: store.CronCauseSchedule, State: store.CronRunning, ScheduledAt: start, StartedAt: start}); err != nil {
		t.Fatal(err)
	}
	h.startScheduler()
	r, err := h.st.GetCronRun(context.Background(), "cron_x")
	if err != nil || r.State != store.CronFailed || r.FinishedAt.IsZero() {
		t.Fatalf("run %+v %v", r, err)
	}
}
