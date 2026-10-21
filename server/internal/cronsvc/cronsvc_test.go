package cronsvc

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"path/filepath"
	"testing"
	"time"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/scheduler"
	"github.com/iggy/flit/server/internal/store"
)

func TestCronService(t *testing.T) {
	llm := llmtest.New(t)
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "fake", BaseURL: llm.BaseURL()}}
	cfg.Agent.Provider, cfg.Agent.Model = "fake", "m"
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	m, err := agent.NewManager(context.Background(), st, func() config.Config { return cfg }, log)
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	s := &scheduler.Scheduler{M: m, Store: st, CronsDir: func() string { return dir }, DataDir: t.TempDir(), Log: log}
	ctx, cancel := context.WithCancel(context.Background())
	t.Cleanup(func() {
		cancel()
		m.Close()
		s.Wait()
		st.Close()
	})
	if err := s.Start(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := cron.Write(dir, "morning", []byte("---\nschedule: weekdays at 8:30\nask: wait\ntimezone: Europe/Berlin\n---\nCheck CI.\n")); err != nil {
		t.Fatal(err)
	}
	if _, err := cron.Write(dir, "broken", []byte("---\nschedule: whenever\n---\nx\n")); err != nil {
		t.Fatal(err)
	}
	svc := &Service{S: s}

	list, err := svc.ListCronJobs(ctx, connect.NewRequest(&flitv1.ListCronJobsRequest{}))
	if err != nil {
		t.Fatal(err)
	}
	jobs := list.Msg.Jobs
	if len(jobs) != 2 || list.Msg.Dir != dir {
		t.Fatalf("jobs %v", jobs)
	}
	if b := jobs[0]; b.Name != "broken" || b.Error == "" || b.NextRunTime != nil {
		t.Errorf("broken %v", b)
	}
	if j := jobs[1]; j.ScheduleText != "weekdays at 08:30" || j.Ask != flitv1.CronAsk_CRON_ASK_WAIT || j.AskTimeoutSeconds != 3600 ||
		j.Timezone != "Europe/Berlin" || j.NextRunTime == nil || j.ProjectName != store.DefaultProjectName || j.Prompt != "Check CI." || !j.Enabled {
		t.Errorf("morning %v", j)
	}

	off, err := svc.SetCronJobEnabled(ctx, connect.NewRequest(&flitv1.SetCronJobEnabledRequest{Name: "morning", Enabled: false}))
	if err != nil {
		t.Fatal(err)
	}
	if off.Msg.Job.Enabled || off.Msg.Job.NextRunTime != nil {
		t.Errorf("disabled %v", off.Msg.Job)
	}

	llm.Push(llmtest.Response{Chunks: llmtest.Text("CI is green.")})
	run, err := svc.RunCronJob(ctx, connect.NewRequest(&flitv1.RunCronJobRequest{Name: "morning"}))
	if err != nil {
		t.Fatal(err)
	}
	if r := run.Msg.Run; r.SessionId == "" || r.Trigger != flitv1.CronTrigger_CRON_TRIGGER_MANUAL {
		t.Fatalf("run %v", r)
	}
	deadline := time.Now().Add(10 * time.Second)
	for {
		runs, err := svc.ListCronRuns(ctx, connect.NewRequest(&flitv1.ListCronRunsRequest{Name: "morning"}))
		if err != nil {
			t.Fatal(err)
		}
		if r := runs.Msg.Runs[0]; r.State == flitv1.CronRunState_CRON_RUN_STATE_OK {
			if r.Summary != "CI is green." || r.FinishTime == nil {
				t.Fatalf("run %v", r)
			}
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("run never finished")
		}
		time.Sleep(10 * time.Millisecond)
	}
	got, err := svc.GetCronJob(ctx, connect.NewRequest(&flitv1.GetCronJobRequest{Name: "morning"}))
	if err != nil || got.Msg.Job.LastRun.GetSummary() != "CI is green." {
		t.Fatalf("get %v %v", got, err)
	}

	for _, err := range []error{
		func() error {
			_, err := svc.GetCronJob(ctx, connect.NewRequest(&flitv1.GetCronJobRequest{Name: "nope"}))
			return err
		}(),
		func() error {
			_, err := svc.RunCronJob(ctx, connect.NewRequest(&flitv1.RunCronJobRequest{Name: "broken"}))
			return err
		}(),
		func() error {
			_, err := svc.RunCronJob(ctx, connect.NewRequest(&flitv1.RunCronJobRequest{}))
			return err
		}(),
	} {
		var ce *connect.Error
		if !errors.As(err, &ce) || ce.Code() == connect.CodeInternal {
			t.Errorf("error %v", err)
		}
	}
}
