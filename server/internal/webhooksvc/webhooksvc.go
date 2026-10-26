// Package webhooksvc receives webhook deliveries (see package webhook) at
// /webhooks/<name> and runs each one as a new, unattended session in the
// hook's project (see agent.Manager.StartWebhookRun), recorded in the
// store's webhook_runs.
//
// This is the only part of flit meant to be reachable from the internet, so
// it needs no token: each delivery must carry a valid signature made with
// the hook's secret. Hook files are read on every delivery, so edits apply
// at once.
package webhooksvc

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/cron"
	"github.com/iggy/flit/server/internal/notify"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/webhook"
)

// Prefix is the URL path deliveries arrive under.
const Prefix = "/webhooks/"

// maxBody caps a delivery (GitHub's own cap is 25 MB; real ones are far
// smaller).
const maxBody = 10 << 20

// maxQueued caps the deliveries waiting per hook; beyond it they are
// recorded as skipped.
const maxQueued = 50

// Service receives deliveries and runs them.
type Service struct {
	M     *agent.Manager
	Store *store.Store
	// Dir returns the webhooks directory.
	Dir func() string
	// DataDir holds working directories for hooks in Scratch with no dir.
	DataDir string
	Log     *slog.Logger
	// Notify, if set, receives run results worth telling someone about.
	Notify func(context.Context, notify.Message)
	// Now is the clock; nil means time.Now.
	Now func() time.Time
	// PublicURL, if set, returns the config's public_url, for logging the
	// hooks' URLs.
	PublicURL func() string

	mu     sync.Mutex
	queues map[string]*queue
	runs   sync.WaitGroup
	ctx    context.Context
}

// queue is one hook's runs in progress and waiting.
type queue struct {
	running int
	waiting []pending
}

type pending struct {
	hook webhook.Hook
	d    webhook.Delivery
	run  *store.WebhookRun
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func newID() string {
	b := make([]byte, 8)
	_, _ = rand.Read(b)
	return fmt.Sprintf("whr_%012x%s", time.Now().UnixMilli(), hex.EncodeToString(b))
}

// Start marks runs a previous flit left unfinished as failed. Deliveries
// are taken until ctx ends; then call Wait (after the agent manager has
// stopped its turns).
func (s *Service) Start(ctx context.Context) error {
	s.mu.Lock()
	s.ctx = ctx
	s.queues = map[string]*queue{}
	s.mu.Unlock()
	n, err := s.Store.FailUnfinishedWebhookRuns(ctx, "flit stopped before the run finished")
	if err != nil {
		return err
	}
	if n > 0 {
		s.Log.Warn("webhook runs left unfinished by the last flit marked failed", "runs", n)
	}
	hooks, err := webhook.List(s.Dir())
	if err != nil {
		s.Log.Error("read webhooks directory", "dir", s.Dir(), "err", err)
	}
	for _, h := range hooks {
		if h.Err != nil {
			s.Log.Warn("webhook file has errors; it won't take deliveries", "hook", h.Name, "path", h.Path, "err", h.Err)
			continue
		}
		s.Log.Info("webhook ready", "hook", h.Name, "url", s.URL(h.Name), "events", strings.Join(h.Events, ","))
	}
	return nil
}

// URL is where hook name takes deliveries: public_url + /webhooks/<name>,
// or just the path when public_url isn't set.
func (s *Service) URL(name string) string {
	base := ""
	if s.PublicURL != nil {
		base = strings.TrimSuffix(s.PublicURL(), "/")
	}
	return base + Prefix + name
}

// Wait waits for the runs' bookkeeping to finish.
func (s *Service) Wait() { s.runs.Wait() }

// ServeHTTP takes a delivery for the hook named by the path.
func (s *Service) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	name := strings.TrimPrefix(r.URL.Path, Prefix)
	h, err := webhook.Get(s.Dir(), name)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "webhooks take POST", http.StatusMethodNotAllowed)
		return
	}
	s.mu.Lock()
	started := s.ctx != nil && s.ctx.Err() == nil
	s.mu.Unlock()
	if !started {
		http.Error(w, "flit is not taking webhook deliveries right now", http.StatusServiceUnavailable)
		return
	}
	if h.Err != nil {
		s.Log.Warn("webhook delivery for a hook whose file has errors", "hook", name, "err", h.Err)
		http.Error(w, "this webhook's file on the flit server has errors; see the server log", http.StatusServiceUnavailable)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, maxBody))
	if err != nil {
		http.Error(w, "body too large", http.StatusRequestEntityTooLarge)
		return
	}
	var d webhook.Delivery
	switch h.Source {
	case webhook.SourceGitHub:
		d, err = webhook.ParseGitHub(h.Secret, r.Header, body)
	}
	switch {
	case errors.Is(err, webhook.ErrBadSignature):
		s.Log.Warn("webhook delivery with a bad signature", "hook", name, "remote", r.RemoteAddr)
		http.Error(w, "bad signature", http.StatusUnauthorized)
		return
	case err != nil:
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	reply := func(code int, msg string, args ...any) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(code)
		out := map[string]any{"status": msg}
		for i := 0; i+1 < len(args); i += 2 {
			out[fmt.Sprint(args[i])] = args[i+1]
		}
		_ = json.NewEncoder(w).Encode(out)
	}
	switch {
	case d.Ping:
		s.Log.Info("webhook ping", "hook", name, "repo", d.Repo)
		reply(http.StatusOK, "pong")
		return
	case !h.IsEnabled():
		reply(http.StatusOK, "ignored: the hook is disabled")
		return
	case !h.Wants(d.Event, d.Action):
		reply(http.StatusOK, "ignored: not one of the hook's events")
		return
	case !h.WantsRepo(d.Repo):
		reply(http.StatusOK, "ignored: not one of the hook's repos")
		return
	case h.Ignores(d.Sender):
		reply(http.StatusOK, "ignored: sender is in ignore_senders")
		return
	}
	run, err := s.accept(h, d)
	switch {
	case errors.Is(err, errSeen):
		reply(http.StatusOK, "ignored: delivery already received")
	case err != nil:
		s.Log.Error("record webhook run", "hook", name, "err", err)
		http.Error(w, "could not record the delivery", http.StatusInternalServerError)
	default:
		reply(http.StatusAccepted, run.State, "run", run.ID)
	}
}

// errSeen is accept's error for a delivery that already ran.
var errSeen = errors.New("delivery already received")

// accept records a delivery and starts its run, or queues it. A delivery
// whose earlier run failed or was skipped runs again.
func (s *Service) accept(h webhook.Hook, d webhook.Delivery) (store.WebhookRun, error) {
	run := &store.WebhookRun{
		ID: newID(), TeamID: store.DefaultTeamID, Hook: h.Name, DeliveryID: d.ID, Event: d.Event, Action: d.Action,
		About: d.About, State: store.WebhookQueued, ReceivedAt: s.now(),
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if seen, err := s.Store.DeliverySeen(s.ctx, store.DefaultTeamID, h.Name, d.ID); err != nil {
		return store.WebhookRun{}, err
	} else if seen {
		return store.WebhookRun{}, errSeen
	}
	q := s.queues[h.Name]
	if q == nil {
		q = &queue{}
		s.queues[h.Name] = q
	}
	if q.running >= h.Slots() && len(q.waiting) >= maxQueued {
		run.State, run.FinishedAt = store.WebhookSkipped, s.now()
		run.Summary = fmt.Sprintf("skipped: %d deliveries were already waiting", len(q.waiting))
	}
	if err := s.Store.CreateWebhookRun(s.ctx, run); err != nil {
		return store.WebhookRun{}, err
	}
	switch {
	case run.State == store.WebhookSkipped:
	case q.running < h.Slots():
		s.startLocked(q, pending{hook: h, d: d, run: run})
	default:
		q.waiting = append(q.waiting, pending{hook: h, d: d, run: run})
	}
	s.Log.Info("webhook delivery", "hook", h.Name, "event", d.Event, "action", d.Action, "about", d.About, "delivery", d.ID, "state", run.State)
	return *run, nil
}

// startLocked starts p's run.
func (s *Service) startLocked(q *queue, p pending) {
	q.running++
	run := p.run
	run.State, run.StartedAt = store.WebhookRunning, s.now()
	o, err := s.runOptions(p.hook, p.d, run)
	var outcome <-chan agent.CronOutcome
	if err == nil {
		var sess store.Session
		sess, outcome, err = s.M.StartWebhookRun(s.ctx, o)
		run.SessionID, run.ProjectID = sess.ID, sess.ProjectID
	}
	if uerr := s.Store.UpdateWebhookRun(s.ctx, *run); uerr != nil {
		s.Log.Error("record webhook run start", "hook", run.Hook, "err", uerr)
	}
	s.runs.Add(1)
	go func() {
		defer s.runs.Done()
		var out agent.CronOutcome
		if err != nil {
			out = agent.CronOutcome{Failed: true, Reason: "could not start: " + err.Error()}
		} else {
			out = <-outcome
		}
		s.finish(p.hook, q, run, out)
	}()
}

// runOptions turns a hook and a delivery into the run's session options.
func (s *Service) runOptions(h webhook.Hook, d webhook.Delivery, run *store.WebhookRun) (agent.WebhookRunOptions, error) {
	create := agent.CreateOptions{
		WorkingDir: h.Dir, Role: h.Role, Provider: h.Model.Provider, Model: h.Model.Model, Effort: h.Model.Effort,
		Yolo: &h.Yolo, WebhookID: h.Name, Title: clip(h.Name+" · "+d.About, 120),
	}
	if h.Project != "" {
		p, err := s.M.ResolveProject(s.ctx, h.Project)
		if err != nil {
			return agent.WebhookRunOptions{}, err
		}
		create.ProjectID = p.ID
		if create.WorkingDir == "" {
			create.WorkingDir = p.Dir
		}
	}
	if create.WorkingDir == "" {
		// Scratch has no directory: each hook gets one of its own.
		dir := filepath.Join(s.DataDir, "webhooks", h.Name)
		if err := os.MkdirAll(dir, 0o700); err != nil {
			return agent.WebhookRunOptions{}, err
		}
		create.WorkingDir = dir
	}
	return agent.WebhookRunOptions{
		Create: create, Hook: h.Name, Source: h.Source, Event: d.Event, Action: d.Action, DeliveryID: d.ID,
		About: d.About, URL: d.URL, RunID: run.ID, Wait: h.Ask == cron.AskWait, AskTimeout: h.AskWaitFor(),
		Prompt: h.Prompt, Details: d.Details,
	}, nil
}

// finish records how a run ended, archives old runs' sessions, sends
// notifications and starts the next waiting delivery.
func (s *Service) finish(h webhook.Hook, q *queue, run *store.WebhookRun, out agent.CronOutcome) {
	r := *run
	r.FinishedAt = s.now()
	r.Refused = out.Refused
	r.State, r.Summary, r.Quiet = out.Result()
	ctx := context.Background()
	if n, err := s.M.ArchiveWebhookSessions(ctx, r.Hook, h.Keep()); err != nil {
		s.Log.Error("archive old webhook runs", "hook", r.Hook, "err", err)
	} else if n > 0 {
		s.Log.Info("archived old webhook run sessions", "hook", r.Hook, "sessions", n)
	}
	if err := s.Store.UpdateWebhookRun(ctx, r); err != nil {
		s.Log.Error("record webhook run result", "hook", r.Hook, "err", err)
	}
	s.Log.Info("webhook run finished", "hook", r.Hook, "about", r.About, "state", r.State, "summary", r.Summary, "refused", len(r.Refused))
	if s.Notify != nil && !r.Quiet {
		s.Notify(ctx, Message(r))
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	q.running--
	if len(q.waiting) > 0 && s.ctx.Err() == nil {
		next := q.waiting[0]
		q.waiting = q.waiting[1:]
		s.startLocked(q, next)
	}
}

// Message is the notification for a finished run.
func Message(r store.WebhookRun) notify.Message {
	m := notify.Message{Body: r.About + "\n\n" + r.Summary}
	switch r.State {
	case store.WebhookNeedsAttention:
		m.Title, m.Tags, m.High = r.Hook+" needs attention", []string{"warning"}, true
		if len(r.Refused) > 0 {
			m.Body += "\n\nRefused: " + strings.Join(r.Refused, "; ")
		}
	case store.WebhookFailed:
		m.Title, m.Tags, m.High = r.Hook+" failed", []string{"x"}, true
	default:
		m.Title, m.Tags = r.Hook, []string{"white_check_mark"}
	}
	return m
}

func clip(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	return string([]rune(s)[:n-1]) + "…"
}
