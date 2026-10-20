package agent

import (
	"context"
	"errors"
	"fmt"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/branches"
)

// Branches: retrying from or editing an earlier user message starts a new
// branch of the conversation in the same session (see package branches).
// The session has one active branch; turns run on it and the model sees
// only its path.

// ErrQueued: forking while messages are queued. They were written as
// follow-ups to the conversation as it is, so they are sent or cancelled
// first rather than guessing which branch they belong on.
var ErrQueued = errors.New("messages are queued; send or cancel them first")

// loadBranches rebuilds the branch tree from the log.
func (s *session) loadBranches(ctx context.Context) error {
	evs, err := s.m.store.EventsOfKinds(ctx, s.info.ID, "branch_created")
	if err != nil {
		return err
	}
	s.tree = branches.New(evs)
	return nil
}

// pathEvents returns the session's events of the given kinds on the active
// branch's path, in order. Everything that rebuilds the conversation for
// the model reads the log through here, so it follows the active branch.
func (s *session) pathEvents(ctx context.Context, kinds ...string) ([]*flitv1.Event, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.pathEventsLocked(ctx, kinds...)
}

func (s *session) pathEventsLocked(ctx context.Context, kinds ...string) ([]*flitv1.Event, error) {
	evs, err := s.m.store.EventsOfKinds(ctx, s.info.ID, kinds...)
	if err != nil {
		return nil, err
	}
	return s.tree.Path(s.info.BranchID).Filter(evs), nil
}

// ForkResult is the branch a fork made.
type ForkResult struct {
	BranchID string
	// Seq is its BranchCreated event's.
	Seq int64
}

// fork starts a new branch from user message msgID on the active branch's
// path, switches to it and runs a turn there. A retry (edit false) keeps
// the message and answers it again; an edit forks just before it and
// sends text instead.
func (s *session) fork(ctx context.Context, msgID, text, client string, edit bool) (ForkResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancelTurn != nil {
		return ForkResult{}, fmt.Errorf("%w; stop it first", ErrBusy)
	}
	if len(s.queue) > 0 {
		return ForkResult{}, ErrQueued
	}
	evs, err := s.pathEventsLocked(ctx, "message_started", "message_done")
	if err != nil {
		return ForkResult{}, err
	}
	var started, done *flitv1.Event
	for _, ev := range evs {
		if ev.GetMessageStarted().GetMessageId() == msgID {
			started = ev
		}
		if ev.GetMessageDone().GetMessageId() == msgID {
			done = ev
		}
	}
	if started == nil || done == nil {
		return ForkResult{}, invalid("no message %s on this branch", msgID)
	}
	if started.GetMessageStarted().Role != flitv1.Role_ROLE_USER {
		return ForkResult{}, invalid("message %s is not a user message", msgID)
	}

	kind, forkSeq := flitv1.BranchKind_BRANCH_KIND_RETRY, done.Seq
	if edit {
		kind, forkSeq = flitv1.BranchKind_BRANCH_KIND_EDIT, started.Seq-1
	}
	id := newID("br")
	ev, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_BranchCreated{BranchCreated: &flitv1.BranchCreated{
		// The message's own branch is the parent: the new branch is an
		// alternative to what followed the message there.
		BranchId: id, ParentBranchId: started.BranchId, ForkSeq: forkSeq, Kind: kind, MessageId: msgID, Client: client,
	}}})
	if err != nil {
		return ForkResult{}, err
	}
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_BranchSwitched{BranchSwitched: &flitv1.BranchSwitched{
		BranchId: id, Client: client,
	}}}); err != nil {
		return ForkResult{}, err
	}
	turnID := msgID
	if edit {
		if _, turnID, err = s.appendUserLocked(text); err != nil {
			return ForkResult{}, err
		}
	}
	if err := s.startTurnLocked(turnID); err != nil {
		return ForkResult{}, err
	}
	return ForkResult{BranchID: id, Seq: ev.Seq}, nil
}

// switchBranch makes branch id the active one.
func (s *session) switchBranch(id, client string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancelTurn != nil {
		return fmt.Errorf("%w; stop it first", ErrBusy)
	}
	if _, ok := s.tree.Get(id); !ok {
		return invalid("no branch %s in this session", id)
	}
	if id == s.info.BranchID {
		return nil
	}
	_, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_BranchSwitched{BranchSwitched: &flitv1.BranchSwitched{
		BranchId: id, Client: client,
	}}})
	return err
}

// kvKeys are the names the active branch's llama.cpp prompt cache may be
// saved under, best first: its own, then its ancestors'. An ancestor's
// cache shares the conversation up to the fork, and llama.cpp reuses only
// the tokens a prompt has in common with a cache, so restoring one is
// never wrong, just partly useful. Once the path has a compaction
// (compacted), the prompt starts with its summary, so only the branch's
// own cache can match it.
func (s *session) kvKeys(compacted bool) []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	var keys []string
	for _, b := range s.tree.Ancestry(s.info.BranchID) {
		keys = append(keys, kvKey(s.info.ID, b))
		if compacted {
			break
		}
	}
	return keys
}

func kvKey(session, branch string) string {
	if branch == branches.Root {
		return session
	}
	return session + "/" + branch
}
