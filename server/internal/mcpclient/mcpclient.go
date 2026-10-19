// Package mcpclient runs the MCP servers configured in flit's YAML config
// (stdio subprocesses, or remote servers over streamable HTTP or legacy
// SSE) and exposes their tools to the agent. Servers start on first use and are shared by all sessions; a server whose config changes is
// restarted on its next use.
package mcpclient

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"reflect"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"

	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
)

const (
	startTimeout = 30 * time.Second
	callTimeout  = 10 * time.Minute
	// ToolPrefix starts every MCP tool name the model sees:
	// mcp__<server>__<tool>.
	ToolPrefix = "mcp__"
)

// Tool is one tool an MCP server offers.
type Tool struct {
	Server      string
	Name        string // as the server names it
	Description string
	// Schema is the tool's JSON Schema input, as JSON.
	Schema json.RawMessage
}

// QualifiedName is the name the model sees.
func (t Tool) QualifiedName() string {
	return ToolPrefix + t.Server + "__" + sanitize(t.Name)
}

// sanitize keeps tool names within what chat APIs accept.
func sanitize(s string) string {
	return strings.Map(func(r rune) rune {
		if r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9' || r == '-' || r == '_' {
			return r
		}
		return '_'
	}, s)
}

// Status is how a server is doing.
type Status struct {
	Name      string
	Running   bool
	ToolCount int
	Err       string
}

type server struct {
	cfg     config.MCPServer
	session *mcp.ClientSession
	tools   []Tool
	err     error
}

// Manager owns the MCP server processes.
type Manager struct {
	cfg func() config.Config
	log *slog.Logger

	mu      sync.Mutex
	servers map[string]*server
	starts  map[string]*sync.Mutex // serializes starting each server
}

// New returns a Manager; servers start on first use.
func New(cfg func() config.Config, log *slog.Logger) *Manager {
	return &Manager{cfg: cfg, log: log, servers: map[string]*server{}, starts: map[string]*sync.Mutex{}}
}

// Close stops every server.
func (m *Manager) Close() {
	m.mu.Lock()
	defer m.mu.Unlock()
	for name, s := range m.servers {
		if s.session != nil {
			_ = s.session.Close()
		}
		delete(m.servers, name)
	}
}

// get returns a started server, starting or restarting it as needed.
func (m *Manager) get(ctx context.Context, name string) (*server, error) {
	cfg, ok := m.cfg().MCPServer(name)
	if !ok {
		return nil, fmt.Errorf("no MCP server named %q in the config", name)
	}
	m.mu.Lock()
	lock := m.starts[name]
	if lock == nil {
		lock = &sync.Mutex{}
		m.starts[name] = lock
	}
	m.mu.Unlock()
	lock.Lock()
	defer lock.Unlock()

	m.mu.Lock()
	s := m.servers[name]
	m.mu.Unlock()
	if s != nil && reflect.DeepEqual(s.cfg, cfg) {
		if s.err != nil {
			return s, s.err
		}
		return s, nil
	}
	if s != nil && s.session != nil {
		_ = s.session.Close() // config changed
	}
	s = m.start(ctx, cfg)
	m.mu.Lock()
	m.servers[name] = s
	m.mu.Unlock()
	return s, s.err
}

func (m *Manager) start(ctx context.Context, cfg config.MCPServer) *server {
	s := &server{cfg: cfg}
	ctx, cancel := context.WithTimeout(ctx, startTimeout)
	defer cancel()

	session, err := m.connect(ctx, cfg)
	if err != nil {
		s.err = fmt.Errorf("start MCP server %q: %w", cfg.Name, err)
		return s
	}
	for t, err := range session.Tools(ctx, nil) {
		if err != nil {
			_ = session.Close()
			s.err = fmt.Errorf("list tools of MCP server %q: %w", cfg.Name, err)
			return s
		}
		schema, err := json.Marshal(t.InputSchema)
		if err != nil || string(schema) == "null" {
			schema = json.RawMessage(`{"type":"object"}`)
		}
		s.tools = append(s.tools, Tool{Server: cfg.Name, Name: t.Name, Description: t.Description, Schema: schema})
	}
	s.session = session
	m.log.Info("MCP server started", "server", cfg.Name, "tools", len(s.tools))
	return s
}

// connect starts a command server, or connects to a url server: streamable
// HTTP first, then legacy SSE for servers that only speak that.
func (m *Manager) connect(ctx context.Context, cfg config.MCPServer) (*mcp.ClientSession, error) {
	client := mcp.NewClient(&mcp.Implementation{Name: "flit", Version: buildinfo.Get().Version}, nil)
	if cfg.URL == "" {
		cmd := exec.Command(cfg.Command, cfg.Args...)
		cmd.Dir = cfg.Dir
		cmd.Env = os.Environ()
		for k, v := range cfg.Env {
			cmd.Env = append(cmd.Env, k+"="+v)
		}
		cmd.Stderr = &logWriter{log: m.log, server: cfg.Name}
		return client.Connect(ctx, &mcp.CommandTransport{Command: cmd}, nil)
	}
	// The transports keep their event streams on the Connect context, so
	// it must outlive this call; only the handshake is bounded.
	connCtx, timeOut := context.WithCancel(context.WithoutCancel(ctx))
	timer := time.AfterFunc(startTimeout, timeOut)
	defer timer.Stop()
	stop := context.AfterFunc(ctx, timeOut) // ctx ending also aborts the handshake
	defer stop()
	ctx = connCtx
	httpClient := &http.Client{Transport: headerTransport{headers: cfg.Headers, base: http.DefaultTransport}}
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{
		Endpoint: cfg.URL, HTTPClient: httpClient, MaxRetries: -1,
	}, nil)
	if err == nil {
		return session, nil
	}
	session, sseErr := client.Connect(ctx, &mcp.SSEClientTransport{Endpoint: cfg.URL, HTTPClient: httpClient}, nil)
	if sseErr != nil {
		return nil, fmt.Errorf("streamable HTTP: %w; SSE: %w", err, sseErr)
	}
	m.log.Info("MCP server speaks legacy SSE", "server", cfg.Name)
	return session, nil
}

// headerTransport adds the configured headers to every request.
type headerTransport struct {
	headers map[string]string
	base    http.RoundTripper
}

func (t headerTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	if len(t.headers) > 0 {
		r = r.Clone(r.Context())
		for k, v := range t.headers {
			r.Header.Set(k, v)
		}
	}
	return t.base.RoundTrip(r)
}

// Tools returns the tools of the named servers, starting them if needed.
// Servers that fail are skipped; their errors are returned joined.
func (m *Manager) Tools(ctx context.Context, names []string) ([]Tool, error) {
	var out []Tool
	var errs []error
	for _, n := range names {
		s, err := m.get(ctx, n)
		if err != nil {
			errs = append(errs, err)
			continue
		}
		out = append(out, s.tools...)
	}
	return out, errors.Join(errs...)
}

// Call calls a tool. The result's text content is joined; other content
// kinds are summarized.
func (m *Manager) Call(ctx context.Context, t Tool, args json.RawMessage) (string, bool, error) {
	s, err := m.get(ctx, t.Server)
	if err != nil {
		return "", true, err
	}
	ctx, cancel := context.WithTimeout(ctx, callTimeout)
	defer cancel()
	var arguments any = map[string]any{}
	if len(args) > 0 {
		arguments = args
	}
	res, err := s.session.CallTool(ctx, &mcp.CallToolParams{Name: t.Name, Arguments: arguments})
	if err != nil {
		return "", true, fmt.Errorf("MCP %s/%s: %w", t.Server, t.Name, err)
	}
	var b strings.Builder
	for _, c := range res.Content {
		switch c := c.(type) {
		case *mcp.TextContent:
			b.WriteString(c.Text)
		case *mcp.ImageContent:
			fmt.Fprintf(&b, "[image: %s, %d bytes]", c.MIMEType, len(c.Data))
		case *mcp.AudioContent:
			fmt.Fprintf(&b, "[audio: %s, %d bytes]", c.MIMEType, len(c.Data))
		case *mcp.EmbeddedResource:
			if c.Resource != nil {
				fmt.Fprintf(&b, "[resource %s]\n%s", c.Resource.URI, c.Resource.Text)
			}
		case *mcp.ResourceLink:
			fmt.Fprintf(&b, "[resource link: %s]", c.URI)
		default:
			b.WriteString("[unsupported content]")
		}
		b.WriteString("\n")
	}
	if b.Len() == 0 && res.StructuredContent != nil {
		if j, err := json.Marshal(res.StructuredContent); err == nil {
			b.Write(j)
		}
	}
	return strings.TrimRight(b.String(), "\n"), res.IsError, nil
}

// Status reports on every configured server without starting any.
func (m *Manager) Status() []Status {
	cfg := m.cfg()
	m.mu.Lock()
	defer m.mu.Unlock()
	var out []Status
	for _, c := range cfg.MCPServers {
		st := Status{Name: c.Name}
		if s, ok := m.servers[c.Name]; ok && reflect.DeepEqual(s.cfg, c) {
			st.Running = s.session != nil
			st.ToolCount = len(s.tools)
			if s.err != nil {
				st.Err = s.err.Error()
			}
		}
		out = append(out, st)
	}
	return out
}

// Names lists configured servers.
func (m *Manager) Names() []string {
	var out []string
	for _, c := range m.cfg().MCPServers {
		out = append(out, c.Name)
	}
	return slices.Clip(out)
}

// logWriter forwards a server's stderr to the log, line by line.
type logWriter struct {
	log    *slog.Logger
	server string
	mu     sync.Mutex
	buf    []byte
}

func (w *logWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.buf = append(w.buf, p...)
	for {
		i := slices.Index(w.buf, '\n')
		if i < 0 {
			break
		}
		w.log.Debug("MCP server stderr", "server", w.server, "line", string(w.buf[:i]))
		w.buf = w.buf[i+1:]
	}
	if len(w.buf) > 64<<10 {
		w.buf = w.buf[:0]
	}
	return len(p), nil
}
