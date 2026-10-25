package llm

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

// limits is a settable limit table, keyed "provider/model" with "provider"
// as the fallback, like config.Concurrency.
type limits struct {
	mu sync.Mutex
	m  map[string]int
}

func (l *limits) get(provider, model string) int {
	l.mu.Lock()
	defer l.mu.Unlock()
	if n, ok := l.m[provider+"/"+model]; ok {
		return n
	}
	return l.m[provider]
}

func (l *limits) set(key string, n int) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.m[key] = n
}

// acquireAsync starts an Acquire and returns a channel that gets its
// release func (or nil on error), plus a channel closed once it queued.
func acquireAsync(ctx context.Context, l *Limiter, provider, model string) (got chan func(), queued chan int) {
	got, queued = make(chan func(), 1), make(chan int, 1)
	go func() {
		release, err := l.Acquire(ctx, provider, model, func(limit int) { queued <- limit })
		if err != nil {
			got <- nil
			return
		}
		got <- release
	}()
	return got, queued
}

func waitQueued(t *testing.T, queued chan int) int {
	t.Helper()
	select {
	case n := <-queued:
		return n
	case <-time.After(2 * time.Second):
		t.Fatal("the call never queued")
		return 0
	}
}

func mustGet(t *testing.T, got chan func()) func() {
	t.Helper()
	select {
	case r := <-got:
		if r == nil {
			t.Fatal("acquire failed")
		}
		return r
	case <-time.After(2 * time.Second):
		t.Fatal("the call never got a slot")
		return nil
	}
}

func notYet(t *testing.T, got chan func()) {
	t.Helper()
	select {
	case <-got:
		t.Fatal("the call got a slot over the limit")
	case <-time.After(30 * time.Millisecond):
	}
}

func TestLimiterEnforcesLimit(t *testing.T) {
	lim := &limits{m: map[string]int{"local": 2}}
	l := NewLimiter(lim.get)
	ctx := context.Background()
	r1, err := l.Acquire(ctx, "local", "big", nil)
	if err != nil {
		t.Fatal(err)
	}
	r2, err := l.Acquire(ctx, "local", "big", nil)
	if err != nil {
		t.Fatal(err)
	}
	got, queued := acquireAsync(ctx, l, "local", "big")
	if n := waitQueued(t, queued); n != 2 {
		t.Fatalf("queued with limit %d, want 2", n)
	}
	notYet(t, got)
	if in, w := l.InUse("local", "big"); in != 2 || w != 1 {
		t.Fatalf("InUse = %d, %d; want 2, 1", in, w)
	}
	// Another model on the same provider has its own slots.
	r4, err := l.Acquire(ctx, "local", "other", func(int) { t.Error("other model queued") })
	if err != nil {
		t.Fatal(err)
	}
	r4()
	r1()
	r1() // twice is harmless
	r3 := mustGet(t, got)
	if in, w := l.InUse("local", "big"); in != 2 || w != 0 {
		t.Fatalf("InUse = %d, %d; want 2, 0", in, w)
	}
	r2()
	r3()
	if in, _ := l.InUse("local", "big"); in != 0 {
		t.Fatalf("InUse = %d after all released", in)
	}
}

func TestLimiterNoLimitAndNil(t *testing.T) {
	l := NewLimiter(func(string, string) int { return 0 })
	for range 50 {
		if _, err := l.Acquire(context.Background(), "cloud", "m", func(int) { t.Fatal("queued without a limit") }); err != nil {
			t.Fatal(err)
		}
	}
	var nilL *Limiter
	r, err := nilL.Acquire(context.Background(), "a", "b", nil)
	if err != nil {
		t.Fatal(err)
	}
	r()
	nilL.Changed()
}

func TestLimiterModelOverridesProvider(t *testing.T) {
	lim := &limits{m: map[string]int{"local": 1, "local/small": 3}}
	l := NewLimiter(lim.get)
	ctx := context.Background()
	for i := range 3 {
		if _, err := l.Acquire(ctx, "local", "small", func(int) { t.Fatalf("call %d queued under the model's limit of 3", i) }); err != nil {
			t.Fatal(err)
		}
	}
	got, queued := acquireAsync(ctx, l, "local", "small")
	if n := waitQueued(t, queued); n != 3 {
		t.Fatalf("queued with limit %d, want 3", n)
	}
	notYet(t, got)

	if _, err := l.Acquire(ctx, "local", "big", nil); err != nil {
		t.Fatal(err)
	}
	_, queued = acquireAsync(ctx, l, "local", "big")
	if n := waitQueued(t, queued); n != 1 {
		t.Fatalf("big queued with limit %d, want the provider's 1", n)
	}
}

func TestLimiterCancelWhileWaiting(t *testing.T) {
	l := NewLimiter(func(string, string) int { return 1 })
	r1, err := l.Acquire(context.Background(), "p", "m", nil)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	errc := make(chan error, 1)
	queued := make(chan struct{})
	go func() {
		_, err := l.Acquire(ctx, "p", "m", func(int) { close(queued) })
		errc <- err
	}()
	<-queued
	// A second waiter behind the one that gives up.
	got, q2 := acquireAsync(context.Background(), l, "p", "m")
	waitQueued(t, q2)
	cancel()
	select {
	case err := <-errc:
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("err = %v, want context.Canceled", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("cancel didn't stop the wait")
	}
	if _, w := l.InUse("p", "m"); w != 1 {
		t.Fatalf("waiting = %d after a cancel, want 1", w)
	}
	r1()
	mustGet(t, got)()
	if in, w := l.InUse("p", "m"); in != 0 || w != 0 {
		t.Fatalf("InUse = %d, %d; want 0, 0", in, w)
	}
}

func TestLimiterLiveLimitChange(t *testing.T) {
	lim := &limits{m: map[string]int{"local": 1}}
	l := NewLimiter(lim.get)
	ctx := context.Background()
	r1, err := l.Acquire(ctx, "local", "m", nil)
	if err != nil {
		t.Fatal(err)
	}
	got2, q2 := acquireAsync(ctx, l, "local", "m")
	waitQueued(t, q2)
	got3, q3 := acquireAsync(ctx, l, "local", "m")
	waitQueued(t, q3)

	// Raising the limit lets the waiters in without waiting for r1.
	lim.set("local", 3)
	l.Changed()
	r2, r3 := mustGet(t, got2), mustGet(t, got3)

	// Lowering it never stops calls in flight; new ones wait until the
	// count is under the new limit.
	lim.set("local", 1)
	l.Changed()
	if in, _ := l.InUse("local", "m"); in != 3 {
		t.Fatalf("in use = %d, want 3 still running", in)
	}
	got4, q4 := acquireAsync(ctx, l, "local", "m")
	waitQueued(t, q4)
	r1()
	r2()
	notYet(t, got4) // r3 still holds the one slot
	r3()
	mustGet(t, got4)()

	// Removing the limit.
	lim.set("local", 0)
	l.Changed()
	if _, err := l.Acquire(ctx, "local", "m", func(int) { t.Fatal("queued with no limit") }); err != nil {
		t.Fatal(err)
	}
}

func TestLimiterNeverExceeds(t *testing.T) {
	l := NewLimiter(func(string, string) int { return 3 })
	var running, peak atomic.Int32
	var wg sync.WaitGroup
	for range 40 {
		wg.Go(func() {
			r, err := l.Acquire(context.Background(), "p", "m", nil)
			if err != nil {
				t.Error(err)
				return
			}
			n := running.Add(1)
			for {
				p := peak.Load()
				if n <= p || peak.CompareAndSwap(p, n) {
					break
				}
			}
			time.Sleep(time.Millisecond)
			running.Add(-1)
			r()
		})
	}
	wg.Wait()
	if p := peak.Load(); p > 3 {
		t.Fatalf("peak %d calls in flight, limit 3", p)
	}
}
