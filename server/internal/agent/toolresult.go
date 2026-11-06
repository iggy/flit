package agent

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/tools"
)

// toolOutputDir is where a session's long tool results are saved in full
// ("" when there is no data dir): <data>/sessions/<id>/tool-output.
func (m *Manager) toolOutputDir(sessionID string) string {
	if m.DataDir == "" || sessionID == "" {
		return ""
	}
	return filepath.Join(m.DataDir, "sessions", sessionID, "tool-output")
}

// readDirs are the directories outside the working directory that the
// session's read tools may read.
func (s *session) readDirs() []string {
	if d := s.m.toolOutputDir(s.snapshot().ID); d != "" {
		return []string{d}
	}
	return nil
}

// fileTracker is the session's read-before-write state for the active
// branch (nil when agent.read_before_write is off). Switching or forking
// a branch starts afresh: the reads on the old path are not in the new
// one's context.
func (s *session) fileTracker() *tools.FileTracker {
	if !s.m.cfg().Agent.ReadBeforeWriteOn() {
		return nil
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.files == nil || s.filesBranch != s.info.BranchID {
		s.files, s.filesBranch = tools.NewFileTracker(), s.info.BranchID
	}
	return s.files
}

// shapeResult is the text the model gets for a tool result: cut down to
// agent.tool_output_max_*, with the full text saved under the session's
// tool output dir as name (a subagent's go in a subdirectory) so the model
// can read it, plus a note when this is a repeated call (repeats is how
// many times it has been made).
func (s *session) shapeResult(cfg config.Config, name string, res tools.Result, repeats int) (string, int64, bool) {
	text, omitted, cut := tools.Truncate(res.Text, cfg.Agent.ToolOutputMaxBytes, cfg.Agent.ToolOutputMaxLines)
	if cut {
		if dir := s.m.toolOutputDir(s.snapshot().ID); dir != "" {
			p, err := saveToolOutput(dir, name, res.Text)
			if err != nil {
				s.m.log.Warn("could not save tool output", "session", s.snapshot().ID, "err", err)
			} else {
				text, omitted, cut = tools.TruncateSaved(res.Text, cfg.Agent.ToolOutputMaxBytes, cfg.Agent.ToolOutputMaxLines, p)
			}
		}
	}
	return text + repeatNote(cfg.Agent.RepeatCallNudges, repeats), omitted, cut
}

// saveToolOutput writes text to a new file under dir named after name
// (path elements are tool call ids, which come from the model, so they are
// cleaned) and returns its path.
func saveToolOutput(dir, name, text string) (string, error) {
	parts := strings.Split(name, "/")
	for i, p := range parts {
		parts[i] = safeName(p)
	}
	base := filepath.Join(append([]string{dir}, parts...)...)
	if err := os.MkdirAll(filepath.Dir(base), 0o700); err != nil {
		return "", err
	}
	// Providers that number their calls (call_0, call_1, ...) reuse ids
	// across steps, so never overwrite.
	for n := 1; n < 1000; n++ {
		p := base + ".txt"
		if n > 1 {
			p = fmt.Sprintf("%s-%d.txt", base, n)
		}
		f, err := os.OpenFile(p, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
		if errors.Is(err, fs.ErrExist) {
			continue
		}
		if err != nil {
			return "", err
		}
		_, err = f.WriteString(text)
		if cerr := f.Close(); err == nil {
			err = cerr
		}
		return p, err
	}
	return "", fmt.Errorf("too many saved outputs named %s", name)
}

// safeName keeps a file name to letters, digits, - and _.
func safeName(s string) string {
	s = strings.Map(func(r rune) rune {
		if r == '-' || r == '_' || r >= '0' && r <= '9' || r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' {
			return r
		}
		return '_'
	}, s)
	if len(s) > 100 {
		s = s[:100]
	}
	if s == "" {
		s = "call"
	}
	return s
}

// repeatCounter counts tool calls by name and arguments since the latest
// user message, to notice a model going round in circles.
type repeatCounter map[string]int

// newRepeatCounter counts the tool calls in events after the latest user
// message.
func newRepeatCounter(events []*flitv1.Event) repeatCounter {
	c := repeatCounter{}
	for _, ev := range events {
		switch {
		case ev.GetMessageStarted().GetRole() == flitv1.Role_ROLE_USER:
			clear(c)
		case ev.GetToolCallStarted() != nil:
			tc := ev.GetToolCallStarted()
			c.add(tc.Name, tc.Arguments)
		}
	}
	return c
}

// add counts one call and returns how many times it has now been made.
func (c repeatCounter) add(name, args string) int {
	k := name + "\x00" + canonicalArgs(args)
	c[k]++
	return c[k]
}

// canonicalArgs is args with insignificant differences (whitespace, key
// order) removed, so equal calls compare equal.
func canonicalArgs(args string) string {
	var v any
	if err := json.Unmarshal([]byte(args), &v); err != nil {
		return strings.TrimSpace(args)
	}
	b, err := json.Marshal(v) // map keys come out sorted
	if err != nil {
		return strings.TrimSpace(args)
	}
	return string(b)
}

// repeatNote is the advisory added to the result of a call made n times,
// when n is one of thresholds (agent.repeat_call_nudges). The call still
// runs; this only points out the loop.
func repeatNote(thresholds []int, n int) string {
	if !slices.Contains(thresholds, n) {
		return ""
	}
	return fmt.Sprintf("\n\n[flit: you have now made this exact call (same tool, same arguments) %d times. "+
		"Repeating it is not making progress. Look at the previous result, try a different approach, or finish and report what you have.]", n)
}
