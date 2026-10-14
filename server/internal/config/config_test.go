package config

import (
	"context"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestParseEmptyUsesDefaults(t *testing.T) {
	cfg, err := Parse(nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg != Default() {
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

func TestParseErrors(t *testing.T) {
	for name, in := range map[string]string{
		"unknown key":  "lisen: 127.0.0.1:1\n",
		"bad listen":   "listen: nope\n",
		"half tls":     "tls:\n  cert_file: a.pem\n",
		"bad level":    "log:\n  level: loud\n",
		"invalid yaml": "listen: [\n",
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
	if cfg != Default() {
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
