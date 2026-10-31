// Package branches works out a session's conversation branches from its
// event log. A session's log is one numbered sequence; forking a
// conversation (retry from a message, edit and resend) starts a new branch
// inside it rather than copying events. Every event carries the branch it
// was recorded on (Event.branch_id, empty for the root branch), and a
// BranchCreated event says where a branch forks from its parent. A
// branch's history (its path) is its ancestors' events up to each fork
// point followed by its own events.
//
// Everything that rebuilds a conversation from the log (the model's
// context, ratings, export) reads it through a Path, so the same rules
// apply everywhere.
package branches

import (
	"math"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

// Root is the id of the root branch: the whole log of a session that
// never forked.
const Root = ""

// Branch is one branch of a session's conversation.
type Branch struct {
	ID string
	// Parent is the branch it forked from (Root for the root's children).
	Parent string
	// ForkSeq: the parent's events with seq <= ForkSeq are part of this
	// branch.
	ForkSeq   int64
	Kind      flitv1.BranchKind
	MessageID string
	// Seq is the seq of its BranchCreated event (0 for the root).
	Seq int64
}

// Tree is a session's branches.
type Tree struct {
	byID  map[string]Branch
	order []string // creation order, root first
}

// New builds the tree from a session's events; only BranchCreated events
// matter, so events may be just those.
func New(events []*flitv1.Event) *Tree {
	t := &Tree{byID: map[string]Branch{Root: {ID: Root}}, order: []string{Root}}
	for _, ev := range events {
		t.Add(ev)
	}
	return t
}

// Add records ev if it is a BranchCreated event.
func (t *Tree) Add(ev *flitv1.Event) {
	c := ev.GetBranchCreated()
	if c == nil || c.BranchId == Root {
		return
	}
	if _, ok := t.byID[c.BranchId]; ok {
		return
	}
	t.byID[c.BranchId] = Branch{ID: c.BranchId, Parent: c.ParentBranchId, ForkSeq: c.ForkSeq, Kind: c.Kind,
		MessageID: c.MessageId, Seq: ev.Seq}
	t.order = append(t.order, c.BranchId)
}

// Get returns a branch.
func (t *Tree) Get(id string) (Branch, bool) {
	b, ok := t.byID[id]
	return b, ok
}

// Branches returns every branch, root first, then in creation order.
func (t *Tree) Branches() []Branch {
	out := make([]Branch, 0, len(t.order))
	for _, id := range t.order {
		out = append(out, t.byID[id])
	}
	return out
}

// Forked reports whether the session has any branch besides the root.
func (t *Tree) Forked() bool { return len(t.order) > 1 }

// Ancestry returns id and its ancestors, nearest first, ending with the
// root. An unknown id is treated as the root.
func (t *Tree) Ancestry(id string) []string {
	var out []string
	seen := map[string]bool{}
	for {
		b, ok := t.byID[id]
		if !ok || seen[id] {
			return append(out, Root)
		}
		seen[id] = true
		out = append(out, id)
		if id == Root {
			return out
		}
		id = b.Parent
	}
}

// Path is the history of one branch: which seqs of which branches it
// includes.
type Path struct {
	// limit is, per branch on the path, the last seq it contributes.
	limit map[string]int64
}

// Path returns branch id's path.
func (t *Tree) Path(id string) Path {
	p := Path{limit: map[string]int64{}}
	upTo := int64(math.MaxInt64)
	for _, b := range t.Ancestry(id) {
		p.limit[b] = upTo
		upTo = t.byID[b].ForkSeq
	}
	return p
}

// Includes reports whether the event with seq recorded on branch is part
// of the path. It ignores session-wide events (see Contains).
func (p Path) Includes(branch string, seq int64) bool {
	lim, ok := p.limit[branch]
	return ok && seq <= lim
}

// Contains reports whether ev is part of the path: session-wide events
// always are.
func (p Path) Contains(ev *flitv1.Event) bool {
	return SessionWide(ev) || p.Includes(ev.BranchId, ev.Seq)
}

// Filter returns the events on the path, in order.
func (p Path) Filter(events []*flitv1.Event) []*flitv1.Event {
	out := make([]*flitv1.Event, 0, len(events))
	for _, ev := range events {
		if p.Contains(ev) {
			out = append(out, ev)
		}
	}
	return out
}

// SessionWide reports whether ev is about the session rather than one
// branch's conversation: its state, settings, queue and branches. These
// apply on every branch.
func SessionWide(ev *flitv1.Event) bool {
	switch ev.Payload.(type) {
	case *flitv1.Event_TaskStateChanged, *flitv1.Event_ModelChanged, *flitv1.Event_McpServersChanged,
		*flitv1.Event_SessionMoved, *flitv1.Event_YoloChanged, *flitv1.Event_MessageQueued,
		*flitv1.Event_QueuedMessageUpdated, *flitv1.Event_QueuedMessageDelivered,
		*flitv1.Event_BranchCreated, *flitv1.Event_BranchSwitched, *flitv1.Event_RoleChanged:
		return true
	}
	return false
}
