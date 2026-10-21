package agent

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func (h *harness) cronRun(o CronRunOptions) (string, <-chan CronOutcome) {
	h.t.Helper()
	if o.Create.WorkingDir == "" {
		o.Create.WorkingDir = h.dir
	}
	o.Create.CronID, o.Job, o.ScheduleText = "nightly", "nightly", "every day at 03:00"
	o.Create.Title = "nightly · 2026-10-21 03:00"
	if o.Prompt == "" {
		o.Prompt = "Check the build."
	}
	sess, done, err := h.m.StartCronRun(context.Background(), o)
	if err != nil {
		h.t.Fatal(err)
	}
	return sess.ID, done
}

func waitOutcome(t *testing.T, done <-chan CronOutcome) CronOutcome {
	t.Helper()
	select {
	case out := <-done:
		return out
	case <-time.After(10 * time.Second):
		t.Fatal("cron run never finished")
	}
	return CronOutcome{}
}

func TestCronRunAskDenyRefusesAndReports(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(shellCall("echo flit-was-here"), llmtest.Response{Chunks: llmtest.Text("## Build is red\n\nDetails…")})
	id, done := h.cronRun(CronRunOptions{Trigger: flitv1.CronTrigger_CRON_TRIGGER_SCHEDULE, RunID: "cron_1"})
	out := waitOutcome(t, done)
	if out.Failed || out.Final != "## Build is red\n\nDetails…" || len(out.Refused) != 1 || out.Refused[0] != "echo flit-was-here" {
		t.Fatalf("outcome %+v", out)
	}
	info, _ := h.m.Get(context.Background(), id)
	if info.CronID != "nightly" || info.Title != "nightly · 2026-10-21 03:00" {
		t.Errorf("session %+v", info)
	}
	evs := h.watch(id, 0).waitTurnEnd()
	_ = evs
	all, _ := h.st.Events(context.Background(), id, 1, 1000)
	if cr := all[0].GetCronRun(); cr == nil || cr.Job != "nightly" || cr.RunId != "cron_1" || cr.Ask != flitv1.CronAsk_CRON_ASK_DENY {
		t.Fatalf("first event %v", all[0])
	}
	user, _ := find(all, (*flitv1.Event).GetMessageDone, notNil)
	if !strings.Contains(user.Text, "unattended run of the cron job \"nightly\"") || !strings.HasSuffix(user.Text, "Check the build.") ||
		!strings.Contains(user.Text, NothingToReport) {
		t.Errorf("prompt %q", user.Text)
	}
	res, _ := find(all, (*flitv1.Event).GetPromptResolved, notNil)
	if res.Decision != flitv1.PromptDecision_PROMPT_DECISION_DENY || !strings.Contains(res.Reason, "ask: deny") {
		t.Errorf("resolved %+v", res)
	}
	if _, ok := find(all, (*flitv1.Event).GetTaskStateChanged, func(s *flitv1.TaskStateChanged) bool {
		return s != nil && s.State == flitv1.TaskState_TASK_STATE_WAITING
	}); ok {
		t.Error("ask: deny should never wait")
	}
	tool, _ := find(all, (*flitv1.Event).GetToolCallDone, notNil)
	if !tool.IsError || !strings.Contains(tool.Result, "unattended run") || strings.Contains(tool.Result, "flit-was-here\n") {
		t.Errorf("tool result %+v", tool)
	}

	// Later turns in the session are ordinary: prompts ask again.
	h.llm.Push(shellCall("echo again"), llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(id, info.LastSeq+1)
	if _, err := h.m.Send(context.Background(), id, "try again"); err != nil {
		t.Fatal(err)
	}
	w.waitState(flitv1.TaskState_TASK_STATE_WAITING)
	if _, err := h.m.Interrupt(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
}

func TestCronRunYoloRunsCommands(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(shellCall("echo flit-was-here"), llmtest.Response{Chunks: llmtest.Text("nothing to report")})
	yolo := true
	_, done := h.cronRun(CronRunOptions{Create: CreateOptions{Yolo: &yolo}})
	if out := waitOutcome(t, done); out.Failed || len(out.Refused) != 0 || out.Final != "nothing to report" {
		t.Fatalf("outcome %+v", out)
	}
	// Deny rules still win.
	h.mu.Lock()
	h.cfg.Shell.Deny = []string{"echo *"}
	h.mu.Unlock()
	h.llm.Push(shellCall("echo no"), llmtest.Response{Chunks: llmtest.Text("done")})
	_, done = h.cronRun(CronRunOptions{Create: CreateOptions{Yolo: &yolo}})
	if out := waitOutcome(t, done); len(out.Refused) != 0 {
		t.Fatalf("deny rule counted as refused-for-approval: %+v", out)
	}
	if res := h.llm.Requests()[3].Messages; !strings.Contains(res[len(res)-1].Content, "denied by flit's shell rules") {
		t.Errorf("deny result: %+v", res[len(res)-1])
	}
}

func TestCronRunAskWait(t *testing.T) {
	t.Run("timeout", func(t *testing.T) {
		h := newHarness(t)
		h.llm.Push(shellCall("echo flit-was-here"), llmtest.Response{Chunks: llmtest.Text("Could not run echo")})
		id, done := h.cronRun(CronRunOptions{Wait: true, AskTimeout: 300 * time.Millisecond})
		out := waitOutcome(t, done)
		if out.Failed || len(out.Refused) != 1 {
			t.Fatalf("outcome %+v", out)
		}
		all, _ := h.st.Events(context.Background(), id, 1, 1000)
		res, _ := find(all, (*flitv1.Event).GetPromptResolved, notNil)
		if res.Decision != flitv1.PromptDecision_PROMPT_DECISION_DENY || !strings.Contains(res.Reason, "no answer within 300ms") {
			t.Errorf("resolved %+v", res)
		}
		if _, ok := find(all, (*flitv1.Event).GetTaskStateChanged, func(s *flitv1.TaskStateChanged) bool {
			return s != nil && s.State == flitv1.TaskState_TASK_STATE_WAITING
		}); !ok {
			t.Error("ask: wait should show the session waiting")
		}
	})
	t.Run("answered", func(t *testing.T) {
		h := newHarness(t)
		h.llm.Push(shellCall("echo flit-was-here"), llmtest.Response{Chunks: llmtest.Text("Ran it")})
		id, done := h.cronRun(CronRunOptions{Wait: true, AskTimeout: time.Minute})
		w := h.watch(id, 0)
		req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
		if err := h.m.AnswerPrompt(context.Background(), id, req.PromptId, Answer{Allow: true, Client: "phone"}); err != nil {
			t.Fatal(err)
		}
		if out := waitOutcome(t, done); out.Failed || len(out.Refused) != 0 || out.Final != "Ran it" {
			t.Fatalf("outcome %+v", out)
		}
	})
}

func TestCronRunFailsAndInterrupts(t *testing.T) {
	h := newHarness(t)
	h.llm.Push(llmtest.Response{Status: 400, Body: `{"error":{"message":"bad model"}}`})
	_, done := h.cronRun(CronRunOptions{})
	if out := waitOutcome(t, done); !out.Failed || out.Reason == "" {
		t.Fatalf("outcome %+v", out)
	}
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("working"), Hang: true})
	id, done := h.cronRun(CronRunOptions{})
	h.watch(id, 0).waitFor("text", func(ev *flitv1.Event) bool { return ev.GetTextDelta() != nil && ev.GetTextDelta().Text == "working" })
	if _, err := h.m.Interrupt(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	if out := waitOutcome(t, done); !out.Failed || out.Reason != "interrupted" {
		t.Fatalf("outcome %+v", out)
	}
}

func TestCronRunModelOrder(t *testing.T) {
	h := newHarness(t)
	rolesDir := t.TempDir()
	h.m.RolesDir = func() string { return rolesDir }
	if err := os.WriteFile(filepath.Join(rolesDir, "qa.md"), []byte("---\nprovider: fake\nmodel: role-model\n---\nBe careful."), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(rolesDir, "plain.md"), []byte("Be plain."), 0o644); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name   string
		create CreateOptions
		cron   bool
		want   string
	}{
		{"chat default", CreateOptions{}, false, "fake/test-model"},
		{"tasks.cron", CreateOptions{}, true, "other/cron-model"},
		{"role over tasks.cron", CreateOptions{Role: "qa"}, true, "fake/role-model"},
		{"role without a model", CreateOptions{Role: "plain"}, true, "other/cron-model"},
		{"job over everything", CreateOptions{Role: "qa", Provider: "other", Model: "job-model"}, true, "other/job-model"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h.mu.Lock()
			h.cfg.Agent.Tasks = map[string]config.TaskModel{}
			if tc.cron {
				h.cfg.Agent.Tasks["cron"] = config.TaskModel{Provider: "other", Model: "cron-model", Effort: "low"}
			}
			h.mu.Unlock()
			h.llm.Push(llmtest.Response{Chunks: llmtest.Text("nothing to report")})
			id, done := h.cronRun(CronRunOptions{Create: tc.create})
			waitOutcome(t, done)
			info, _ := h.m.Get(context.Background(), id)
			if got := info.Provider + "/" + info.Model; got != tc.want {
				t.Errorf("model %s, want %s", got, tc.want)
			}
		})
	}
}

// fakeCrons is a CronControl over a directory.
type fakeCrons struct {
	dir     string
	rescans int
	ran     []string
}

func (f *fakeCrons) Dir() string { return f.dir }
func (f *fakeCrons) Describe(context.Context) (string, error) {
	return "Cron jobs: (fake)", nil
}
func (f *fakeCrons) RunNow(_ context.Context, name string) (string, error) {
	f.ran = append(f.ran, name)
	return "ses_x", nil
}
func (f *fakeCrons) Rescan() { f.rescans++ }

func cronCall(args string) llmtest.Response {
	return llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "cron", args})}
}

func TestCronToolAlwaysAsks(t *testing.T) {
	h := newHarness(t)
	crons := &fakeCrons{dir: filepath.Join(t.TempDir(), "crons")}
	h.m.Crons = crons
	yolo := true
	sess, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Yolo: &yolo})
	if err != nil {
		t.Fatal(err)
	}
	run := func(args string, answer *bool) *flitv1.ToolCallDone {
		t.Helper()
		h.llm.Push(cronCall(args), llmtest.Response{Chunks: llmtest.Text("ok")})
		info, _ := h.m.Get(context.Background(), sess.ID)
		w := h.watch(sess.ID, info.LastSeq+1)
		if _, err := h.m.Send(context.Background(), sess.ID, "do it"); err != nil {
			t.Fatal(err)
		}
		if answer != nil {
			req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
			if !strings.Contains(req.Title, "cron job morning") {
				t.Errorf("prompt title %q", req.Title)
			}
			if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: *answer}); err != nil {
				t.Fatal(err)
			}
		}
		w.waitTurnEnd()
		done, _ := find(w.snapshot(), (*flitv1.Event).GetToolCallDone, notNil)
		if _, asked := find(w.snapshot(), (*flitv1.Event).GetPromptRequested, notNil); asked != (answer != nil) {
			t.Fatalf("asked = %v, want %v", asked, answer != nil)
		}
		return done
	}
	no, yes := false, true

	// Invalid jobs are refused without asking.
	if r := run(`{"action":"create","name":"morning","schedule":"whenever","prompt":"x"}`, nil); !r.IsError || !strings.Contains(r.Result, "can't read schedule") {
		t.Fatalf("invalid: %+v", r)
	}
	// Declined: nothing written, even in yolo mode.
	if r := run(`{"action":"create","name":"morning","schedule":"weekdays at 8:30","prompt":"Check CI."}`, &no); !r.IsError {
		t.Fatalf("declined: %+v", r)
	}
	if _, err := os.Stat(filepath.Join(crons.dir, "morning.md")); !os.IsNotExist(err) {
		t.Fatal("job written though declined")
	}
	if r := run(`{"action":"create","name":"morning","schedule":"weekdays at 8:30","prompt":"Check CI.","ask":"wait"}`, &yes); r.IsError ||
		!strings.Contains(r.Result, "weekdays at 08:30") {
		t.Fatalf("created: %+v", r)
	}
	j := cron.Load(filepath.Join(crons.dir, "morning.md"))
	if j.Err != nil || j.Schedule != "weekdays at 8:30" || j.Prompt != "Check CI." || j.Ask != cron.AskWait {
		t.Fatalf("job file: %+v", j)
	}
	// Edit keeps what isn't given; "in 20m" is pinned to a time.
	if r := run(`{"action":"edit","name":"morning","schedule":"in 20m"}`, &yes); r.IsError {
		t.Fatalf("edit: %+v", r)
	}
	j = cron.Load(filepath.Join(crons.dir, "morning.md"))
	if !strings.HasPrefix(j.Schedule, "at ") || j.Prompt != "Check CI." || j.Ask != cron.AskWait || !j.Sched.OneShot() {
		t.Fatalf("edited: %+v", j)
	}
	if r := run(`{"action":"run","name":"morning"}`, nil); r.IsError || len(crons.ran) != 1 {
		t.Fatalf("run: %+v", r)
	}
	if r := run(`{"action":"list"}`, nil); r.Result != "Cron jobs: (fake)" {
		t.Fatalf("list: %+v", r)
	}
	if r := run(`{"action":"remove","name":"morning"}`, &yes); r.IsError {
		t.Fatalf("remove: %+v", r)
	}
	if _, err := os.Stat(filepath.Join(crons.dir, "morning.md")); !os.IsNotExist(err) {
		t.Fatal("job not removed")
	}
	if crons.rescans != 3 {
		t.Errorf("rescans = %d, want 3", crons.rescans)
	}
}
