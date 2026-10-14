package auth

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestLoadOrCreateToken(t *testing.T) {
	dir := t.TempDir()
	tok, created, err := LoadOrCreateToken(dir)
	if err != nil || !created {
		t.Fatalf("first call = %v, %v; want created", created, err)
	}
	if !strings.HasPrefix(tok, tokenPrefix) || len(tok) < 40 {
		t.Fatalf("token %q looks wrong", tok)
	}
	if runtime.GOOS != "windows" {
		fi, err := os.Stat(filepath.Join(dir, TokenFile))
		if err != nil {
			t.Fatal(err)
		}
		if perm := fi.Mode().Perm(); perm != 0o600 {
			t.Fatalf("token file mode = %v, want 0600", perm)
		}
	}

	again, created, err := LoadOrCreateToken(dir)
	if err != nil || created || again != tok {
		t.Fatalf("second call = %q, %v, %v; want same token, not created", again, created, err)
	}
}

func TestNewTokenIsRandom(t *testing.T) {
	if NewToken() == NewToken() {
		t.Fatal("two tokens are equal")
	}
}

func TestReadTokenEmpty(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, TokenFile), []byte("\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ReadToken(dir); err == nil {
		t.Fatal("expected an error for an empty token file")
	}
}
