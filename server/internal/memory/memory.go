// Package memory reads and writes flit's memory layers: flat Markdown files
// of lessons the agent keeps between sessions.
//
//   - user memory, <data>/memory/user.md, in every session;
//   - project memory, <data>/memory/projects/<project id>.md, in the
//     project's sessions;
//   - a role's memory_file (see package roles), in that role's sessions.
//
// An entry is a top-level Markdown list item (continuation lines indented
// under it). Entries flit writes look like
//
//   - **When running the Go tests:** use `go test ./...` from server/, not the repo root. _(evidence: ses_1a2b T3)_
//
// but the files are the user's to edit: anything else in them is kept and
// shown to the model as it is.
package memory

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
)

// Kinds of layer.
const (
	User    = "user"
	Project = "project"
	Role    = "role"
)

// UserPath is the user memory file in dataDir.
func UserPath(dataDir string) string {
	return filepath.Join(dataDir, "memory", "user.md")
}

// ProjectPath is project projectID's memory file in dataDir.
func ProjectPath(dataDir, projectID string) string {
	return filepath.Join(dataDir, "memory", "projects", safeName(projectID)+".md")
}

var unsafeChars = regexp.MustCompile(`[^A-Za-z0-9._-]`)

func safeName(id string) string {
	s := unsafeChars.ReplaceAllString(id, "_")
	if s == "" || s == "." || s == ".." {
		return "_"
	}
	return s
}

// Layer is one memory file as the system prompt shows it.
type Layer struct {
	Kind string
	Path string
	// Content is the file's text, cut to the budget.
	Content string
	// Truncated is how many bytes were cut.
	Truncated int
}

// ReadCapped reads the memory file at path, cut to at most maxBytes (0:
// no cap) at a line boundary with a marker saying how much is missing. A
// missing or blank file gives "".
func ReadCapped(path string, maxBytes int) (content string, cut int, err error) {
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return "", 0, nil
	}
	if err != nil {
		return "", 0, err
	}
	s := strings.TrimSpace(string(data))
	if maxBytes <= 0 || len(s) <= maxBytes {
		return s, 0, nil
	}
	head := s[:maxBytes]
	if i := strings.LastIndexByte(head, '\n'); i > 0 {
		head = head[:i]
	}
	cut = len(s) - len(head)
	return head + fmt.Sprintf("\n[... %d more bytes in %s ...]", cut, path), cut, nil
}

// Entry is one lesson.
type Entry struct {
	Cue      string
	Lesson   string
	Evidence string
}

// Render is the entry as a Markdown list item.
func (e Entry) Render() string {
	var b strings.Builder
	b.WriteString("- ")
	if cue := oneLine(e.Cue); cue != "" {
		cue = strings.TrimRight(cue, ":.")
		fmt.Fprintf(&b, "**%s:** ", cue)
	}
	b.WriteString(oneLine(e.Lesson))
	if ev := oneLine(e.Evidence); ev != "" {
		fmt.Fprintf(&b, " _(evidence: %s)_", ev)
	}
	return b.String()
}

func oneLine(s string) string { return strings.Join(strings.Fields(s), " ") }

// Item is a top-level list item in a memory file.
type Item struct {
	// Text is the item, its continuation lines included, without the
	// trailing newline.
	Text string
}

// Items returns the top-level list items of a memory file, in order.
func Items(content string) []Item {
	var out []Item
	var cur []string
	flush := func() {
		if cur != nil {
			out = append(out, Item{Text: strings.TrimRight(strings.Join(cur, "\n"), "\n ")})
			cur = nil
		}
	}
	for _, line := range strings.Split(strings.ReplaceAll(content, "\r\n", "\n"), "\n") {
		switch {
		case isItemStart(line):
			flush()
			cur = []string{line}
		case cur != nil && (strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t")):
			cur = append(cur, line)
		case cur != nil && strings.TrimSpace(line) == "":
			cur = append(cur, line) // may be inside the item; trimmed if it ends it
		default:
			flush()
		}
	}
	flush()
	return out
}

func isItemStart(line string) bool {
	return strings.HasPrefix(line, "- ") || strings.HasPrefix(line, "* ")
}

// Change is an edit to a memory file.
type Change struct {
	// Action is "add", "update" or "remove".
	Action string
	// Old is the existing item to update or remove, exactly as Items
	// returned it.
	Old string
	// New is the text to add or put in Old's place.
	New string
	// Header starts a file that doesn't exist yet.
	Header string
}

// ErrChanged is returned when the item a change refers to is no longer in
// the file.
var ErrChanged = errors.New("the memory entry is no longer in the file; it was edited since the proposal was made")

var writeMu sync.Mutex

// Apply makes c to the memory file at path, creating it (and its
// directory) if needed.
func Apply(path string, c Change) error {
	writeMu.Lock()
	defer writeMu.Unlock()
	data, err := os.ReadFile(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	content := strings.ReplaceAll(string(data), "\r\n", "\n")
	newText := strings.TrimSpace(c.New)
	switch c.Action {
	case "add":
		if newText == "" {
			return errors.New("nothing to add")
		}
		if strings.TrimSpace(content) == "" {
			content = c.Header
		}
		content = strings.TrimRight(content, "\n")
		if content != "" {
			content += "\n"
			if !lastLineIsItem(content) {
				content += "\n"
			}
		}
		content += newText + "\n"
	case "update", "remove":
		i := strings.Index(content, c.Old)
		if c.Old == "" || i < 0 {
			return ErrChanged
		}
		end := i + len(c.Old)
		if c.Action == "remove" {
			if end < len(content) && content[end] == '\n' {
				end++
			}
			newText = ""
		} else if newText == "" {
			return errors.New("an update needs the new text")
		}
		content = content[:i] + newText + content[end:]
	default:
		return fmt.Errorf("unknown action %q", c.Action)
	}
	return WriteFile(path, []byte(content))
}

func lastLineIsItem(content string) bool {
	lines := strings.Split(strings.TrimRight(content, "\n"), "\n")
	last := lines[len(lines)-1]
	return isItemStart(last) || strings.HasPrefix(last, " ")
}

// WriteFile writes data to path through a temporary file, so readers never
// see half a file, creating the directory if needed.
func WriteFile(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".*")
	if err != nil {
		return err
	}
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return err
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmp.Name())
		return err
	}
	if fi, err := os.Stat(path); err == nil {
		_ = os.Chmod(tmp.Name(), fi.Mode().Perm())
	} else {
		_ = os.Chmod(tmp.Name(), 0o644)
	}
	return os.Rename(tmp.Name(), path)
}

// Header returns the text a new memory file of kind starts with; name is
// the project's or role's name.
func Header(kind, name string) string {
	switch kind {
	case User:
		return "# User memory\n\nWhat flit has learned about working with you, in every project. Edit freely: each lesson is a list item.\n"
	case Project:
		return fmt.Sprintf("# Project memory: %s\n\nWhat flit has learned about this project. Edit freely: each lesson is a list item.\n", name)
	}
	return ""
}
