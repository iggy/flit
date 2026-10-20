// Package export writes flit's recorded sessions as JSONL for training and
// evaluation datasets. See docs/export.md for the format.
package export

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"regexp"
	"slices"
	"strings"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/branches"
	"github.com/iggy/flit/server/internal/store"
)

// FormatVersion is bumped when the record shape changes incompatibly.
const FormatVersion = 1

// Options control an export.
type Options struct {
	store.ExportFilter
	// Rating keeps only records with a matching rating: "good", "bad",
	// "rated" (any), or "" (everything).
	Rating string
	// Records picks record types: any of "session", "turn", "model_call";
	// empty means all.
	Records []string
	// Redact replaces absolute paths (working directories, Paths) and
	// secret-looking strings with placeholders.
	Redact bool
	// Paths are extra absolute paths to redact, e.g. the home directory.
	Paths map[string]string
}

// Stats counts what an export wrote.
type Stats struct {
	Sessions, Turns, ModelCalls int
}

type rating struct {
	Target    string    `json:"target"`
	Rating    string    `json:"rating"`
	Note      string    `json:"note,omitempty"`
	Client    string    `json:"client,omitempty"`
	Provider  string    `json:"provider"`
	Model     string    `json:"model"`
	CreatedAt time.Time `json:"created_at"`
	// Only on session records: what was rated.
	TurnID      string `json:"turn_id,omitempty"`
	ModelCallID string `json:"model_call_id,omitempty"`
	BranchID    string `json:"branch_id,omitempty"`
}

type project struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type modelCallRecord struct {
	Type          string            `json:"type"`
	FormatVersion int               `json:"format_version"`
	ID            string            `json:"id"`
	SessionID     string            `json:"session_id"`
	TurnID        string            `json:"turn_id"`
	BranchID      string            `json:"branch_id,omitempty"`
	Task          string            `json:"task"`
	Project       project           `json:"project"`
	CreatedAt     time.Time         `json:"created_at"`
	Provider      string            `json:"provider"`
	Model         string            `json:"model"`
	Effort        string            `json:"reasoning_effort,omitempty"`
	FlitVersion   string            `json:"flit_version"`
	Role          string            `json:"role,omitempty"`
	Skills        []string          `json:"skills,omitempty"`
	Params        json.RawMessage   `json:"params"`
	Messages      []json.RawMessage `json:"messages"`
	Tools         json.RawMessage   `json:"tools,omitempty"`
	Response      json.RawMessage   `json:"response"`
	FinishReason  string            `json:"finish_reason"`
	Usage         json.RawMessage   `json:"usage,omitempty"`
	Metrics       json.RawMessage   `json:"metrics,omitempty"`
	Error         string            `json:"error,omitempty"`
	Ratings       []rating          `json:"ratings"`
	TurnRatings   []rating          `json:"turn_ratings"`
}

type turnRecord struct {
	Type          string `json:"type"`
	FormatVersion int    `json:"format_version"`
	TurnID        string `json:"turn_id"`
	BranchID      string `json:"branch_id,omitempty"`
	// BranchHead marks the last turn of a branch: its messages are that
	// branch's whole conversation.
	BranchHead   bool              `json:"branch_head,omitempty"`
	SessionID    string            `json:"session_id"`
	Project      project           `json:"project"`
	CreatedAt    time.Time         `json:"created_at"`
	Provider     string            `json:"provider"`
	Model        string            `json:"model"`
	Effort       string            `json:"reasoning_effort,omitempty"`
	ModelCalls   []string          `json:"model_calls"`
	Messages     []json.RawMessage `json:"messages"`
	Tools        json.RawMessage   `json:"tools,omitempty"`
	FinishReason string            `json:"finish_reason"`
	// PermissionChecks are the safety check's verdicts on shell commands
	// in this turn.
	PermissionChecks []permissionCheck `json:"permission_checks"`
	Ratings          []rating          `json:"ratings"`
}

type permissionCheck struct {
	ToolCallID  string `json:"tool_call_id"`
	Command     string `json:"command"`
	Verdict     string `json:"verdict"`
	Reason      string `json:"reason"`
	Provider    string `json:"provider"`
	Model       string `json:"model"`
	ModelCallID string `json:"model_call_id"`
}

type sessionRecord struct {
	Type          string    `json:"type"`
	FormatVersion int       `json:"format_version"`
	SessionID     string    `json:"session_id"`
	Project       project   `json:"project"`
	WorkingDir    string    `json:"working_dir"`
	CreatedAt     time.Time `json:"created_at"`
	Turns         []string  `json:"turns"`
	Models        []string  `json:"models"`
	Ratings       []rating  `json:"ratings"`
	// Branches, for sessions that forked.
	Branches []branch `json:"branches,omitempty"`
}

type branch struct {
	// ID is empty for the root branch.
	ID       string `json:"id"`
	ParentID string `json:"parent_id,omitempty"`
	ForkSeq  int64  `json:"fork_seq,omitempty"`
	// Kind is "retry" or "edit" ("" for the root); MessageID is the user
	// message retried or edited.
	Kind      string `json:"kind,omitempty"`
	MessageID string `json:"message_id,omitempty"`
	// HeadTurnID is the branch's last turn (the turn record with this
	// turn_id and branch_id has branch_head set); empty if it has none
	// in this export.
	HeadTurnID string `json:"head_turn_id"`
	// HeadBranchID is the branch that turn ran on: this one, or an
	// ancestor if the branch has no turns of its own yet.
	HeadBranchID string `json:"head_branch_id,omitempty"`
}

func toRating(r store.Rating) rating {
	v := "bad"
	if r.Good {
		v = "good"
	}
	return rating{Target: r.Target, Rating: v, Note: r.Note, Client: r.Client, Provider: r.Provider, Model: r.Model, CreatedAt: r.CreatedAt}
}

func keep(opts Options, rs []rating) bool {
	switch opts.Rating {
	case "":
		return true
	case "rated":
		return len(rs) > 0
	default:
		return slices.ContainsFunc(rs, func(r rating) bool { return r.Rating == opts.Rating })
	}
}

func want(opts Options, kind string) bool {
	return len(opts.Records) == 0 || slices.Contains(opts.Records, kind)
}

// Write exports to w and reports what it wrote.
func Write(ctx context.Context, st *store.Store, w io.Writer, opts Options) (Stats, error) {
	switch opts.Rating {
	case "", "good", "bad", "rated":
	default:
		return Stats{}, fmt.Errorf("rating %q: want good, bad or rated", opts.Rating)
	}
	for _, r := range opts.Records {
		if r != "session" && r != "turn" && r != "model_call" {
			return Stats{}, fmt.Errorf("record type %q: want session, turn or model_call", r)
		}
	}

	var calls []store.ExportCall
	if err := st.ExportModelCalls(ctx, opts.ExportFilter, func(c store.ExportCall) error {
		calls = append(calls, c)
		return nil
	}); err != nil {
		return Stats{}, err
	}
	var sessionIDs []string
	for _, c := range calls {
		if !slices.Contains(sessionIDs, c.SessionID) {
			sessionIDs = append(sessionIDs, c.SessionID)
		}
	}
	ratings, err := st.RatingsFor(ctx, sessionIDs)
	if err != nil {
		return Stats{}, err
	}
	byCall, byTurn, bySession := map[string][]rating{}, map[string][]rating{}, map[string][]rating{}
	for _, r := range ratings {
		rr := toRating(r)
		if r.ModelCallID != "" {
			byCall[r.ModelCallID] = append(byCall[r.ModelCallID], rr)
		}
		if r.Target == "turn" && r.TurnID != "" {
			k := turnKey(r.TurnID, r.BranchID)
			byTurn[k] = append(byTurn[k], rr)
		}
		rr.TurnID, rr.ModelCallID, rr.BranchID = r.TurnID, r.ModelCallID, r.BranchID
		bySession[r.SessionID] = append(bySession[r.SessionID], rr)
	}

	enc := &encoder{w: w, opts: opts}
	var stats Stats
	type turnAcc struct {
		rec  turnRecord
		last store.ExportCall
	}
	turns := map[string]*turnAcc{}
	var turnOrder []string
	sessions := map[string]*sessionRecord{}
	var sessionOrder []string

	for _, c := range calls {
		msgs, tools, err := st.ModelCallRequest(ctx, c.ID)
		if err != nil {
			return stats, err
		}
		enc.workDir = c.WorkingDir
		proj := project{ID: c.ProjectID, Name: c.ProjectName}
		if want(opts, "model_call") {
			rec := modelCallRecord{
				Type: "model_call", FormatVersion: FormatVersion, ID: c.ID, SessionID: c.SessionID, TurnID: c.TurnID,
				BranchID: c.BranchID, Task: c.Task,
				Project: proj, CreatedAt: c.CreatedAt, Provider: c.Provider, Model: c.Model, Effort: c.Effort,
				FlitVersion: c.FlitVersion, Role: c.Role, Skills: c.Skills, Params: c.Params, Messages: msgs,
				Tools: tools, Response: c.Response, FinishReason: c.FinishReason, Usage: nonNull(c.Usage),
				Metrics: nonNull(c.Metrics), Error: c.Error,
				Ratings: orEmpty(byCall[c.ID]), TurnRatings: orEmpty(byTurn[turnKey(c.TurnID, c.BranchID)]),
			}
			if keep(opts, append(slices.Clone(rec.Ratings), rec.TurnRatings...)) {
				if err := enc.write(rec); err != nil {
					return stats, err
				}
				stats.ModelCalls++
			}
		}
		if c.Task != "chat" {
			continue // safety checks aren't part of the conversation
		}
		// A turn's conversation is its last call's request plus that
		// call's response. A retry answers the same user message again on
		// another branch: that's another turn.
		tk := turnKey(c.TurnID, c.BranchID)
		t := turns[tk]
		if t == nil {
			t = &turnAcc{rec: turnRecord{Type: "turn", FormatVersion: FormatVersion, TurnID: c.TurnID, BranchID: c.BranchID,
				SessionID: c.SessionID, Project: proj, CreatedAt: c.CreatedAt}}
			turns[tk] = t
			turnOrder = append(turnOrder, tk)
		}
		t.rec.ModelCalls = append(t.rec.ModelCalls, c.ID)
		t.rec.Provider, t.rec.Model, t.rec.Effort, t.rec.FinishReason = c.Provider, c.Model, c.Effort, c.FinishReason
		t.rec.Messages = append(slices.Clone(msgs), c.Response)
		t.rec.Tools = tools
		t.last = c

		s := sessions[c.SessionID]
		if s == nil {
			s = &sessionRecord{Type: "session", FormatVersion: FormatVersion, SessionID: c.SessionID, Project: proj,
				WorkingDir: c.WorkingDir, CreatedAt: c.CreatedAt}
			sessions[c.SessionID] = s
			sessionOrder = append(sessionOrder, c.SessionID)
		}
		if !slices.Contains(s.Turns, c.TurnID) {
			s.Turns = append(s.Turns, c.TurnID)
		}
		if m := c.Provider + "/" + c.Model; !slices.Contains(s.Models, m) {
			s.Models = append(s.Models, m)
		}
	}
	heads, err := branchHeads(ctx, st, sessionOrder, calls)
	if err != nil {
		return stats, err
	}
	for id, bs := range heads {
		if len(bs) > 1 {
			sessions[id].Branches = bs
		}
		for _, b := range bs {
			if t := turns[turnKey(b.HeadTurnID, b.HeadBranchID)]; t != nil && b.HeadTurnID != "" {
				t.rec.BranchHead = true
			}
		}
	}
	if want(opts, "turn") {
		checks, err := permissionChecks(ctx, st, sessionOrder)
		if err != nil {
			return stats, err
		}
		for _, id := range turnOrder {
			t := turns[id]
			t.rec.PermissionChecks = checks[id]
			if t.rec.PermissionChecks == nil {
				t.rec.PermissionChecks = []permissionCheck{}
			}
			t.rec.Ratings = orEmpty(byTurn[id])
			if !keep(opts, t.rec.Ratings) {
				continue
			}
			enc.workDir = t.last.WorkingDir
			if err := enc.write(t.rec); err != nil {
				return stats, err
			}
			stats.Turns++
		}
	}
	if want(opts, "session") {
		for _, id := range sessionOrder {
			s := sessions[id]
			s.Ratings = orEmpty(bySession[id])
			if !keep(opts, s.Ratings) {
				continue
			}
			enc.workDir = s.WorkingDir
			if err := enc.write(s); err != nil {
				return stats, err
			}
			stats.Sessions++
		}
	}
	return stats, nil
}

// turnKey identifies a turn: its user message on a branch.
func turnKey(turnID, branchID string) string { return turnID + "@" + branchID }

// branchHeads finds each session's branches and the last turn on each
// one's path among calls (the calls exported).
func branchHeads(ctx context.Context, st *store.Store, sessions []string, calls []store.ExportCall) (map[string][]branch, error) {
	out := map[string][]branch{}
	for _, id := range sessions {
		evs, err := st.EventsOfKinds(ctx, id, "branch_created", "message_started")
		if err != nil {
			return nil, err
		}
		tree := branches.New(evs)
		seq := map[string]int64{} // message id -> seq of its MessageStarted
		for _, ev := range evs {
			if ms := ev.GetMessageStarted(); ms != nil {
				seq[ms.MessageId] = ev.Seq
			}
		}
		var list []branch
		for _, b := range tree.Branches() {
			path := tree.Path(b.ID)
			rec := branch{ID: b.ID, ParentID: b.Parent, ForkSeq: b.ForkSeq, MessageID: b.MessageID, Kind: branchKind(b.Kind)}
			var headSeq int64
			for _, c := range calls {
				if c.SessionID != id || c.Task != "chat" {
					continue
				}
				if s, ok := seq[c.ID]; ok && s > headSeq && path.Includes(c.BranchID, s) {
					headSeq, rec.HeadTurnID, rec.HeadBranchID = s, c.TurnID, c.BranchID
				}
			}
			list = append(list, rec)
		}
		out[id] = list
	}
	return out, nil
}

func branchKind(k flitv1.BranchKind) string {
	switch k {
	case flitv1.BranchKind_BRANCH_KIND_RETRY:
		return "retry"
	case flitv1.BranchKind_BRANCH_KIND_EDIT:
		return "edit"
	}
	return ""
}

// permissionChecks reads the sessions' safety check verdicts from their
// event logs, by turn (turnKey).
func permissionChecks(ctx context.Context, st *store.Store, sessions []string) (map[string][]permissionCheck, error) {
	out := map[string][]permissionCheck{}
	for _, id := range sessions {
		evs, err := st.EventsOfKinds(ctx, id, "permission_check")
		if err != nil {
			return nil, err
		}
		for _, ev := range evs {
			c := ev.GetPermissionCheck()
			verdict := strings.ToLower(strings.TrimPrefix(c.Verdict.String(), "PERMISSION_VERDICT_"))
			k := turnKey(c.TurnId, ev.BranchId)
			out[k] = append(out[k], permissionCheck{
				ToolCallID: c.ToolCallId, Command: c.Command, Verdict: verdict, Reason: c.Reason,
				Provider: c.Provider, Model: c.Model, ModelCallID: c.ModelCallId,
			})
		}
	}
	return out, nil
}

func orEmpty(rs []rating) []rating {
	if rs == nil {
		return []rating{}
	}
	return rs
}

func nonNull(b json.RawMessage) json.RawMessage {
	if len(b) == 0 || string(b) == "null" {
		return nil
	}
	return b
}

type encoder struct {
	w       io.Writer
	opts    Options
	workDir string
}

func (e *encoder) write(v any) error {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(v); err != nil {
		return err
	}
	line := buf.String()
	if e.opts.Redact {
		paths := map[string]string{}
		for p, r := range e.opts.Paths {
			paths[p] = r
		}
		if e.workDir != "" {
			paths[e.workDir] = "<workdir>"
		}
		line = Redact(line, paths)
	}
	_, err := io.WriteString(e.w, line)
	return err
}

// secretPatterns match strings that look like credentials.
var secretPatterns = []*regexp.Regexp{
	regexp.MustCompile(`-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----`),
	regexp.MustCompile(`\b(sk|pk|rk)-[A-Za-z0-9_-]{16,}`),                                 // OpenAI/Anthropic/Stripe-style keys
	regexp.MustCompile(`\bgh[pousr]_[A-Za-z0-9]{20,}`),                                    // GitHub tokens
	regexp.MustCompile(`\bgithub_pat_[A-Za-z0-9_]{20,}`),                                  // GitHub fine-grained tokens
	regexp.MustCompile(`\bglpat-[A-Za-z0-9_-]{16,}`),                                      // GitLab tokens
	regexp.MustCompile(`\bxox[abprs]-[A-Za-z0-9-]{10,}`),                                  // Slack tokens
	regexp.MustCompile(`\b(AKIA|ASIA)[A-Z0-9]{16}\b`),                                     // AWS access key ids
	regexp.MustCompile(`\bAIza[0-9A-Za-z_-]{30,}`),                                        // Google API keys
	regexp.MustCompile(`\bflitd?_[A-Za-z0-9_-]{20,}`),                                     // flit tokens
	regexp.MustCompile(`\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}`), // JWTs
	regexp.MustCompile(`(?i)\b(bearer)\s+[A-Za-z0-9._~+/=-]{16,}`),
	regexp.MustCompile(`(?i)((?:api[_-]?key|secret|token|password|passwd|auth)["']?\s*[:=]\s*["']?)[^\s"',;]{8,}`),
}

// Redact replaces each path in paths (longest first; JSON-escaped forms
// too) with its placeholder, and secret-looking strings with <redacted>.
func Redact(s string, paths map[string]string) string {
	keys := make([]string, 0, len(paths))
	for p := range paths {
		if p != "" && p != "/" {
			keys = append(keys, p)
		}
	}
	slices.SortFunc(keys, func(a, b string) int { return len(b) - len(a) })
	for _, p := range keys {
		s = strings.ReplaceAll(s, p, paths[p])
		if esc := strings.ReplaceAll(p, `\`, `\\`); esc != p {
			s = strings.ReplaceAll(s, esc, paths[p])
		}
	}
	for _, re := range secretPatterns {
		s = re.ReplaceAllStringFunc(s, func(m string) string {
			if sub := re.FindStringSubmatch(m); len(sub) > 1 && re.NumSubexp() == 1 && strings.ContainsAny(sub[1], ":=") {
				return sub[1] + "<redacted>"
			}
			return "<redacted>"
		})
	}
	return s
}
