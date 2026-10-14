package mcpclient

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"os"
	"strings"
	"testing"

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
	s := mcp.NewServer(&mcp.Implementation{Name: "test", Version: "1"}, nil)
	mcp.AddTool(s, &mcp.Tool{Name: "echo", Description: "Echo text back."},
		func(_ context.Context, _ *mcp.CallToolRequest, in echoIn) (*mcp.CallToolResult, any, error) {
			return &mcp.CallToolResult{Content: []mcp.Content{&mcp.TextContent{Text: "echo: " + in.Text}}}, nil, nil
		})
	mcp.AddTool(s, &mcp.Tool{Name: "fail.me", Description: "Always fails."},
		func(_ context.Context, _ *mcp.CallToolRequest, _ struct{}) (*mcp.CallToolResult, any, error) {
			return &mcp.CallToolResult{IsError: true, Content: []mcp.Content{&mcp.TextContent{Text: "nope"}}}, nil, nil
		})
	_ = s.Run(context.Background(), &mcp.StdioTransport{})
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
