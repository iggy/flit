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
	"strings"
	"sync"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/roles"
	"github.com/iggy/flit/server/internal/store"
)

// Errors returned by Manager. The API layer maps them to status codes.
var (
	ErrNotFound    = store.ErrNotFound
	ErrBusy        = errors.New("a turn is already running in this session")
	ErrPromptGone  = errors.New("prompt is not pending (already answered, or the turn ended)")
	ErrInvalid     = errors.New("invalid argument")
	ErrSlowClient  = errors.New("client fell too far behind")
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

	mu       sync.Mutex
	sessions map[string]*session
	closed   bool
	turns    sync.WaitGroup
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
	if o.WorkingDir == "" {
		return store.Session{}, invalid("working_dir is required")
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
		TeamID:     store.DefaultTeamID,
		ProjectID:  store.DefaultProjectID,
		Title:      o.Title,
		WorkingDir: dir,
		Provider:   provider,
		Model:      model,
		State:      flitv1.TaskState_TASK_STATE_IDLE,
		Effort:     effort,
		Role:       o.Role,
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

// List returns sessions, most recently updated first.
func (m *Manager) List(ctx context.Context, limit, offset int) ([]store.Session, error) {
	list, err := m.store.ListSessions(ctx, limit, offset)
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
	s, err := m.session(ctx, id)
	if err != nil {
		return 0, err
	}
	m.mu.Lock()
	closed := m.closed
	m.mu.Unlock()
	if closed {
		return 0, errors.New("flit is shutting down")
	}
	return s.send(text)
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

// AnswerPrompt answers a pending prompt.
func (m *Manager) AnswerPrompt(ctx context.Context, id, promptID string, allow bool, client string) error {
	s, err := m.session(ctx, id)
	if err != nil {
		return err
	}
	return s.answer(promptID, allow, client)
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
