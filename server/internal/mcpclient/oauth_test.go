package mcpclient

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/modelcontextprotocol/go-sdk/mcp"

	"github.com/iggy/flit/server/internal/config"
)

// fakeOAuth is an MCP server behind a minimal OAuth 2.1 authorization
// server with dynamic client registration.
type fakeOAuth struct {
	*httptest.Server
	mu        sync.Mutex
	valid     map[string]bool // access tokens the MCP endpoint accepts
	issued    int
	refreshes int
	registers int
}

func newFakeOAuth(t *testing.T) *fakeOAuth {
	f := &fakeOAuth{valid: map[string]bool{}}
	mcpHandler := mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return newTestServer() }, nil)
	writeJSON := func(w http.ResponseWriter, status int, v any) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(v)
	}
	issue := func(w http.ResponseWriter) {
		f.mu.Lock()
		f.issued++
		tok := fmt.Sprintf("access-%d", f.issued)
		f.valid = map[string]bool{tok: true} // older tokens stop working
		f.mu.Unlock()
		writeJSON(w, 200, map[string]any{"access_token": tok, "token_type": "Bearer", "expires_in": 1, "refresh_token": "refresh"})
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/mcp", func(w http.ResponseWriter, r *http.Request) {
		f.mu.Lock()
		ok := f.valid[strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")]
		f.mu.Unlock()
		if !ok {
			w.Header().Set("WWW-Authenticate", `Bearer resource_metadata="`+f.URL+`/.well-known/oauth-protected-resource/mcp"`)
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		mcpHandler.ServeHTTP(w, r)
	})
	mux.HandleFunc("/.well-known/oauth-protected-resource/mcp", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{"resource": f.URL + "/mcp", "authorization_servers": []string{f.URL}, "scopes_supported": []string{"read"}})
	})
	mux.HandleFunc("/.well-known/oauth-authorization-server", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{
			"issuer": f.URL, "authorization_endpoint": f.URL + "/authorize", "token_endpoint": f.URL + "/token",
			"registration_endpoint": f.URL + "/register", "response_types_supported": []string{"code"},
			"grant_types_supported": []string{"authorization_code", "refresh_token"}, "code_challenge_methods_supported": []string{"S256"},
			"token_endpoint_auth_methods_supported": []string{"none"},
		})
	})
	mux.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
		var md map[string]any
		_ = json.NewDecoder(r.Body).Decode(&md)
		f.mu.Lock()
		f.registers++
		f.mu.Unlock()
		writeJSON(w, 201, map[string]any{"client_id": "flit-client", "redirect_uris": md["redirect_uris"], "token_endpoint_auth_method": "none"})
	})
	mux.HandleFunc("/authorize", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		if q.Get("client_id") != "flit-client" || q.Get("code_challenge") == "" || q.Get("resource") != f.URL+"/mcp" {
			http.Error(w, "bad authorize request: "+r.URL.RawQuery, 400)
			return
		}
		http.Redirect(w, r, q.Get("redirect_uri")+"?code=the-code&state="+url.QueryEscape(q.Get("state")), http.StatusFound)
	})
	mux.HandleFunc("/token", func(w http.ResponseWriter, r *http.Request) {
		_ = r.ParseForm()
		switch r.Form.Get("grant_type") {
		case "authorization_code":
			if r.Form.Get("code") != "the-code" || r.Form.Get("code_verifier") == "" {
				http.Error(w, "bad code", 400)
				return
			}
		case "refresh_token":
			if r.Form.Get("refresh_token") != "refresh" {
				writeJSON(w, 400, map[string]any{"error": "invalid_grant"})
				return
			}
			f.mu.Lock()
			f.refreshes++
			f.mu.Unlock()
		default:
			http.Error(w, "bad grant", 400)
			return
		}
		issue(w)
	})
	f.Server = httptest.NewServer(mux)
	t.Cleanup(f.Close)
	return f
}

func freePort(t *testing.T) int {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	return ln.Addr().(*net.TCPAddr).Port
}

// browser follows the authorization URL like a user who approves, without
// following the redirect itself (the login listener gets it below).
func browser(t *testing.T) func(string) error {
	return func(u string) error {
		go func() {
			c := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
			res, err := c.Get(u)
			if err != nil {
				t.Errorf("authorize: %v", err)
				return
			}
			res.Body.Close()
			loc := res.Header.Get("Location")
			if loc == "" {
				t.Errorf("authorize: status %d, no redirect", res.StatusCode)
				return
			}
			res, err = http.Get(loc)
			if err != nil {
				t.Errorf("redirect: %v", err)
				return
			}
			res.Body.Close()
		}()
		return nil
	}
}

func TestOAuthLoginAndRefresh(t *testing.T) {
	f := newFakeOAuth(t)
	cfg := config.Default()
	cfg.MCPServers = []config.MCPServer{{Name: "remote", URL: f.URL + "/mcp"}}
	tokens := NewTokenStore(filepath.Join(t.TempDir(), TokenFileName))
	m := New(func() config.Config { return cfg }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	m.Tokens = tokens
	defer m.Close()
	ctx := context.Background()

	// Before signing in, the server reports that a sign-in is needed.
	_, err := m.Tools(ctx, []string{"remote"})
	var nl *NeedsLoginError
	if !errors.As(err, &nl) || nl.Server != "remote" || !strings.Contains(err.Error(), "flit mcp login remote") {
		t.Fatalf("before login: %v", err)
	}

	var out strings.Builder
	n, err := Login(ctx, cfg.MCPServers[0], tokens, LoginOptions{Port: freePort(t), Out: &out, Open: browser(t)})
	if err != nil || n != 2 {
		t.Fatalf("login = %d, %v\n%s", n, err, out.String())
	}
	if !strings.Contains(out.String(), f.URL+"/authorize?") {
		t.Fatalf("login output lacks the URL:\n%s", out.String())
	}
	// Windows has no Unix permission bits, so only check the mode elsewhere.
	if fi, err := os.Stat(tokens.path); err != nil || (runtime.GOOS != "windows" && fi.Mode().Perm() != 0o600) {
		t.Fatalf("token file: %v, %v", fi, err)
	}
	if !tokens.SignedIn("remote", f.URL+"/mcp") || tokens.SignedIn("remote", "https://elsewhere/mcp") {
		t.Fatal("SignedIn wrong")
	}

	// The running manager picks the sign-in up without waiting out the
	// retry delay, and refreshes the short-lived token as it expires.
	time.Sleep(1100 * time.Millisecond)
	tools, err := m.Tools(ctx, []string{"remote"})
	if err != nil || len(tools) != 2 {
		t.Fatalf("after login: %+v, %v", tools, err)
	}
	time.Sleep(1100 * time.Millisecond)
	for _, tl := range tools {
		if tl.Name == "echo" {
			if out, _, err := m.Call(ctx, tl, json.RawMessage(`{"text":"hi"}`)); err != nil || out != "echo: hi" {
				t.Fatalf("call = %q, %v", out, err)
			}
		}
	}
	f.mu.Lock()
	refreshes, registers := f.refreshes, f.registers
	f.mu.Unlock()
	if refreshes == 0 || registers != 1 {
		t.Fatalf("refreshes = %d, registers = %d", refreshes, registers)
	}
	a, _, _ := tokens.get("remote")
	if a.AccessToken != fmt.Sprintf("access-%d", f.issued) {
		t.Fatalf("refreshed token not saved: %+v", a)
	}

	if had, err := tokens.Delete("remote"); !had || err != nil {
		t.Fatalf("delete = %v, %v", had, err)
	}
}

// A pasted redirect URL works when the browser can't reach the listener.
func TestOAuthLoginPaste(t *testing.T) {
	f := newFakeOAuth(t)
	srv := config.MCPServer{Name: "remote", URL: f.URL + "/mcp"}
	tokens := NewTokenStore(filepath.Join(t.TempDir(), TokenFileName))
	pr, pw := io.Pipe()
	defer pw.Close()
	open := func(u string) error {
		go func() {
			c := &http.Client{CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
			res, err := c.Get(u)
			if err != nil {
				t.Errorf("authorize: %v", err)
				return
			}
			res.Body.Close()
			fmt.Fprintln(pw, "  "+res.Header.Get("Location"))
		}()
		return nil
	}
	n, err := Login(context.Background(), srv, tokens, LoginOptions{Port: freePort(t), Out: io.Discard, In: pr, Open: open})
	if err != nil || n != 2 {
		t.Fatalf("login = %d, %v", n, err)
	}
}
