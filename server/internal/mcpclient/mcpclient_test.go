package mcpclient

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"

	"github.com/iggy/flit/server/internal/config"
)

// When FLIT_TEST_MCP_SERVER is set, the test binary acts as an MCP server.
func TestMain(m *testing.M) {
	if os.Getenv("FLIT_TEST_MCP_SERVER") == "1" {
		serve()
		return
	}
	os.Exit(m.Run())
}

type echoIn struct {
	Text string `json:"text" jsonschema:"what to echo"`
}

func serve() {
	_ = newTestServer().Run(context.Background(), &mcp.StdioTransport{})
}

func newTestServer() *mcp.Server {
	s := mcp.NewServer(&mcp.Implementation{Name: "test", Version: "1"}, nil)
	mcp.AddTool(s, &mcp.Tool{Name: "echo", Description: "Echo text back."},
		func(_ context.Context, _ *mcp.CallToolRequest, in echoIn) (*mcp.CallToolResult, any, error) {
			return &mcp.CallToolResult{Content: []mcp.Content{&mcp.TextContent{Text: "echo: " + in.Text}}}, nil, nil
		})
	mcp.AddTool(s, &mcp.Tool{Name: "fail.me", Description: "Always fails."},
		func(_ context.Context, _ *mcp.CallToolRequest, _ struct{}) (*mcp.CallToolResult, any, error) {
			return &mcp.CallToolResult{IsError: true, Content: []mcp.Content{&mcp.TextContent{Text: "nope"}}}, nil, nil
		})
	return s
}

func TestManager(t *testing.T) {
	self, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{
		{Name: "test", Command: self, Env: map[string]string{"FLIT_TEST_MCP_SERVER": "1"}},
		{Name: "broken", Command: "/nonexistent/flit-mcp"},
	}
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer m.Close()
	ctx := context.Background()

	if st := m.Status(); len(st) != 2 || st[0].Running {
		t.Fatalf("status before use = %+v", st)
	}
	tools, err := m.Tools(ctx, []string{"test", "broken"})
	if err == nil || !strings.Contains(err.Error(), "broken") {
		t.Fatalf("expected broken server error, got %v", err)
	}
	if len(tools) != 2 {
		t.Fatalf("tools = %+v", tools)
	}
	var echo Tool
	for _, tl := range tools {
		if tl.Name == "echo" {
			echo = tl
		}
	}
	if echo.QualifiedName() != "mcp__test__echo" || !json.Valid(echo.Schema) || !strings.Contains(string(echo.Schema), "text") {
		t.Fatalf("echo tool = %+v", echo)
	}
	if got := (Tool{Server: "s", Name: "fail.me"}).QualifiedName(); got != "mcp__s__fail_me" {
		t.Fatalf("sanitized name = %s", got)
	}

	out, isErr, err := m.Call(ctx, echo, json.RawMessage(`{"text":"hi"}`))
	if err != nil || isErr || out != "echo: hi" {
		t.Fatalf("call = %q, %v, %v", out, isErr, err)
	}
	out, isErr, err = m.Call(ctx, Tool{Server: "test", Name: "fail.me"}, nil)
	if err != nil || !isErr || out != "nope" {
		t.Fatalf("failing call = %q, %v, %v", out, isErr, err)
	}

	st := m.Status()
	if !st[0].Running || st[0].ToolCount != 2 || st[1].Err == "" {
		t.Fatalf("status = %+v", st)
	}

	// A config change restarts the server on next use.
	cfg.MCPServers[0].Args = []string{"-test.run=^$"}
	if st := m.Status(); st[0].Running {
		t.Fatal("changed server still reported running")
	}
	if _, err := m.Tools(ctx, []string{"test"}); err != nil {
		t.Fatalf("restart: %v", err)
	}
}

// requireToken rejects requests without the configured header.
func requireToken(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer sekrit" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		h.ServeHTTP(w, r)
	})
}

// Remote servers: streamable HTTP, and legacy SSE through the fallback,
// both getting the configured headers.
func TestManagerHTTP(t *testing.T) {
	getServer := func(*http.Request) *mcp.Server { return newTestServer() }
	streamable := httptest.NewServer(requireToken(mcp.NewStreamableHTTPHandler(getServer, nil)))
	defer streamable.Close()
	sse := httptest.NewServer(requireToken(mcp.NewSSEHandler(getServer, nil)))
	defer sse.Close()
	t.Setenv("FLIT_TEST_MCP_TOKEN", "sekrit")
	auth := map[string]string{"Authorization": "Bearer ${FLIT_TEST_MCP_TOKEN}"}

	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{
		{Name: "streamable", URL: streamable.URL, Headers: auth},
		{Name: "sse", URL: sse.URL, Headers: auth},
		{Name: "noauth", URL: streamable.URL},
		{Name: "unset", URL: streamable.URL, Headers: map[string]string{"Authorization": "Bearer ${FLIT_TEST_MCP_UNSET}"}},
	}
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer m.Close()
	ctx := context.Background()

	for _, name := range []string{"streamable", "sse"} {
		tools, err := m.Tools(ctx, []string{name})
		if err != nil || len(tools) != 2 {
			t.Fatalf("%s: tools = %+v, %v", name, tools, err)
		}
		for _, tl := range tools {
			if tl.Name != "echo" {
				continue
			}
			out, isErr, err := m.Call(ctx, tl, json.RawMessage(`{"text":"hi"}`))
			if err != nil || isErr || out != "echo: hi" {
				t.Fatalf("%s: call = %q, %v, %v", name, out, isErr, err)
			}
		}
	}
	if _, err := m.Tools(ctx, []string{"noauth"}); err == nil {
		t.Fatal("server without the header should fail")
	}
	if _, err := m.Tools(ctx, []string{"unset"}); err == nil || !strings.Contains(err.Error(), "FLIT_TEST_MCP_UNSET") {
		t.Fatalf("unset variable: %v", err)
	}
	if st := m.Status(); st[3].Running || !strings.Contains(st[3].Err, "FLIT_TEST_MCP_UNSET") {
		t.Fatalf("status = %+v", st[3])
	}
}

// swapHandler lets a test replace the server behind a URL, as a restart
// would.
type swapHandler struct {
	mu sync.Mutex
	h  http.Handler
}

func (s *swapHandler) set(h http.Handler) {
	s.mu.Lock()
	s.h = h
	s.mu.Unlock()
}

func (s *swapHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.mu.Lock()
	h := s.h
	s.mu.Unlock()
	h.ServeHTTP(w, r)
}

// A remote server that restarts (forgetting its sessions) gets a new
// session, and the call that hit the missing session is retried.
func TestManagerHTTPReconnect(t *testing.T) {
	fresh := func() http.Handler {
		return mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return newTestServer() }, nil)
	}
	sw := &swapHandler{h: fresh()}
	ts := httptest.NewServer(sw)
	defer ts.Close()
	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{{Name: "remote", URL: ts.URL}}
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer m.Close()
	ctx := context.Background()

	tools, err := m.Tools(ctx, []string{"remote"})
	if err != nil {
		t.Fatal(err)
	}
	var echo Tool
	for _, tl := range tools {
		if tl.Name == "echo" {
			echo = tl
		}
	}
	for i := range 2 {
		sw.set(fresh())
		out, isErr, err := m.Call(ctx, echo, json.RawMessage(`{"text":"again"}`))
		if err != nil || isErr || out != "echo: again" {
			t.Fatalf("call %d after restart = %q, %v, %v", i, out, isErr, err)
		}
	}
}

// A server that fails to start is tried again after retryAfter, not
// only after a config change.
func TestManagerRetriesFailedStart(t *testing.T) {
	sw := &swapHandler{h: http.NotFoundHandler()}
	ts := httptest.NewServer(sw)
	defer ts.Close()
	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{{Name: "remote", URL: ts.URL}}
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer m.Close()
	ctx := context.Background()
	if _, err := m.Tools(ctx, []string{"remote"}); err == nil {
		t.Fatal("expected failure")
	}
	sw.set(mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return newTestServer() }, nil))
	if _, err := m.Tools(ctx, []string{"remote"}); err == nil {
		t.Fatal("retried before retryAfter")
	}
	m.mu.Lock()
	m.servers["remote"].failed = time.Now().Add(-retryAfter)
	m.mu.Unlock()
	if tools, err := m.Tools(ctx, []string{"remote"}); err != nil || len(tools) != 2 {
		t.Fatalf("after retryAfter: %v, %v", tools, err)
	}
}

// A server's tools/list_changed notification refreshes its tools, and its
// log messages reach flit's log.
func TestManagerToolListChanged(t *testing.T) {
	srv := newTestServer()
	ts := httptest.NewServer(mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return srv }, nil))
	defer ts.Close()
	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{{Name: "remote", URL: ts.URL}}
	var logs syncBuf
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(&logs, &slog.HandlerOptions{Level: slog.LevelDebug})))
	defer m.Close()
	ctx := context.Background()
	if tools, err := m.Tools(ctx, []string{"remote"}); err != nil || len(tools) != 2 {
		t.Fatalf("tools = %v, %v", tools, err)
	}
	mcp.AddTool(srv, &mcp.Tool{Name: "late", Description: "Added later."},
		func(ctx context.Context, req *mcp.CallToolRequest, _ struct{}) (*mcp.CallToolResult, any, error) {
			_ = req.Session.Log(ctx, &mcp.LoggingMessageParams{Level: "warning", Logger: "late", Data: "careful"})
			return &mcp.CallToolResult{Content: []mcp.Content{&mcp.TextContent{Text: "here"}}}, nil, nil
		})
	deadline := time.Now().Add(5 * time.Second)
	for {
		tools, _ := m.Tools(ctx, []string{"remote"})
		if len(tools) == 3 {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("tools never refreshed: %v", tools)
		}
		time.Sleep(20 * time.Millisecond)
	}
	if out, _, err := m.Call(ctx, Tool{Server: "remote", Name: "late"}, nil); err != nil || out != "here" {
		t.Fatalf("late call = %q, %v", out, err)
	}
	for !strings.Contains(logs.String(), "careful") {
		if time.Now().After(deadline) {
			t.Fatalf("server log not forwarded:\n%s", logs.String())
		}
		time.Sleep(20 * time.Millisecond)
	}
}

type syncBuf struct {
	mu sync.Mutex
	b  strings.Builder
}

func (s *syncBuf) Write(p []byte) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.Write(p)
}

func (s *syncBuf) String() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.String()
}
