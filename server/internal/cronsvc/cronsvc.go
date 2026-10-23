// Package cronsvc implements flit.v1.CronService on top of the scheduler.
package cronsvc

import (
	"context"
	"errors"
	"strconv"
	"time"

	"connectrpc.com/connect/v2"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/scheduler"
	"github.com/iggy/flit/server/internal/store"
)

const (
	defaultPageSize = 50
	maxPageSize     = 200
)

// Service implements flitv1connect.CronServiceHandler.
type Service struct {
	S *scheduler.Scheduler
}

var _ flitv1connect.CronServiceHandler = (*Service)(nil)

func connectErr(err error) error {
	code := connect.CodeInternal
	switch {
	case errors.Is(err, scheduler.ErrNotFound):
		code = connect.CodeNotFound
	case errors.Is(err, scheduler.ErrRunning), errors.Is(err, scheduler.ErrBroken):
		code = connect.CodeFailedPrecondition
	case errors.Is(err, agent.ErrInvalid):
		code = connect.CodeInvalidArgument
	}
	return connect.NewError(code, err.Error())
}

func ts(t time.Time) *timestamppb.Timestamp {
	if t.IsZero() {
		return nil
	}
	return timestamppb.New(t)
}

// RunProto converts a run.
func RunProto(r store.CronRun) *flitv1.CronRun {
	state := map[string]flitv1.CronRunState{
		store.CronRunning:        flitv1.CronRunState_CRON_RUN_STATE_RUNNING,
		store.CronOK:             flitv1.CronRunState_CRON_RUN_STATE_OK,
		store.CronNeedsAttention: flitv1.CronRunState_CRON_RUN_STATE_NEEDS_ATTENTION,
		store.CronFailed:         flitv1.CronRunState_CRON_RUN_STATE_FAILED,
		store.CronSkipped:        flitv1.CronRunState_CRON_RUN_STATE_SKIPPED,
	}[r.State]
	trigger := map[string]flitv1.CronTrigger{
		store.CronCauseSchedule: flitv1.CronTrigger_CRON_TRIGGER_SCHEDULE,
		store.CronCauseCatchUp:  flitv1.CronTrigger_CRON_TRIGGER_CATCH_UP,
		store.CronCauseManual:   flitv1.CronTrigger_CRON_TRIGGER_MANUAL,
	}[r.Cause]
	return &flitv1.CronRun{
		Id: r.ID, Job: r.Job, SessionId: r.SessionID, State: state, Trigger: trigger,
		ScheduledTime: ts(r.ScheduledAt), StartTime: ts(r.StartedAt), FinishTime: ts(r.FinishedAt),
		Summary: r.Summary, RefusedCommands: r.Refused, Quiet: r.Quiet,
	}
}

// JobProto converts a job's status.
func JobProto(st scheduler.JobStatus) *flitv1.CronJob {
	j := st.Job
	p := &flitv1.CronJob{
		Name: j.Name, Schedule: j.Schedule, Enabled: j.IsEnabled(), Dir: j.Dir, Role: j.Role,
		Provider: j.Model.Provider, Model: j.Model.Model, Effort: j.Model.Effort, Yolo: j.Yolo, Timezone: j.Timezone,
		Prompt: j.Prompt, Path: j.Path, NextRunTime: ts(st.Next),
		AskTimeoutSeconds: int64(j.AskWaitFor() / time.Second),
		ProjectId:         st.Project.ID, ProjectName: st.Project.Name,
		Ask: flitv1.CronAsk_CRON_ASK_DENY,
	}
	if j.Ask == cron.AskWait {
		p.Ask = flitv1.CronAsk_CRON_ASK_WAIT
	}
	if j.Loc != nil && p.Timezone == "" {
		p.Timezone = j.Loc.String()
		if p.Timezone == "Local" {
			p.Timezone = localZone()
		}
	}
	if j.Sched != nil {
		p.ScheduleText, p.OneShot = j.Sched.Words(), j.Sched.OneShot()
	}
	switch {
	case j.Err != nil:
		p.Error = j.Err.Error()
	case st.ProjectErr != nil:
		p.Error = st.ProjectErr.Error()
	}
	if st.Last != nil {
		p.LastRun = RunProto(*st.Last)
	}
	if st.Running != nil {
		p.RunningSessionId = st.Running.SessionID
	}
	return p
}

// localZone names the server's time zone (its abbreviation).
func localZone() string {
	name, _ := time.Now().Zone()
	return name
}

func required(name, v string) error {
	if v == "" {
		return connect.NewError(connect.CodeInvalidArgument, errors.New(name+" is required").Error())
	}
	return nil
}

// ListCronJobs implements flitv1connect.CronServiceHandler.
func (s *Service) ListCronJobs(ctx context.Context, _ *flitv1.ListCronJobsRequest) (*flitv1.ListCronJobsResponse, error) {
	list, err := s.S.Jobs(ctx)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListCronJobsResponse{Dir: s.S.Dir()}
	for _, st := range list {
		res.Jobs = append(res.Jobs, JobProto(st))
	}
	return res, nil
}

// GetCronJob implements flitv1connect.CronServiceHandler.
func (s *Service) GetCronJob(ctx context.Context, req *flitv1.GetCronJobRequest) (*flitv1.GetCronJobResponse, error) {
	if err := required("name", req.Name); err != nil {
		return nil, err
	}
	st, err := s.S.Job(ctx, req.Name)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.GetCronJobResponse{Job: JobProto(st)}, nil
}

// RunCronJob implements flitv1connect.CronServiceHandler.
func (s *Service) RunCronJob(ctx context.Context, req *flitv1.RunCronJobRequest) (*flitv1.RunCronJobResponse, error) {
	if err := required("name", req.Name); err != nil {
		return nil, err
	}
	run, err := s.S.Run(ctx, req.Name)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.RunCronJobResponse{Run: RunProto(run)}, nil
}

// SetCronJobEnabled implements flitv1connect.CronServiceHandler.
func (s *Service) SetCronJobEnabled(ctx context.Context, req *flitv1.SetCronJobEnabledRequest) (*flitv1.SetCronJobEnabledResponse, error) {
	if err := required("name", req.Name); err != nil {
		return nil, err
	}
	st, err := s.S.SetEnabled(ctx, req.Name, req.Enabled)
	if err != nil {
		return nil, connectErr(err)
	}
	return &flitv1.SetCronJobEnabledResponse{Job: JobProto(st)}, nil
}

// ListCronRuns implements flitv1connect.CronServiceHandler.
func (s *Service) ListCronRuns(ctx context.Context, req *flitv1.ListCronRunsRequest) (*flitv1.ListCronRunsResponse, error) {
	size := int(req.PageSize)
	if size <= 0 {
		size = defaultPageSize
	}
	size = min(size, maxPageSize)
	offset := 0
	if t := req.PageToken; t != "" {
		n, err := strconv.Atoi(t)
		if err != nil || n < 0 {
			return nil, connect.NewError(connect.CodeInvalidArgument, errors.New("bad page_token").Error())
		}
		offset = n
	}
	runs, err := s.S.Runs(ctx, req.Name, size+1, offset)
	if err != nil {
		return nil, connectErr(err)
	}
	res := &flitv1.ListCronRunsResponse{}
	if len(runs) > size {
		runs = runs[:size]
		res.NextPageToken = strconv.Itoa(offset + size)
	}
	for _, r := range runs {
		res.Runs = append(res.Runs, RunProto(r))
	}
	return res, nil
}
