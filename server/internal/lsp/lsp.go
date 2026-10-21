// Package lsp checks files the agent edits with language servers and
// reports their diagnostics compactly, for the model to read in the tool
// result.
//
// One server process runs per configured server (in practice, per
// language) for the whole flit server: every session and project shares
// it, each project root joining as a workspace folder. Servers start on the
// first edit of a file they handle, stop after the idle timeout, restart
// when their config changes, and are killed with their process group when
// flit shuts down. Nothing here ever fails an edit: a missing, slow or
// crashed server just means no diagnostics.
package lsp

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// startTimeout bounds starting and initializing a server. It runs in the
// background, so an edit waits for it only up to its own wait timeout.
const startTimeout = time.Minute

// Severity is an LSP diagnostic severity; lower is more severe.
type Severity int

const (
	SeverityError   Severity = 1
	SeverityWarning Severity = 2
	SeverityInfo    Severity = 3
	SeverityHint    Severity = 4
)

func (s Severity) String() string {
	switch s {
	case SeverityError:
		return "error"
	case SeverityWarning:
		return "warning"
	case SeverityInfo:
		return "info"
	}
	return "hint"
}

// parseSeverity reads a config.LSP.Severity value.
func parseSeverity(s string) Severity {
	return Severity(slices.Index(config.LSPSeverities, s) + 1)
}

// Diagnostic is one problem a server found. Line and Col are 1-based.
type Diagnostic struct {
	Line, Col int
	Severity  Severity
	Message   string
}

// Manager owns the language server processes.
type Manager struct {
	cfg func() config.Config
	log *slog.Logger
	// lookPath finds server commands; tests replace it.
	lookPath func(string) (string, error)

	ctx    context.Context // ends on Close
	cancel context.CancelFunc

	mu      sync.Mutex
	clients map[string]*client // by server name
	closed  bool
}

// New returns a Manager; servers start on first use.
func New(cfg func() config.Config, log *slog.Logger) *Manager {
	ctx, cancel := context.WithCancel(context.Background())
	return &Manager{cfg: cfg, log: log, lookPath: exec.LookPath, ctx: ctx, cancel: cancel, clients: map[string]*client{}}
}

// Close stops every server and waits for them to exit.
func (m *Manager) Close() {
	m.mu.Lock()
	m.closed = true
	all := make([]*client, 0, len(m.clients))
	for name, c := range m.clients {
		all = append(all, c)
		delete(m.clients, name)
	}
	m.mu.Unlock()
	m.cancel()
	var wg sync.WaitGroup
	for _, c := range all {
		wg.Go(c.stop)
	}
	wg.Wait()
}

// Checker returns what the edit tools call after changing a file in a
// session working in workDir: the file's diagnostics formatted for the
// model, or "" when there are none (or no server). Nil-safe: a nil Manager
// returns nil.
func (m *Manager) Checker(workDir string) func(ctx context.Context, path string) string {
	if m == nil {
		return nil
	}
	return func(ctx context.Context, path string) string {
		diags := m.Diagnose(ctx, workDir, path)
		return Format(display(workDir, path), diags, m.cfg().LSP.MaxLines)
	}
}

// Diagnose returns path's diagnostics at or above the configured severity,
// most severe first. It returns within the configured wait timeout (or
// sooner if ctx ends), with nil when no server handles the file or the
// server didn't answer in time.
func (m *Manager) Diagnose(ctx context.Context, workDir, path string) []Diagnostic {
	cfg := m.cfg().LSP
	if !cfg.IsEnabled() {
		return nil
	}
	srv, lang, ok := pick(cfg, path, m.lookPath)
	if !ok {
		return nil
	}
	text, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(ctx, cfg.WaitTimeout)
	defer cancel()

	c := m.client(srv)
	if c == nil {
		return nil
	}
	c.begin()
	defer c.end(cfg.IdleTimeout)
	select {
	case <-c.ready:
	case <-ctx.Done():
		return nil
	}
	if c.err != nil {
		return nil
	}
	c.addFolder(findRoot(path, workDir, srv.RootMarkers))
	diags, err := c.check(ctx, path, lang, string(text), cfg.Debounce)
	if err != nil {
		m.log.Debug("lsp check", "server", srv.Name, "path", path, "err", err)
	}
	least := parseSeverity(cfg.Severity)
	diags = slices.DeleteFunc(diags, func(d Diagnostic) bool { return d.Severity > least })
	slices.SortStableFunc(diags, func(a, b Diagnostic) int {
		if a.Severity != b.Severity {
			return int(a.Severity - b.Severity)
		}
		if a.Line != b.Line {
			return a.Line - b.Line
		}
		return a.Col - b.Col
	})
	return diags
}

// client returns the running client for srv, starting it (in the
// background) if there is none or its config changed. Nil after Close.
func (m *Manager) client(srv config.LSPServer) *client {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.closed {
		return nil
	}
	if c := m.clients[srv.Name]; c != nil {
		if reflect.DeepEqual(c.cfg, srv) {
			return c
		}
		go c.stop() // config changed
	}
	c := newClient(m, srv)
	m.clients[srv.Name] = c
	go c.start()
	return c
}

// forget drops c if it is still the current client for its server.
func (m *Manager) forget(c *client) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.clients[c.cfg.Name] == c {
		delete(m.clients, c.cfg.Name)
	}
}

// Running returns the names of the servers currently running or starting.
func (m *Manager) Running() []string {
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []string
	for name := range m.clients {
		out = append(out, name)
	}
	slices.Sort(out)
	return out
}

// Format renders diags for the model: one "path:line:col severity: message"
// line each, at most max (0 means 10), then "(+N more)". "" when there are
// none.
func Format(path string, diags []Diagnostic, max int) string {
	if len(diags) == 0 {
		return ""
	}
	if max <= 0 {
		max = 10
	}
	var b strings.Builder
	b.WriteString("Diagnostics:\n")
	for i, d := range diags {
		if i == max {
			fmt.Fprintf(&b, "(+%d more)\n", len(diags)-max)
			break
		}
		fmt.Fprintf(&b, "%s:%d:%d %s: %s\n", path, d.Line, d.Col, d.Severity, firstLine(d.Message))
	}
	return strings.TrimSuffix(b.String(), "\n")
}

func firstLine(s string) string {
	s = strings.TrimSpace(s)
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		s = strings.TrimSpace(s[:i])
	}
	return s
}

// display shows p relative to dir.
func display(dir, p string) string {
	if r, err := filepath.Rel(dir, p); err == nil && !strings.HasPrefix(r, "..") {
		return filepath.ToSlash(r)
	}
	return p
}

func exists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}
