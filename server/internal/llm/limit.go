package llm

import (
	"context"
	"sync"
)

// Limiter caps how many calls to each provider+model are in flight at once,
// across every Client that shares it. Calls over the limit wait their turn,
// first come first served.
//
// The limit is looked up each time a call asks for a slot or one frees up,
// so a changed limit applies to the next call; calls already running are
// never stopped. Call Changed after the limits change so waiting calls see
// a raised limit straight away.
type Limiter struct {
	limit func(provider, model string) int

	mu    sync.Mutex
	gates map[limitKey]*gate
}

type limitKey struct{ provider, model string }

// gate is one provider+model's slots.
type gate struct {
	inUse   int
	waiting []*waiter
}

type waiter struct {
	ready   chan struct{}
	granted bool
}

// NewLimiter returns a Limiter. limit returns the most calls to a
// provider's model that may be in flight at once; 0 or less means no limit.
func NewLimiter(limit func(provider, model string) int) *Limiter {
	return &Limiter{limit: limit, gates: map[limitKey]*gate{}}
}

// Acquire takes a slot for a call to model on provider, waiting for one if
// all are in use; queued, if not nil, is called with the limit before it
// waits. It returns release, which frees the slot (calling it more than
// once is fine), or ctx's error if ctx ends first. A nil Limiter never
// waits.
func (l *Limiter) Acquire(ctx context.Context, provider, model string, queued func(limit int)) (release func(), err error) {
	if l == nil {
		return func() {}, nil
	}
	key := limitKey{provider, model}
	l.mu.Lock()
	g := l.gates[key]
	if g == nil {
		g = &gate{}
		l.gates[key] = g
	}
	limit := l.limit(provider, model)
	if len(g.waiting) == 0 && (limit <= 0 || g.inUse < limit) {
		g.inUse++
		l.mu.Unlock()
		return l.releaser(key), nil
	}
	w := &waiter{ready: make(chan struct{})}
	g.waiting = append(g.waiting, w)
	l.mu.Unlock()

	if queued != nil {
		queued(limit)
	}
	select {
	case <-w.ready:
		return l.releaser(key), nil
	case <-ctx.Done():
		l.mu.Lock()
		if w.granted {
			// The slot came free as ctx ended: pass it on.
			g.inUse--
			l.pump(key, g)
		} else {
			g.waiting = removeWaiter(g.waiting, w)
			l.forget(key, g)
		}
		l.mu.Unlock()
		return nil, ctx.Err()
	}
}

// Changed lets waiting calls take slots a raised limit opened up.
func (l *Limiter) Changed() {
	if l == nil {
		return
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	for key, g := range l.gates {
		l.pump(key, g)
	}
}

// InUse reports how many calls to model on provider hold a slot and how
// many wait for one.
func (l *Limiter) InUse(provider, model string) (inUse, waiting int) {
	if l == nil {
		return 0, 0
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	if g := l.gates[limitKey{provider, model}]; g != nil {
		return g.inUse, len(g.waiting)
	}
	return 0, 0
}

func (l *Limiter) releaser(key limitKey) func() {
	var once sync.Once
	return func() {
		once.Do(func() {
			l.mu.Lock()
			defer l.mu.Unlock()
			g := l.gates[key]
			g.inUse--
			l.pump(key, g)
		})
	}
}

// pump hands free slots to waiters in order. l.mu is held.
func (l *Limiter) pump(key limitKey, g *gate) {
	limit := l.limit(key.provider, key.model)
	for len(g.waiting) > 0 && (limit <= 0 || g.inUse < limit) {
		w := g.waiting[0]
		g.waiting = g.waiting[1:]
		g.inUse++
		w.granted = true
		close(w.ready)
	}
	l.forget(key, g)
}

// forget drops an idle gate so the map doesn't grow with every model ever
// used. l.mu is held.
func (l *Limiter) forget(key limitKey, g *gate) {
	if g.inUse == 0 && len(g.waiting) == 0 {
		delete(l.gates, key)
	}
}

func removeWaiter(ws []*waiter, w *waiter) []*waiter {
	for i, x := range ws {
		if x == w {
			return append(ws[:i], ws[i+1:]...)
		}
	}
	return ws
}
