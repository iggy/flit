package agent

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llamacpp"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

// What flit does with llama.cpp servers beyond the OpenAI API: say why a
// call waits (busy slots, a sleeping or loading model), keep each session's
// prompt cache in a save file across other sessions' use of its slot, and
// let the user cut the model's thinking short.

// Timings, vars for tests.
var (
	// waitCheckEvery is how often a call that hasn't started asks the
	// server why.
	waitCheckEvery = 3 * time.Second
	// reasoningEndGrace is how long the model may keep thinking after
	// EndReasoning before flit decides it can't be cut short.
	reasoningEndGrace = 5 * time.Second
)

// ErrCantEndReasoning: EndReasoning while the model isn't thinking (or on a
// server that can't do it).
var ErrCantEndReasoning = errors.New("the model isn't thinking right now (or this server can't cut it short)")

// isLlamaCpp reports whether the provider is a llama.cpp server, and
// whether it's a router.
func (m *Manager) isLlamaCpp(provider string) (llama, router bool) {
	if m.Catalog == nil || m.Catalog.Kind(provider) != models.KindLlamaCpp {
		return false, false
	}
	for _, p := range m.Catalog.Providers() {
		if p.Name == provider {
			return true, p.CanLoad
		}
	}
	return true, false
}

func (m *Manager) llamaClient(p config.Provider, router bool) *llamacpp.Client {
	// A header error (an unset variable) already stopped the turn's chat
	// request; these calls are extras, so they go without the headers.
	header, _ := p.Header()
	return &llamacpp.Client{BaseURL: p.BaseURL, APIKey: p.Key(), Header: header, Router: router, HTTP: m.http}
}

// slotRef is the llama.cpp slot a session's call was pinned to.
type slotRef struct {
	provider config.Provider
	router   bool
	model    string
	slot     int
	// key names the cache: the session and branch (see kvKeys).
	key string
}

// liveCall is the model call a session has in flight (session.call).
type liveCall struct {
	msgID    string
	provider config.Provider
	model    string
	router   bool
	// id is the completion id, once the first chunk names it.
	id string
	// Output so far, and whether the server has started (prompt progress
	// or output).
	reasoning, text int
	started         bool
	endAsked        bool
	// queued: the call waits for flit's concurrency limit, not the server.
	queued bool
}

// --- Waiting: why hasn't the call started? ---

// watchWait reports, as ModelCallWaiting events, why a llama.cpp call
// hasn't started: all slots busy (or its pinned slot), the model asleep
// or loading. It stops when the call starts or stop is called.
func (s *session) watchWait(ctx context.Context, c *llamacpp.Client, call *liveCall, attempt int32, slot *int) (stop func()) {
	ctx, cancel := context.WithCancel(ctx)
	done := make(chan struct{})
	go func() {
		defer close(done)
		last := flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED
		timer := time.NewTimer(waitCheckEvery)
		defer timer.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-timer.C:
			}
			if s.callStarted(call) {
				return
			}
			if s.callQueued(call) {
				// flit holds it back, not the server; report again once
				// it's sent.
				last = flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED
				timer.Reset(waitCheckEvery)
				continue
			}
			reason, total := waitReason(ctx, c, call.model, slot)
			if ctx.Err() != nil || s.callStarted(call) {
				return
			}
			if reason != last && reason != flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED {
				if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ModelCallWaiting{ModelCallWaiting: &flitv1.ModelCallWaiting{
					MessageId: call.msgID, Attempt: attempt, Reason: reason, TotalSlots: int32(total),
				}}}); err != nil {
					return
				}
			}
			last = reason
			timer.Reset(waitCheckEvery)
		}
	}()
	return func() {
		cancel()
		<-done
	}
}

func waitReason(ctx context.Context, c *llamacpp.Client, model string, slot *int) (flitv1.ModelWaitReason, int) {
	switch state, _ := c.State(ctx, model); state {
	case "sleeping":
		return flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLEEPING, 0
	case "loading":
		return flitv1.ModelWaitReason_MODEL_WAIT_REASON_LOADING, 0
	}
	slots, err := c.Slots(ctx, model)
	if err != nil || len(slots) == 0 {
		return flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED, 0
	}
	busy := 0
	for _, sl := range slots {
		if sl.IsProcessing {
			busy++
			if slot != nil && sl.ID == *slot {
				// Pinned to a slot someone else is using.
				return flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLOTS_BUSY, len(slots)
			}
		}
	}
	if busy == len(slots) {
		return flitv1.ModelWaitReason_MODEL_WAIT_REASON_SLOTS_BUSY, len(slots)
	}
	return flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED, len(slots)
}

func (s *session) callStarted(c *liveCall) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return c.started
}

// --- Prompt cache: slots and save files ---

// A session's llama.cpp prompt cache lives in a slot, and any other
// request on the server can wipe it: another slot's work does too on
// servers with a unified KV cache. So flit saves it to a file the moment a
// turn ends, and restores it before the next turn's first call, into the
// slot the call is then pinned to (id_slot). A save that captured nothing
// is never restored. Each branch of a session has its own cache (key
// session/branch, just the session for the root branch), so switching
// branches never restores another branch's conversation; a branch without
// a save of its own starts from its nearest ancestor's.

// kvPool tracks, per llama.cpp server, which slot each session branch used
// last and which save file holds whose cache.
type kvPool struct {
	mu      sync.Mutex
	servers map[string]*kvServer // by provider name
}

type kvServer struct {
	// mu serializes slot work on one server.
	mu sync.Mutex
	// off: the server has no slot API, or can't save.
	off bool
	// last is the slot each session branch last used, per model.
	last  map[string]map[string]int // model → key → slot
	files []*kvFile
}

type kvFile struct {
	name, key, model string
	tokens           int
	used             time.Time
}

func (p *kvPool) server(name string) *kvServer {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.servers == nil {
		p.servers = map[string]*kvServer{}
	}
	srv := p.servers[name]
	if srv == nil {
		srv = &kvServer{last: map[string]map[string]int{}}
		p.servers[name] = srv
	}
	return srv
}

// fileFor returns key's save file for model, if it holds a cache.
func (srv *kvServer) fileFor(key, model string) *kvFile {
	for _, f := range srv.files {
		if f.key == key && f.model == model && f.tokens > 0 {
			return f
		}
	}
	return nil
}

// claimFile gives key a save file: its own, a new one while the pool has
// room, else the least recently used.
func (srv *kvServer) claimFile(key, model string, n int) *kvFile {
	var oldest *kvFile
	for _, f := range srv.files {
		if f.key == key {
			f.model, f.used = model, time.Now()
			return f
		}
		if oldest == nil || f.used.Before(oldest.used) {
			oldest = f
		}
	}
	if len(srv.files) < n {
		f := &kvFile{name: fmt.Sprintf("flit-kv-%d.bin", len(srv.files)), key: key, model: model, used: time.Now()}
		srv.files = append(srv.files, f)
		return f
	}
	oldest.key, oldest.model, oldest.tokens, oldest.used = key, model, 0, time.Now()
	return oldest
}

// prepareSlot picks the slot for a session's llama.cpp call (its last one
// if free, else a free one) and, on a turn's first call, restores the
// branch's saved cache into it. keys are the branch's cache keys, best
// first (kvKeys). It returns the slot to pin (nil: let the server choose)
// and a PromptCache event for the log, if any.
func (m *Manager) prepareSlot(ctx context.Context, cfg config.Config, info store.Session, keys []string, p config.Provider, router bool, msgID string, first bool) (*int, *flitv1.Event) {
	if !cfg.LlamaCpp.KVCacheOn() {
		return nil, nil
	}
	srv := m.kv.server(p.Name)
	srv.mu.Lock()
	defer srv.mu.Unlock()
	if srv.off {
		return nil, nil
	}
	c := m.llamaClient(p, router)
	slots, err := c.Slots(ctx, info.Model)
	if err != nil {
		if llamacpp.Unsupported(err) {
			srv.off = true
			m.log.Info("llama.cpp server has no slot API; not keeping prompt caches", "provider", p.Name)
		}
		return nil, nil
	}
	last, had := -1, false
	for _, k := range keys {
		if last, had = srv.last[info.Model][k]; had {
			break
		}
	}
	pick := -1
	for _, sl := range slots {
		if sl.IsProcessing {
			continue
		}
		if had && sl.ID == last {
			pick = sl.ID
			break
		}
		if pick < 0 {
			pick = sl.ID
		}
	}
	if pick < 0 {
		return nil, nil // all busy: let the server choose; nothing to restore
	}
	if srv.last[info.Model] == nil {
		srv.last[info.Model] = map[string]int{}
	}
	srv.last[info.Model][keys[0]] = pick
	var f *kvFile
	for _, k := range keys {
		if f = srv.fileFor(k, info.Model); f != nil {
			break
		}
	}
	if !first || f == nil {
		return &pick, nil
	}
	start := time.Now()
	n, err := c.RestoreSlot(ctx, info.Model, pick, f.name)
	pc := &flitv1.PromptCache{Action: flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_RESTORED, MessageId: msgID,
		Slot: int32(pick), File: f.name, Tokens: int64(n), ElapsedMs: time.Since(start).Milliseconds()}
	if err != nil {
		pc.Error = err.Error()
		f.tokens = 0 // don't try that file again
		if llamacpp.Unsupported(err) {
			srv.off = true
		}
	} else {
		f.used = time.Now()
	}
	return &pick, &flitv1.Event{Payload: &flitv1.Event_PromptCache{PromptCache: pc}}
}

// saveAfterTurn saves the session branch's cache from the slot its last
// call used, and logs it. A save of nothing (the cache was already gone)
// leaves no file to restore.
func (m *Manager) saveAfterTurn(s *session, ref *slotRef) {
	p, router, model, slot := ref.provider, ref.router, ref.model, ref.slot
	cfg := m.cfg()
	if !cfg.LlamaCpp.KVCacheOn() || m.closing.Load() {
		return
	}
	srv := m.kv.server(p.Name)
	srv.mu.Lock()
	defer srv.mu.Unlock()
	if srv.off {
		return
	}
	info := s.snapshot()
	f := srv.claimFile(ref.key, model, cfg.LlamaCpp.KVCacheFiles)
	start := time.Now()
	n, err := m.llamaClient(p, router).SaveSlot(context.Background(), model, slot, f.name)
	f.tokens = n
	pc := &flitv1.PromptCache{Action: flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_SAVED,
		Slot: int32(slot), File: f.name, Tokens: int64(n), ElapsedMs: time.Since(start).Milliseconds()}
	if err != nil {
		f.tokens = 0
		pc.Error = err.Error()
		if llamacpp.Unsupported(err) {
			srv.off = true
			m.log.Info("llama.cpp server can't save prompt caches (no --slot-save-path?); not keeping them", "provider", p.Name, "err", err)
			return // nothing to tell the user about
		}
	}
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptCache{PromptCache: pc}}); err != nil {
		m.log.Warn("record prompt cache save", "session", info.ID, "err", err)
	}
}

// discardKV forgets the active branch's prompt cache save files: after
// compaction its prompt starts differently, so restoring one would load a
// prefix the next call doesn't share. Other branches' prompts haven't
// changed; their caches stay. Each one dropped is logged.
func (m *Manager) discardKV(s *session) {
	info := s.snapshot()
	key := kvKey(info.ID, info.BranchID)
	m.kv.mu.Lock()
	servers := make([]*kvServer, 0, len(m.kv.servers))
	for _, srv := range m.kv.servers {
		servers = append(servers, srv)
	}
	m.kv.mu.Unlock()
	for _, srv := range servers {
		srv.mu.Lock()
		var dropped []*kvFile
		for _, f := range srv.files {
			if f.key == key && f.tokens > 0 {
				f.tokens = 0
				dropped = append(dropped, f)
			}
		}
		srv.mu.Unlock()
		for _, f := range dropped {
			if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_PromptCache{PromptCache: &flitv1.PromptCache{
				Action: flitv1.PromptCacheAction_PROMPT_CACHE_ACTION_DISCARDED, File: f.name, Slot: -1,
			}}}); err != nil {
				m.log.Warn("record prompt cache discard", "session", info.ID, "err", err)
			}
		}
	}
}

// --- Answer now ---

// endReasoning asks the model of the session's running call to stop
// thinking. If it keeps thinking past reasoningEndGrace, the log gets
// ReasoningEndIgnored and the model is marked as not supporting it.
func (s *session) endReasoning(ctx context.Context, client string) error {
	s.mu.Lock()
	c := s.call
	if c == nil || c.id == "" || c.reasoning == 0 || c.text > 0 || c.endAsked {
		s.mu.Unlock()
		return ErrCantEndReasoning
	}
	c.endAsked = true
	before := c.reasoning
	team := s.info.TeamID
	s.mu.Unlock()

	if err := s.m.llamaClient(c.provider, c.router).EndReasoning(ctx, c.model, c.id); err != nil {
		return fmt.Errorf("%w: %v", ErrCantEndReasoning, err)
	}
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ReasoningEndRequested{ReasoningEndRequested: &flitv1.ReasoningEndRequested{
		MessageId: c.msgID, Client: client,
	}}}); err != nil {
		return err
	}
	time.AfterFunc(reasoningEndGrace, func() {
		s.mu.Lock()
		ignored := c.text == 0 && c.reasoning > before && s.call == c
		s.mu.Unlock()
		if !ignored {
			return
		}
		if err := s.m.store.SetNoReasoningEnd(context.Background(), team, store.ModelKey{Provider: c.provider.Name, Model: c.model}); err != nil {
			s.m.log.Warn("record ignored reasoning end", "err", err)
		}
		if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_ReasoningEndIgnored{ReasoningEndIgnored: &flitv1.ReasoningEndIgnored{
			MessageId: c.msgID,
		}}}); err != nil {
			s.m.log.Warn("record ignored reasoning end", "err", err)
		}
	})
	return nil
}
