package lsp

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
)

// client is one running language server.
type client struct {
	m   *Manager
	cfg config.LSPServer
	// ctx ends when the client stops (or the Manager closes), aborting a
	// start still in progress.
	ctx    context.Context
	cancel context.CancelFunc

	ready  chan struct{} // closed once started (err says how it went)
	err    error
	cmd    *exec.Cmd
	conn   *conn
	exited chan struct{} // closed when the process has exited

	// multiRoot is whether the server takes workspace folder changes.
	multiRoot bool

	mu       sync.Mutex
	folders  map[string]bool
	waiters  map[string]waiter      // by file path
	docLocks map[string]*sync.Mutex // one check per file at a time
	version  int
	busy     int
	idle     *time.Timer
	stopOnce sync.Once
}

// waiter is a check waiting for a file's diagnostics.
type waiter struct {
	ch      chan []rawDiagnostic
	version int // of the file as opened for the check
}

func newClient(m *Manager, cfg config.LSPServer) *client {
	ctx, cancel := context.WithCancel(m.ctx)
	return &client{
		m: m, cfg: cfg, ctx: ctx, cancel: cancel,
		ready: make(chan struct{}), exited: make(chan struct{}),
		folders: map[string]bool{}, waiters: map[string]waiter{}, docLocks: map[string]*sync.Mutex{},
	}
}

// start launches and initializes the server, then closes ready.
func (c *client) start() {
	defer close(c.ready)
	if c.err = c.launch(); c.err != nil {
		c.m.log.Warn("language server did not start", "server", c.cfg.Name, "err", c.err)
		c.m.forget(c)
		return
	}
	ctx, cancel := context.WithTimeout(c.ctx, startTimeout)
	defer cancel()
	if c.err = c.initialize(ctx); c.err != nil {
		c.m.log.Warn("language server did not initialize", "server", c.cfg.Name, "err", c.err)
		go c.stop()
		return
	}
	c.m.log.Info("language server started", "server", c.cfg.Name, "pid", c.cmd.Process.Pid)
}

func (c *client) launch() error {
	cmd := exec.Command(c.cfg.Command, c.cfg.Args...)
	cmd.Env = os.Environ()
	for k, v := range c.cfg.Env {
		cmd.Env = append(cmd.Env, k+"="+v)
	}
	setGroup(cmd)
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}
	if err := cmd.Start(); err != nil {
		return err
	}
	c.cmd = cmd
	go c.logStderr(stderr)
	c.conn = newConn(stdout, stdin, c.handle, c.notify)
	go func() {
		err := cmd.Wait()
		killGroup(cmd) // anything it started
		close(c.exited)
		c.m.forget(c)
		select {
		case <-c.m.ctx.Done():
		default:
			c.m.log.Debug("language server exited", "server", c.cfg.Name, "err", err)
		}
	}()
	return nil
}

func (c *client) logStderr(r io.Reader) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64<<10), 1<<20)
	for sc.Scan() {
		c.m.log.Debug("language server", "server", c.cfg.Name, "stderr", sc.Text())
	}
}

func (c *client) initialize(ctx context.Context) error {
	params := map[string]any{
		"processId":  os.Getpid(),
		"clientInfo": map[string]any{"name": "flit", "version": buildinfo.Get().Version},
		"rootUri":    nil,
		"capabilities": map[string]any{
			"workspace": map[string]any{
				"workspaceFolders": true,
				"configuration":    true,
			},
			"textDocument": map[string]any{
				"synchronization":    map[string]any{"didSave": true},
				"publishDiagnostics": map[string]any{"versionSupport": true},
			},
		},
		"workspaceFolders": []any{},
	}
	if len(c.cfg.InitOptions) > 0 {
		params["initializationOptions"] = c.cfg.InitOptions
	}
	var res struct {
		Capabilities struct {
			Workspace struct {
				WorkspaceFolders struct {
					Supported           bool            `json:"supported"`
					ChangeNotifications json.RawMessage `json:"changeNotifications"`
				} `json:"workspaceFolders"`
			} `json:"workspace"`
		} `json:"capabilities"`
	}
	if err := c.conn.call(ctx, "initialize", params, &res); err != nil {
		return err
	}
	// changeNotifications is true or a registration id string.
	cn := strings.TrimSpace(string(res.Capabilities.Workspace.WorkspaceFolders.ChangeNotifications))
	c.multiRoot = cn != "" && cn != "false" && cn != "null"
	return c.conn.notifyServer("initialized", map[string]any{})
}

// handle answers requests from the server: workspace/configuration gets
// "no settings" for each item; everything else (registerCapability,
// workDoneProgress/create, ...) gets a null result.
func (c *client) handle(method string, params json.RawMessage) any {
	if method == "workspace/configuration" {
		var p struct {
			Items []json.RawMessage `json:"items"`
		}
		_ = json.Unmarshal(params, &p)
		return make([]any, len(p.Items))
	}
	return nil
}

type rawDiagnostic struct {
	Range struct {
		Start struct {
			Line      int `json:"line"`
			Character int `json:"character"`
		} `json:"start"`
	} `json:"range"`
	Severity int    `json:"severity"`
	Message  string `json:"message"`
}

func (c *client) notify(method string, params json.RawMessage) {
	if method != "textDocument/publishDiagnostics" {
		return
	}
	var p struct {
		URI         string          `json:"uri"`
		Version     *int            `json:"version"`
		Diagnostics []rawDiagnostic `json:"diagnostics"`
	}
	if json.Unmarshal(params, &p) != nil {
		return
	}
	path, ok := uriPath(p.URI)
	if !ok {
		return
	}
	c.mu.Lock()
	w, ok := c.waiters[path]
	c.mu.Unlock()
	if !ok || p.Version != nil && *p.Version != w.version {
		return
	}
	select {
	case w.ch <- p.Diagnostics:
	default: // the waiter hasn't caught up; it'll get the next one
	}
}

// addFolder makes dir one of the server's workspace folders.
func (c *client) addFolder(dir string) {
	c.mu.Lock()
	if c.folders[dir] {
		c.mu.Unlock()
		return
	}
	c.folders[dir] = true
	c.mu.Unlock()
	if !c.multiRoot {
		return
	}
	_ = c.conn.notifyServer("workspace/didChangeWorkspaceFolders", map[string]any{
		"event": map[string]any{
			"added":   []any{map[string]any{"uri": pathURI(dir), "name": filepath.Base(dir)}},
			"removed": []any{},
		},
	})
}

// Folders returns the workspace folders added so far.
func (c *client) Folders() []string {
	c.mu.Lock()
	defer c.mu.Unlock()
	var out []string
	for f := range c.folders {
		out = append(out, f)
	}
	return out
}

// check opens path with text, waits for its diagnostics to settle (no new
// publish for debounce) or ctx to end, and closes it again. Closing means
// the server goes back to reading the file from disk, so later changes
// made some other way (the shell) aren't hidden behind a stale copy.
func (c *client) check(ctx context.Context, path, lang, text string, debounce time.Duration) ([]Diagnostic, error) {
	c.mu.Lock()
	lock := c.docLocks[path]
	if lock == nil {
		lock = &sync.Mutex{}
		c.docLocks[path] = lock
	}
	c.mu.Unlock()
	lock.Lock()
	defer lock.Unlock()

	ch := make(chan []rawDiagnostic, 8)
	c.mu.Lock()
	c.version++
	version := c.version
	c.waiters[path] = waiter{ch: ch, version: version}
	c.mu.Unlock()
	defer func() {
		c.mu.Lock()
		delete(c.waiters, path)
		c.mu.Unlock()
	}()

	uri := pathURI(path)
	if err := c.conn.notifyServer("textDocument/didOpen", map[string]any{
		"textDocument": map[string]any{"uri": uri, "languageId": lang, "version": version, "text": text},
	}); err != nil {
		return nil, err
	}
	defer func() {
		_ = c.conn.notifyServer("textDocument/didClose", map[string]any{"textDocument": map[string]any{"uri": uri}})
	}()

	var last []rawDiagnostic
	got := false
	var settle <-chan time.Time
	for {
		select {
		case d := <-ch:
			last, got = d, true
			settle = time.After(debounce)
		case <-settle:
			return convert(last), nil
		case <-c.exited:
			return convert(last), errors.New("language server exited")
		case <-ctx.Done():
			if got {
				return convert(last), nil
			}
			return nil, ctx.Err()
		}
	}
}

func convert(raw []rawDiagnostic) []Diagnostic {
	var out []Diagnostic
	for _, r := range raw {
		sev := Severity(r.Severity)
		if sev < SeverityError || sev > SeverityHint {
			sev = SeverityError // the spec says a missing severity is the client's call
		}
		out = append(out, Diagnostic{
			Line: r.Range.Start.Line + 1, Col: r.Range.Start.Character + 1,
			Severity: sev, Message: r.Message,
		})
	}
	return out
}

// begin and end bracket a use; the idle timer runs only while unused.
func (c *client) begin() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.busy++
	if c.idle != nil {
		c.idle.Stop()
	}
}

func (c *client) end(idle time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.busy--
	if c.busy > 0 {
		return
	}
	if c.idle != nil {
		c.idle.Stop()
	}
	c.idle = time.AfterFunc(idle, func() {
		c.mu.Lock()
		busy := c.busy
		c.mu.Unlock()
		if busy == 0 {
			c.m.log.Info("stopping idle language server", "server", c.cfg.Name)
			c.m.forget(c)
			c.stop()
		}
	})
}

// stop asks the server to shut down, then kills its process group if it
// hasn't exited within a second, and waits for it to exit.
func (c *client) stop() {
	c.stopOnce.Do(func() {
		if !c.isReady() {
			c.cancel() // abort the start
		}
		<-c.ready
		c.mu.Lock()
		if c.idle != nil {
			c.idle.Stop()
		}
		c.mu.Unlock()
		if c.cmd == nil {
			return
		}
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		if c.err == nil && c.conn.call(ctx, "shutdown", nil, nil) == nil {
			_ = c.conn.notifyServer("exit", nil)
		}
		select {
		case <-c.exited:
		case <-ctx.Done():
		}
		killGroup(c.cmd)
		<-c.exited
		c.cancel()
	})
}

func (c *client) isReady() bool {
	select {
	case <-c.ready:
		return true
	default:
		return false
	}
}

// pathURI is the file URI of an absolute path.
func pathURI(p string) string {
	p = filepath.ToSlash(p)
	if runtime.GOOS == "windows" {
		p = "/" + p
	}
	return (&url.URL{Scheme: "file", Path: p}).String()
}

// uriPath is the path of a file URI, cleaned so it compares equal to the
// path it was made from whatever the server's escaping.
func uriPath(uri string) (string, bool) {
	u, err := url.Parse(uri)
	if err != nil || u.Scheme != "file" {
		return "", false
	}
	p := u.Path
	if runtime.GOOS == "windows" {
		p = strings.TrimPrefix(p, "/")
		if len(p) >= 2 && p[1] == ':' {
			p = strings.ToUpper(p[:1]) + p[1:]
		}
	}
	return filepath.Clean(filepath.FromSlash(p)), true
}
