package main

import (
	"bytes"
	"context"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
)

// syncBuffer is a bytes.Buffer safe for the server goroutine to write while
// the test reads.
type syncBuffer struct {
	mu sync.Mutex
	b  bytes.Buffer
}

func (s *syncBuffer) Write(p []byte) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.Write(p)
}

func (s *syncBuffer) String() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.String()
}

func freeAddr(t *testing.T) string {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	return ln.Addr().String()
}

func version(addr, token string) (*flitv1.VersionResponse, error) {
	c := flitv1connect.NewSystemServiceClient(connect.NewClient(connecthttp.NewTransport(http.DefaultClient, "http://"+addr, connecthttp.WithReadMaxBytes(0)), connect.ClientInterceptor(
		func(next connect.ClientFunc) connect.ClientFunc {
			return func(ctx context.Context, spec connect.Spec) (connect.ClientStream, error) {
				if token != "" {
					var info *connect.CallInfo
					ctx, info = connect.NewClientContext(ctx)
					info.RequestHeader().Set("Authorization", "Bearer "+token)
				}
				return next(ctx, spec)
			}
		},
	)))
	res, err := c.Version(context.Background(), &flitv1.VersionRequest{})
	if err != nil {
		return nil, err
	}
	return res, nil
}

func eventually(t *testing.T, what string, f func() bool) {
	t.Helper()
	deadline := time.Now().Add(5 * time.Second)
	for !f() {
		if time.Now().After(deadline) {
			t.Fatalf("timed out waiting for %s", what)
		}
		time.Sleep(50 * time.Millisecond)
	}
}

// TestServe runs "flit serve" end to end: first-run token, auth on every
// call, and a listen address change applied without a restart.
func TestServe(t *testing.T) {
	dir := t.TempDir()
	configPath := filepath.Join(dir, "config.yaml")
	dataDir := filepath.Join(dir, "data")
	addr := freeAddr(t)
	if err := os.WriteFile(configPath, []byte("listen: "+addr+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	var stderr syncBuffer
	done := make(chan error, 1)
	go func() {
		done <- run(ctx, []string{"serve", "--config", configPath, "--data-dir", dataDir}, &bytes.Buffer{}, &stderr)
	}()
	defer func() {
		cancel()
		if err := <-done; err != nil {
			t.Errorf("serve: %v", err)
		}
	}()

	var stdout bytes.Buffer
	eventually(t, "token file", func() bool {
		stdout.Reset()
		return run(ctx, []string{"token", "--config", configPath, "--data-dir", dataDir}, &stdout, &bytes.Buffer{}) == nil
	})
	token := strings.TrimSpace(stdout.String())
	if !strings.Contains(stderr.String(), token) {
		t.Errorf("first run did not show the token; stderr:\n%s", stderr.String())
	}

	eventually(t, "server", func() bool { _, err := version(addr, token); return err == nil })
	if _, err := version(addr, ""); connect.CodeOf(err) != connect.CodeUnauthenticated {
		t.Fatalf("unauthenticated Version: err = %v, want unauthenticated", err)
	}

	// flit pair talks to the running server with the admin token.
	var pairOut bytes.Buffer
	if err := run(ctx, []string{"pair", "--config", configPath, "--data-dir", dataDir}, &pairOut, &bytes.Buffer{}); err != nil {
		t.Fatalf("pair: %v", err)
	}
	if out := pairOut.String(); !strings.Contains(out, "Code:   ") || !strings.Contains(out, "Server: http://"+addr) || !strings.Contains(out, "█") {
		t.Fatalf("pair output:\n%s", out)
	}
	var devOut bytes.Buffer
	if err := run(ctx, []string{"devices", "--config", configPath, "--data-dir", dataDir}, &devOut, &bytes.Buffer{}); err != nil || !strings.Contains(devOut.String(), "No paired devices") {
		t.Fatalf("devices: %v\n%s", err, devOut.String())
	}

	// Hot reload: move to a new address without restarting.
	newAddr := freeAddr(t)
	if err := os.WriteFile(configPath, []byte("listen: "+newAddr+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	eventually(t, "rebind", func() bool { _, err := version(newAddr, token); return err == nil })
}
