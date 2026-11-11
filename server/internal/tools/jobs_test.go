package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// jobRecorder collects what Jobs reports.
type jobRecorder struct {
	mu     sync.Mutex
	events []string
	ended  chan JobInfo
	seen   []string
}

func newJobEnv(t *testing.T, after time.Duration, maxJobs int) (*Env, *Jobs, *jobRecorder) {
	t.Helper()
	if runtime.GOOS == "windows" {
		t.Skip("uses sh")
	}
	r := &jobRecorder{ended: make(chan JobInfo, 10)}
	n := 0
	js := NewJobs(JobHooks{
		Started: func(j JobInfo) { r.add("started " + j.ID) },
		Output:  func(id, text string) { r.add("output " + id + " " + strings.TrimSpace(text)) },
		Done: func(j JobInfo) {
			r.add("done " + j.ID)
			r.ended <- j
		},
		Seen: func(ids []string) {
			r.mu.Lock()
			r.seen = append(r.seen, ids...)
			r.mu.Unlock()
		},
	}, func() string { n++; return fmt.Sprintf("job_%d", n) })
	t.Cleanup(js.Close)
	env := &Env{
		Dir:    t.TempDir(),
		Shell:  config.Shell{Timeout: 10 * time.Second, MaxTimeout: time.Minute, Default: "allow", BackgroundAfter: &after, MaxJobs: &maxJobs},
		Jobs:   js,
		CallID: "call_1",
	}
	return env, js, r
}

func (r *jobRecorder) add(s string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.events = append(r.events, s)
}

func (r *jobRecorder) wait(t *testing.T) JobInfo {
	t.Helper()
	select {
	case j := <-r.ended:
		return j
	case <-time.After(10 * time.Second):
		t.Fatal("no job ended")
	}
	return JobInfo{}
}

func shell(t *testing.T, env *Env, args string) Result {
	t.Helper()
	return Run(context.Background(), env, WithJobs(All()), "shell", args)
}

func jobCall(t *testing.T, env *Env, args string) Result {
	t.Helper()
	return Run(context.Background(), env, WithJobs(All()), "job", args)
}

func TestBackgroundJob(t *testing.T) {
	env, _, r := newJobEnv(t, 0, 4)
	res := shell(t, env, `{"command":"sleep 0.2; echo built","background":true}`)
	if res.IsError || !strings.Contains(res.Text, "job_1") {
		t.Fatalf("start: %+v", res)
	}
	j := r.wait(t)
	if j.Outcome != JobExited || j.ExitCode != 0 || strings.TrimSpace(j.Output) != "built" || j.ToolCallID != "call_1" || j.Detached {
		t.Fatalf("job %+v", j)
	}
	r.mu.Lock()
	got := strings.Join(r.events, "|")
	r.mu.Unlock()
	if got != "started job_1|output job_1 built|done job_1" {
		t.Fatalf("events %s", got)
	}

	// The job tool reports it and marks it seen.
	res = jobCall(t, env, `{"action":"status","job_id":"job_1"}`)
	if res.IsError || !strings.Contains(res.Text, "built") || !strings.Contains(res.Text, "exited with code 0") {
		t.Fatalf("status: %+v", res)
	}
	if len(r.seen) != 1 || r.seen[0] != "job_1" {
		t.Fatalf("seen %v", r.seen)
	}
}

func TestLongCommandMovesToBackground(t *testing.T) {
	env, _, r := newJobEnv(t, 100*time.Millisecond, 4)
	var live []string
	env.Output = func(s string) { live = append(live, s) }
	res := shell(t, env, `{"command":"echo early; sleep 0.4; echo late; exit 3"}`)
	if res.IsError || !strings.HasPrefix(res.Text, "early\n") || !strings.Contains(res.Text, "moved to the background as job job_1") {
		t.Fatalf("result: %+v", res)
	}
	j := r.wait(t)
	if j.Outcome != JobExited || j.ExitCode != 3 || !j.Detached || j.Output != "early\nlate\n" {
		t.Fatalf("job %+v", j)
	}
	// Output before the move went to the tool call, after it to the job.
	if strings.Join(live, "") != "early\n" {
		t.Fatalf("live %q", live)
	}

	// Quick commands stay in the foreground.
	res = shell(t, env, `{"command":"echo quick"}`)
	if res.Text != "quick\n[exit code 0]" {
		t.Fatalf("quick: %+v", res)
	}
}

func TestForegroundTimeoutBeforeDetach(t *testing.T) {
	env, _, _ := newJobEnv(t, 5*time.Second, 4)
	res := shell(t, env, `{"command":"sleep 5","timeout_seconds":1}`)
	if !res.IsError || !strings.Contains(res.Text, "timed out after 1s") {
		t.Fatalf("result: %+v", res)
	}
}

func TestInterruptKillsForegroundCommand(t *testing.T) {
	env, _, _ := newJobEnv(t, 5*time.Second, 4)
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	start := time.Now()
	res := Run(ctx, env, WithJobs(All()), "shell", `{"command":"sleep 5"}`)
	if !res.IsError || !strings.Contains(res.Text, "[interrupted]") || time.Since(start) > 4*time.Second {
		t.Fatalf("result: %+v after %s", res, time.Since(start))
	}
}

func TestJobWaitCancelAndLimit(t *testing.T) {
	env, js, r := newJobEnv(t, 0, 1)
	shell(t, env, `{"command":"sleep 30","background":true}`)
	if res := shell(t, env, `{"command":"sleep 30","background":true}`); !res.IsError || !strings.Contains(res.Text, "too many") {
		t.Fatalf("over the limit: %+v", res)
	}
	res := jobCall(t, env, `{"action":"wait","job_id":"job_1","timeout_seconds":1}`)
	if res.IsError || !strings.Contains(res.Text, "running for") {
		t.Fatalf("wait: %+v", res)
	}
	res = jobCall(t, env, `{"action":"cancel","job_id":"job_1"}`)
	if res.IsError || !strings.Contains(res.Text, "cancelled after") {
		t.Fatalf("cancel: %+v", res)
	}
	if j := r.wait(t); j.Outcome != JobCancelled || j.CancelledBy != "" {
		t.Fatalf("job %+v", j)
	}
	if _, err := js.Cancel("job_1", "phone"); err != ErrJobEnded {
		t.Fatalf("second cancel: %v", err)
	}
	if res := jobCall(t, env, `{"action":"status","job_id":"job_9"}`); !res.IsError {
		t.Fatalf("unknown job: %+v", res)
	}

	// A user's cancel names them; a job running out of time is timed out.
	shell(t, env, `{"command":"sleep 30","background":true}`)
	if _, err := js.Cancel("job_2", "phone"); err != nil {
		t.Fatal(err)
	}
	if j := r.wait(t); j.Outcome != JobCancelled || j.CancelledBy != "phone" {
		t.Fatalf("job %+v", j)
	}
	shell(t, env, `{"command":"sleep 30","background":true,"timeout_seconds":1}`)
	if j := r.wait(t); j.Outcome != JobTimedOut {
		t.Fatalf("job %+v", j)
	}

	// Close kills what still runs.
	shell(t, env, `{"command":"sleep 30","background":true}`)
	js.Close()
	if j := r.wait(t); j.Outcome != JobLost {
		t.Fatalf("job %+v", j)
	}
	if res := shell(t, env, `{"command":"sleep 1","background":true}`); !res.IsError {
		t.Fatalf("started after Close: %+v", res)
	}
}

func TestBackgroundNeedsJobs(t *testing.T) {
	env := &Env{Dir: t.TempDir(), Shell: config.Shell{Timeout: time.Second, MaxTimeout: time.Second, Default: "allow"}}
	res := Run(context.Background(), env, All(), "shell", `{"command":"echo hi","background":true}`)
	if !res.IsError || !strings.Contains(res.Text, "background jobs can't run here") {
		t.Fatalf("result: %+v", res)
	}
	var schema map[string]any
	for _, tool := range WithJobs(All()) {
		if tool.Name == "shell" {
			if err := json.Unmarshal([]byte(tool.Schema), &schema); err != nil {
				t.Fatal(err)
			}
		}
	}
	if _, ok := schema["properties"].(map[string]any)["background"]; !ok {
		t.Fatalf("WithJobs shell schema: %v", schema)
	}
}

func TestTailAndNotice(t *testing.T) {
	if got := tail("a\nb\nc\nd\n", 2, 100); got != "c\nd" {
		t.Fatalf("lines: %q", got)
	}
	if got := tail("aaaa\nbbbb\ncccc", 10, 7); got != "cccc" {
		t.Fatalf("bytes: %q", got)
	}
	n := NoticeText([]JobInfo{{ID: "job_1", Command: "go test ./...", Outcome: JobExited, ExitCode: 1, Duration: 3 * time.Second, Output: "FAIL x\n"}})
	if !strings.Contains(n, "job_1 (go test ./...): exited with code 1 after 3s") || !strings.Contains(n, "    FAIL x") {
		t.Fatalf("notice: %s", n)
	}
}
