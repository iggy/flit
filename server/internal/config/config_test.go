package config

import (
	"context"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestParseEmptyUsesDefaults(t *testing.T) {
	cfg, err := Parse(nil)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(cfg, Default()) {
		t.Fatalf("got %+v, want defaults %+v", cfg, Default())
	}
}

func TestParse(t *testing.T) {
	cfg, err := Parse([]byte("listen: 0.0.0.0:9000\ndata_dir: /srv/flit\nlog:\n  level: debug\n"))
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Listen != "0.0.0.0:9000" || cfg.DataDir != "/srv/flit" || cfg.Log.Level != "debug" {
		t.Fatalf("unexpected config %+v", cfg)
	}
}

func TestParseMCPServers(t *testing.T) {
	cfg, err := Parse([]byte("mcp_servers:\n" +
		"  - {name: local, command: uvx, args: [mcp-server-fetch]}\n" +
		"  - name: remote\n    url: https://example.com/mcp\n    headers:\n      Authorization: Bearer t\n" +
		"  - name: signed\n    url: https://example.com/mcp\n    oauth: {client_id: c, client_secret: \"${S}\", scopes: [read]}\n"))
	if err != nil {
		t.Fatal(err)
	}
	if r, ok := cfg.MCPServer("remote"); !ok || r.URL != "https://example.com/mcp" || r.Headers["Authorization"] != "Bearer t" {
		t.Fatalf("remote = %+v", r)
	}
}

func TestParseErrors(t *testing.T) {
	for name, in := range map[string]string{
		"unknown key":            "lisen: 127.0.0.1:1\n",
		"bad listen":             "listen: nope\n",
		"half tls":               "tls:\n  cert_file: a.pem\n",
		"bad level":              "log:\n  level: loud\n",
		"invalid yaml":           "listen: [\n",
		"no provider name":       "providers:\n  - base_url: http://x/v1\n",
		"bad base_url":           "providers:\n  - name: a\n    base_url: localhost:8080\n",
		"dup provider":           "providers:\n  - {name: a, base_url: http://x}\n  - {name: a, base_url: http://y}\n",
		"both keys":              "providers:\n  - {name: a, base_url: http://x, api_key: k, api_key_env: K}\n",
		"unknown agent provider": "agent:\n  provider: nope\n",
		"bad shell default":      "shell:\n  default: maybe\n",
		"timeout over max":       "shell:\n  timeout: 1h\n  max_timeout: 1m\n",
		"mcp neither":            "mcp_servers:\n  - name: a\n",
		"mcp both":               "mcp_servers:\n  - {name: a, command: x, url: http://h/mcp}\n",
		"mcp bad url":            "mcp_servers:\n  - {name: a, url: h/mcp}\n",
		"mcp url with args":      "mcp_servers:\n  - {name: a, url: http://h/mcp, args: [x]}\n",
		"mcp command headers":    "mcp_servers:\n  - {name: a, command: x, headers: {A: b}}\n",
		"mcp command oauth":      "mcp_servers:\n  - {name: a, command: x, oauth: {client_id: c}}\n",
		"mcp secret no id":       "mcp_servers:\n  - {name: a, url: http://h/mcp, oauth: {client_secret: s}}\n",
		"mcp oauth unknown":      "mcp_servers:\n  - {name: a, url: http://h/mcp, oauth: {client: c}}\n",
		"compaction threshold":   "agent:\n  compaction:\n    threshold: 1.5\n",
		"compaction keep":        "agent:\n  compaction:\n    keep_turns: 100\n",
		"compaction max":         "agent:\n  compaction:\n    max_summary_tokens: -1\n",
		"compaction unknown":     "agent:\n  compaction:\n    ratio: 0.5\n",
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := Parse([]byte(in)); err == nil {
				t.Fatal("expected an error")
			}
		})
	}
}

func TestDefaultFileParsesToDefaults(t *testing.T) {
	path := filepath.Join(t.TempDir(), "sub", "config.yaml")
	created, err := EnsureFile(path)
	if err != nil || !created {
		t.Fatalf("EnsureFile = %v, %v", created, err)
	}
	cfg, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(cfg, Default()) {
		t.Fatalf("default file parsed to %+v, want %+v", cfg, Default())
	}
	if created, err := EnsureFile(path); err != nil || created {
		t.Fatalf("second EnsureFile = %v, %v; want false, nil", created, err)
	}
}

func TestWatchReloads(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.yaml")
	if err := os.WriteFile(path, []byte("log:\n  level: info\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	got := make(chan Config, 10)
	done := make(chan error, 1)
	go func() {
		done <- Watch(ctx, path, slog.New(slog.NewTextHandler(io.Discard, nil)), func(c Config) { got <- c })
	}()
	time.Sleep(100 * time.Millisecond) // let the watcher start

	// An invalid file is skipped.
	if err := os.WriteFile(path, []byte("log:\n  level: loud\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	select {
	case c := <-got:
		t.Fatalf("invalid config was applied: %+v", c)
	case <-time.After(500 * time.Millisecond):
	}

	// A replace-by-rename save, as editors do, is picked up.
	tmp := filepath.Join(dir, "config.yaml.tmp")
	if err := os.WriteFile(tmp, []byte("log:\n  level: debug\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(tmp, path); err != nil {
		t.Fatal(err)
	}
	select {
	case c := <-got:
		if c.Log.Level != "debug" {
			t.Fatalf("reloaded level = %q, want debug", c.Log.Level)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("config change not picked up")
	}

	cancel()
	if err := <-done; err != nil {
		t.Fatal(err)
	}
}

func TestLoadNamesFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.yaml")
	if err := os.WriteFile(path, []byte("bogus: 1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := Load(path)
	if err == nil || !strings.Contains(err.Error(), path) {
		t.Fatalf("err = %v, want it to name %s", err, path)
	}
}

func TestParseProvidersAndShell(t *testing.T) {
	t.Setenv("FLIT_TEST_KEY", "secret")
	cfg, err := Parse([]byte(`
providers:
  - name: local
    base_url: http://localhost:8080/v1
  - name: cloud
    base_url: https://api.example.com/v1
    api_key_env: FLIT_TEST_KEY
agent:
  provider: local
  model: qwen
shell:
  timeout: 10s
  allow: ["go test*"]
`))
	if err != nil {
		t.Fatal(err)
	}
	p, ok := cfg.Provider("cloud")
	if !ok || p.Key() != "secret" {
		t.Fatalf("cloud provider = %+v, %v", p, ok)
	}
	if cfg.Shell.Timeout != 10*time.Second || cfg.Shell.MaxTimeout != Default().Shell.MaxTimeout {
		t.Fatalf("shell = %+v", cfg.Shell)
	}
	if !reflect.DeepEqual(cfg.Shell.Allow, []string{"go test*"}) {
		t.Fatalf("shell.allow = %q; a configured list must replace the default", cfg.Shell.Allow)
	}
	if cfg.Agent.MaxSteps != Default().Agent.MaxSteps {
		t.Fatalf("agent defaults not applied: %+v", cfg.Agent)
	}
}

func TestChatModel(t *testing.T) {
	cfg, err := Parse([]byte(`
providers:
  - {name: a, base_url: http://a/v1, kind: llamacpp}
  - {name: b, base_url: http://b/v1}
agent:
  provider: a
  model: small
  effort: low
`))
	if err != nil {
		t.Fatal(err)
	}
	if got := cfg.ChatModel(); got != (TaskModel{Provider: "a", Model: "small", Effort: "low"}) {
		t.Fatalf("ChatModel = %+v", got)
	}
	cfg.Agent.Tasks = map[string]TaskModel{"chat": {Provider: "b", Model: "big", Effort: "high"}}
	if got := cfg.ChatModel(); got.Provider != "b" || got.Model != "big" {
		t.Fatalf("ChatModel with tasks.chat = %+v", got)
	}
}

func TestShellAndEffortSettings(t *testing.T) {
	cfg, err := Parse([]byte(`
providers: [{name: local, base_url: "http://localhost:8080/v1"}]
agent:
  effort: low
  tasks:
    permission: {provider: local, model: guard, effort: off}
shell:
  read_only: false
  yolo: true
`))
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Shell.ReadOnlyEnabled() || !cfg.Shell.Yolo {
		t.Fatalf("shell = %+v", cfg.Shell)
	}
	if p, ok := cfg.Task("permission"); !ok || p.Effort != "off" {
		t.Fatalf("permission task = %+v, %v", p, ok)
	}
	if _, ok := cfg.Task("planning"); ok {
		t.Fatal("unset task reported")
	}
	if c := cfg.ChatModel(); c.Effort != "low" {
		t.Fatalf("chat model = %+v", c)
	}
	if d, _ := Parse(nil); !d.Shell.ReadOnlyEnabled() || d.Shell.Yolo {
		t.Fatal("defaults: read_only should be on, yolo off")
	}
}

func TestCompactionSettings(t *testing.T) {
	cfg, err := Parse(nil)
	if err != nil {
		t.Fatal(err)
	}
	c := cfg.Agent.Compaction
	if !c.AutoOn() || c.Threshold != 0.8 || c.KeepTurns != 2 || c.MaxSummaryTokens != 4096 {
		t.Fatalf("defaults %+v", c)
	}
	cfg, err = Parse([]byte("agent:\n  compaction:\n    auto: false\n    threshold: 0.5\n    keep_turns: 4\n    max_summary_tokens: 0\n  tasks:\n    compaction: {provider: \"\", model: \"\"}\n"))
	if err != nil {
		t.Fatal(err)
	}
	c = cfg.Agent.Compaction
	if c.AutoOn() || c.Threshold != 0.5 || c.KeepTurns != 4 || c.MaxSummaryTokens != 0 {
		t.Fatalf("parsed %+v", c)
	}
	if _, ok := cfg.Task("compaction"); ok {
		t.Fatal("empty compaction task counts as set")
	}
}

func TestLSPSettings(t *testing.T) {
	cfg, err := Parse([]byte("lsp:\n  wait_timeout: 5s\n  severity: error\n  servers:\n" +
		"    - name: zls\n      command: zls\n      languages: {zig: [.zig, .zon]}\n      root_markers: [build.zig]\n      init_options: {enable_snippets: false}\n" +
		"    - {name: clangd, enabled: false}\n"))
	if err != nil {
		t.Fatal(err)
	}
	l := cfg.LSP
	if !l.IsEnabled() || l.WaitTimeout != 5*time.Second || l.IdleTimeout != 10*time.Minute || l.Severity != "error" || l.MaxLines != 10 {
		t.Fatalf("lsp = %+v", l)
	}
	if len(l.Servers) != 2 || l.Servers[0].Languages["zig"][1] != ".zon" || l.Servers[0].InitOptions["enable_snippets"] != false || l.Servers[1].IsEnabled() {
		t.Fatalf("servers = %+v", l.Servers)
	}
	for _, bad := range []string{
		"lsp: {severity: loud}",
		"lsp: {wait_timeout: -1s}",
		"lsp: {servers: [{command: x, languages: {x: [.x]}}]}",
		"lsp: {servers: [{name: x, languages: {x: [.x]}}]}",
		"lsp: {servers: [{name: x, command: x}]}",
		"lsp: {servers: [{name: x, command: x, languages: {x: [x]}}]}",
		"lsp: {servers: [{name: x, command: x, languages: {x: [.x]}}, {name: x, command: y, languages: {y: [.y]}}]}",
		"lsp: {servers: [{name: x, command: x, languages: {x: [.x]}, extensions: [.x]}]}",
	} {
		if _, err := Parse([]byte(bad)); err == nil {
			t.Errorf("%q: no error", bad)
		}
	}
}
