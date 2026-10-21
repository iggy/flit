package main

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/iggy/flit/server/internal/config"
)

func TestConfigDefaults(t *testing.T) {
	var out bytes.Buffer
	if err := run(context.Background(), []string{"config", "defaults"}, &out, &out); err != nil {
		t.Fatal(err)
	}
	if out.String() != config.DefaultFile() {
		t.Fatalf("defaults = %q", out.String())
	}
}

func TestConfigUpdate(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.yaml")
	cur := "# mine\nlisten: 127.0.0.1:9999\n\nshell:\n  timeout: 5m\n"
	if err := os.WriteFile(path, []byte(cur), 0o600); err != nil {
		t.Fatal(err)
	}
	var out bytes.Buffer
	if err := run(context.Background(), []string{"config", "update", "--config", path, "--dry-run"}, &out, &out); err != nil {
		t.Fatal(err)
	}
	diff := out.String()
	for _, want := range []string{"--- " + path, "@@ -1,", "+roles_dir: roles", "+  max_timeout: 30m", "   timeout: 5m", "Would add: "} {
		if !strings.Contains(diff, want) {
			t.Errorf("diff missing %q:\n%s", want, diff)
		}
	}
	if got, _ := os.ReadFile(path); string(got) != cur {
		t.Fatal("dry run wrote the file")
	}

	out.Reset()
	if err := run(context.Background(), []string{"config", "update", "--config", path}, &out, &out); err != nil {
		t.Fatal(err)
	}
	if bak, _ := os.ReadFile(path + ".bak"); string(bak) != cur {
		t.Fatalf("backup = %q", bak)
	}
	got, _ := os.ReadFile(path)
	cfg, err := config.Parse(got)
	if err != nil || cfg.Listen != "127.0.0.1:9999" || !strings.HasPrefix(string(got), "# mine\nlisten: 127.0.0.1:9999\n") {
		t.Fatalf("updated config %v:\n%s", err, got)
	}
	if info, _ := os.Stat(path); info.Mode().Perm() != 0o600 {
		t.Fatalf("mode = %v", info.Mode())
	}

	out.Reset()
	if err := run(context.Background(), []string{"config", "update", "--config", path}, &out, &out); err != nil || !strings.Contains(out.String(), "already has every setting") {
		t.Fatalf("second update: %v %s", err, out.String())
	}
}
