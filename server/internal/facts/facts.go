package facts

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"slices"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/branches"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/store"
)

// Modes of learning.facts.
const (
	ModeOn      = "on"
	ModePropose = "propose"
	ModeOff     = "off"
)

// Service learns facts and serves them.
type Service struct {
	Store  *store.Store
	Config func() config.Config
}

// Fact is a learned fact as listed.
type Fact struct {
	ID            string
	ProjectID     string
	Scope         string
	Family        string
	State         string
	Text          string
	Confirmations int
	Exercised     int
	Fired         int
	// Injected says it goes into the system prompt now.
	Injected bool
	// Evidence is "ses_01a15d96 T2", newest last.
	Evidence []string
}

// scopeOf narrows facts within a project. Scratch holds unrelated
// directories, so its facts apply per directory.
func scopeOf(sess store.Session) string {
	if sess.ProjectID != store.DefaultProjectID {
		return ""
	}
	if sess.SourceDir != "" {
		return sess.SourceDir
	}
	return sess.WorkingDir
}

func factID(projectID, scope, family, key string) string {
	sum := sha256.Sum256([]byte(projectID + "\x00" + scope + "\x00" + family + "\x00" + key))
	return "fct_" + hex.EncodeToString(sum[:8])
}

// Observe reads a session's shell calls and records what they say. It runs
// after every turn and redoes the whole session, so it is idempotent.
func (s *Service) Observe(ctx context.Context, sessionID string) error {
	if s.Config().Learning.Facts != ModeOn && s.Config().Learning.Facts != ModePropose {
		return nil
	}
	sess, err := s.Store.GetSession(ctx, sessionID)
	if err != nil {
		return err
	}
	return s.observe(ctx, sess)
}

func (s *Service) observe(ctx context.Context, sess store.Session) error {
	if sess.ProjectID == "" {
		return nil
	}
	events, err := s.Store.EventsOfKinds(ctx, sess.ID, "branch_created", "message_started", "tool_call_started", "tool_call_done")
	if err != nil {
		return err
	}
	events = branches.New(events).Path(sess.BranchID).Filter(events)
	obs := observeEvents(events, sess.WorkingDir)

	existing, err := s.Store.ListFacts(ctx, sess.ProjectID)
	if err != nil {
		return err
	}
	injected, err := s.Store.FactInjections(ctx, sess.ID)
	if err != nil {
		return err
	}
	scope := scopeOf(sess)
	known := map[string]bool{}
	type live struct {
		id, family string
		detail     detail
	}
	var facts []live
	for _, f := range existing {
		known[f.ID] = true
		if f.Scope != scope || !f.ForgottenAt.IsZero() {
			continue
		}
		var d detail
		if err := json.Unmarshal([]byte(f.Detail), &d); err != nil {
			return fmt.Errorf("fact %s: %w", f.ID, err)
		}
		facts = append(facts, live{f.ID, f.Family, d})
	}
	var added []store.Fact
	for _, c := range discover(obs) {
		id := factID(sess.ProjectID, scope, c.family, c.key)
		if known[id] {
			continue
		}
		added = append(added, store.Fact{
			ID: id, TeamID: sess.TeamID, ProjectID: sess.ProjectID, Scope: scope,
			Family: c.family, Detail: c.detail.json(), CreatedAt: time.Now(),
		})
		facts = append(facts, live{id, c.family, c.detail})
	}
	var verdicts []store.FactSession
	for _, f := range facts {
		v := evaluate(f.family, f.detail, obs, injected[f.id])
		if v == nil {
			continue
		}
		verdicts = append(verdicts, store.FactSession{
			FactID: f.id, SessionID: sess.ID, SessionCreatedAt: sess.CreatedAt,
			Confirmed: v.confirmed, Contradicted: v.contradicted, Fired: v.fired, Turns: turnsText(v.turns),
		})
	}
	return s.Store.ReplaceFactSession(ctx, sess.ID, sess.ProjectID, added, verdicts)
}

// view is a stored fact with its lifecycle worked out.
type view struct {
	store.Fact
	detail detail
	status status
	text   string
}

func (s *Service) views(ctx context.Context, projectID string, l config.Learning) ([]view, error) {
	list, err := s.Store.ListFacts(ctx, projectID)
	if err != nil {
		return nil, err
	}
	out := make([]view, 0, len(list))
	for _, f := range list {
		v := view{Fact: f}
		if err := json.Unmarshal([]byte(f.Detail), &v.detail); err != nil {
			return nil, fmt.Errorf("fact %s: %w", f.ID, err)
		}
		v.status = fold(f.Family, f.Sessions, l)
		if !f.ForgottenAt.IsZero() {
			v.status.state = StateForgotten
		}
		v.text = text(f.Family, v.detail)
		out = append(out, v)
	}
	return out, nil
}

var familyOrder = map[string]int{familyForm: 0, familyEnv: 1, familyBoundary: 2}

// selectFacts picks what goes in the prompt from facts of one scope: those
// past the gate, one per failing spelling, within the caps.
func selectFacts(facts []view, l config.Learning) []view {
	var pool []view
	for _, f := range facts {
		if f.status.injectable(l) && lintOK(f.text) {
			pool = append(pool, f)
		}
	}
	rate := func(f view) float64 { return float64(f.status.fired) / float64(max(f.status.exercised, 1)) }
	slices.SortStableFunc(pool, func(a, b view) int {
		if c := familyOrder[a.Family] - familyOrder[b.Family]; c != 0 {
			return c
		}
		switch ra, rb := rate(a), rate(b); {
		case ra > rb:
			return -1
		case ra < rb:
			return 1
		}
		return strings.Compare(a.ID, b.ID)
	})
	var out []view
	used := 0
	seen := map[string]bool{}
	for _, f := range pool {
		if l.FactsMax > 0 && len(out) >= l.FactsMax {
			break
		}
		if f.Family == familyForm {
			k := f.detail.Intent + "|" + f.detail.Bad
			if seen[k] {
				continue
			}
			seen[k] = true
		}
		n := len(f.text) + len("- \n")
		if l.FactsMaxBytes > 0 && used+n > l.FactsMaxBytes {
			continue
		}
		used += n
		out = append(out, f)
	}
	return out
}

// Prompt is the block of facts for a session's system prompt ("" if none),
// and records that the session carried them.
func (s *Service) Prompt(ctx context.Context, sess store.Session) (string, error) {
	l := s.Config().Learning
	if l.Facts != ModeOn || sess.ProjectID == "" {
		return "", nil
	}
	all, err := s.views(ctx, sess.ProjectID, l)
	if err != nil {
		return "", err
	}
	scope := scopeOf(sess)
	all = slices.DeleteFunc(all, func(v view) bool { return v.Scope != scope })
	chosen := selectFacts(all, l)
	if len(chosen) == 0 {
		return "", nil
	}
	var b strings.Builder
	b.WriteString("\nFacts flit learned from earlier sessions in this project. Follow them when their situation applies:\n\n<project-facts>\n")
	ids := make([]string, 0, len(chosen))
	for _, f := range chosen {
		b.WriteString("- " + f.text + "\n")
		ids = append(ids, f.ID)
	}
	b.WriteString("</project-facts>\n")
	if err := s.Store.RecordFactInjections(ctx, sess.ID, ids); err != nil {
		return "", err
	}
	return b.String(), nil
}

// List returns a project's facts (every project's for ""): active first,
// then forming, retired and forgotten.
func (s *Service) List(ctx context.Context, projectID string) ([]Fact, error) {
	l := s.Config().Learning
	all, err := s.views(ctx, projectID, l)
	if err != nil {
		return nil, err
	}
	injected := map[string]bool{}
	if l.Facts == ModeOn {
		byScope := map[string][]view{}
		for _, v := range all {
			k := v.ProjectID + "\x00" + v.Scope
			byScope[k] = append(byScope[k], v)
		}
		for _, group := range byScope {
			for _, v := range selectFacts(group, l) {
				injected[v.ID] = true
			}
		}
	}
	out := make([]Fact, 0, len(all))
	for _, v := range all {
		out = append(out, Fact{
			ID: v.ID, ProjectID: v.ProjectID, Scope: v.Scope, Family: v.Family, State: v.status.state, Text: v.text,
			Confirmations: v.status.confirmations, Exercised: v.status.exercised, Fired: v.status.fired,
			Injected: injected[v.ID], Evidence: evidence(v.Sessions),
		})
	}
	order := map[string]int{StateActive: 0, StateForming: 1, StateRetired: 2, StateForgotten: 3}
	slices.SortStableFunc(out, func(a, b Fact) int { return order[a.State] - order[b.State] })
	return out, nil
}

const maxEvidence = 5

// evidence is the sessions that confirmed or contradicted the fact, or saw
// the failure, in flit learn's "ses_01a15d96 T2" form.
func evidence(rows []store.FactSession) []string {
	var out []string
	for _, r := range rows {
		if !r.Confirmed && !r.Contradicted && !r.Fired {
			continue
		}
		id := r.SessionID
		if len(id) > 12 {
			id = id[:12]
		}
		var turns []string
		for _, t := range strings.Split(r.Turns, ",") {
			if t != "" {
				turns = append(turns, "T"+t)
			}
		}
		out = append(out, strings.TrimSpace(id+" "+strings.Join(turns, ", ")))
	}
	if len(out) > maxEvidence {
		out = out[len(out)-maxEvidence:]
	}
	return out
}

// ErrAmbiguous is returned when an id prefix matches several facts.
var ErrAmbiguous = errors.New("matches more than one fact; give more of the id")

// Forget retires a fact for good; a unique id prefix will do. It returns
// the full id.
func (s *Service) Forget(ctx context.Context, id string) (string, error) {
	list, err := s.Store.ListFacts(ctx, "")
	if err != nil {
		return "", err
	}
	var found []string
	for _, f := range list {
		if f.ID == id {
			found = []string{f.ID}
			break
		}
		if f.ForgottenAt.IsZero() && strings.HasPrefix(f.ID, id) {
			found = append(found, f.ID)
		}
	}
	switch len(found) {
	case 0:
		return "", store.ErrNotFound
	case 1:
		return found[0], s.Store.ForgetFact(ctx, found[0], time.Now())
	}
	return "", ErrAmbiguous
}

// Rebuild forgets what was learned and replays every session's event log,
// oldest first (one project's, or all for ""). Forgotten facts stay
// forgotten and the record of injections is kept. It returns how many
// sessions it read.
func (s *Service) Rebuild(ctx context.Context, projectID string) (int, error) {
	sessions, err := s.Store.ListSessionsArchived(ctx, projectID, true, math.MaxInt32, 0)
	if err != nil {
		return 0, err
	}
	slices.SortStableFunc(sessions, func(a, b store.Session) int {
		if c := a.CreatedAt.Compare(b.CreatedAt); c != 0 {
			return c
		}
		return strings.Compare(a.ID, b.ID)
	})
	if err := s.Store.ClearFacts(ctx, projectID); err != nil {
		return 0, err
	}
	for _, sess := range sessions {
		if err := s.observe(ctx, sess); err != nil {
			return 0, fmt.Errorf("session %s: %w", sess.ID, err)
		}
	}
	return len(sessions), nil
}
