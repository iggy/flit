// Package scheduler runs cron jobs (see package cron) on their schedules:
// each run is a new, unattended session in the job's project (see
// agent.Manager.StartCronRun), recorded in the store's cron_runs.
//
// The crons directory is rescanned every few seconds and whenever something
// asks (the API, the cron tool, a config reload), so job files take effect
// without a restart. A run still going when the job is due again makes that
// slot a skipped run. When flit starts, a job whose last slot was missed
// within its catch_up window runs once, however many slots were missed.
package scheduler

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/notify"
	"github.com/iggy/flit/server/internal/store"
)

// rescanInterval is how often the crons directory is reread.
const rescanInterval = 10 * time.Second

// Errors returned to the API.
var (
	ErrNotFound = errors.New("no such cron job")
	ErrRunning  = errors.New("a run of this job is still going")
	ErrBroken   = errors.New("the job file has errors")
)

// Scheduler runs cron jobs.
type Scheduler struct {
	M     *agent.Manager
	Store *store.Store
	// CronsDir returns the crons directory.
	CronsDir func() string
	// DataDir holds working directories for jobs in Scratch with no dir.
	DataDir string
	Log     *slog.Logger
	// Notify, if set, receives run results worth telling someone about.
	Notify func(context.Context, notify.Message)
	// Now is the clock; nil means time.Now.
	Now func() time.Time

	mu   sync.Mutex
	jobs map[string]*jobState
	// lastSlot is the latest slot each job ran (or skipped) for.
	lastSlot map[string]time.Time
	wake     chan struct{}
	runs     sync.WaitGroup
	ctx      context.Context
}

type jobState struct {
	job  cron.Job
	next time.Time
	// running is the run in progress, if any.
	running *store.CronRun
}

func (s *Scheduler) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func newID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return fmt.Sprintf("cron_%012x%s", time.Now().UnixMilli(), hex.EncodeToString(b))
}

// Start loads the jobs, catches up on slots missed while flit was down and
// schedules the rest. Runs happen until ctx ends; then call Wait (after the
// agent manager has stopped its turns).
func (s *Scheduler) Start(ctx context.Context) error {
	s.ctx = ctx
	s.wake = make(chan struct{}, 1)
	s.jobs = map[string]*jobState{}
	if n, err := s.Store.FailUnfinishedCronRuns(ctx, "flit stopped during the run"); err != nil {
		return err
	} else if n > 0 {
		s.Log.Warn("cron runs left unfinished by the last flit marked failed", "runs", n)
	}
	slots, err := s.Store.LastCronSlots(ctx, store.DefaultTeamID)
	if err != nil {
		return err
	}
	s.lastSlot = slots
	s.mu.Lock()
	s.rescanLocked(true)
	s.mu.Unlock()
	go s.loop(ctx)
	return nil
}

// Wait waits for the runs' bookkeeping to finish.
func (s *Scheduler) Wait() { s.runs.Wait() }

// Rescan rereads the crons directory now.
func (s *Scheduler) Rescan() {
	s.mu.Lock()
	s.rescanLocked(false)
	s.mu.Unlock()
	s.poke()
}

func (s *Scheduler) poke() {
	select {
	case s.wake <- struct{}{}:
	default:
	}
}

func (s *Scheduler) loop(ctx context.Context) {
	timer := time.NewTimer(0)
	defer timer.Stop()
	lastScan := s.now()
	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
		case <-s.wake:
		}
		s.mu.Lock()
		if s.now().Sub(lastScan) >= rescanInterval {
			s.rescanLocked(false)
			lastScan = s.now()
		}
		s.fireDueLocked()
		wait := rescanInterval - s.now().Sub(lastScan)
		for _, js := range s.jobs {
			if !js.next.IsZero() {
				wait = min(wait, js.next.Sub(s.now()))
			}
		}
		s.mu.Unlock()
		timer.Reset(max(wait, 10*time.Millisecond))
	}
}

// rescanLocked rereads the job files. New and changed jobs get their next
// slot from now; at startup, missed slots within catch_up run once.
func (s *Scheduler) rescanLocked(startup bool) {
	jobs, err := cron.List(s.Dir())
	if err != nil {
		s.Log.Error("read crons directory", "dir", s.Dir(), "err", err)
		return
	}
	now := s.now()
	seen := map[string]bool{}
	for _, j := range jobs {
		seen[j.Name] = true
		js, ok := s.jobs[j.Name]
		if ok && js.job.ModTime.Equal(j.ModTime) && js.job.Path == j.Path {
			continue
		}
		if !ok {
			js = &jobState{}
			s.jobs[j.Name] = js
		}
		if j.Err != nil && (!ok || js.job.Err == nil || js.job.Err.Error() != j.Err.Error()) {
			s.Log.Warn("cron job file has errors; it won't run", "job", j.Name, "path", j.Path, "err", j.Err)
		}
		js.job = j
		js.next = time.Time{}
		if j.Err != nil || !j.IsEnabled() {
			continue
		}
		if startup {
			if missed := s.missed(j, now); !missed.IsZero() {
				s.startLocked(js, store.CronCauseCatchUp, missed)
			}
		}
		js.next = s.nextAfter(j, now)
	}
	for name, js := range s.jobs {
		if !seen[name] && js.running == nil {
			delete(s.jobs, name)
		}
	}
}

// nextAfter is j's first slot after t that hasn't run yet.
func (s *Scheduler) nextAfter(j cron.Job, t time.Time) time.Time {
	if last := s.lastSlot[j.Name]; last.After(t) {
		t = last
	}
	return j.Sched.Next(t)
}

// missed is the latest slot of j at or before now that it never ran for,
// if it is within the catch_up window and after the file was written.
func (s *Scheduler) missed(j cron.Job, now time.Time) time.Time {
	window := j.CatchUpWindow()
	if window <= 0 {
		return time.Time{}
	}
	from := now.Add(-window)
	for _, t := range []time.Time{s.lastSlot[j.Name], j.ModTime} {
		if t.After(from) {
			from = t
		}
	}
	var last time.Time
	for t, n := j.Sched.Next(from), 0; !t.IsZero() && !t.After(now) && n < 100000; t, n = j.Sched.Next(t), n+1 {
		last = t
	}
	return last
}

func (s *Scheduler) fireDueLocked() {
	now := s.now()
	for _, js := range s.jobs {
		if js.next.IsZero() || js.next.After(now) {
			continue
		}
		slot := js.next
		s.startLocked(js, store.CronCauseSchedule, slot)
		// Never more than one run for slots missed meanwhile (a sleeping
		// laptop): the next is the first one after now.
		js.next = s.nextAfter(js.job, now)
	}
}

// startLocked starts a run of js for slot, or records it skipped if one is
// still going.
func (s *Scheduler) startLocked(js *jobState, cause string, slot time.Time) *store.CronRun {
	j := js.job
	now := s.now()
	run := &store.CronRun{
		ID: newID(), TeamID: store.DefaultTeamID, Job: j.Name, Cause: cause, State: store.CronRunning,
		ScheduledAt: slot, StartedAt: now,
	}
	if cause != store.CronCauseManual {
		if slot.After(s.lastSlot[j.Name]) {
			s.lastSlot[j.Name] = slot
		}
		if j.Sched.OneShot() {
			// Disabled once it has run (or tried to).
			if err := cron.FinishOneShot(j.Path, slot.In(j.Loc)); err != nil {
				s.Log.Error("disable one-shot cron job", "job", j.Name, "err", err)
			}
		}
	}
	if js.running != nil {
		run.State, run.FinishedAt = store.CronSkipped, now
		run.Summary = "skipped: the previous run (" + js.running.StartedAt.Format("15:04") + ") was still going"
		if err := s.Store.CreateCronRun(s.ctx, run); err != nil {
			s.Log.Error("record skipped cron run", "job", j.Name, "err", err)
		}
		s.Log.Info("cron run skipped; the previous one is still going", "job", j.Name, "slot", slot)
		return run
	}
	if err := s.Store.CreateCronRun(s.ctx, run); err != nil {
		s.Log.Error("record cron run", "job", j.Name, "err", err)
		return nil
	}
	js.running = run
	s.Log.Info("starting cron run", "job", j.Name, "cause", cause, "slot", slot)

	o, err := s.runOptions(j, run)
	var outcome <-chan agent.CronOutcome
	if err == nil {
		var sess store.Session
		sess, outcome, err = s.M.StartCronRun(s.ctx, o)
		run.SessionID, run.ProjectID = sess.ID, sess.ProjectID
		if run.SessionID != "" {
			if uerr := s.Store.UpdateCronRun(s.ctx, *run); uerr != nil {
				s.Log.Error("record cron run session", "job", j.Name, "err", uerr)
			}
		}
	}
	s.runs.Add(1)
	go func() {
		defer s.runs.Done()
		var out agent.CronOutcome
		if err != nil {
			out = agent.CronOutcome{Failed: true, Reason: "could not start: " + err.Error()}
		} else {
			out = <-outcome
		}
		s.finish(js, run, out)
	}()
	return run
}

// runOptions turns a job into the run's session options.
func (s *Scheduler) runOptions(j cron.Job, run *store.CronRun) (agent.CronRunOptions, error) {
	create := agent.CreateOptions{
		WorkingDir: j.Dir, Role: j.Role, Provider: j.Model.Provider, Model: j.Model.Model, Effort: j.Model.Effort,
		Yolo: &j.Yolo, CronID: j.Name,
		Title: j.Name + " · " + run.StartedAt.In(j.Loc).Format("2006-01-02 15:04"),
	}
	if j.Project != "" {
		p, err := s.M.ResolveProject(s.ctx, j.Project)
		if err != nil {
			return agent.CronRunOptions{}, err
		}
		create.ProjectID = p.ID
		if create.WorkingDir == "" {
			create.WorkingDir = p.Dir
		}
	}
	if create.WorkingDir == "" {
		// Scratch has no directory: each job gets one of its own.
		dir := filepath.Join(s.DataDir, "cron", j.Name)
		if err := os.MkdirAll(dir, 0o700); err != nil {
			return agent.CronRunOptions{}, err
		}
		create.WorkingDir = dir
	}
	trigger := map[string]flitv1.CronTrigger{
		store.CronCauseSchedule: flitv1.CronTrigger_CRON_TRIGGER_SCHEDULE,
		store.CronCauseCatchUp:  flitv1.CronTrigger_CRON_TRIGGER_CATCH_UP,
		store.CronCauseManual:   flitv1.CronTrigger_CRON_TRIGGER_MANUAL,
	}[run.Cause]
	return agent.CronRunOptions{
		Create: create, Job: j.Name, Schedule: j.Schedule, ScheduleText: j.Sched.Words(), Trigger: trigger,
		ScheduledAt: run.ScheduledAt, RunID: run.ID, Wait: j.Ask == cron.AskWait, AskTimeout: j.AskWaitFor(),
		Prompt: j.Prompt,
	}, nil
}

// finish records how a run ended, archives old runs' sessions and sends
// notifications.
func (s *Scheduler) finish(js *jobState, run *store.CronRun, out agent.CronOutcome) {
	r := *run
	r.FinishedAt = s.now()
	r.Refused = out.Refused
	r.State, r.Summary, r.Quiet = out.Result()
	ctx := context.Background()
	s.mu.Lock()
	keep := js.job.Keep()
	s.mu.Unlock()
	if n, err := s.M.ArchiveCronSessions(ctx, r.Job, keep); err != nil {
		s.Log.Error("archive old cron runs", "job", r.Job, "err", err)
	} else if n > 0 {
		s.Log.Info("archived old cron run sessions", "job", r.Job, "sessions", n)
	}
	if err := s.Store.UpdateCronRun(ctx, r); err != nil {
		s.Log.Error("record cron run result", "job", r.Job, "err", err)
	}
	s.mu.Lock()
	if js.running == run {
		js.running = nil
	}
	s.mu.Unlock()
	s.Log.Info("cron run finished", "job", r.Job, "state", r.State, "summary", r.Summary, "refused", len(r.Refused))
	if s.Notify != nil && !r.Quiet {
		s.Notify(ctx, Message(r))
	}
}

// Message is the notification for a finished run.
func Message(r store.CronRun) notify.Message {
	m := notify.Message{Body: r.Summary}
	switch r.State {
	case store.CronNeedsAttention:
		m.Title, m.Tags, m.High = r.Job+" needs attention", []string{"warning"}, true
		if len(r.Refused) > 0 {
			m.Body += "\n\nRefused: " + strings.Join(r.Refused, "; ")
		}
	case store.CronFailed:
		m.Title, m.Tags, m.High = r.Job+" failed", []string{"x"}, true
	default:
		m.Title, m.Tags = r.Job, []string{"white_check_mark"}
	}
	return m
}

func clip(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	return string([]rune(s)[:n-1]) + "…"
}

// JobStatus is a job as the API shows it.
type JobStatus struct {
	Job  cron.Job
	Next time.Time
	// Last is the latest run, if any; Running the one in progress.
	Last    *store.CronRun
	Running *store.CronRun
	// Project is the job's project, resolved; ProjectErr why it can't be.
	Project    agent.ProjectRef
	ProjectErr error
}

// Jobs rescans and returns every job, by name.
func (s *Scheduler) Jobs(ctx context.Context) ([]JobStatus, error) {
	s.Rescan()
	last, err := s.Store.LastCronRuns(ctx, store.DefaultTeamID)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	var out []JobStatus
	for _, js := range s.jobs {
		if js.job.Path == "" {
			continue
		}
		st := JobStatus{Job: js.job, Next: js.next}
		if r, ok := last[js.job.Name]; ok {
			st.Last = &r
		}
		if js.running != nil {
			r := *js.running
			st.Running = &r
		}
		out = append(out, st)
	}
	s.mu.Unlock()
	for i := range out {
		out[i].Project, out[i].ProjectErr = s.project(ctx, out[i].Job.Project)
	}
	slices.SortFunc(out, func(a, b JobStatus) int { return strings.Compare(a.Job.Name, b.Job.Name) })
	return out, nil
}

func (s *Scheduler) project(ctx context.Context, ref string) (agent.ProjectRef, error) {
	if ref == "" {
		ref = store.DefaultProjectID
	}
	return s.M.ResolveProject(ctx, ref)
}

// Job returns one job.
func (s *Scheduler) Job(ctx context.Context, name string) (JobStatus, error) {
	list, err := s.Jobs(ctx)
	if err != nil {
		return JobStatus{}, err
	}
	for _, st := range list {
		if st.Job.Name == name {
			return st, nil
		}
	}
	return JobStatus{}, fmt.Errorf("%w: %q", ErrNotFound, name)
}

// Run starts a run of job name now.
func (s *Scheduler) Run(ctx context.Context, name string) (store.CronRun, error) {
	s.Rescan()
	s.mu.Lock()
	defer s.mu.Unlock()
	js, ok := s.jobs[name]
	switch {
	case !ok || js.job.Path == "":
		return store.CronRun{}, fmt.Errorf("%w: %q", ErrNotFound, name)
	case js.job.Err != nil:
		return store.CronRun{}, fmt.Errorf("%w: %v", ErrBroken, js.job.Err)
	case js.running != nil:
		return store.CronRun{}, fmt.Errorf("%w (session %s)", ErrRunning, js.running.SessionID)
	}
	run := s.startLocked(js, store.CronCauseManual, s.now())
	if run == nil {
		return store.CronRun{}, errors.New("could not record the run")
	}
	return *run, nil
}

// SetEnabled turns job name's schedule on or off in its file.
func (s *Scheduler) SetEnabled(ctx context.Context, name string, enabled bool) (JobStatus, error) {
	st, err := s.Job(ctx, name)
	if err != nil {
		return JobStatus{}, err
	}
	if err := cron.SetEnabled(st.Job.Path, enabled); err != nil {
		return JobStatus{}, err
	}
	return s.Job(ctx, name)
}

// Runs lists runs of job name (all jobs if empty), newest first.
func (s *Scheduler) Runs(ctx context.Context, name string, limit, offset int) ([]store.CronRun, error) {
	return s.Store.ListCronRuns(ctx, store.DefaultTeamID, name, limit, offset)
}

// --- agent.CronControl, for the cron tool ---

var _ agent.CronControl = (*Scheduler)(nil)

// Dir implements agent.CronControl.
func (s *Scheduler) Dir() string { return s.CronsDir() }

// RunNow implements agent.CronControl.
func (s *Scheduler) RunNow(ctx context.Context, name string) (string, error) {
	run, err := s.Run(ctx, name)
	if err != nil {
		return "", err
	}
	if run.SessionID == "" {
		return "", errors.New("the run failed to start; see the job's runs")
	}
	return run.SessionID, nil
}

// Describe implements agent.CronControl.
func (s *Scheduler) Describe(ctx context.Context) (string, error) {
	list, err := s.Jobs(ctx)
	if err != nil {
		return "", err
	}
	if len(list) == 0 {
		return "No cron jobs yet (directory " + s.Dir() + ").", nil
	}
	var b strings.Builder
	fmt.Fprintf(&b, "Cron jobs in %s:\n", s.Dir())
	for _, st := range list {
		j := st.Job
		fmt.Fprintf(&b, "\n- %s", j.Name)
		if j.Err != nil {
			fmt.Fprintf(&b, ": BROKEN, won't run: %v\n", j.Err)
			continue
		}
		fmt.Fprintf(&b, ": %s (%q)", j.Sched.Words(), j.Schedule)
		if !j.IsEnabled() {
			b.WriteString(", disabled")
		}
		fmt.Fprintf(&b, "\n  project: %s", orDefault(st.Project.Name, j.Project))
		if j.Dir != "" {
			fmt.Fprintf(&b, ", dir: %s", j.Dir)
		}
		if j.Role != "" {
			fmt.Fprintf(&b, ", role: %s", j.Role)
		}
		if j.Model.Provider != "" {
			fmt.Fprintf(&b, ", model: %s/%s", j.Model.Provider, j.Model.Model)
		}
		fmt.Fprintf(&b, ", ask: %s", j.Ask)
		if j.Yolo {
			b.WriteString(", yolo")
		}
		if !st.Next.IsZero() {
			fmt.Fprintf(&b, "\n  next run: %s", st.Next.Format("2006-01-02 15:04 MST"))
		}
		if st.Running != nil {
			fmt.Fprintf(&b, "\n  running now (session %s)", st.Running.SessionID)
		}
		if r := st.Last; r != nil && r.State != store.CronRunning {
			fmt.Fprintf(&b, "\n  last run: %s, %s: %s", r.StartedAt.Format("2006-01-02 15:04"), r.State, r.Summary)
		}
		fmt.Fprintf(&b, "\n  prompt: %s\n", clip(strings.Join(strings.Fields(j.Prompt), " "), 200))
	}
	return b.String(), nil
}

func orDefault(v, d string) string {
	if v != "" {
		return v
	}
	if d == "" {
		return store.DefaultProjectName
	}
	return d
}
