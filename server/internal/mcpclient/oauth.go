package mcpclient

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/modelcontextprotocol/go-sdk/auth"
	"github.com/modelcontextprotocol/go-sdk/mcp"
	"github.com/modelcontextprotocol/go-sdk/oauthex"
	"go.yaml.in/yaml/v3"
	"golang.org/x/oauth2"

	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
)

// TokenFileName is where MCP sign-ins are kept, in the data dir.
const TokenFileName = "mcp-oauth.yaml"

// DefaultLoginPort is the loopback port "flit mcp login" listens on for the
// authorization server's redirect.
const DefaultLoginPort = 7434

// NeedsLoginError is returned when a server wants a sign-in flit doesn't
// have (or that has expired and can't be refreshed).
type NeedsLoginError struct{ Server string }

func (e *NeedsLoginError) Error() string {
	return fmt.Sprintf("MCP server %q needs you to sign in: run \"flit mcp login %s\" on the flit server's machine", e.Server, e.Server)
}

// storedAuth is one server's OAuth client and token.
type storedAuth struct {
	// URL is the server the sign-in is for; a config pointing the name
	// somewhere else doesn't use it.
	URL          string    `yaml:"url"`
	ClientID     string    `yaml:"client_id"`
	ClientSecret string    `yaml:"client_secret,omitempty"`
	AuthURL      string    `yaml:"auth_url"`
	TokenURL     string    `yaml:"token_url"`
	AuthStyle    int       `yaml:"auth_style"`
	Scopes       []string  `yaml:"scopes,omitempty"`
	AccessToken  string    `yaml:"access_token"`
	RefreshToken string    `yaml:"refresh_token,omitempty"`
	TokenType    string    `yaml:"token_type,omitempty"`
	Expiry       time.Time `yaml:"expiry,omitempty"`
}

func (a storedAuth) config() *oauth2.Config {
	return &oauth2.Config{
		ClientID: a.ClientID, ClientSecret: a.ClientSecret, Scopes: a.Scopes,
		Endpoint: oauth2.Endpoint{AuthURL: a.AuthURL, TokenURL: a.TokenURL, AuthStyle: oauth2.AuthStyle(a.AuthStyle)},
	}
}

func (a storedAuth) token() *oauth2.Token {
	return &oauth2.Token{AccessToken: a.AccessToken, RefreshToken: a.RefreshToken, TokenType: a.TokenType, Expiry: a.Expiry}
}

func (a *storedAuth) setToken(t *oauth2.Token) {
	a.AccessToken, a.TokenType, a.Expiry = t.AccessToken, t.TokenType, t.Expiry
	if t.RefreshToken != "" {
		a.RefreshToken = t.RefreshToken
	}
}

type tokenFile struct {
	Servers map[string]storedAuth `yaml:"servers"`
}

// TokenStore keeps MCP sign-ins (OAuth clients and tokens) in a YAML file
// readable only by the user. "flit mcp login" writes it and the server
// reads it on each connect, so a sign-in takes effect without a restart.
type TokenStore struct {
	path string
	mu   sync.Mutex
}

// NewTokenStore returns the store kept in path.
func NewTokenStore(path string) *TokenStore { return &TokenStore{path: path} }

func (s *TokenStore) read() (tokenFile, error) {
	var f tokenFile
	b, err := os.ReadFile(s.path)
	if errors.Is(err, os.ErrNotExist) {
		return f, nil
	}
	if err != nil {
		return f, err
	}
	if err := yaml.Unmarshal(b, &f); err != nil {
		return f, fmt.Errorf("%s: %w", s.path, err)
	}
	return f, nil
}

func (s *TokenStore) get(name string) (storedAuth, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	f, err := s.read()
	a, ok := f.Servers[name]
	return a, ok, err
}

// update changes one server's entry (nil deletes it) and rewrites the file.
func (s *TokenStore) update(name string, fn func(a *storedAuth, ok bool) *storedAuth) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	f, err := s.read()
	if err != nil {
		return err
	}
	a, ok := f.Servers[name]
	next := fn(&a, ok)
	if f.Servers == nil {
		f.Servers = map[string]storedAuth{}
	}
	if next == nil {
		delete(f.Servers, name)
	} else {
		f.Servers[name] = *next
	}
	b, err := yaml.Marshal(f)
	if err != nil {
		return err
	}
	b = append([]byte("# MCP server sign-ins, written by \"flit mcp login\". Holds secrets.\n"), b...)
	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(s.path), ".mcp-oauth-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if err := tmp.Chmod(0o600); err != nil {
		tmp.Close()
		return err
	}
	if _, err := tmp.Write(b); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), s.path)
}

// Delete forgets a server's sign-in, reporting whether there was one.
func (s *TokenStore) Delete(name string) (bool, error) {
	var had bool
	err := s.update(name, func(_ *storedAuth, ok bool) *storedAuth {
		had = ok
		return nil
	})
	return had, err
}

// SignedIn reports whether there is a sign-in for the server at url.
func (s *TokenStore) SignedIn(name, url string) bool {
	a, ok, err := s.get(name)
	return err == nil && ok && a.URL == url
}

// modTime changes whenever a sign-in is added, refreshed or removed.
func (s *TokenStore) modTime() time.Time {
	if s == nil {
		return time.Time{}
	}
	fi, err := os.Stat(s.path)
	if err != nil {
		return time.Time{}
	}
	return fi.ModTime()
}

// savingSource saves each new token it hands out (after a refresh).
type savingSource struct {
	store *TokenStore
	name  string
	base  oauth2.TokenSource

	mu   sync.Mutex
	last string
}

func (s *savingSource) Token() (*oauth2.Token, error) {
	t, err := s.base.Token()
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if t.AccessToken != s.last {
		s.last = t.AccessToken
		_ = s.store.update(s.name, func(a *storedAuth, ok bool) *storedAuth {
			if !ok {
				return nil // signed out meanwhile
			}
			a.setToken(t)
			return a
		})
	}
	return t, nil
}

// storedHandler is the OAuth handler a running server uses: it sends the
// stored token (refreshing it when it expires) and, when the server refuses
// it, reports that a sign-in is needed. Signing in is interactive, so it's
// left to "flit mcp login".
type storedHandler struct {
	store *TokenStore
	name  string
	url   string

	mu sync.Mutex
	ts oauth2.TokenSource
}

func (h *storedHandler) TokenSource(context.Context) (oauth2.TokenSource, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.ts != nil {
		return h.ts, nil
	}
	a, ok, err := h.store.get(h.name)
	if err != nil {
		return nil, err
	}
	if !ok || a.URL != h.url {
		return nil, nil
	}
	tok := a.token()
	h.ts = &savingSource{store: h.store, name: h.name, last: tok.AccessToken,
		base: oauth2.ReuseTokenSource(tok, a.config().TokenSource(context.Background(), tok))}
	return h.ts, nil
}

func (h *storedHandler) Authorize(_ context.Context, _ *http.Request, resp *http.Response) error {
	_, _ = io.Copy(io.Discard, resp.Body)
	resp.Body.Close()
	return &NeedsLoginError{Server: h.name}
}

// LoginOptions say how "flit mcp login" talks to the user.
type LoginOptions struct {
	// Port is the loopback port for the redirect; 0 means DefaultLoginPort.
	Port int
	// Out gets the sign-in URL and instructions.
	Out io.Writer
	// In, if set, is read for a pasted redirect URL, for when the browser
	// runs on another machine and can't reach the loopback listener.
	In io.Reader
	// Open opens a URL in a browser, best effort. May be nil.
	Open func(string) error
}

// Login signs in to a url server in a browser and saves the result,
// returning how many tools the server offers once signed in.
func Login(ctx context.Context, cfg config.MCPServer, store *TokenStore, opts LoginOptions) (int, error) {
	if cfg.URL == "" {
		return 0, fmt.Errorf("MCP server %q is a command server; only url servers sign in", cfg.Name)
	}
	port := opts.Port
	if port == 0 {
		port = DefaultLoginPort
	}
	redirect := fmt.Sprintf("http://127.0.0.1:%d/callback", port)

	results := make(chan *auth.AuthorizationResult, 1)
	deliver := func(q url.Values) bool {
		if q.Get("code") == "" && q.Get("error") == "" {
			return false
		}
		select {
		case results <- &auth.AuthorizationResult{Code: q.Get("code"), State: q.Get("state"), Iss: q.Get("iss")}:
		default:
		}
		return true
	}
	errDesc := func(q url.Values) error {
		if e := q.Get("error"); e != "" {
			return fmt.Errorf("sign-in refused: %s %s", e, q.Get("error_description"))
		}
		return nil
	}
	var refused error
	var refusedMu sync.Mutex
	note := func(q url.Values) {
		if err := errDesc(q); err != nil {
			refusedMu.Lock()
			refused = err
			refusedMu.Unlock()
		}
	}

	ln, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		return 0, fmt.Errorf("listen for the sign-in redirect on port %d (pick another with --port): %w", port, err)
	}
	srv := &http.Server{Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/callback" {
			http.NotFound(w, r)
			return
		}
		q := r.URL.Query()
		note(q)
		if !deliver(q) {
			http.Error(w, "missing code", http.StatusBadRequest)
			return
		}
		fmt.Fprintln(w, "flit: signed in. You can close this tab.")
	}), ReadHeaderTimeout: 10 * time.Second}
	go func() { _ = srv.Serve(ln) }()
	defer srv.Close()

	if opts.In != nil {
		go func() {
			sc := bufio.NewScanner(opts.In)
			for sc.Scan() {
				u, err := url.Parse(strings.TrimSpace(sc.Text()))
				if err != nil {
					continue
				}
				q := u.Query()
				note(q)
				if deliver(q) {
					return
				}
			}
		}()
	}

	fetch := func(ctx context.Context, args *auth.AuthorizationArgs) (*auth.AuthorizationResult, error) {
		fmt.Fprintf(opts.Out, "Open this URL to sign in to %s:\n\n  %s\n\n", cfg.Name, args.URL)
		fmt.Fprintf(opts.Out, "Waiting for the redirect to %s. If your browser is on another machine,\npaste the address it ends up on (it starts with %s) here.\n", redirect, redirect)
		if opts.Open != nil {
			_ = opts.Open(args.URL)
		}
		select {
		case r := <-results:
			refusedMu.Lock()
			defer refusedMu.Unlock()
			if refused != nil {
				return nil, refused
			}
			return r, nil
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	hc := &auth.AuthorizationCodeHandlerConfig{
		RedirectURL:              redirect,
		AuthorizationCodeFetcher: fetch,
		RequestRefreshToken:      true,
		NewTokenSource: func(ctx context.Context, oc *oauth2.Config, tok *oauth2.Token) (oauth2.TokenSource, error) {
			a := storedAuth{URL: cfg.URL, ClientID: oc.ClientID, ClientSecret: oc.ClientSecret,
				AuthURL: oc.Endpoint.AuthURL, TokenURL: oc.Endpoint.TokenURL, AuthStyle: int(oc.Endpoint.AuthStyle), Scopes: oc.Scopes}
			a.setToken(tok)
			if err := store.update(cfg.Name, func(*storedAuth, bool) *storedAuth { return &a }); err != nil {
				return nil, fmt.Errorf("save sign-in: %w", err)
			}
			return oc.TokenSource(ctx, tok), nil
		},
	}
	if o := cfg.OAuth; o != nil && o.ClientID != "" {
		creds := &oauthex.ClientCredentials{ClientID: o.ClientID}
		if o.ClientSecret != "" {
			secret, err := config.ExpandEnv(o.ClientSecret)
			if err != nil {
				return 0, fmt.Errorf("oauth.client_secret %w", err)
			}
			creds.ClientSecretAuth = &oauthex.ClientSecretAuth{ClientSecret: secret}
		}
		hc.PreregisteredClient = creds
	} else {
		hc.DynamicClientRegistrationConfig = &auth.DynamicClientRegistrationConfig{Metadata: &oauthex.ClientRegistrationMetadata{
			RedirectURIs:            []string{redirect},
			ClientName:              "flit",
			ClientURI:               "https://github.com/iggy/flit",
			GrantTypes:              []string{"authorization_code", "refresh_token"},
			ResponseTypes:           []string{"code"},
			TokenEndpointAuthMethod: "none",
		}}
	}
	if o := cfg.OAuth; o != nil && len(o.Scopes) > 0 {
		hc.ScopeFilter = func([]string) []string { return o.Scopes }
	}
	h, err := auth.NewAuthorizationCodeHandler(hc)
	if err != nil {
		return 0, err
	}

	headers, err := config.ExpandHeaders(cfg.Headers)
	if err != nil {
		return 0, err
	}
	// Forget the old sign-in first, so a stale token doesn't get sent and
	// the server asks again.
	if _, err := store.Delete(cfg.Name); err != nil {
		return 0, err
	}
	client := mcp.NewClient(&mcp.Implementation{Name: "flit", Version: buildinfo.Get().Version}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{
		Endpoint: cfg.URL, HTTPClient: &http.Client{Transport: headerTransport{headers: headers, base: http.DefaultTransport}},
		OAuthHandler: h, DisableStandaloneSSE: true,
	}, nil)
	if err != nil {
		return 0, err
	}
	defer session.Close()
	n := 0
	for _, err := range session.Tools(ctx, nil) {
		if err != nil {
			return 0, fmt.Errorf("list tools: %w", err)
		}
		n++
	}
	if !store.SignedIn(cfg.Name, cfg.URL) {
		return n, errors.New("the server didn't ask for a sign-in; it works without one")
	}
	return n, nil
}
