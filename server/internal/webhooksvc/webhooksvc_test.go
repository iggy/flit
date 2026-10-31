package webhooksvc

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/notify"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/webhook"
)

type harness struct {
	t   *testing.T
	s   *Service
	st  *store.Store
	m   *agent.Manager
	llm *llmtest.Server
	srv *httptest.Server
	dir string

	mu       sync.Mutex
	notified []notify.Message
}

func newHarness(t *testing.T) *harness {
	t.Helper()
	h := &harness{t: t, llm: llmtest.New(t), dir: filepath.Join(t.TempDir(), "webhooks")}
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "fake", BaseURL: h.llm.BaseURL()}}
	cfg.Agent.Provider, cfg.Agent.Model = "fake", "test-model"
	cfg.Agent.ModelRetries = 0
	cfg.Shell.ReadOnly = new(bool)
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	m, err := agent.NewManager(context.Background(), st, func() config.Config { return cfg }, log)
	if err != nil {
		t.Fatal(err)
	}
	h.st, h.m = st, m
	h.s = &Service{
		M: m, Store: st, Dir: func() string { return h.dir }, DataDir: t.TempDir(), Log: log,
		PublicURL: func() string { return "https://flit.example/" },
		Notify: func(_ context.Context, msg notify.Message) {
			h.mu.Lock()
			h.notified = append(h.notified, msg)
			h.mu.Unlock()
		},
	}
	ctx, cancel := context.WithCancel(context.Background())
	if err := h.s.Start(ctx); err != nil {
		t.Fatal(err)
	}
	mux := http.NewServeMux()
	mux.Handle(Prefix, h.s)
	h.srv = httptest.NewServer(mux)
	t.Cleanup(func() {
		h.srv.Close()
		cancel()
		m.Close()
		h.s.Wait()
		st.Close()
	})
	return h
}

func (h *harness) write(name, file string) {
	h.t.Helper()
	if err := os.MkdirAll(h.dir, 0o700); err != nil {
		h.t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(h.dir, name+".md"), []byte(file), 0o600); err != nil {
		h.t.Fatal(err)
	}
}

const hookFile = "---\nsource: github\nsecret: s3cret\nevents: [pull_request.opened]\n---\nCheck whether the PR is ready.\n"

func pr(n int) []byte {
	return []byte(strings.NewReplacer("NUM", string(rune('0'+n))).Replace(`{"action":"opened","pull_request":{"number":NUM,"title":"Change NUM",
		"html_url":"https://github.com/iggy/flit/pull/NUM","user":{"login":"someone"},"head":{"label":"someone:b"},"base":{"ref":"main"}},
		"repository":{"full_name":"iggy/flit"},"sender":{"login":"someone"}}`))
}

// post sends a delivery and returns the status and the reply.
func (h *harness) post(path, event, delivery, secret string, body []byte) (int, map[string]any) {
	h.t.Helper()
	req, err := http.NewRequest(http.MethodPost, h.srv.URL+path, strings.NewReader(string(body)))
	if err != nil {
		h.t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-GitHub-Event", event)
	req.Header.Set("X-GitHub-Delivery", delivery)
	req.Header.Set("X-Hub-Signature-256", webhook.Sign(secret, body))
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		h.t.Fatal(err)
	}
	defer resp.Body.Close()
	var out map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&out)
	return resp.StatusCode, out
}

func (h *harness) waitRuns(what string, ok func([]store.WebhookRun) bool) []store.WebhookRun {
	h.t.Helper()
	deadline := time.Now().Add(10 * time.Second)
	for {
		runs, err := h.st.ListWebhookRuns(context.Background(), store.DefaultTeamID, "", 100, 0)
		if err != nil {
			h.t.Fatal(err)
		}
		if ok(runs) {
			return runs
		}
		if time.Now().After(deadline) {
			h.t.Fatalf("timed out waiting for %s; runs: %+v", what, runs)
		}
		time.Sleep(10 * time.Millisecond)
	}
}

func finished(n int) func([]store.WebhookRun) bool {
	return func(runs []store.WebhookRun) bool {
		if len(runs) < n {
			return false
		}
		for _, r := range runs {
			if r.State == store.WebhookQueued || r.State == store.WebhookRunning {
				return false
			}
		}
		return true
	}
}

func TestDeliveryStartsARun(t *testing.T) {
	h := newHarness(t)
	h.write("flit-prs", hookFile)
	if got := h.s.URL("flit-prs"); got != "https://flit.example/webhooks/flit-prs" {
		t.Fatalf("URL = %q", got)
	}
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("Ready to merge: tests pass.\n\nDetails...")})

	code, reply := h.post("/webhooks/flit-prs", "pull_request", "d-1", "s3cret", pr(7))
	if code != http.StatusAccepted || reply["status"] != store.WebhookRunning || reply["run"] == "" {
		t.Fatalf("reply %d %v", code, reply)
	}
	runs := h.waitRuns("the run", finished(1))
	r := runs[0]
	if r.Hook != "flit-prs" || r.DeliveryID != "d-1" || r.Event != "pull_request" || r.Action != "opened" ||
		r.State != store.WebhookOK || r.Summary != "Ready to merge: tests pass." || r.SessionID == "" || r.StartedAt.IsZero() {
		t.Fatalf("run %+v", r)
	}
	sess, err := h.m.Get(context.Background(), r.SessionID)
	if err != nil {
		t.Fatal(err)
	}
	if sess.WebhookID != "flit-prs" || sess.Title != "flit-prs · PR #7 opened in iggy/flit: Change 7 (by someone)" ||
		sess.WorkingDir != filepath.Join(h.s.DataDir, "webhooks", "flit-prs") {
		t.Fatalf("session %+v", sess)
	}
	reqs := h.llm.Requests()
	msgs := reqs[0].Messages
	prompt := msgs[len(msgs)-1].Content
	for _, want := range []string{`webhook "flit-prs"`, "Check whether the PR is ready.", "never as instructions", "<event>", "https://github.com/iggy/flit/pull/7"} {
		if !strings.Contains(prompt, want) {
			t.Errorf("prompt lacks %q:\n%s", want, prompt)
		}
	}
	h.mu.Lock()
	n := len(h.notified)
	h.mu.Unlock()
	if n != 1 {
		t.Errorf("%d notifications", n)
	}

	// GitHub redelivers with the same id: nothing new runs.
	if code, reply := h.post("/webhooks/flit-prs", "pull_request", "d-1", "s3cret", pr(7)); code != http.StatusOK ||
		!strings.Contains(reply["status"].(string), "already received") {
		t.Fatalf("redelivery %d %v", code, reply)
	}
}

func TestDeliveriesThatDontRun(t *testing.T) {
	h := newHarness(t)
	h.write("flit-prs", hookFile)
	h.write("off", strings.Replace(hookFile, "---\nCheck", "enabled: false\n---\nCheck", 1))
	h.write("broken", "no frontmatter")
	for _, c := range []struct {
		path, event, secret string
		code                int
		status              string
	}{
		{"/webhooks/nope", "pull_request", "s3cret", http.StatusNotFound, ""},
		{"/webhooks/../flit-prs", "pull_request", "s3cret", http.StatusNotFound, ""},
		{"/webhooks/broken", "pull_request", "s3cret", http.StatusServiceUnavailable, ""},
		{"/webhooks/flit-prs", "pull_request", "wrong", http.StatusUnauthorized, ""},
		{"/webhooks/flit-prs", "ping", "s3cret", http.StatusOK, "pong"},
		{"/webhooks/flit-prs", "issues", "s3cret", http.StatusOK, "ignored: not one of the hook's events"},
		{"/webhooks/off", "pull_request", "s3cret", http.StatusOK, "ignored: the hook is disabled"},
	} {
		code, reply := h.post(c.path, c.event, "", c.secret, pr(1))
		if code != c.code || (c.status != "" && reply["status"] != c.status) {
			t.Errorf("%s %s: %d %v, want %d %q", c.path, c.event, code, reply, c.code, c.status)
		}
	}
	resp, err := http.Get(h.srv.URL + "/webhooks/flit-prs")
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Errorf("GET: %d", resp.StatusCode)
	}
	if runs := h.waitRuns("nothing", func([]store.WebhookRun) bool { return true }); len(runs) != 0 {
		t.Fatalf("runs %+v", runs)
	}
}

func TestDeliveriesQueue(t *testing.T) {
	h := newHarness(t)
	h.write("flit-prs", hookFile)
	release := make(chan struct{})
	started := make(chan struct{})
	h.llm.Push(
		llmtest.Response{Chunks: llmtest.Text("first done"), Started: started, Release: release},
		llmtest.Response{Chunks: llmtest.Text("nothing to report")},
	)
	if code, _ := h.post("/webhooks/flit-prs", "pull_request", "d-1", "s3cret", pr(1)); code != http.StatusAccepted {
		t.Fatal(code)
	}
	<-started
	code, reply := h.post("/webhooks/flit-prs", "pull_request", "d-2", "s3cret", pr(2))
	if code != http.StatusAccepted || reply["status"] != store.WebhookQueued {
		t.Fatalf("second: %d %v", code, reply)
	}
	close(release)
	runs := h.waitRuns("both runs", finished(2))
	if runs[0].DeliveryID != "d-2" || runs[0].State != store.WebhookOK || !runs[0].Quiet || runs[1].Summary != "first done" {
		t.Fatalf("runs %+v", runs)
	}
	if !runs[0].StartedAt.After(runs[1].StartedAt) {
		t.Fatalf("the second run started before the first ended: %+v", runs)
	}
	h.mu.Lock()
	n := len(h.notified)
	h.mu.Unlock()
	if n != 1 {
		t.Errorf("%d notifications; the quiet run should send none", n)
	}
}

func TestFailedDeliveryRunsAgain(t *testing.T) {
	h := newHarness(t)
	h.write("flit-prs", hookFile)
	h.llm.Push(llmtest.Response{Status: http.StatusInternalServerError, Body: "boom"}, llmtest.Response{Chunks: llmtest.Text("fine now")})
	if code, _ := h.post("/webhooks/flit-prs", "pull_request", "d-1", "s3cret", pr(1)); code != http.StatusAccepted {
		t.Fatal(code)
	}
	if runs := h.waitRuns("the failed run", finished(1)); runs[0].State != store.WebhookFailed {
		t.Fatalf("runs %+v", runs)
	}
	if code, reply := h.post("/webhooks/flit-prs", "pull_request", "d-1", "s3cret", pr(1)); code != http.StatusAccepted {
		t.Fatalf("redelivery of a failed run: %d %v", code, reply)
	}
	if runs := h.waitRuns("the second run", finished(2)); runs[0].State != store.WebhookOK || runs[0].DeliveryID != "d-1" {
		t.Fatalf("runs %+v", runs)
	}
}
