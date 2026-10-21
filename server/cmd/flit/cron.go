package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"strings"
	"text/tabwriter"
	"time"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/auth"
)

const cronUsage = `Usage:
  flit cron list [flags]          list cron jobs: schedule, next run, last run
  flit cron run [flags] NAME      run a job now and wait for it to finish

Both talk to the running "flit serve" on this machine. Jobs are files in
crons_dir (see docs/cron.md).

Flags:
`

// cronClient returns a CronService client for the server on this machine.
func cronClient(configPath, dataDirFlag string) (flitv1connect.CronServiceClient, error) {
	cfg, err := loadConfig(configPath)
	if err != nil {
		return nil, err
	}
	dataDir, err := resolveDataDir(dataDirFlag, cfg)
	if err != nil {
		return nil, err
	}
	token, err := auth.ReadToken(dataDir)
	if err != nil {
		return nil, fmt.Errorf("read admin token from %s: %w (is this the machine running \"flit serve\"?)", dataDir, err)
	}
	base, hc := localURL(cfg)
	return flitv1connect.NewCronServiceClient(hc, base, connect.WithInterceptors(bearerInterceptor(token))), nil
}

func cronCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	if len(args) == 0 || (args[0] != "list" && args[0] != "run") {
		fmt.Fprint(stderr, cronUsage)
		return errors.New("usage: flit cron list | flit cron run NAME")
	}
	fs := flag.NewFlagSet("cron "+args[0], flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, cronUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDir := fs.String("data-dir", "", "data directory")
	noWait := fs.Bool("no-wait", false, "run: return once the run has started")
	// Flags may come before or after the job name.
	var names []string
	for rest := args[1:]; ; {
		if err := fs.Parse(rest); err != nil {
			return err
		}
		if fs.NArg() == 0 {
			break
		}
		names = append(names, fs.Arg(0))
		rest = fs.Args()[1:]
	}
	c, err := cronClient(*configPath, *dataDir)
	if err != nil {
		return err
	}
	if args[0] == "list" {
		if len(names) != 0 {
			return errors.New("usage: flit cron list")
		}
		return cronList(ctx, stdout, c)
	}
	if len(names) != 1 {
		return errors.New("usage: flit cron run NAME")
	}
	return cronRun(ctx, stdout, c, names[0], !*noWait)
}

func cronList(ctx context.Context, w io.Writer, c flitv1connect.CronServiceClient) error {
	res, err := c.ListCronJobs(ctx, connect.NewRequest(&flitv1.ListCronJobsRequest{}))
	if err != nil {
		return err
	}
	if len(res.Msg.Jobs) == 0 {
		fmt.Fprintf(w, "No cron jobs. Add one as a .md file in %s (see docs/cron.md).\n", res.Msg.Dir)
		return nil
	}
	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	fmt.Fprintln(tw, "NAME\tSCHEDULE\tNEXT RUN\tLAST RUN")
	for _, j := range res.Msg.Jobs {
		sched, next, last := j.ScheduleText, "-", "-"
		switch {
		case j.Error != "":
			sched, next = "error: "+j.Error, "never"
		case !j.Enabled:
			next = "disabled"
		case j.NextRunTime != nil:
			next = j.NextRunTime.AsTime().Local().Format("2006-01-02 15:04")
		}
		if j.RunningSessionId != "" {
			last = "running now (session " + j.RunningSessionId + ")"
		} else if r := j.LastRun; r != nil {
			last = fmt.Sprintf("%s %s: %s", r.StartTime.AsTime().Local().Format("01-02 15:04"), runState(r.State), r.Summary)
		}
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\n", j.Name, sched, next, last)
	}
	fmt.Fprintf(tw, "\n(jobs in %s)\n", res.Msg.Dir)
	return tw.Flush()
}

func runState(s flitv1.CronRunState) string {
	return strings.ToLower(strings.TrimPrefix(s.String(), "CRON_RUN_STATE_"))
}

func cronRun(ctx context.Context, w io.Writer, c flitv1connect.CronServiceClient, name string, wait bool) error {
	res, err := c.RunCronJob(ctx, connect.NewRequest(&flitv1.RunCronJobRequest{Name: name}))
	if err != nil {
		return err
	}
	run := res.Msg.Run
	fmt.Fprintf(w, "Started %s (session %s).\n", name, run.SessionId)
	if !wait {
		return nil
	}
	for run.State == flitv1.CronRunState_CRON_RUN_STATE_RUNNING {
		select {
		case <-ctx.Done():
			fmt.Fprintln(w, "Stopped waiting; the run goes on.")
			return nil
		case <-time.After(2 * time.Second):
		}
		runs, err := c.ListCronRuns(ctx, connect.NewRequest(&flitv1.ListCronRunsRequest{Name: name, PageSize: 20}))
		if err != nil {
			return err
		}
		for _, r := range runs.Msg.Runs {
			if r.Id == run.Id {
				run = r
			}
		}
	}
	fmt.Fprintf(w, "%s: %s\n", runState(run.State), run.Summary)
	for _, cmd := range run.RefusedCommands {
		fmt.Fprintf(w, "  refused: %s\n", cmd)
	}
	if run.State == flitv1.CronRunState_CRON_RUN_STATE_FAILED {
		return errors.New("the run failed")
	}
	return nil
}
