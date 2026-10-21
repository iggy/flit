package lsp

import (
	"context"
	"io"
	"log/slog"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// TestGopls checks two Go modules with a real gopls: both get their type
// errors, from one gopls process.
func TestGopls(t *testing.T) {
	if _, err := exec.LookPath("gopls"); err != nil {
		t.Skip("gopls is not installed")
	}
	if testing.Short() {
		t.Skip("slow")
	}
	cfg := config.Default()
	cfg.LSP.WaitTimeout = time.Minute // a cold gopls loads the module first
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	defer m.Close()

	var pids []int
	for _, mod := range []string{"one", "two"} {
		root := t.TempDir()
		write(t, filepath.Join(root, "go.mod"), "module example.com/"+mod+"\n\ngo 1.22\n")
		file := filepath.Join(root, "main.go")
		write(t, file, "package main\n\nfunc main() {\n\tvar n int = \"nope\"\n\t_ = n\n\tundefinedThing()\n}\n")
		got := m.Checker(root)(context.Background(), file)
		t.Logf("%s:\n%s", mod, got)
		if !strings.Contains(got, "main.go:4:") || !strings.Contains(got, "main.go:6:") || !strings.Contains(got, "undefinedThing") {
			t.Fatalf("%s: diagnostics missing:\n%s", mod, got)
		}
		m.mu.Lock()
		pids = append(pids, m.clients["gopls"].cmd.Process.Pid)
		m.mu.Unlock()
	}
	if pids[0] != pids[1] {
		t.Fatalf("two gopls processes: %v", pids)
	}
}
