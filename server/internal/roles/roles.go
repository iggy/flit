// Package roles reads role files: Markdown with YAML frontmatter, one role
// per file in the roles directory.
//
//	---
//	description: Careful reviewer
//	provider: openrouter
//	model: some/big-model
//	effort: high
//	memory_file: NOTES.md
//	tasks:
//	  planning: {provider: openrouter, model: some/bigger-model}
//	---
//	You review changes for correctness before style. …
//
// The body is added to the system prompt. Roles are read when used, so
// edits apply to the next turn.
//
// Some roles ship with flit (see builtin/); a file in the roles directory
// with the same name replaces one.
package roles

import (
	"bytes"
	"embed"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"

	"go.yaml.in/yaml/v3"

	"github.com/iggy/flit/server/internal/config"
)

// maxRoleBytes caps a role file.
const maxRoleBytes = 256 << 10

// Role is one role file.
type Role struct {
	Name        string                      `yaml:"name"`
	Description string                      `yaml:"description"`
	Provider    string                      `yaml:"provider"`
	Model       string                      `yaml:"model"`
	Effort      string                      `yaml:"effort"`
	MemoryFile  string                      `yaml:"memory_file"`
	Tasks       map[string]config.TaskModel `yaml:"tasks"`

	// Prompt is the Markdown body.
	Prompt string `yaml:"-"`
	// Path is the file it came from.
	Path string `yaml:"-"`
	// Err is set when the file couldn't be read; such a role can't be used.
	Err error `yaml:"-"`
	// Builtin is set for roles that ship with flit; they have no Path.
	Builtin bool `yaml:"-"`
}

// builtinFS holds the roles that ship with flit.
//
//go:embed builtin/*.md
var builtinFS embed.FS

// Builtin returns the roles that ship with flit, sorted by name.
func Builtin() []Role {
	entries, _ := builtinFS.ReadDir("builtin")
	var out []Role
	for _, e := range entries {
		data, err := builtinFS.ReadFile("builtin/" + e.Name())
		if err != nil {
			panic(err)
		}
		r, err := Parse(data)
		if err != nil {
			panic(fmt.Errorf("built-in role %s: %w", e.Name(), err)) // tested
		}
		if r.Name == "" {
			r.Name = strings.TrimSuffix(e.Name(), ".md")
		}
		r.Builtin = true
		out = append(out, r)
	}
	return out
}

// List returns the built-in roles plus every *.md file in dir, sorted by
// name; a file replaces a built-in role with the same name. A missing dir
// means only the built-in roles. Unreadable files are returned with Err
// set.
func List(dir string) ([]Role, error) {
	files, err := listDir(dir)
	if err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	for _, r := range files {
		seen[r.Name] = true
	}
	out := files
	for _, r := range Builtin() {
		if !seen[r.Name] {
			out = append(out, r)
		}
	}
	slices.SortFunc(out, func(a, b Role) int { return strings.Compare(a.Name, b.Name) })
	return out, nil
}

// listDir reads every *.md file in dir.
func listDir(dir string) ([]Role, error) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var out []Role
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") {
			continue
		}
		r, err := Load(filepath.Join(dir, e.Name()))
		if err != nil {
			r = Role{Name: strings.TrimSuffix(e.Name(), ".md"), Path: filepath.Join(dir, e.Name()), Err: err}
		}
		out = append(out, r)
	}
	return out, nil
}

// Get returns the role named name from dir.
func Get(dir, name string) (Role, error) {
	list, err := List(dir)
	if err != nil {
		return Role{}, err
	}
	for _, r := range list {
		if r.Name == name {
			if r.Err != nil {
				return Role{}, fmt.Errorf("role %q: %w", name, r.Err)
			}
			return r, nil
		}
	}
	return Role{}, fmt.Errorf("no role named %q in %s", name, dir)
}

// Load reads one role file.
func Load(path string) (Role, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Role{}, err
	}
	if len(data) > maxRoleBytes {
		return Role{}, fmt.Errorf("%s is larger than %d bytes", path, maxRoleBytes)
	}
	r, err := Parse(data)
	if err != nil {
		return Role{}, fmt.Errorf("%s: %w", path, err)
	}
	if r.Name == "" {
		r.Name = strings.TrimSuffix(filepath.Base(path), ".md")
	}
	r.Path = path
	return r, nil
}

// Parse reads a role from its file contents. The frontmatter is optional;
// without it the whole file is the prompt.
func Parse(data []byte) (Role, error) {
	data = bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	var r Role
	body := data
	if rest, ok := bytes.CutPrefix(data, []byte("---\n")); ok {
		front, after, found := bytes.Cut(rest, []byte("\n---"))
		if !found {
			return Role{}, errors.New("frontmatter starts with --- but never ends")
		}
		dec := yaml.NewDecoder(bytes.NewReader(front))
		dec.KnownFields(true)
		if err := dec.Decode(&r); err != nil && !errors.Is(err, io.EOF) {
			return Role{}, fmt.Errorf("frontmatter: %w", err)
		}
		body = after
		if i := bytes.IndexByte(body, '\n'); i >= 0 {
			body = body[i+1:] // drop the rest of the closing --- line
		} else {
			body = nil
		}
	}
	for task := range r.Tasks {
		if !slices.Contains(config.Tasks, task) {
			return Role{}, fmt.Errorf("tasks: unknown task %q", task)
		}
	}
	r.Prompt = strings.TrimSpace(string(body))
	return r, nil
}

// MemoryPath resolves the role's memory file for a session working in dir.
func (r Role) MemoryPath(dir string) string {
	if r.MemoryFile == "" || filepath.IsAbs(r.MemoryFile) {
		return r.MemoryFile
	}
	return filepath.Join(dir, r.MemoryFile)
}
