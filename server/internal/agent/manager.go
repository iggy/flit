// Package agent runs flit's sessions: the agent loop that calls the model
// and tools, and the per-session event log that clients attach to.
//
// Every observable step of a turn is appended to the session's event log
// (persisted in the store) and then published to attached clients, in that
// order, so replaying the log from any sequence number yields exactly what a
// live client saw.
package agent

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/mcpclient"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/skills"
	"github.com/iggy/flit/server/internal/store"
)

// Errors returned by Manager. The API layer maps them to status codes.
var (
	ErrNotFound   = store.ErrNotFound
	ErrBusy       = errors.New("a turn is already running in this session")
	ErrPromptGone = errors.New("prompt is not pending (already answered, or the turn ended)")
	ErrInvalid    = errors.New("invalid argument")
	ErrSlowClient = errors.New("client fell too far behind")
	// ErrNoCallToRetry: RetryModelCall with no model call waiting (none
	// running, or the reply is already streaming).
	ErrNoCallToRetry = errors.New("no model call is waiting for the model to answer")
	// ErrQueueGone: the queued message was delivered or cancelled already.
	ErrQueueGone   = errors.New("message is not queued (already delivered or cancelled)")
	errInterrupted = errors.New("interrupted")
)

func invalid(format string, args ...any) error {
	return fmt.Errorf("%w: %s", ErrInvalid, fmt.Sprintf(format, args...))
}

// Manager owns all sessions.
type Manager struct {
	store *store.Store
	cfg   func() config.Config
	log   *slog.Logger
	http  *http.Client

	// Catalog, if set, supplies context windows for models. Set before use.
	Catalog *models.Catalog
	// RolesDir, if set, returns the roles directory. Set before use.
	RolesDir func() string
	// MCP, if set, runs MCP servers. Set before use.
	MCP *mcpclient.Manager
	// SkillsDirs, if set, returns the skills directories. Set before use.
	SkillsDirs func() []string

	// kv tracks llama.cpp slots and prompt cache save files.
	kv kvPool

	mu       sync.Mutex
	sessions map[string]*session
	closed   bool
	// closing is closed without the lock, for sessions holding theirs.
	closing atomic.Bool
	turns   sync.WaitGroup
}

// NewManager returns a Manager. cfg is called whenever the current config
// is needed, so config reloads apply to the next model call or tool run.
// Sessions left mid-turn by a previous run are marked stuck.
func NewManager(ctx context.Context, st *store.Store, cfg func() config.Config, log *slog.Logger) (*Manager, error) {
	m := &Manager{store: st, cfg: cfg, log: log, http: &http.Client{}, sessions: map[string]*session{}}
	ids, err := st.SessionIDsInStates(ctx, flitv1.TaskState_TASK_STATE_WORKING, flitv1.TaskState_TASK_STATE_WAITING)
	if err != nil {
		return nil, err
	}
	for _, id := range ids {
		s, err := m.session(ctx, id)
		if err != nil {
			return nil, err
		}
		if _, err := s.append(stateChanged(flitv1.TaskState_TASK_STATE_STUCK, "flit restarted during the turn")); err != nil {
			return nil, err
		}
	}
	return m, nil
}

// Close interrupts all running turns and waits for them to stop.
func (m *Manager) Close() {
	m.closing.Store(true)
	m.mu.Lock()
	m.closed = true
	for _, s := range m.sessions {
		s.interrupt()
	}
	m.mu.Unlock()
	m.turns.Wait()
}

func newID(prefix string) string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return fmt.Sprintf("%s_%012x%s", prefix, time.Now().UnixMilli(), hex.EncodeToString(b))
}

// session returns the runtime for a stored session, loading it if needed.
func (m *Manager) session(ctx context.Context, id string) (*session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if s, ok := m.sessions[id]; ok {
		return s, nil
	}
	info, err := m.store.GetSession(ctx, id)
	if err != nil {
		return nil, err
	}
	s := newSession(m, info)
	if err := s.loadAllowed(ctx); err != nil {
		return nil, err
	}
	if err := s.loadQueue(ctx); err != nil {
		return nil, err
	}
	m.sessions[id] = s
	return s, nil
}

// CreateOptions are the inputs to Create.
type CreateOptions struct {
	WorkingDir string
	Title      string
	Provider   string
	Model      string
	Effort     string
	// Role names a role file; its model and effort are defaults.
	Role string
	// ProjectID is the project; empty means Scratch. Without a WorkingDir,
	// the project's directory is used.
	ProjectID string
	// Yolo turns yolo mode on or off; nil means the config's shell.yolo.
	Yolo *bool
}

// contextLength is the model's context window, if the catalog knows it.
func (m *Manager) contextLength(provider, model string) int64 {
	if m.Catalog == nil || provider == "" || model == "" {
		return 0
	}
	if info, ok := m.Catalog.Lookup(provider, model); ok {
		return info.ContextLength
	}
	return 0
}

// role loads a role by name.
func (m *Manager) role(name string) (*roles.Role, error) {
	if name == "" {
		return nil, nil
	}
	if m.RolesDir == nil {
		return nil, invalid("roles are not enabled")
	}
	r, err := roles.Get(m.RolesDir(), name)
	if err != nil {
		return nil, invalid("%v", err)
	}
	return &r, nil
}

// Create starts a new idle session in the default team and project.
func (m *Manager) Create(ctx context.Context, o CreateOptions) (store.Session, error) {
	projectID := o.ProjectID
	if projectID == "" {
		projectID = store.DefaultProjectID
	}
	project, err := m.store.GetProject(ctx, projectID)
	if errors.Is(err, store.ErrNotFound) {
		return store.Session{}, invalid("no project %q", projectID)
	}
	if err != nil {
		return store.Session{}, err
	}
	if o.WorkingDir == "" {
		o.WorkingDir = project.Directory
	}
	if o.WorkingDir == "" {
		return store.Session{}, invalid("working_dir is required (the project has no directory)")
	}
	if !filepath.IsAbs(o.WorkingDir) {
		return store.Session{}, invalid("working_dir must be an absolute path")
	}
	dir := filepath.Clean(o.WorkingDir)
	if fi, err := os.Stat(dir); err != nil || !fi.IsDir() {
		return store.Session{}, invalid("working_dir %s is not an existing directory", dir)
	}
	role, err := m.role(o.Role)
	if err != nil {
		return store.Session{}, err
	}
	provider, model, effort := o.Provider, o.Model, o.Effort
	if provider == "" && role != nil && role.Provider != "" {
		provider, model = role.Provider, role.Model
	}
	if effort == "" && role != nil {
		effort = role.Effort
	}
	if provider == "" {
		chat := m.cfg().ChatModel()
		if chat.Provider != "" {
			provider, model = chat.Provider, chat.Model
			if effort == "" {
				effort = chat.Effort
			}
		}
	}
	provider, model, err = m.resolveModel(provider, model)
	if err != nil {
		return store.Session{}, err
	}
	info := store.Session{
		ID:         newID("ses"),
		TeamID:     project.TeamID,
		ProjectID:  project.ID,
		Title:      o.Title,
		WorkingDir: dir,
		Provider:   provider,
		Model:      model,
		State:      flitv1.TaskState_TASK_STATE_IDLE,
		Effort:     effort,
		Role:       o.Role,
		Yolo:       m.cfg().Shell.Yolo,
	}
	if o.Yolo != nil {
		info.Yolo = *o.Yolo
	}
	for _, srv := range m.cfg().MCPServers {
		if srv.EnabledByDefault() {
			info.MCPServers = append(info.MCPServers, srv.Name)
		}
	}
	info.ContextLength = m.contextLength(provider, model)
	if err := m.store.CreateSession(ctx, &info); err != nil {
		return store.Session{}, err
	}
	return info, nil
}

// resolveModel fills in config defaults and checks the provider exists.
// The model may stay empty until a turn needs it.
func (m *Manager) resolveModel(provider, model string) (string, string, error) {
	cfg := m.cfg()
	if provider == "" {
		provider = cfg.Agent.Provider
		if provider == "" && len(cfg.Providers) == 1 {
			provider = cfg.Providers[0].Name
		}
		if model == "" {
			model = cfg.Agent.Model
		}
	}
	if provider != "" {
		if _, ok := cfg.Provider(provider); !ok {
			return "", "", invalid("provider %q is not configured", provider)
		}
	}
	return provider, model, nil
}

// Get returns a session.
func (m *Manager) Get(ctx context.Context, id string) (store.Session, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.snapshot(), nil
}

// List returns sessions, most recently updated first, optionally only one
// project's.
func (m *Manager) List(ctx context.Context, projectID string, limit, offset int) ([]store.Session, error) {
	list, err := m.store.ListSessions(ctx, projectID, limit, offset)
	if err != nil {
		return nil, err
	}
	// Prefer the in-memory copy of loaded sessions, so state and last_seq
	// match what Attach sees.
	m.mu.Lock()
	defer m.mu.Unlock()
	for i, info := range list {
		if s, ok := m.sessions[info.ID]; ok {
			list[i] = s.snapshot()
		}
	}
	return list, nil
}

// Attach calls send with the session's events from fromSeq on, then with
// new events as they happen, until ctx ends or send fails.
func (m *Manager) Attach(ctx context.Context, id string, fromSeq int64, send func(*flitv1.Event) error) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.attach(ctx, fromSeq, send)
}

// Send adds a user message and starts a turn. It returns the sequence number
// of the message's first event.
func (m *Manager) Send(ctx context.Context, id, text string) (int64, error) {
	if strings.TrimSpace(text) == "" {
		return 0, invalid("text is empty")
	}
	res, err := m.SendMessage(ctx, id, text, "")
	return res.Seq, err
}

// SendMessage adds a user message from client: it starts a turn, or is
// queued for the running turn's next step (see SendResult). Empty text
// delivers the queue, if there is one.
func (m *Manager) SendMessage(ctx context.Context, id, text, client string) (SendResult, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return SendResult{}, err
	}
	if m.closing.Load() {
		return SendResult{}, errors.New("flit is shutting down")
	}
	return s.send(text, client)
}

// EditQueuedMessage changes a queued message's text.
func (m *Manager) EditQueuedMessage(ctx context.Context, id, queueID, text string) error {
	if strings.TrimSpace(text) == "" {
		return invalid("text is empty")
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.updateQueued(queueID, text, false)
}

// CancelQueuedMessage withdraws a queued message.
func (m *Manager) CancelQueuedMessage(ctx context.Context, id, queueID string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.updateQueued(queueID, "", true)
}

// Interrupt stops the session's running turn. It reports whether one was
// running.
func (m *Manager) Interrupt(ctx context.Context, id string) (bool, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return false, err
	}
	return s.interrupt(), nil
}

// touchModel marks the session's model as just used, for the model
// picker's recents. Failures are logged; they never fail what used it.
func (m *Manager) touchModel(info store.Session) {
	if info.Provider == "" || info.Model == "" {
		return
	}
	k := store.ModelKey{Provider: info.Provider, Model: info.Model}
	if err := m.store.TouchModel(context.Background(), info.TeamID, k, time.Now()); err != nil {
		m.log.Warn("record model use", "session", info.ID, "err", err)
	}
}

// RetryModelCall gives up on the session's model call and sends it again.
// It only works while the model hasn't sent any of the reply.
func (m *Manager) RetryModelCall(ctx context.Context, id string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.retryCall()
}

// EndReasoning asks the model of the session's running call to stop
// thinking and answer (llama.cpp).
func (m *Manager) EndReasoning(ctx context.Context, id, client string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.endReasoning(ctx, client)
}

// Answer is a reply to a prompt.
type Answer struct {
	Allow bool
	// ForSession allows this and the prompt's session patterns for the
	// rest of the session (implies Allow).
	ForSession bool
	Client     string
}

// AnswerPrompt answers a pending prompt.
func (m *Manager) AnswerPrompt(ctx context.Context, id, promptID string, a Answer) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.answer(promptID, a)
}

// SetModel changes the session's provider and model, effective from its
// next model call.
func (m *Manager) SetModel(ctx context.Context, id, provider, model string) (store.Session, error) {
	if provider == "" || model == "" {
		return store.Session{}, invalid("provider and model are required")
	}
	if _, ok := m.cfg().Provider(provider); !ok {
		return store.Session{}, invalid("provider %q is not configured", provider)
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.setModel(ctx, provider, model)
}

// SetEffort changes the session's reasoning effort, effective from its next
// model call. Empty means the model's default.
func (m *Manager) SetEffort(ctx context.Context, id, effort string) (store.Session, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.setEffort(ctx, effort)
}

// SetYolo turns the session's yolo mode on or off, effective from its next
// shell command. client names who changed it, for the log.
func (m *Manager) SetYolo(ctx context.Context, id string, yolo bool, client string) (store.Session, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.setYolo(ctx, yolo, client)
}

// Projects lists the default team's projects.
func (m *Manager) Projects(ctx context.Context) ([]store.Project, error) {
	return m.store.ListProjects(ctx, store.DefaultTeamID)
}

// CreateProject adds a project for an existing directory.
func (m *Manager) CreateProject(ctx context.Context, dir, name string) (store.Project, error) {
	if !filepath.IsAbs(dir) {
		return store.Project{}, invalid("directory must be an absolute path")
	}
	dir = filepath.Clean(dir)
	if fi, err := os.Stat(dir); err != nil || !fi.IsDir() {
		return store.Project{}, invalid("directory %s does not exist", dir)
	}
	if strings.TrimSpace(name) == "" {
		name = filepath.Base(dir)
	}
	p := store.Project{ID: newID("proj"), TeamID: store.DefaultTeamID, Name: strings.TrimSpace(name), Directory: dir}
	if err := m.store.CreateProject(ctx, &p); err != nil {
		if errors.Is(err, store.ErrExists) {
			return store.Project{}, invalid("%v", err)
		}
		return store.Project{}, err
	}
	return m.store.GetProject(ctx, p.ID)
}

// MoveSession moves a session to another project.
func (m *Manager) MoveSession(ctx context.Context, id, projectID string) (store.Session, error) {
	p, err := m.store.GetProject(ctx, projectID)
	if errors.Is(err, store.ErrNotFound) {
		return store.Session{}, invalid("no project %q", projectID)
	}
	if err != nil {
		return store.Session{}, err
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.move(ctx, p.ID)
}

// Rating is a good/bad mark on a turn or a model.
type Rating struct {
	Target    flitv1.RatingTarget
	Good      bool
	MessageID string
	Note      string
	Client    string
}

// Rate records a rating as a Feedback event.
func (m *Manager) Rate(ctx context.Context, id string, r Rating) error {
	if r.Target == flitv1.RatingTarget_RATING_TARGET_UNSPECIFIED {
		return invalid("target is required")
	}
	if r.Target == flitv1.RatingTarget_RATING_TARGET_TURN && r.MessageID == "" {
		return invalid("rating a turn needs message_id")
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.rate(ctx, r)
}

// MCPServerStatus is an MCP server as one session sees it.
type MCPServerStatus struct {
	mcpclient.Status
	Enabled bool
}

// MCPServers lists the configured MCP servers for a session.
func (m *Manager) MCPServers(ctx context.Context, id string) ([]MCPServerStatus, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return nil, err
	}
	enabled := s.snapshot().MCPServers
	var out []MCPServerStatus
	if m.MCP == nil {
		return out, nil
	}
	for _, st := range m.MCP.Status() {
		out = append(out, MCPServerStatus{Status: st, Enabled: slices.Contains(enabled, st.Name)})
	}
	return out, nil
}

// SetMCPServer enables or disables an MCP server for a session.
func (m *Manager) SetMCPServer(ctx context.Context, id, server string, enabled bool) (store.Session, error) {
	if _, ok := m.cfg().MCPServer(server); !ok {
		return store.Session{}, invalid("no MCP server named %q in the config", server)
	}
	s, err := m.session(ctx, id)
	if err != nil {
		return store.Session{}, err
	}
	return s.setMCPServer(ctx, server, enabled)
}

// SetProjectExport includes or excludes a project from export.
func (m *Manager) SetProjectExport(ctx context.Context, id string, enabled bool) (store.Project, error) {
	if err := m.store.SetProjectExport(ctx, id, enabled); err != nil {
		return store.Project{}, err
	}
	return m.store.GetProject(ctx, id)
}

// Skills lists the skills a session's agent can load, with where each
// came from.
func (m *Manager) Skills(ctx context.Context, id string) ([]skills.Skill, error) {
	s, err := m.session(ctx, id)
	if err != nil {
		return nil, err
	}
	var global []string
	if m.SkillsDirs != nil {
		global = m.SkillsDirs()
	}
	list, _ := skills.Load(skills.SessionDirs(s.snapshot().WorkingDir, global))
	return skills.WithBuiltin(list), nil
}
