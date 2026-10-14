// Package devices pairs new clients and checks their tokens.
//
// Pairing: an admin creates a short-lived, single-use code ("flit pair");
// a device trades it for its own token with Pair. Tokens are stored only as
// SHA-256 hashes and can be revoked.
package devices

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/store"
)

const (
	// CodeTTL is how long a pairing code works.
	CodeTTL = 10 * time.Minute
	// maxFailures wrong codes in a row invalidate all outstanding codes, so
	// guessing a code is hopeless.
	maxFailures = 10
	// touchEvery limits last-seen writes per device.
	touchEvery = time.Minute

	codeAlphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789" // no 0/O, 1/I/L
	codeLen      = 8
	tokenPrefix  = "flitd_"
)

// ErrBadCode is returned by Pair for an unknown, used or expired code.
var ErrBadCode = errors.New("pairing code is wrong, already used or expired; run \"flit pair\" for a new one")

// Registry implements auth.DeviceTokens.
type Registry struct {
	store *store.Store
	now   func() time.Time

	mu       sync.Mutex
	codes    map[string]time.Time // normalized code -> expiry
	failures int
	cache    map[string]auth.Principal // token hash (hex) -> principal
	touched  map[string]time.Time      // device id -> last write
}

var _ auth.DeviceTokens = (*Registry)(nil)

// New returns a Registry backed by st.
func New(st *store.Store) *Registry {
	return &Registry{
		store:   st,
		now:     time.Now,
		codes:   map[string]time.Time{},
		cache:   map[string]auth.Principal{},
		touched: map[string]time.Time{},
	}
}

func normalize(code string) string {
	return strings.ToUpper(strings.NewReplacer("-", "", " ", "").Replace(strings.TrimSpace(code)))
}

// CreateCode returns a new pairing code, formatted "XXXX-XXXX", and when it
// expires.
func (r *Registry) CreateCode() (string, time.Time) {
	// Rejection sampling keeps every character equally likely.
	limit := byte(256 - 256%len(codeAlphabet))
	var b []byte
	buf := make([]byte, 1)
	for len(b) < codeLen {
		_, _ = rand.Read(buf)
		if buf[0] < limit {
			b = append(b, codeAlphabet[int(buf[0])%len(codeAlphabet)])
		}
	}
	code := string(b)
	r.mu.Lock()
	defer r.mu.Unlock()
	now := r.now()
	for c, exp := range r.codes {
		if now.After(exp) {
			delete(r.codes, c)
		}
	}
	exp := now.Add(CodeTTL)
	r.codes[code] = exp
	return code[:4] + "-" + code[4:], exp
}

// Pair trades a code for a new device and its token.
func (r *Registry) Pair(ctx context.Context, code, name string) (store.Device, string, error) {
	name = strings.TrimSpace(name)
	if name == "" {
		name = "device"
	}
	if len(name) > 100 {
		name = name[:100]
	}
	r.mu.Lock()
	norm := normalize(code)
	exp, ok := r.codes[norm]
	if !ok || r.now().After(exp) {
		r.failures++
		if r.failures >= maxFailures {
			clear(r.codes)
			r.failures = 0
		}
		r.mu.Unlock()
		return store.Device{}, "", ErrBadCode
	}
	delete(r.codes, norm)
	r.failures = 0
	r.mu.Unlock()

	tok := make([]byte, 32)
	_, _ = rand.Read(tok)
	token := tokenPrefix + base64.RawURLEncoding.EncodeToString(tok)
	id := make([]byte, 8)
	_, _ = rand.Read(id)
	sum := sha256.Sum256([]byte(token))
	d := store.Device{ID: "dev_" + hex.EncodeToString(id), Name: name, TokenHash: sum[:]}
	if err := r.store.CreateDevice(ctx, &d); err != nil {
		return store.Device{}, "", fmt.Errorf("save device: %w", err)
	}
	return d, token, nil
}

// Lookup implements auth.DeviceTokens.
func (r *Registry) Lookup(ctx context.Context, token string) (auth.Principal, bool) {
	if !strings.HasPrefix(token, tokenPrefix) {
		return auth.Principal{}, false
	}
	sum := sha256.Sum256([]byte(token))
	key := hex.EncodeToString(sum[:])

	r.mu.Lock()
	p, ok := r.cache[key]
	r.mu.Unlock()
	if !ok {
		d, err := r.store.DeviceByTokenHash(ctx, sum[:])
		if err != nil {
			return auth.Principal{}, false
		}
		p = auth.Principal{DeviceID: d.ID, Name: d.Name}
		r.mu.Lock()
		r.cache[key] = p
		r.mu.Unlock()
	}
	r.touch(p.DeviceID)
	return p, true
}

func (r *Registry) touch(id string) {
	now := r.now()
	r.mu.Lock()
	if now.Sub(r.touched[id]) < touchEvery {
		r.mu.Unlock()
		return
	}
	r.touched[id] = now
	r.mu.Unlock()
	_ = r.store.TouchDevice(context.Background(), id, now)
}

// List returns paired devices.
func (r *Registry) List(ctx context.Context, includeRevoked bool) ([]store.Device, error) {
	return r.store.ListDevices(ctx, includeRevoked)
}

// Revoke revokes a device; its token stops working immediately.
func (r *Registry) Revoke(ctx context.Context, id string) error {
	if err := r.store.RevokeDevice(ctx, id); err != nil {
		return err
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	for k, p := range r.cache {
		if p.DeviceID == id {
			delete(r.cache, k)
		}
	}
	return nil
}
