package tools

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// JobOutcome is how a background job ended; JobRunning while it runs.
type JobOutcome int

const (
	JobRunning JobOutcome = iota
	// JobExited: the command exited by itself (see JobInfo.ExitCode).
	JobExited
	// JobFailed: it could not be run or waited for (see JobInfo.Err).
	JobFailed
	// JobTimedOut: killed when its time ran out.
	JobTimedOut
	// JobCancelled: killed by the job tool or a client.
	JobCancelled
	// JobLost: killed because flit is stopping.
	JobLost
)

// JobInfo is a background job as it is now.
type JobInfo struct {
	ID string
	// ToolCallID is the shell call that started it.
	ToolCallID string
	Command    string
	// Workdir is relative to the session's directory.
	Workdir string
	// Detached is set when it ran in the foreground first (see
	// config.Shell.BackgroundAfter).
	Detached bool
	// Timeout counts from Started.
	Timeout time.Duration
	Started time.Time

	Outcome  JobOutcome
	ExitCode int
	Err      string
	// Duration is how long it ran (so far, while running).
	Duration time.Duration
	// CancelledBy is the client that cancelled it; empty when the agent
	// did.
	CancelledBy string
	// Output is all of its output flit kept: the start and end of it.
	Output string
}

// Running reports whether the job is still running.
func (i JobInfo) Running() bool { return i.Outcome == JobRunning }

// Summary is one line about the job, e.g.
// "job_1 (go test ./...): exited with code 0 after 3m12s".
func (i JobInfo) Summary() string {
	cmd := i.Command
	if len(cmd) > 120 {
		cmd = cmd[:117] + "..."
	}
	return fmt.Sprintf("%s (%s): %s", i.ID, cmd, i.status())
}

func (i JobInfo) status() string {
	d := i.Duration.Round(time.Second)
	switch i.Outcome {
	case JobRunning:
		return fmt.Sprintf("running for %s", d)
	case JobExited:
		return fmt.Sprintf("exited with code %d after %s", i.ExitCode, d)
	case JobFailed:
		return fmt.Sprintf("failed: %s", i.Err)
	case JobTimedOut:
		return fmt.Sprintf("killed: timed out after %s", d)
	case JobCancelled:
		if i.CancelledBy != "" {
			return fmt.Sprintf("cancelled by the user after %s", d)
		}
		return fmt.Sprintf("cancelled after %s", d)
	case JobLost:
		return fmt.Sprintf("killed after %s because flit stopped", d)
	}
	return "unknown"
}

// Tail is the end of the job's output: at most lines lines and max bytes.
func (i JobInfo) Tail(lines, max int) string {
	return tail(i.Output, lines, max)
}

func tail(s string, lines, max int) string {
	s = strings.TrimRight(s, "\n")
	if len(s) > max {
		s = s[len(s)-max:]
		if i := strings.IndexByte(s, '\n'); i >= 0 && i < len(s)-1 {
			s = s[i+1:]
		}
	}
	if n := strings.Count(s, "\n") + 1; n > lines {
		for range n - lines {
			s = s[strings.IndexByte(s, '\n')+1:]
		}
	}
	return s
}

// NoticeText is what the agent is told when jobs end without it having
// seen the end through the job tool.
func NoticeText(ended []JobInfo) string {
	var b strings.Builder
	if len(ended) == 1 {
		b.WriteString("[flit notice] A background job ended:\n")
	} else {
		b.WriteString("[flit notice] Background jobs ended:\n")
	}
	for _, j := range ended {
		fmt.Fprintf(&b, "- %s\n", j.Summary())
		if t := j.Tail(20, 2000); t != "" {
			b.WriteString("  Last output:\n")
			for l := range strings.SplitSeq(t, "\n") {
				b.WriteString("    " + l + "\n")
			}
		}
	}
	b.WriteString("Use the job tool (action status) to see all of a job's output.")
	return b.String()
}

// JobHooks report a session's jobs. Jobs calls them without holding its
// own lock: Started before any Output, Output as the job prints, Done once
// when it ends (with all its output).
type JobHooks struct {
	Started func(JobInfo)
	Output  func(id, text string)
	Done    func(JobInfo)
	// Seen reports jobs whose end the agent saw through the job tool, so
	// it needs no notice about them.
	Seen func(ids []string)
}

// ErrJobLimit is returned when a session already runs its maximum number
// of jobs.
var ErrJobLimit = errors.New("too many background jobs running")

// ErrJobNotFound and ErrJobEnded are Cancel's errors.
var (
	ErrJobNotFound = errors.New("no such background job")
	ErrJobEnded    = errors.New("the background job has already ended")
)

// Jobs are one session's background shell jobs. They outlive turns; Close
// kills them.
type Jobs struct {
	hooks JobHooks
	newID func() string

	mu     sync.Mutex
	jobs   map[string]*job
	order  []string
	closed bool
	wg     sync.WaitGroup
}

type job struct {
	info JobInfo // the parts fixed at start
	p    *proc
	// end is set, and done closed, once it has ended and Done ran.
	end  *JobInfo
	done chan struct{}
}

// NewJobs returns an empty set of jobs. newID makes job ids.
func NewJobs(hooks JobHooks, newID func() string) *Jobs {
	return &Jobs{hooks: hooks, newID: newID, jobs: map[string]*job{}}
}

// adopt makes p, started by shell call callID, a background job that is
// killed limit after it started. maxJobs caps the running jobs (0: no
// cap).
func (js *Jobs) adopt(p *proc, callID, command, workdir string, detached bool, limit time.Duration, maxJobs int) (JobInfo, error) {
	js.mu.Lock()
	if js.closed {
		js.mu.Unlock()
		return JobInfo{}, errors.New("flit is stopping")
	}
	if maxJobs > 0 {
		running := 0
		for _, j := range js.jobs {
			if j.end == nil {
				running++
			}
		}
		if running >= maxJobs {
			js.mu.Unlock()
			return JobInfo{}, fmt.Errorf("%w (%d, shell.max_jobs); wait for one or cancel one first", ErrJobLimit, running)
		}
	}
	j := &job{p: p, done: make(chan struct{}), info: JobInfo{
		ID: js.newID(), ToolCallID: callID, Command: command, Workdir: workdir, Detached: detached,
		Timeout: limit, Started: p.start,
	}}
	js.jobs[j.info.ID] = j
	js.order = append(js.order, j.info.ID)
	js.wg.Add(1)
	js.mu.Unlock()

	if js.hooks.Started != nil {
		js.hooks.Started(j.info)
	}
	id := j.info.ID
	p.out.setLive(func(text string) {
		if js.hooks.Output != nil {
			js.hooks.Output(id, text)
		}
	})
	timer := time.AfterFunc(max(limit-time.Since(p.start), 0), func() { p.kill(JobTimedOut, "") })
	go func() {
		defer js.wg.Done()
		<-p.done
		timer.Stop()
		end := j.info
		end.Outcome, end.ExitCode, end.Err, end.CancelledBy = p.result()
		end.Duration = p.ended.Sub(p.start)
		end.Output = p.out.String()
		if js.hooks.Done != nil {
			js.hooks.Done(end)
		}
		js.mu.Lock()
		j.end = &end
		js.mu.Unlock()
		close(j.done)
	}()
	return j.info, nil
}

// snapshot is j as it is now; call with js.mu held.
func (j *job) snapshot() JobInfo {
	if j.end != nil {
		return *j.end
	}
	i := j.info
	i.Duration = time.Since(i.Started)
	i.Output = j.p.out.String()
	return i
}

// Get returns a job as it is now.
func (js *Jobs) Get(id string) (JobInfo, bool) {
	js.mu.Lock()
	defer js.mu.Unlock()
	j, ok := js.jobs[id]
	if !ok {
		return JobInfo{}, false
	}
	return j.snapshot(), true
}

// List returns every job flit has run for the session since it started,
// oldest first.
func (js *Jobs) List() []JobInfo {
	js.mu.Lock()
	defer js.mu.Unlock()
	out := make([]JobInfo, 0, len(js.order))
	for _, id := range js.order {
		out = append(out, js.jobs[id].snapshot())
	}
	return out
}

// Wait waits up to d for job id to end (or ctx to end), and returns it as
// it is then.
func (js *Jobs) Wait(ctx context.Context, id string, d time.Duration) (JobInfo, bool) {
	js.mu.Lock()
	j, ok := js.jobs[id]
	js.mu.Unlock()
	if !ok {
		return JobInfo{}, false
	}
	t := time.NewTimer(d)
	defer t.Stop()
	select {
	case <-j.done:
	case <-t.C:
	case <-ctx.Done():
	}
	return js.Get(id)
}

// Cancel kills job id and waits for its end to be reported. by is the
// client cancelling it, empty for the agent.
func (js *Jobs) Cancel(id, by string) (JobInfo, error) {
	js.mu.Lock()
	j, ok := js.jobs[id]
	ended := ok && j.end != nil
	js.mu.Unlock()
	switch {
	case !ok:
		return JobInfo{}, ErrJobNotFound
	case ended:
		return JobInfo{}, ErrJobEnded
	}
	j.p.kill(JobCancelled, by)
	<-j.done
	i, _ := js.Get(id)
	return i, nil
}

// MarkSeen tells the hooks the agent saw how these jobs ended.
func (js *Jobs) MarkSeen(ids ...string) {
	if len(ids) > 0 && js.hooks.Seen != nil {
		js.hooks.Seen(ids)
	}
}

// Running reports whether any job is still running.
func (js *Jobs) Running() bool {
	js.mu.Lock()
	defer js.mu.Unlock()
	for _, j := range js.jobs {
		if j.end == nil {
			return true
		}
	}
	return false
}

// Close kills every running job (JobLost) and waits until their ends are
// reported. No job can start afterwards.
func (js *Jobs) Close() {
	js.mu.Lock()
	js.closed = true
	for _, j := range js.jobs {
		if j.end == nil {
			j.p.kill(JobLost, "")
		}
	}
	js.mu.Unlock()
	js.wg.Wait()
}

// proc is a running shell command.
type proc struct {
	out    *headTail
	cancel context.CancelFunc
	start  time.Time
	// done is closed when it has exited and all its output is in; err and
	// ended are set then.
	done  chan struct{}
	err   error
	ended time.Time

	mu     sync.Mutex
	reason JobOutcome // why flit killed it; JobRunning if it didn't
	by     string
}

// startProc starts command in dir; live gets its output as it arrives.
func startProc(dir, command string, live func(string)) (*proc, error) {
	ctx, cancel := context.WithCancel(context.Background())
	cmd := shellCommand(ctx, command)
	cmd.Dir = dir
	out := &headTail{keep: shellKeep, live: live}
	cmd.Stdout, cmd.Stderr = out, out
	cmd.WaitDelay = 2 * time.Second
	p := &proc{out: out, cancel: cancel, done: make(chan struct{})}
	p.start = time.Now()
	if err := cmd.Start(); err != nil {
		cancel()
		return nil, err
	}
	go func() {
		p.err = cmd.Wait()
		p.ended = time.Now()
		cancel()
		close(p.done)
	}()
	return p, nil
}

// kill kills the command (if it still runs) and records why; the first
// reason wins.
func (p *proc) kill(reason JobOutcome, by string) {
	select {
	case <-p.done:
		return
	default:
	}
	p.mu.Lock()
	if p.reason == JobRunning {
		p.reason, p.by = reason, by
	}
	p.mu.Unlock()
	p.cancel()
}

// result is how it ended; call after done.
func (p *proc) result() (outcome JobOutcome, exitCode int, errText, by string) {
	p.mu.Lock()
	reason, by := p.reason, p.by
	p.mu.Unlock()
	var exitErr *exec.ExitError
	switch {
	case reason != JobRunning:
		return reason, -1, "", by
	case errors.As(p.err, &exitErr):
		return JobExited, exitErr.ExitCode(), "", ""
	case p.err != nil:
		return JobFailed, -1, p.err.Error(), ""
	}
	return JobExited, 0, "", ""
}

// WithJobs is set for a session that runs background jobs: its shell takes
// background (and moves long commands to the background), and the job
// tool checks on them.
func WithJobs(set []Tool) []Tool {
	out := make([]Tool, 0, len(set)+1)
	for _, t := range set {
		if t.Name == shellTool.Name {
			t.Description = "Run a shell command (sh -c on Unix, cmd /C on Windows) and return its combined stdout and stderr " +
				"and exit code. Some commands need the user's approval first. Long output is cut to its start and end. " +
				"A command that runs long moves to the background as a job; you get its id, and a notice when it ends."
			t.Schema = shellJobSchema
		}
		out = append(out, t)
	}
	return append(out, jobTool)
}

var jobTool = Tool{
	Name: "job",
	Description: "Check on, wait for or cancel background shell jobs (started by shell with background, or moved to " +
		"the background because they ran long). You also get a notice when a job ends.",
	Schema: `{"type":"object","properties":{
"action":{"type":"string","enum":["status","wait","cancel"],"description":"status: how the job is doing and its output (without job_id: all jobs); wait: wait until it ends or timeout_seconds pass; cancel: kill it"},
"job_id":{"type":"string","description":"The job's id; required for wait and cancel"},
"timeout_seconds":{"type":"integer","description":"For wait: wait at most this long (default from config)"}
},"required":["action"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Action         string `json:"action"`
			JobID          string `json:"job_id"`
			TimeoutSeconds int    `json:"timeout_seconds"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if env.Jobs == nil {
			return errorf("background jobs aren't available here")
		}
		js := env.Jobs
		if a.Action == "status" && a.JobID == "" {
			list := js.List()
			if len(list) == 0 {
				return Result{Text: "No background jobs."}
			}
			var b strings.Builder
			var seen []string
			for _, j := range list {
				b.WriteString(j.Summary() + "\n")
				if !j.Running() {
					seen = append(seen, j.ID)
				}
			}
			js.MarkSeen(seen...)
			return Result{Text: b.String()}
		}
		if a.JobID == "" {
			return errorf("job_id is required for %s", a.Action)
		}
		var info JobInfo
		switch a.Action {
		case "status":
			i, ok := js.Get(a.JobID)
			if !ok {
				return errorf("%v %q (jobs from before flit restarted are gone)", ErrJobNotFound, a.JobID)
			}
			info = i
		case "wait":
			i, ok := js.Wait(ctx, a.JobID, timeoutFor(a.TimeoutSeconds, env.Shell.Timeout, env.Shell.MaxTimeout))
			if !ok {
				return errorf("%v %q (jobs from before flit restarted are gone)", ErrJobNotFound, a.JobID)
			}
			info = i
		case "cancel":
			i, err := js.Cancel(a.JobID, "")
			if err != nil {
				return errorf("%v: %s", err, a.JobID)
			}
			info = i
		default:
			return errorf("unknown action %q; use status, wait or cancel", a.Action)
		}
		return jobReport(js, info)
	},
}

// jobReport is the job tool's result about one job: a status line and its
// output (the last part of it while it runs).
func jobReport(js *Jobs, i JobInfo) Result {
	out := i.Output
	if i.Running() {
		const keep = 8 << 10
		if len(out) > keep {
			out = fmt.Sprintf("[... %d earlier bytes not shown ...]\n%s", len(out)-keep, tail(out, 1<<30, keep))
		}
	} else {
		js.MarkSeen(i.ID)
	}
	return Result{Text: withNewline(out) + "[" + i.Summary() + "]"}
}
