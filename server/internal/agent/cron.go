package agent

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// CronRunOptions start an unattended run of a cron job (see package cron
// and package scheduler).
type CronRunOptions struct {
	// Create makes the run's session; its CronID and Title are set by the
	// caller.
	Create CreateOptions
	// Job, Schedule and ScheduleText describe the job, for the CronRun
	// event and the prompt's preamble.
	Job, Schedule, ScheduleText string
	Trigger                     flitv1.CronTrigger
	ScheduledAt                 time.Time
	RunID                       string
	// Wait holds prompts nobody answers for AskTimeout and then refuses
	// them; otherwise they are refused at once.
	Wait       bool
	AskTimeout time.Duration
	// Prompt is the job's prompt; the unattended preamble is added.
	Prompt string
}

// CronOutcome is how an unattended run's turn ended.
type CronOutcome struct {
	// Failed is set when the turn ended stuck (an error) or was
	// interrupted; Reason says why.
	Failed bool
	Reason string
	// Final is the last reply's text.
	Final string
	// Refused are what nobody could approve: shell commands, cron job
	// changes.
	Refused []string
}

// maxSummary caps a run's summary.
const maxSummary = 300

// Result is how a run is recorded: its state (store.CronOK,
// CronNeedsAttention or CronFailed), its summary (the first line of the
// final reply, or why it failed) and whether it had nothing to report.
func (o CronOutcome) Result() (state, summary string, quiet bool) {
	first := firstLine(o.Final)
	switch {
	case o.Failed:
		state, summary = store.CronFailed, o.Reason
		if first != "" {
			summary = o.Reason + ": " + first
		}
	case len(o.Refused) > 0:
		state, summary = store.CronNeedsAttention, first
	default:
		state, summary = store.CronOK, first
		quiet = isNothing(first)
	}
	if summary == "" {
		summary = "(no report)"
	}
	if utf8.RuneCountInString(summary) > maxSummary {
		summary = string([]rune(summary)[:maxSummary-1]) + "…"
	}
	return state, summary, quiet
}

// firstLine is the first non-empty line of a reply, without Markdown
// heading, list, quote or bold markers.
func firstLine(text string) string {
	for _, line := range strings.Split(text, "\n") {
		line = strings.NewReplacer("**", "", "__", "").Replace(line)
		line = strings.TrimSpace(strings.TrimLeft(strings.TrimSpace(line), "#>*- "))
		if line != "" {
			return line
		}
	}
	return ""
}

// isNothing reports whether a summary says there is nothing to report.
func isNothing(summary string) bool {
	s := strings.ToLower(strings.Trim(strings.TrimSpace(summary), ".!*_\"'` "))
	return s == NothingToReport
}

// unattended is a cron run's turn in progress.
type unattended struct {
	wait    bool
	timeout time.Duration
	refused []string
	final   string
	done    chan CronOutcome
}

// CronControl is what the cron tool needs from the scheduler.
type CronControl interface {
	// Dir is the crons directory.
	Dir() string
	// Describe lists the jobs for the model: schedule, next run, last run.
	Describe(ctx context.Context) (string, error)
	// RunNow starts a run of job name and returns its session id.
	RunNow(ctx context.Context, name string) (string, error)
	// Rescan rereads the crons directory now.
	Rescan()
}

// NothingToReport is what a run replies when there's nothing to report.
const NothingToReport = "nothing to report"

func cronPreamble(o CronRunOptions) string {
	approval := "Commands that need approval are refused, so don't count on them."
	if o.Wait {
		approval = fmt.Sprintf("Commands that need approval wait up to %s for someone to answer and are refused if nobody does.", o.AskTimeout)
	}
	return fmt.Sprintf(`This is an unattended run of the cron job %q (%s). Nobody is watching: no one can answer questions while it runs. %s If something you need is refused, carry on without it if you can and mention it in your report.

When you're done, finish with a short report of what you found or did. Its first line should sum it up: it is shown in lists and notifications. If there is nothing worth reporting, reply with exactly "%s".

The task:

%s`, o.Job, o.ScheduleText, approval, NothingToReport, strings.TrimSpace(o.Prompt))
}

// StartCronRun creates the run's session, records the CronRun event and the
// prompt, and starts the turn unattended. The outcome arrives on the channel
// when the turn ends.
func (m *Manager) StartCronRun(ctx context.Context, o CronRunOptions) (store.Session, <-chan CronOutcome, error) {
	ask := flitv1.CronAsk_CRON_ASK_DENY
	if o.Wait {
		ask = flitv1.CronAsk_CRON_ASK_WAIT
	}
	return m.startUnattended(ctx, unattendedStart{
		create: o.Create, tasks: []string{"cron"}, wait: o.Wait, timeout: o.AskTimeout, prompt: cronPreamble(o), client: "cron",
		opening: func(yolo bool) *flitv1.Event {
			return &flitv1.Event{Payload: &flitv1.Event_CronRun{CronRun: &flitv1.CronRunStarted{
				Job: o.Job, Schedule: o.Schedule, ScheduleText: o.ScheduleText, Trigger: o.Trigger,
				ScheduledTime: timestamppb.New(o.ScheduledAt), RunId: o.RunID, Ask: ask,
				AskTimeoutSeconds: int64(o.AskTimeout / time.Second), Yolo: yolo,
			}}}
		},
	})
}

// unattendedStart is how startUnattended starts a run.
type unattendedStart struct {
	create CreateOptions
	// tasks are the agent.tasks entries to try, in order, for the model
	// when neither the run nor its role picks one.
	tasks   []string
	wait    bool
	timeout time.Duration
	prompt  string
	client  string
	opening func(yolo bool) *flitv1.Event
}

// startUnattended creates a run's session, records its opening event and
// the prompt, and starts the turn unattended (see approveUnattended).
func (m *Manager) startUnattended(ctx context.Context, o unattendedStart) (store.Session, <-chan CronOutcome, error) {
	if m.closing.Load() {
		return store.Session{}, nil, errors.New("flit is shutting down")
	}
	// The model: the run's, else its role's, else the task's, else the
	// chat default (Create does the last two's fallbacks).
	if o.create.Provider == "" {
		role, err := m.role(o.create.Role)
		if err != nil {
			return store.Session{}, nil, err
		}
		for _, task := range o.tasks {
			t, ok := m.cfg().Task(task)
			if !ok || (role != nil && role.Provider != "") {
				continue
			}
			o.create.Provider, o.create.Model = t.Provider, t.Model
			if o.create.Effort == "" && (role == nil || role.Effort == "") {
				o.create.Effort = t.Effort
			}
			break
		}
	}
	info, err := m.Create(ctx, o.create)
	if err != nil {
		return store.Session{}, nil, err
	}
	s, err := m.session(ctx, info.ID)
	if err != nil {
		return store.Session{}, nil, err
	}
	u := &unattended{wait: o.wait, timeout: o.timeout, done: make(chan CronOutcome, 1)}
	s.mu.Lock()
	s.unattended = u
	_, err = s.appendLocked(o.opening(s.info.Yolo))
	s.mu.Unlock()
	if err == nil {
		_, err = s.send(o.prompt, o.client)
	}
	if err != nil {
		s.mu.Lock()
		s.unattended = nil
		s.mu.Unlock()
		return info, nil, err
	}
	return s.snapshot(), u.done, nil
}

// ArchiveCronSessions archives the sessions of job's runs beyond the
// newest keep (they leave the session list; nothing is deleted). It returns
// how many it archived.
func (m *Manager) ArchiveCronSessions(ctx context.Context, job string, keep int) (int, error) {
	ids, err := m.store.ArchiveCronSessions(ctx, store.DefaultTeamID, job, keep)
	return m.archived(ctx, ids, err)
}

// archived updates live sessions the store just archived and removes their
// worktrees.
func (m *Manager) archived(ctx context.Context, ids []string, err error) (int, error) {
	m.mu.Lock()
	for _, id := range ids {
		if s, ok := m.sessions[id]; ok {
			s.mu.Lock()
			s.info.Archived = true
			s.mu.Unlock()
		}
	}
	m.mu.Unlock()
	// An archived session's worktree goes too, unless work would be lost.
	for _, id := range ids {
		if err := m.cleanUpWorktree(ctx, id); err != nil {
			m.log.Warn("remove worktree", "session", id, "err", err)
		}
	}
	return len(ids), err
}

// noteFinal records the turn's last reply for an unattended run.
func (s *session) noteFinal(text string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.unattended != nil {
		s.unattended.final = text
	}
}

// finishUnattendedLocked reports how an unattended run's turn ended.
func (s *session) finishUnattendedLocked(e end) {
	u := s.unattended
	if u == nil {
		return
	}
	s.unattended = nil
	out := CronOutcome{Final: u.final, Refused: u.refused}
	switch {
	case e == endInterrupted:
		out.Failed, out.Reason = true, "interrupted"
	case e.state != flitv1.TaskState_TASK_STATE_DONE:
		out.Failed, out.Reason = true, e.reason
	}
	u.done <- out // buffered; sent once
}

// unattendedRefusal is the tool result for something refused in an
// unattended run.
var errUnattended = fmt.Errorf("%w: this is an unattended run (a cron job or webhook) and nobody approved it, so it was not done. "+
	"Don't retry it; carry on without it if you can, and mention it in your report", tools.ErrNotApproved)

// approveUnattended handles a prompt in an unattended run: refused at once
// (ask: deny), or held until answered or the timeout (ask: wait). handled
// is false when the session isn't running unattended.
func (s *session) approveUnattended(ctx context.Context, toolCallID string, a tools.Approval) (ok, handled bool, err error) {
	s.mu.Lock()
	u := s.unattended
	s.mu.Unlock()
	if u == nil {
		return false, false, nil
	}
	refuse := func(promptID, reason string) error {
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptResolved{PromptResolved: &flitv1.PromptResolved{
			PromptId: promptID, Decision: flitv1.PromptDecision_PROMPT_DECISION_DENY, Reason: reason,
		}}}); err != nil {
			return err
		}
		s.mu.Lock()
		u.refused = append(u.refused, refusedLabel(a))
		s.mu.Unlock()
		return errUnattended
	}
	if !u.wait {
		promptID := newID("prm")
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptRequested{PromptRequested: &flitv1.PromptRequested{
			PromptId: promptID, ToolCallId: toolCallID, Title: a.Title, Detail: a.Detail, SafetyReason: a.Reason,
		}}}); err != nil {
			return false, true, err
		}
		return false, true, refuse(promptID, "unattended run (ask: deny): nobody can approve it")
	}
	waitCtx, cancel := context.WithTimeoutCause(ctx, u.timeout, errAskTimeout)
	defer cancel()
	ok, _, err = s.approveWith(waitCtx, toolCallID, a, fmt.Sprintf("unattended run (ask: wait): no answer within %s", u.timeout))
	if err == nil && ok {
		return true, true, nil
	}
	if err == nil || errors.Is(err, errAskTimeout) {
		s.mu.Lock()
		u.refused = append(u.refused, refusedLabel(a))
		s.mu.Unlock()
	}
	if errors.Is(err, errAskTimeout) {
		return false, true, errUnattended
	}
	return false, true, err
}

var errAskTimeout = errors.New("no answer in time")

// refusedLabel is how a refused approval is listed in the run.
func refusedLabel(a tools.Approval) string {
	detail, _, _ := strings.Cut(strings.TrimSpace(a.Detail), "\n")
	if a.Title == "Run shell command" || a.Title == "" {
		return detail
	}
	return a.Title
}
