package agent

import (
	"context"
	"errors"
	"fmt"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/tools"
)

// Background shell jobs (see tools.Jobs). Their start, output and end go
// to the log; when one ends the agent gets a notice: a user message,
// marked by JobNoticeDelivered, delivered like a queued message (see
// queue.go). With no turn running, a notice starts one.

// jobTailBytes is how much of a job's output JobDone keeps.
const jobTailBytes = 4 << 10

// newJobs returns the session's jobs, logging what they do. Job ids are
// numbered within the session (job_1, job_2, ...), short for the model.
func (s *session) newJobs() *tools.Jobs {
	return tools.NewJobs(tools.JobHooks{
		Started: s.jobStarted,
		Output:  s.jobOutput,
		Done:    s.jobDone,
		Seen:    s.jobsSeen,
	}, func() string {
		s.jobSeq++ // only Jobs calls this, under its lock
		return fmt.Sprintf("job_%d", s.jobSeq)
	})
}

func (s *session) jobStarted(j tools.JobInfo) {
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_JobStarted{JobStarted: &flitv1.JobStarted{
		JobId: j.ID, ToolCallId: j.ToolCallID, Command: j.Command, Workdir: j.Workdir, Detached: j.Detached,
		TimeoutMs: j.Timeout.Milliseconds(),
	}}}); err != nil {
		s.m.log.Error("could not record a background job's start", "session", s.info.ID, "err", err)
	}
}

// jobOutput logs a job's output, up to maxLiveToolOutput per job.
func (s *session) jobOutput(id, text string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	n := s.jobLive[id]
	if n >= maxLiveToolOutput {
		return
	}
	n += len(text)
	s.jobLive[id] = n
	if n >= maxLiveToolOutput {
		text += "\n[live output stopped here; the agent still sees the end of it]\n"
	}
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_JobOutput{JobOutput: &flitv1.JobOutput{
		JobId: id, Text: text,
	}}}); err != nil {
		s.m.log.Error("could not record a background job's output", "session", s.info.ID, "err", err)
	}
}

// jobDone logs a job's end and queues a notice about it, starting a turn
// for it if none is running.
func (s *session) jobDone(j tools.JobInfo) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.jobLive, j.ID)
	j.Output = j.Tail(1<<30, jobTailBytes)
	if _, err := s.appendLocked(jobDoneEvent(j)); err != nil {
		s.m.log.Error("could not record a background job's end", "session", s.info.ID, "err", err)
		return
	}
	s.notices = append(s.notices, j)
	if s.cancelTurn != nil || s.m.closing.Load() {
		return // the turn's next step (or its end) delivers it
	}
	_, msgID, err := s.deliverQueuedLocked()
	if err == nil {
		err = s.startTurnLocked(msgID)
	}
	if err != nil {
		s.m.log.Error("could not start a turn for a background job's notice", "session", s.info.ID, "err", err)
	}
}

func jobDoneEvent(j tools.JobInfo) *flitv1.Event {
	return &flitv1.Event{Payload: &flitv1.Event_JobDone{JobDone: &flitv1.JobDone{
		JobId: j.ID, Outcome: jobOutcome(j.Outcome), ExitCode: int32(j.ExitCode), Error: j.Err,
		OutputTail: j.Output, DurationMs: j.Duration.Milliseconds(), CancelledBy: j.CancelledBy,
	}}}
}

// jobsSeen drops notices about jobs the agent saw end through its job tool.
func (s *session) jobsSeen(ids []string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	var dropped []string
	kept := s.notices[:0]
	for _, n := range s.notices {
		seen := false
		for _, id := range ids {
			seen = seen || id == n.ID
		}
		if seen {
			dropped = append(dropped, n.ID)
		} else {
			kept = append(kept, n)
		}
	}
	s.notices = kept
	if len(dropped) == 0 {
		return
	}
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_JobNoticeDelivered{JobNoticeDelivered: &flitv1.JobNoticeDelivered{
		JobIds: dropped,
	}}}); err != nil {
		s.m.log.Error("could not record seen background jobs", "session", s.info.ID, "err", err)
	}
}

// deliverNoticesLocked turns the pending notices into one user message.
// It returns its first event's seq and the message id (0 and "" when there
// were none).
func (s *session) deliverNoticesLocked() (int64, string, error) {
	if len(s.notices) == 0 {
		return 0, "", nil
	}
	ids := make([]string, len(s.notices))
	for i, n := range s.notices {
		ids[i] = n.ID
	}
	msgID := newID("msg")
	ev, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_JobNoticeDelivered{JobNoticeDelivered: &flitv1.JobNoticeDelivered{
		JobIds: ids, MessageId: msgID,
	}}})
	if err != nil {
		return 0, "", err
	}
	if err := s.appendUserMessageLocked(msgID, tools.NoticeText(s.notices)); err != nil {
		return 0, "", err
	}
	s.notices = nil
	return ev.Seq, msgID, nil
}

// loadJobs rebuilds the pending notices from the log. Jobs that never
// ended there were lost when flit stopped without recording it (a crash):
// their end is recorded now.
func (s *session) loadJobs(ctx context.Context) error {
	evs, err := s.m.store.EventsOfKinds(ctx, s.info.ID, "job_started", "job_done", "job_notice_delivered")
	if err != nil {
		return err
	}
	started := map[string]*flitv1.JobStarted{}
	var order []string
	ended := map[string]tools.JobInfo{} // ended, no notice yet
	done := map[string]bool{}
	for _, ev := range evs {
		switch {
		case ev.GetJobStarted() != nil:
			st := ev.GetJobStarted()
			started[st.JobId] = st
			order = append(order, st.JobId)
			s.jobSeq++
		case ev.GetJobDone() != nil:
			d := ev.GetJobDone()
			ended[d.JobId] = jobInfo(started[d.JobId], d)
			done[d.JobId] = true
		case ev.GetJobNoticeDelivered() != nil:
			for _, id := range ev.GetJobNoticeDelivered().JobIds {
				delete(ended, id)
			}
		}
	}
	for _, id := range order {
		if j, ok := ended[id]; ok {
			s.notices = append(s.notices, j)
			continue
		}
		if done[id] {
			continue
		}
		st := started[id]
		d := &flitv1.JobDone{JobId: id, Outcome: flitv1.JobOutcome_JOB_OUTCOME_LOST, Error: "flit stopped while it ran"}
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_JobDone{JobDone: d}}); err != nil {
			return err
		}
		s.notices = append(s.notices, jobInfo(st, d))
	}
	return nil
}

// jobInfo is a job as its events tell it (st may be nil).
func jobInfo(st *flitv1.JobStarted, d *flitv1.JobDone) tools.JobInfo {
	j := tools.JobInfo{
		ID: d.JobId, ExitCode: int(d.ExitCode), Err: d.Error, Output: d.OutputTail,
		Duration: time.Duration(d.DurationMs) * time.Millisecond, CancelledBy: d.CancelledBy,
	}
	switch d.Outcome {
	case flitv1.JobOutcome_JOB_OUTCOME_EXITED:
		j.Outcome = tools.JobExited
	case flitv1.JobOutcome_JOB_OUTCOME_TIMED_OUT:
		j.Outcome = tools.JobTimedOut
	case flitv1.JobOutcome_JOB_OUTCOME_CANCELLED:
		j.Outcome = tools.JobCancelled
	case flitv1.JobOutcome_JOB_OUTCOME_LOST:
		j.Outcome = tools.JobLost
	default:
		j.Outcome = tools.JobFailed
	}
	if st != nil {
		j.ToolCallID, j.Command, j.Workdir, j.Detached = st.ToolCallId, st.Command, st.Workdir, st.Detached
		j.Timeout = time.Duration(st.TimeoutMs) * time.Millisecond
	}
	return j
}

func jobOutcome(o tools.JobOutcome) flitv1.JobOutcome {
	switch o {
	case tools.JobExited:
		return flitv1.JobOutcome_JOB_OUTCOME_EXITED
	case tools.JobFailed:
		return flitv1.JobOutcome_JOB_OUTCOME_FAILED
	case tools.JobTimedOut:
		return flitv1.JobOutcome_JOB_OUTCOME_TIMED_OUT
	case tools.JobCancelled:
		return flitv1.JobOutcome_JOB_OUTCOME_CANCELLED
	case tools.JobLost:
		return flitv1.JobOutcome_JOB_OUTCOME_LOST
	}
	return flitv1.JobOutcome_JOB_OUTCOME_UNSPECIFIED
}

// ErrJobEnded: CancelJob on a job that has already ended.
var ErrJobEnded = errors.New("the job has already ended")

// CancelJob kills a running background job of session id; client is who
// asked.
func (m *Manager) CancelJob(ctx context.Context, id, jobID, client string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	_, err = s.jobs.Cancel(jobID, client)
	switch {
	case errors.Is(err, tools.ErrJobNotFound):
		return fmt.Errorf("%w: job %s", ErrNotFound, jobID)
	case errors.Is(err, tools.ErrJobEnded):
		return fmt.Errorf("%w: %s", ErrJobEnded, jobID)
	}
	return err
}
