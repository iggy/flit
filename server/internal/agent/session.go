package agent

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/branches"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// subscriberBuffer is how many events an attached client may lag behind
// before it is dropped (it can reattach from the last seq it saw).
const subscriberBuffer = 4096

// replayPage is how many events Attach reads from the store at a time.
const replayPage = 1000

// session is the live state of one session.
type session struct {
	m *Manager

	// mu guards everything below and serializes appends, so sequence
	// numbers are assigned, stored and published in order.
	mu         sync.Mutex
	info       store.Session
	subs       map[*subscriber]struct{}
	cancelTurn context.CancelFunc // non-nil while a turn runs
	// cancelCall stops the model call in progress (nil when none);
	// callOutput says whether any of its reply has arrived.
	cancelCall context.CancelCauseFunc
	callOutput bool
	// call is the model call in flight, for EndReasoning and the waiting
	// watcher (see llamacpp.go).
	call *liveCall
	// lastSlot is the llama.cpp slot this turn's last call was pinned to;
	// only the turn's goroutine uses it.
	lastSlot *slotRef
	// queue holds messages sent while a turn ran, in order, until the
	// turn's next step delivers them (see queue.go).
	queue []queuedMessage
	// compactAsk is a Compact request for the running turn's next step.
	compactAsk *compactAsk
	prompts    map[string]pendingPrompt
	// allowed are shell patterns allowed for the rest of the session
	// ("allow for this session"), rebuilt from the log on load.
	allowed []string
	// tree is the session's conversation branches; info.BranchID is the
	// active one (see branch.go).
	tree *branches.Tree
	// unattended is set while a cron run's turn runs (see cron.go).
	unattended *unattended
}

type pendingPrompt struct {
	ch       chan promptAnswer
	patterns []string // offered for "allow for this session"
}

type subscriber struct {
	ch      chan *flitv1.Event
	dropped bool
}

type promptAnswer struct {
	allow      bool
	forSession bool
	client     string
}

func newSession(m *Manager, info store.Session) *session {
	return &session{
		m:       m,
		info:    info,
		subs:    map[*subscriber]struct{}{},
		prompts: map[string]pendingPrompt{},
		tree:    branches.New(nil),
	}
}

// loadAllowed rebuilds the session's "allow for this session" patterns
// from its log.
func (s *session) loadAllowed(ctx context.Context) error {
	evs, err := s.m.store.EventsOfKinds(ctx, s.info.ID, "prompt_resolved")
	if err != nil {
		return err
	}
	for _, ev := range evs {
		r := ev.GetPromptResolved()
		if r.Decision != flitv1.PromptDecision_PROMPT_DECISION_ALLOW_SESSION {
			continue
		}
		for _, p := range r.SessionPatterns {
			if !slices.Contains(s.allowed, p) {
				s.allowed = append(s.allowed, p)
			}
		}
	}
	return nil
}

// sessionAllowed returns a copy of the session's allowed shell patterns.
func (s *session) sessionAllowed() []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return slices.Clone(s.allowed)
}

func (s *session) snapshot() store.Session {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.info
}

// append assigns ev the next sequence number, stores it and publishes it to
// attached clients.
func (s *session) append(ev *flitv1.Event) (*flitv1.Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.appendLocked(ev)
}

func (s *session) appendLocked(ev *flitv1.Event) (*flitv1.Event, error) {
	ev.SessionId = s.info.ID
	ev.BranchId = s.info.BranchID
	if sw := ev.GetBranchSwitched(); sw != nil {
		ev.BranchId = sw.BranchId
	}
	ev.Seq = s.info.LastSeq + 1
	ev.Time = timestamppb.New(time.Now())
	if err := s.m.store.AppendEvent(context.Background(), s.info, ev); err != nil {
		return nil, fmt.Errorf("record event: %w", err)
	}
	s.info.LastSeq = ev.Seq
	s.info.UpdatedAt = ev.Time.AsTime()
	switch {
	case ev.GetTaskStateChanged() != nil:
		s.info.State = ev.GetTaskStateChanged().State
	case ev.GetUsage() != nil:
		u := ev.GetUsage()
		s.info.ContextTokens, s.info.ContextLength = u.InputTokens+u.OutputTokens, u.ContextLength
	case ev.GetModelChanged() != nil:
		s.info.ContextLength = ev.GetModelChanged().ContextLength
	case ev.GetCompactionDone() != nil && ev.GetCompactionDone().Error == "":
		s.info.ContextTokens = ev.GetCompactionDone().TokensAfter
	case ev.GetWorktreeRemoved() != nil:
		s.info.WorktreeRemoved = true
	case ev.GetBranchCreated() != nil:
		s.tree.Add(ev)
	case ev.GetBranchSwitched() != nil:
		s.info.BranchID = ev.GetBranchSwitched().BranchId
	case ev.GetRoleChanged() != nil:
		s.info.Role = ev.GetRoleChanged().Role
	}
	for sub := range s.subs {
		select {
		case sub.ch <- ev:
		default:
			sub.dropped = true
			close(sub.ch)
			delete(s.subs, sub)
		}
	}
	return ev, nil
}

func (s *session) attach(ctx context.Context, fromSeq int64, send func(*flitv1.Event) error) error {
	fromSeq = max(fromSeq, 1)

	// Subscribe before replaying, so nothing appended in between is missed:
	// everything up to last comes from the store, everything after from the
	// subscription.
	sub := &subscriber{ch: make(chan *flitv1.Event, subscriberBuffer)}
	s.mu.Lock()
	last := s.info.LastSeq
	s.subs[sub] = struct{}{}
	s.mu.Unlock()
	defer func() {
		s.mu.Lock()
		delete(s.subs, sub)
		s.mu.Unlock()
	}()

	next := fromSeq
	for next <= last {
		evs, err := s.m.store.Events(ctx, s.info.ID, next, min(last, next+replayPage-1))
		if err != nil {
			return err
		}
		if len(evs) == 0 {
			break
		}
		for _, ev := range evs {
			if err := send(ev); err != nil {
				return err
			}
			next = ev.Seq + 1
		}
	}

	for {
		select {
		case <-ctx.Done():
			return nil
		case ev, ok := <-sub.ch:
			if !ok {
				return fmt.Errorf("%w; attach again from seq %d", ErrSlowClient, next)
			}
			if ev.Seq < next {
				continue
			}
			if err := send(ev); err != nil {
				return err
			}
			next = ev.Seq + 1
		}
	}
}

// SendResult says what Send did with a message.
type SendResult struct {
	// Seq is the first event recorded for it.
	Seq int64
	// QueueID is set when it was queued because a turn is running.
	QueueID string
}

// send starts a turn with text (after any queued messages), or queues text
// if a turn is running. Empty text with a non-empty queue just delivers the
// queue.
func (s *session) send(text, client string) (SendResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	empty := strings.TrimSpace(text) == ""
	if s.cancelTurn != nil {
		if empty {
			return SendResult{}, invalid("text is empty")
		}
		q := queuedMessage{id: newID("queue"), text: text, client: client}
		ev, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_MessageQueued{MessageQueued: &flitv1.MessageQueued{
			QueueId: q.id, Text: text, Client: client,
		}}})
		if err != nil {
			return SendResult{}, err
		}
		s.queue = append(s.queue, q)
		return SendResult{Seq: ev.Seq, QueueID: q.id}, nil
	}
	if empty && len(s.queue) == 0 {
		return SendResult{}, invalid("text is empty")
	}
	if s.info.Title == "" {
		first := text
		if len(s.queue) > 0 {
			first = s.queue[0].text
		}
		s.info.Title = titleFrom(first)
		if err := s.m.store.SetTitle(context.Background(), s.info.ID, s.info.Title); err != nil {
			return SendResult{}, err
		}
	}
	seq, turnID, err := s.deliverQueuedLocked()
	if err != nil {
		return SendResult{}, err
	}
	if !empty {
		ev, msgID, err := s.appendUserLocked(text)
		if err != nil {
			return SendResult{}, err
		}
		if seq == 0 {
			seq, turnID = ev.Seq, msgID
		}
	}
	if err := s.startTurnLocked(turnID); err != nil {
		return SendResult{}, err
	}
	return SendResult{Seq: seq}, nil
}

// appendUserLocked records a user message with a new id.
func (s *session) appendUserLocked(text string) (*flitv1.Event, string, error) {
	msgID := newID("msg")
	seq := s.info.LastSeq + 1
	if err := s.appendUserMessageLocked(msgID, text); err != nil {
		return nil, "", err
	}
	return &flitv1.Event{Seq: seq}, msgID, nil
}

// appendUserMessageLocked records user message msgID.
func (s *session) appendUserMessageLocked(msgID, text string) error {
	for _, ev := range []*flitv1.Event{
		{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: msgID, Role: flitv1.Role_ROLE_USER}}},
		{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: msgID, Text: text}}},
		{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: msgID, Text: text, FinishReason: "stop"}}},
	} {
		if _, err := s.appendLocked(ev); err != nil {
			return err
		}
	}
	return nil
}

// startTurnLocked marks the session working and runs a turn.
func (s *session) startTurnLocked(turnID string) error {
	if _, err := s.appendLocked(stateChanged(flitv1.TaskState_TASK_STATE_WORKING, "")); err != nil {
		return err
	}
	ctx, cancel := context.WithCancel(context.Background())
	s.cancelTurn = cancel
	s.m.turns.Add(1)
	go func() {
		defer s.m.turns.Done()
		defer cancel()
		s.runTurn(ctx, turnID)
	}()
	return nil
}

func titleFrom(text string) string {
	t := strings.Join(strings.Fields(text), " ")
	if utf8.RuneCountInString(t) > 60 {
		t = string([]rune(t)[:60]) + "…"
	}
	return t
}

func (s *session) interrupt() bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancelTurn == nil {
		return false
	}
	s.cancelTurn()
	return true
}

// errUserRetry is the cause a model call is cancelled with by
// RetryModelCall.
var errUserRetry = errors.New("retried by request")

func (s *session) retryCall() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancelCall == nil {
		return fmt.Errorf("%w: none is running", ErrNoCallToRetry)
	}
	if s.callOutput {
		return fmt.Errorf("%w: the model is already answering; interrupt the turn instead", ErrNoCallToRetry)
	}
	s.cancelCall(errUserRetry)
	return nil
}

// setCall records the model call in progress (cancel nil: none).
func (s *session) setCall(cancel context.CancelCauseFunc, c *liveCall) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.cancelCall, s.callOutput, s.call = cancel, false, c
}

// callActivity records what the call in flight produced: reply text or
// reasoning (n bytes), or just that the server started on it.
func (s *session) callActivity(text, reasoning int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if text > 0 || reasoning > 0 {
		s.callOutput = true
	}
	if c := s.call; c != nil {
		c.started = true
		c.text += text
		c.reasoning += reasoning
	}
}

func (s *session) callID(id string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.call != nil {
		s.call.id = id
	}
}

func (s *session) answer(promptID string, a Answer) error {
	s.mu.Lock()
	p, ok := s.prompts[promptID]
	if ok && a.ForSession && len(p.patterns) == 0 {
		s.mu.Unlock()
		return invalid("this prompt can't be allowed for the whole session")
	}
	delete(s.prompts, promptID)
	s.mu.Unlock()
	if !ok {
		return ErrPromptGone
	}
	// buffered; never blocks
	p.ch <- promptAnswer{allow: a.Allow || a.ForSession, forSession: a.ForSession, client: a.Client}
	return nil
}

// approve raises a prompt and waits for a client to answer it or for the
// turn to be interrupted. In an unattended run (a cron job or webhook) it may refuse
// at once or give up after a while instead (see approveUnattended).
func (s *session) approve(ctx context.Context, toolCallID string, a tools.Approval) (bool, error) {
	if ok, handled, err := s.approveUnattended(ctx, toolCallID, a); handled {
		return ok, err
	}
	ok, _, err := s.approveWith(ctx, toolCallID, a, "")
	return ok, err
}

// approveWith raises a prompt and waits for an answer or for ctx to end.
// When ctx ends with errAskTimeout as its cause, the prompt is resolved as
// denied with timeoutReason and errAskTimeout is returned; otherwise an
// ended ctx is an interrupt.
func (s *session) approveWith(ctx context.Context, toolCallID string, a tools.Approval, timeoutReason string) (bool, string, error) {
	title, patterns := a.Title, a.SessionPatterns
	promptID := newID("prm")
	ch := make(chan promptAnswer, 1)
	s.mu.Lock()
	s.prompts[promptID] = pendingPrompt{ch: ch, patterns: patterns}
	s.mu.Unlock()

	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptRequested{PromptRequested: &flitv1.PromptRequested{
		PromptId: promptID, ToolCallId: toolCallID, Title: title, Detail: a.Detail, SessionPatterns: patterns,
		SafetyReason: a.Reason,
	}}}); err != nil {
		return false, promptID, err
	}
	if _, err := s.append(stateChanged(flitv1.TaskState_TASK_STATE_WAITING, title)); err != nil {
		return false, promptID, err
	}

	resolved := &flitv1.PromptResolved{PromptId: promptID}
	var answerErr error
	select {
	case ans := <-ch:
		resolved.Client = ans.client
		resolved.Decision = flitv1.PromptDecision_PROMPT_DECISION_DENY
		switch {
		case ans.forSession:
			resolved.Decision = flitv1.PromptDecision_PROMPT_DECISION_ALLOW_SESSION
			resolved.SessionPatterns = patterns
			s.mu.Lock()
			for _, p := range patterns {
				if !slices.Contains(s.allowed, p) {
					s.allowed = append(s.allowed, p)
				}
			}
			s.mu.Unlock()
		case ans.allow:
			resolved.Decision = flitv1.PromptDecision_PROMPT_DECISION_ALLOW
		}
	case <-ctx.Done():
		s.mu.Lock()
		delete(s.prompts, promptID)
		s.mu.Unlock()
		resolved.Decision = flitv1.PromptDecision_PROMPT_DECISION_DENY
		resolved.Reason = "interrupted"
		answerErr = errInterrupted
		if errors.Is(context.Cause(ctx), errAskTimeout) {
			resolved.Reason, answerErr = timeoutReason, errAskTimeout
		}
	}
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptResolved{PromptResolved: resolved}}); err != nil {
		return false, promptID, err
	}
	if answerErr != nil && answerErr != errAskTimeout {
		return false, promptID, answerErr
	}
	if _, err := s.append(stateChanged(flitv1.TaskState_TASK_STATE_WORKING, "")); err != nil {
		return false, promptID, err
	}
	return resolved.Decision != flitv1.PromptDecision_PROMPT_DECISION_DENY, promptID, answerErr
}

func (s *session) setModel(ctx context.Context, provider, model string) (store.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	// Picking the current model again still logs a ModelChanged when the
	// catalog's context window moved (an override edited and refreshed),
	// so clients pick it up; otherwise it is a no-op.
	if provider == s.info.Provider && model == s.info.Model &&
		s.m.contextLength(provider, model) == s.info.ContextLength {
		return s.info, nil
	}
	if err := s.m.store.SetModel(ctx, s.info.ID, provider, model); err != nil {
		return store.Session{}, err
	}
	s.info.Provider, s.info.Model = provider, model
	if _, err := s.appendLocked(s.modelChangedLocked()); err != nil {
		return store.Session{}, err
	}
	s.m.touchModel(s.info)
	return s.info, nil
}

func (s *session) setEffort(ctx context.Context, effort string) (store.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.m.store.SetEffort(ctx, s.info.ID, effort); err != nil {
		return store.Session{}, err
	}
	s.info.Effort = effort
	if _, err := s.appendLocked(s.modelChangedLocked()); err != nil {
		return store.Session{}, err
	}
	return s.info, nil
}

func (s *session) setYolo(ctx context.Context, yolo bool, client string) (store.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.info.Yolo == yolo {
		return s.info, nil
	}
	if err := s.m.store.SetYolo(ctx, s.info.ID, yolo); err != nil {
		return store.Session{}, err
	}
	s.info.Yolo = yolo
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_YoloChanged{YoloChanged: &flitv1.YoloChanged{
		Yolo: yolo, Client: client,
	}}}); err != nil {
		return store.Session{}, err
	}
	return s.info, nil
}

func (s *session) modelChangedLocked() *flitv1.Event {
	return &flitv1.Event{Payload: &flitv1.Event_ModelChanged{ModelChanged: &flitv1.ModelChanged{
		Provider:      s.info.Provider,
		Model:         s.info.Model,
		Effort:        s.info.Effort,
		ContextLength: s.m.contextLength(s.info.Provider, s.info.Model),
	}}}
}

func stateChanged(state flitv1.TaskState, reason string) *flitv1.Event {
	return &flitv1.Event{Payload: &flitv1.Event_TaskStateChanged{TaskStateChanged: &flitv1.TaskStateChanged{
		State: state, Reason: reason,
	}}}
}

func (s *session) move(ctx context.Context, projectID string) (store.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.m.store.MoveSession(ctx, s.info.ID, projectID); err != nil {
		return store.Session{}, err
	}
	s.info.ProjectID = projectID
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_SessionMoved{SessionMoved: &flitv1.SessionMoved{
		ProjectId: projectID,
	}}}); err != nil {
		return store.Session{}, err
	}
	return s.info, nil
}

func (s *session) setMCPServer(ctx context.Context, server string, enabled bool) (store.Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	names := slices.DeleteFunc(slices.Clone(s.info.MCPServers), func(n string) bool { return n == server })
	if enabled {
		names = append(names, server)
		slices.Sort(names)
	}
	if err := s.m.store.SetMCPServers(ctx, s.info.ID, names); err != nil {
		return store.Session{}, err
	}
	s.info.MCPServers = names
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_McpServersChanged{McpServersChanged: &flitv1.McpServersChanged{
		Enabled: slices.Clone(names),
	}}}); err != nil {
		return store.Session{}, err
	}
	return s.info, nil
}

func (s *session) rate(ctx context.Context, r Rating) error {
	fb := &flitv1.Feedback{Target: r.Target, MessageId: r.MessageID, Note: r.Note, Client: r.Client,
		Rating: flitv1.Rating_RATING_BAD}
	if r.Good {
		fb.Rating = flitv1.Rating_RATING_GOOD
	}
	info := s.snapshot()
	fb.Provider, fb.Model = info.Provider, info.Model
	modelCallID, branch := "", info.BranchID
	if r.MessageID != "" {
		started, err := s.messageStarted(ctx, r.MessageID)
		if err != nil {
			return err
		}
		ms := started.GetMessageStarted()
		if ms.Role != flitv1.Role_ROLE_ASSISTANT {
			return invalid("message %s is not an assistant message", r.MessageID)
		}
		if ms.Model != "" {
			fb.Provider, fb.Model = ms.Provider, ms.Model
		}
		// The rating belongs to the branch the reply was written on, which
		// may be an ancestor of the active one.
		branch = started.BranchId
		turn, err := s.m.store.ModelCallTurn(ctx, r.MessageID)
		switch {
		case err == nil:
			fb.TurnId, modelCallID = turn, r.MessageID
		case errors.Is(err, store.ErrNotFound):
			// Recorded before model calls were kept: find the turn in the log.
			if fb.TurnId, err = s.turnOf(ctx, started); err != nil {
				return err
			}
		default:
			return err
		}
	}
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_Feedback{Feedback: fb}}); err != nil {
		return err
	}
	target := "turn"
	if r.Target == flitv1.RatingTarget_RATING_TARGET_MODEL {
		target = "model"
	}
	return s.m.store.AddRating(ctx, &store.Rating{
		ID: newID("rat"), SessionID: info.ID, TeamID: info.TeamID, ProjectID: info.ProjectID,
		TurnID: fb.TurnId, ModelCallID: modelCallID, BranchID: branch, Target: target, Good: r.Good, Note: r.Note,
		Client: r.Client, Provider: fb.Provider, Model: fb.Model,
	})
}

// messageStarted returns the MessageStarted event of message id, on any
// branch.
func (s *session) messageStarted(ctx context.Context, id string) (*flitv1.Event, error) {
	evs, err := s.m.store.EventsOfKinds(ctx, s.snapshot().ID, "message_started")
	if err != nil {
		return nil, err
	}
	for _, ev := range evs {
		if ev.GetMessageStarted().GetMessageId() == id {
			return ev, nil
		}
	}
	return nil, invalid("no message %s in this session", id)
}

// turnOf finds the user message that started the turn containing the
// message started by ev, on that message's branch.
func (s *session) turnOf(ctx context.Context, started *flitv1.Event) (string, error) {
	s.mu.Lock()
	id, path := s.info.ID, s.tree.Path(started.BranchId)
	s.mu.Unlock()
	evs, err := s.m.store.EventsOfKinds(ctx, id, "message_started")
	if err != nil {
		return "", err
	}
	turn := ""
	for _, ev := range path.Filter(evs) {
		if ev.Seq > started.Seq {
			break
		}
		if ms := ev.GetMessageStarted(); ms.Role == flitv1.Role_ROLE_USER {
			turn = ms.MessageId
		}
	}
	return turn, nil
}
