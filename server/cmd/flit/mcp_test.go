package main

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMCPCommands(t *testing.T) {
	dir := t.TempDir()
	configPath := filepath.Join(dir, "config.yaml")
	conf := `mcp_servers:
  - name: fetch
    command: uvx
  - name: docs
    url: https://example.com/mcp
`
	if err := os.WriteFile(configPath, []byte(conf), 0o600); err != nil {
		t.Fatal(err)
	}
	flags := []string{"--config", configPath, "--data-dir", filepath.Join(dir, "data")}
	ctx := context.Background()

	var out bytes.Buffer
	if err := run(ctx, append([]string{"mcp", "list"}, flags...), &out, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "fetch\tcommand: uvx") || !strings.Contains(out.String(), "docs\thttps://example.com/mcp\n") {
		t.Fatalf("list:\n%s", out.String())
	}
	out.Reset()
	if err := run(ctx, append([]string{"mcp", "logout", "docs"}, flags...), &out, &bytes.Buffer{}); err != nil || !strings.Contains(out.String(), "no sign-in") {
		t.Fatalf("logout = %v\n%s", err, out.String())
	}
	if err := run(ctx, append([]string{"mcp", "login", "fetch"}, flags...), &out, &bytes.Buffer{}); err == nil || !strings.Contains(err.Error(), "command server") {
		t.Fatalf("login to a command server: %v", err)
	}
	if err := run(ctx, append([]string{"mcp", "login", "nope"}, flags...), &out, &bytes.Buffer{}); err == nil {
		t.Fatal("login to an unknown server should fail")
	}
}
