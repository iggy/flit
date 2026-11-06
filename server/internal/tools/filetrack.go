package tools

import (
	"crypto/sha256"
	"fmt"
	"sync"
)

// FileTracker remembers which files the agent has read, and what they held
// then, so write and patch can refuse to change a file the agent hasn't
// seen or that changed since it looked (read-before-write). Only the read
// tool and the agent's own successful writes record a file. It is
// in-memory: after a restart the agent has to read files again.
type FileTracker struct {
	mu   sync.Mutex
	seen map[string][sha256.Size]byte
}

// NewFileTracker returns an empty FileTracker.
func NewFileTracker() *FileTracker {
	return &FileTracker{seen: map[string][sha256.Size]byte{}}
}

// Seen records that the agent knows p holds content.
func (t *FileTracker) Seen(p string, content []byte) {
	if t == nil {
		return
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	t.seen[p] = sha256.Sum256(content)
}

// Check returns an error for the model unless p was recorded with exactly
// content (what is on disk now). shown is p as the model should see it.
func (t *FileTracker) Check(p, shown string, content []byte) error {
	if t == nil {
		return nil
	}
	t.mu.Lock()
	defer t.mu.Unlock()
	sum, ok := t.seen[p]
	switch {
	case !ok:
		return fmt.Errorf("%s exists and you have not read it yet; read the file first, then make your change", shown)
	case sum != sha256.Sum256(content):
		return fmt.Errorf("%s has changed since you last read it; read it again, then make your change", shown)
	}
	return nil
}
