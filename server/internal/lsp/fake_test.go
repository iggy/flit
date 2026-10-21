package lsp

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
	"testing"
	"time"
)

// The test binary doubles as a fake language server when FLIT_FAKE_LSP is
// set. It appends what it does to the file FLIT_FAKE_LSP_LOG names
// ("start <pid>", "folder <path>", "child <pid>"), and answers didOpen
// according to the text:
//
//	a line "ERR msg" / "WARN msg" / "HINT msg": a diagnostic at that line
//	CRASH: exit at once
//	SLOW:  never publish
//	TWICE: publish nothing first, the real diagnostics 100ms later
//	SPAWN: start a child process that sleeps (to test group kills)
func TestMain(m *testing.M) {
	switch os.Getenv("FLIT_FAKE_LSP") {
	case "":
		os.Exit(m.Run())
	case "child":
		time.Sleep(time.Hour)
	default:
		fakeServer()
	}
	os.Exit(0)
}

func fakeLog(format string, args ...any) {
	f, err := os.OpenFile(os.Getenv("FLIT_FAKE_LSP_LOG"), os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return
	}
	defer f.Close()
	fmt.Fprintf(f, format+"\n", args...)
}

func fakeServer() {
	fakeLog("start %d", os.Getpid())
	r := bufio.NewReader(os.Stdin)
	var wmu sync.Mutex
	send := func(v any) {
		b, _ := json.Marshal(v)
		wmu.Lock()
		defer wmu.Unlock()
		fmt.Fprintf(os.Stdout, "Content-Length: %d\r\n\r\n%s", len(b), b)
	}
	publish := func(uri string, version int, text string) {
		diags := []any{}
		for i, line := range strings.Split(text, "\n") {
			for sev, prefix := range []string{"ERR ", "WARN ", "INFO ", "HINT "} {
				if msg, ok := strings.CutPrefix(line, prefix); ok {
					diags = append(diags, map[string]any{
						"range":    map[string]any{"start": map[string]any{"line": i, "character": 0}, "end": map[string]any{"line": i, "character": 1}},
						"severity": sev + 1, "message": msg,
					})
				}
			}
		}
		send(map[string]any{"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
			"params": map[string]any{"uri": uri, "version": version, "diagnostics": diags}})
	}
	for {
		b, err := readFrame(r)
		if err != nil {
			return
		}
		var m message
		_ = json.Unmarshal(b, &m)
		switch m.Method {
		case "initialize":
			send(map[string]any{"jsonrpc": "2.0", "id": m.ID, "result": map[string]any{"capabilities": map[string]any{
				"workspace": map[string]any{"workspaceFolders": map[string]any{"supported": true, "changeNotifications": true}},
			}}})
			// Ask for configuration, as pyright does, to check we answer.
			send(map[string]any{"jsonrpc": "2.0", "id": 99, "method": "workspace/configuration",
				"params": map[string]any{"items": []any{map[string]any{"section": "fake"}}}})
		case "workspace/didChangeWorkspaceFolders":
			var p struct {
				Event struct {
					Added []struct {
						URI string `json:"uri"`
					} `json:"added"`
				} `json:"event"`
			}
			_ = json.Unmarshal(m.Params, &p)
			for _, f := range p.Event.Added {
				path, _ := uriPath(f.URI)
				fakeLog("folder %s", path)
			}
		case "textDocument/didOpen":
			var p struct {
				TextDocument struct {
					URI     string `json:"uri"`
					Version int    `json:"version"`
					Text    string `json:"text"`
				} `json:"textDocument"`
			}
			_ = json.Unmarshal(m.Params, &p)
			td := p.TextDocument
			switch {
			case strings.Contains(td.Text, "CRASH"):
				os.Exit(3)
			case strings.Contains(td.Text, "SLOW"):
			case strings.Contains(td.Text, "TWICE"):
				send(map[string]any{"jsonrpc": "2.0", "method": "textDocument/publishDiagnostics",
					"params": map[string]any{"uri": td.URI, "version": td.Version, "diagnostics": []any{}}})
				go func() {
					time.Sleep(100 * time.Millisecond)
					publish(td.URI, td.Version, td.Text)
				}()
			default:
				if strings.Contains(td.Text, "SPAWN") {
					cmd := exec.Command(os.Args[0])
					cmd.Env = append(os.Environ(), "FLIT_FAKE_LSP=child")
					if cmd.Start() == nil {
						fakeLog("child %d", cmd.Process.Pid)
					}
				}
				publish(td.URI, td.Version, td.Text)
			}
		case "shutdown":
			send(map[string]any{"jsonrpc": "2.0", "id": m.ID, "result": nil})
		case "exit":
			return
		}
	}
}

// fakeLines returns the log lines starting with prefix.
func fakeLines(t *testing.T, log, prefix string) []string {
	t.Helper()
	b, err := os.ReadFile(log)
	if err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	var out []string
	for _, l := range strings.Split(string(b), "\n") {
		if rest, ok := strings.CutPrefix(l, prefix+" "); ok {
			out = append(out, rest)
		}
	}
	return out
}
