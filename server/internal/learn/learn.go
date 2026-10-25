// Package learn is manual self-learning: a pass that reads a finished
// session and proposes lessons for the memory layers (see package memory)
// and skills, and the accepting or rejecting of those proposals. Nothing
// is written until a proposal is accepted.
//
// It is built for small local models: the prompt is short, the transcript
// is trimmed to fit the model's context, and the answer is parsed
// leniently, with one retry when it can't be read at all.
package learn

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/branches"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/memory"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/skills"
	"github.com/iggy/flit/server/internal/store"
)

// Targets of a proposal.
const (
	TargetUser    = memory.User
	TargetProject = memory.Project
	TargetRole    = memory.Role
	TargetSkill   = "skill"
)

// maxProposals caps what one pass may propose; a small model that lists
// everything it saw is not learning.
const maxProposals = 8

// defaultTranscriptBytes is the transcript budget when the learning
// model's context window is unknown.
const defaultTranscriptBytes = 24000

// Service runs learning passes and applies their proposals.
type Service struct {
	Store  *store.Store
	Config func() config.Config
	// DataDir holds the user and project memory files.
	DataDir string
	// RolesDir and SkillsDirs return the roles directory and the global
	// skills directories (optional).
	RolesDir   func() string
	SkillsDirs func() []string
	// Catalog, if set, supplies the learning model's context window and
	// how to turn its reasoning off.
	Catalog *models.Catalog
	HTTP    *http.Client
	Log     *slog.Logger
	// Limiter, if set, caps model calls in flight (providers[].concurrency),
	// shared with the sessions'.
	Limiter *llm.Limiter
}

// Result is what a pass proposed.
type Result struct {
	Proposals []store.Proposal
	// Dropped says why proposals the model made were left out.
	Dropped  []string
	Provider string
	Model    string
}

// ErrNoModel is returned when no model is configured for learning.
var ErrNoModel = errors.New("no model for learning: set agent.tasks.learning (or a chat model) in the config")

// Run reads the session's log and asks the learning model for proposals.
// They are stored as pending, replacing the session's earlier pending
// ones, unless dryRun.
func (s *Service) Run(ctx context.Context, sessionID string, dryRun bool) (Result, error) {
	cfg := s.Config()
	sess, err := s.Store.GetSession(ctx, sessionID)
	if err != nil {
		return Result{}, err
	}
	in, err := s.gather(ctx, cfg, sess)
	if err != nil {
		return Result{}, err
	}

	task, ok := cfg.Task("learning")
	if !ok {
		task = config.TaskModel{Provider: sess.Provider, Model: sess.Model, Effort: sess.Effort}
		if task.Provider == "" || task.Model == "" {
			task = cfg.ChatModel()
		}
	}
	if task.Provider == "" || task.Model == "" {
		return Result{}, ErrNoModel
	}
	provider, ok := cfg.Provider(task.Provider)
	if !ok {
		return Result{}, fmt.Errorf("provider %q is not in the config", task.Provider)
	}
	header, err := provider.Header()
	if err != nil {
		return Result{}, err
	}

	fixed := len(systemPrompt) + len(in.context())
	in.transcript = render(in.turns, s.transcriptBudget(cfg, task, fixed))
	req := llm.Request{
		Model: task.Model,
		Messages: []llm.Message{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: in.context() + "\n## Transcript\n\n" + in.transcript + "\nWhat, if anything, is worth keeping? Answer with only the JSON."},
		},
	}
	s.applyReasoning(&req, task)
	client := &llm.Client{
		BaseURL: provider.BaseURL, APIKey: provider.Key(), Header: header, HTTP: s.http(),
		FirstTokenTimeout: cfg.Agent.ModelFirstTokenTimeout, StallTimeout: cfg.Agent.ModelStallTimeout,
		Limiter: s.Limiter, Provider: provider.Name,
	}

	var list []raw
	for attempt := 0; ; attempt++ {
		res, err := client.Stream(ctx, req, llm.Handler{})
		s.record(ctx, sess, task, req, res, err)
		if err != nil {
			return Result{}, fmt.Errorf("the learning model call failed: %w", err)
		}
		list, err = parse(res.Text)
		if err == nil {
			break
		}
		if attempt == 1 {
			return Result{}, fmt.Errorf("could not read the learning model's answer: %w", err)
		}
		req.Messages = append(req.Messages,
			llm.Message{Role: "assistant", Content: res.Text},
			llm.Message{Role: "user", Content: `That couldn't be read. Reply with only a JSON object like {"proposals": [...]}, or {"proposals": []} if nothing is worth keeping.`})
	}

	out := Result{Provider: task.Provider, Model: task.Model}
	seen := map[string]bool{}
	for _, r := range list {
		p, why := in.proposal(r)
		if why != "" {
			out.Dropped = append(out.Dropped, why)
			continue
		}
		if seen[p.Target+"\x00"+p.NewText+"\x00"+p.OldText] {
			continue
		}
		if len(out.Proposals) == maxProposals {
			out.Dropped = append(out.Dropped, fmt.Sprintf("more than %d proposals; the rest were left out", maxProposals))
			break
		}
		seen[p.Target+"\x00"+p.NewText+"\x00"+p.OldText] = true
		p.ID, p.SessionID, p.TeamID, p.ProjectID = newID("lrn"), sess.ID, sess.TeamID, sess.ProjectID
		p.Provider, p.Model, p.Status, p.CreatedAt = task.Provider, task.Model, store.ProposalPending, time.Now()
		out.Proposals = append(out.Proposals, p)
	}
	if !dryRun {
		if err := s.Store.ReplacePendingProposals(ctx, sess.ID, out.Proposals); err != nil {
			return Result{}, err
		}
	}
	return out, nil
}

const systemPrompt = `You review a finished session of a coding agent and pick out lessons worth remembering in future sessions. Most sessions teach nothing new; then propose nothing.

Keep a lesson only if it is:
- durable: true beyond this one task (a preference the user showed, a fact or convention of the project, a fix for a mistake the agent made),
- specific: it names the command, file, tool or habit,
- not already in the memory shown.
Skip one-off details, things any good engineer knows, and secrets.

Where a lesson goes (target):
- user: the user's preferences and habits, true in any project.
- project: facts and conventions of this project.
- role: how the agent's role should work (only when role memory is shown).
- skill: a reusable multi-step procedure. Give skill (lowercase-hyphen name), description (when to use it) and body (Markdown steps).

Write cue as the situation ("When running the tests"), lesson as one or two imperative sentences, evidence as turn refs ("T2, T5").
To fix or drop an existing memory entry use action update or remove with its entry id (e.g. "P2").

Answer with only JSON:
{"proposals": [{"action": "add", "target": "project", "cue": "...", "lesson": "...", "evidence": "T3"}]}
Fields: action (add, update, remove), target (user, project, role, skill), entry (for update and remove), cue, lesson, evidence, and for skills skill, description, body.
Nothing worth keeping: {"proposals": []}`

// input is what a pass knows about the session.
type input struct {
	sess        store.Session
	projectName string
	turns       []turn
	transcript  string
	layers      []layer
	skills      []skills.Skill
	globalSkill []string
}

// layer is a memory file the pass may change.
type layer struct {
	kind   string
	prefix string // entry ids are prefix + number
	path   string
	name   string // the project's or role's
	text   string
	items  []memory.Item
}

func (s *Service) gather(ctx context.Context, cfg config.Config, sess store.Session) (*input, error) {
	in := &input{sess: sess}
	events, err := s.Store.Events(ctx, sess.ID, 0, math.MaxInt64)
	if err != nil {
		return nil, err
	}
	events = branches.New(events).Path(sess.BranchID).Filter(events)
	ratings, err := s.Store.RatingsFor(ctx, []string{sess.ID})
	if err != nil {
		return nil, err
	}
	in.turns = turns(events, ratings)
	if len(in.turns) == 0 {
		return nil, errors.New("the session has no messages yet")
	}
	if p, err := s.Store.GetProject(ctx, sess.ProjectID); err == nil {
		in.projectName = p.Name
	}

	add := func(kind, prefix, path, name string) error {
		text, _, err := memory.ReadCapped(path, cfg.Learning.MemoryMaxBytes)
		if err != nil {
			return err
		}
		in.layers = append(in.layers, layer{kind: kind, prefix: prefix, path: path, name: name, text: text, items: memory.Items(text)})
		return nil
	}
	if s.DataDir != "" {
		if err := add(memory.User, "U", memory.UserPath(s.DataDir), ""); err != nil {
			return nil, err
		}
		if sess.ProjectID != "" {
			if err := add(memory.Project, "P", memory.ProjectPath(s.DataDir, sess.ProjectID), in.projectName); err != nil {
				return nil, err
			}
		}
	}
	if sess.Role != "" && s.RolesDir != nil {
		if r, err := roles.Get(s.RolesDir(), sess.Role); err == nil {
			if path := r.MemoryPath(sess.WorkingDir); path != "" {
				if err := add(memory.Role, "R", path, r.Name); err != nil {
					return nil, err
				}
			}
		}
	}
	if s.SkillsDirs != nil {
		in.globalSkill = s.SkillsDirs()
	}
	list, _ := skills.Load(skills.SessionDirs(sess.WorkingDir, in.globalSkill))
	in.skills = skills.WithBuiltin(list)
	return in, nil
}

// context is the part of the user message before the transcript.
func (in *input) context() string {
	var b strings.Builder
	fmt.Fprintf(&b, "## Session\n\nWorking directory: %s\n", in.sess.WorkingDir)
	if in.projectName != "" {
		fmt.Fprintf(&b, "Project: %s\n", in.projectName)
	}
	b.WriteString("\n## Memory\n")
	for _, l := range in.layers {
		title := l.kind
		if l.name != "" {
			title += " (" + l.name + ")"
		}
		fmt.Fprintf(&b, "\n### %s\n", title)
		if len(l.items) == 0 {
			if l.text != "" {
				b.WriteString(l.text + "\n")
			} else {
				b.WriteString("(empty)\n")
			}
			continue
		}
		for i, it := range l.items {
			fmt.Fprintf(&b, "%s%d. %s\n", l.prefix, i+1, strings.TrimPrefix(strings.TrimPrefix(it.Text, "- "), "* "))
		}
	}
	if len(in.skills) > 0 {
		b.WriteString("\n## Skills\n\n")
		for _, sk := range in.skills {
			fmt.Fprintf(&b, "- %s: %s\n", sk.Name, cut(strings.Join(strings.Fields(sk.Description), " "), 200))
		}
	}
	return b.String()
}

// transcriptBudget is how many bytes of transcript fit: the configured
// cap, else about half the model's context window less the rest of the
// prompt.
func (s *Service) transcriptBudget(cfg config.Config, task config.TaskModel, fixed int) int {
	if n := cfg.Learning.TranscriptMaxBytes; n > 0 {
		return n
	}
	if s.Catalog == nil {
		return defaultTranscriptBytes
	}
	m, ok := s.Catalog.Lookup(task.Provider, task.Model)
	if !ok || m.ContextLength <= 0 {
		return defaultTranscriptBytes
	}
	// ~3 bytes a token; leave room for the answer (and any thinking).
	n := int(m.ContextLength)*3/2 - fixed
	return min(max(n, 4000), 400000)
}

func (s *Service) applyReasoning(req *llm.Request, task config.TaskModel) {
	if task.Effort == "" {
		return
	}
	var kind models.Kind
	if s.Catalog != nil {
		kind = s.Catalog.Kind(task.Provider)
	}
	if task.Effort == "off" {
		if kind == models.KindLlamaCpp {
			req.ChatTemplateKwargs = map[string]any{"enable_thinking": false}
		}
		return
	}
	req.ReasoningEffort = task.Effort
}

func (s *Service) http() *http.Client {
	if s.HTTP != nil {
		return s.HTTP
	}
	return http.DefaultClient
}

// record stores the call for export, like the agent's other task calls.
func (s *Service) record(ctx context.Context, sess store.Session, task config.TaskModel, req llm.Request, res *llm.Result, callErr error) {
	var messages [][]byte
	for _, m := range req.Messages {
		b, _ := json.Marshal(m)
		messages = append(messages, b)
	}
	c := &store.ModelCall{
		ID: newID("msg"), SessionID: sess.ID, TeamID: sess.TeamID, ProjectID: sess.ProjectID, BranchID: sess.BranchID,
		Task: "learning", Provider: task.Provider, Model: task.Model, Effort: task.Effort, FlitVersion: buildinfo.Get().Version,
	}
	c.Params, _ = json.Marshal(map[string]any{"model": req.Model, "reasoning_effort": req.ReasoningEffort})
	if res != nil {
		c.Response, _ = json.Marshal(map[string]any{"role": "assistant", "content": res.Text, "reasoning_content": res.Reasoning})
		c.FinishReason = res.FinishReason
		if res.Usage != nil {
			c.Usage, _ = json.Marshal(res.Usage)
		}
	}
	if callErr != nil {
		c.Error = callErr.Error()
	}
	if err := s.Store.RecordModelCall(ctx, c, messages, nil); err != nil && s.Log != nil {
		s.Log.Warn("could not record the learning model call", "session", sess.ID, "err", err)
	}
}

var (
	entryRef = regexp.MustCompile(`(?i)^\s*([upr])?\s*(\d+)\s*$`)
	nonName  = regexp.MustCompile(`[^a-z0-9]+`)
)

// proposal checks one raw proposal and turns it into a stored one, or
// says why it was left out.
func (in *input) proposal(r raw) (store.Proposal, string) {
	action := normAction(r.Action)
	target := normTarget(r.Target)
	if target == "" && r.Skill != "" && r.Body != "" {
		target = TargetSkill
	}
	if target == "" {
		target = TargetProject
	}
	if action == "" {
		if r.Entry != "" && r.Lesson == "" {
			action = "remove"
		} else if r.Entry != "" {
			action = "update"
		} else {
			action = "add"
		}
	}
	p := store.Proposal{Action: action, Target: target, Cue: r.Cue, Lesson: r.Lesson, Evidence: r.Evidence}
	if target == TargetSkill {
		return in.skillProposal(p, r)
	}

	var l *layer
	for i := range in.layers {
		if in.layers[i].kind == target {
			l = &in.layers[i]
		}
	}
	if l == nil {
		return p, fmt.Sprintf("%s memory isn't available for this session (%q)", target, oneLine(r.Lesson))
	}
	p.Path = l.path
	if action != "remove" && strings.TrimSpace(r.Lesson) == "" {
		return p, "a proposal without a lesson"
	}
	ev := oneLine(r.Evidence)
	if ev != "" {
		ev = shortID(in.sess.ID) + " " + ev
	}
	p.NewText = memory.Entry{Cue: r.Cue, Lesson: r.Lesson, Evidence: ev}.Render()
	if action == "add" {
		for _, it := range l.items {
			if sameLesson(it.Text, r.Lesson) {
				return p, fmt.Sprintf("already in %s memory: %q", target, oneLine(r.Lesson))
			}
		}
		return p, ""
	}
	m := entryRef.FindStringSubmatch(r.Entry)
	if m == nil || (m[1] != "" && !strings.EqualFold(m[1], l.prefix)) {
		return p, fmt.Sprintf("%s refers to entry %q, which isn't one of %s1..%s%d", action, r.Entry, l.prefix, l.prefix, len(l.items))
	}
	n, _ := strconv.Atoi(m[2])
	if n < 1 || n > len(l.items) {
		return p, fmt.Sprintf("%s refers to entry %q, which isn't one of %s1..%s%d", action, r.Entry, l.prefix, l.prefix, len(l.items))
	}
	p.OldText = l.items[n-1].Text
	if action == "remove" {
		p.NewText = ""
	} else if sameLesson(p.OldText, r.Lesson) {
		return p, fmt.Sprintf("update of %s leaves its lesson as it is", r.Entry)
	}
	return p, ""
}

func (in *input) skillProposal(p store.Proposal, r raw) (store.Proposal, string) {
	name := strings.Trim(nonName.ReplaceAllString(strings.ToLower(r.Skill), "-"), "-")
	if name == "" || len(name) > 64 {
		return p, fmt.Sprintf("a skill proposal without a usable name (%q)", r.Skill)
	}
	p.Skill = name
	if p.Action == "remove" {
		return p, fmt.Sprintf("removing skill %q: flit doesn't delete skills; remove its directory yourself if you agree", name)
	}
	var existing *skills.Skill
	for i := range in.skills {
		if in.skills[i].Name == name {
			existing = &in.skills[i]
		}
	}
	body := strings.TrimSpace(r.Body)
	if body == "" {
		return p, fmt.Sprintf("skill %q has no body", name)
	}
	var md string
	if strings.HasPrefix(body, "---") {
		md = body + "\n"
	} else {
		desc := oneLine(r.Description)
		if desc == "" {
			desc = oneLine(r.Cue + " " + r.Lesson)
		}
		front, _ := yamlLine("description", desc)
		md = fmt.Sprintf("---\nname: %s\n%s---\n\n%s\n", name, front, body)
	}
	if _, err := skills.Parse([]byte(md), name); err != nil {
		return p, fmt.Sprintf("skill %q is not a valid SKILL.md: %v", name, err)
	}
	p.NewText = md
	switch {
	case existing != nil && existing.Source != skills.BuiltinSource && existing.Dir != "":
		p.Action = "update"
		p.Path = filepath.Join(existing.Dir, skills.FileName)
		old, err := os.ReadFile(p.Path)
		if err != nil {
			return p, fmt.Sprintf("skill %q: %v", name, err)
		}
		p.OldText = string(old)
		if strings.TrimSpace(p.OldText) == strings.TrimSpace(md) {
			return p, fmt.Sprintf("skill %q is unchanged", name)
		}
	default:
		// New, or overriding a built-in one: into the repo, else the
		// first global skills dir.
		p.Action = "add"
		if existing != nil {
			p.OldText = "(built-in skill " + name + ")"
		}
		dir := ""
		if root := skills.GitRoot(in.sess.WorkingDir); root != "" {
			dir = filepath.Join(root, filepath.FromSlash(skills.RepoDirs[0]))
		} else if len(in.globalSkill) > 0 {
			dir = in.globalSkill[0]
		}
		if dir == "" {
			return p, fmt.Sprintf("skill %q: the session isn't in a git repo and no skills_dirs are configured", name)
		}
		p.Path = filepath.Join(dir, name, skills.FileName)
	}
	return p, ""
}

func yamlLine(key, value string) (string, error) {
	b, err := json.Marshal(value) // a JSON string is a valid YAML scalar
	return key + ": " + string(b) + "\n", err
}

func normAction(a string) string {
	switch strings.ToLower(strings.TrimSpace(a)) {
	case "add", "new", "create", "append":
		return "add"
	case "update", "edit", "change", "replace", "modify":
		return "update"
	case "remove", "delete", "drop":
		return "remove"
	}
	return ""
}

func normTarget(t string) string {
	t = strings.ToLower(t)
	for _, k := range []string{TargetSkill, TargetUser, TargetProject, TargetRole} {
		if strings.Contains(t, k) {
			return k
		}
	}
	return ""
}

func sameLesson(item, lesson string) bool {
	l := strings.ToLower(oneLine(lesson))
	return l != "" && strings.Contains(strings.ToLower(oneLine(item)), l)
}

func oneLine(s string) string { return strings.Join(strings.Fields(s), " ") }

func shortID(id string) string {
	if len(id) > 12 {
		return id[:12]
	}
	return id
}

func newID(prefix string) string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return fmt.Sprintf("%s_%012x%s", prefix, time.Now().UnixMilli(), hex.EncodeToString(b))
}

// ErrDecided is returned when a proposal was already accepted or rejected.
var ErrDecided = errors.New("the proposal was already decided")

// Accept writes a pending proposal, with text in place of its proposed
// text when text is non-nil, and marks it accepted.
func (s *Service) Accept(ctx context.Context, id string, text *string) (store.Proposal, error) {
	p, err := s.pending(ctx, id)
	if err != nil {
		return p, err
	}
	newText := p.NewText
	if text != nil {
		newText = strings.TrimSpace(*text)
	}
	switch p.Target {
	case TargetSkill:
		if err := writeSkill(p, newText); err != nil {
			return p, err
		}
		newText = strings.TrimSpace(newText) + "\n"
	default:
		if p.Action != "remove" {
			if newText == "" {
				return p, errors.New("the entry is empty; reject the proposal instead")
			}
			if !strings.HasPrefix(newText, "- ") && !strings.HasPrefix(newText, "* ") {
				newText = "- " + newText
			}
		}
		name := ""
		if p.Target == TargetProject {
			if pr, err := s.Store.GetProject(ctx, p.ProjectID); err == nil {
				name = pr.Name
			}
		}
		if err := memory.Apply(p.Path, memory.Change{Action: p.Action, Old: p.OldText, New: newText, Header: memory.Header(p.Target, name)}); err != nil {
			return p, err
		}
	}
	if err := s.Store.DecideProposal(ctx, id, store.ProposalAccepted, newText); err != nil {
		return p, err
	}
	p.NewText, p.Status, p.DecidedAt = newText, store.ProposalAccepted, time.Now()
	return p, nil
}

// Reject marks a pending proposal rejected; nothing is written.
func (s *Service) Reject(ctx context.Context, id string) (store.Proposal, error) {
	p, err := s.pending(ctx, id)
	if err != nil {
		return p, err
	}
	if err := s.Store.DecideProposal(ctx, id, store.ProposalRejected, p.NewText); err != nil {
		return p, err
	}
	p.Status, p.DecidedAt = store.ProposalRejected, time.Now()
	return p, nil
}

func (s *Service) pending(ctx context.Context, id string) (store.Proposal, error) {
	p, err := s.Store.GetProposal(ctx, id)
	if err != nil {
		return p, err
	}
	if p.Status != store.ProposalPending {
		return p, ErrDecided
	}
	return p, nil
}

func writeSkill(p store.Proposal, text string) error {
	if _, err := skills.Parse([]byte(text), p.Skill); err != nil {
		return err
	}
	cur, err := os.ReadFile(p.Path)
	switch {
	case errors.Is(err, os.ErrNotExist):
		if p.Action == "update" {
			return memory.ErrChanged
		}
	case err != nil:
		return err
	case p.Action == "add":
		return fmt.Errorf("%s already exists; it was created since the proposal was made", p.Path)
	case string(cur) != p.OldText:
		return fmt.Errorf("%s was edited since the proposal was made", p.Path)
	}
	return memory.WriteFile(p.Path, []byte(strings.TrimSpace(text)+"\n"))
}

// ProposalProto converts a proposal for the API.
func ProposalProto(p store.Proposal) *flitv1.LearnProposal {
	out := &flitv1.LearnProposal{
		Id: p.ID, SessionId: p.SessionID, ProjectId: p.ProjectID, Skill: p.Skill,
		Cue: p.Cue, Lesson: p.Lesson, Evidence: p.Evidence, OldText: p.OldText, NewText: p.NewText, Path: p.Path,
		Provider: p.Provider, Model: p.Model, CreatedAtMs: p.CreatedAt.UnixMilli(),
	}
	switch p.Action {
	case "add":
		out.Action = flitv1.LearnAction_LEARN_ACTION_ADD
	case "update":
		out.Action = flitv1.LearnAction_LEARN_ACTION_UPDATE
	case "remove":
		out.Action = flitv1.LearnAction_LEARN_ACTION_REMOVE
	}
	switch p.Target {
	case TargetUser:
		out.Target = flitv1.LearnTarget_LEARN_TARGET_USER
	case TargetProject:
		out.Target = flitv1.LearnTarget_LEARN_TARGET_PROJECT
	case TargetRole:
		out.Target = flitv1.LearnTarget_LEARN_TARGET_ROLE
	case TargetSkill:
		out.Target = flitv1.LearnTarget_LEARN_TARGET_SKILL
	}
	switch p.Status {
	case store.ProposalPending:
		out.Status = flitv1.LearnStatus_LEARN_STATUS_PENDING
	case store.ProposalAccepted:
		out.Status = flitv1.LearnStatus_LEARN_STATUS_ACCEPTED
	case store.ProposalRejected:
		out.Status = flitv1.LearnStatus_LEARN_STATUS_REJECTED
	}
	if !p.DecidedAt.IsZero() {
		out.DecidedAtMs = p.DecidedAt.UnixMilli()
	}
	return out
}
