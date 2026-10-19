// Package skills reads skills in the open Agent Skills format
// (https://agentskills.io): a directory per skill holding a SKILL.md with
// YAML frontmatter (name, description) and Markdown instructions, plus any
// scripts/, references/ or assets/.
//
// Disclosure is progressive: only names and descriptions go into the system
// prompt; the agent loads a skill's instructions, and then its files, with
// the skill tool when it decides it needs them.
package skills

import (
	"bytes"
	"embed"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"

	"go.yaml.in/yaml/v3"
)

// FileName is the required file in a skill directory.
const FileName = "SKILL.md"

var nameRE = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)

// Skill is one skill directory.
type Skill struct {
	Name          string            `yaml:"name"`
	Description   string            `yaml:"description"`
	License       string            `yaml:"license"`
	Compatibility string            `yaml:"compatibility"`
	Metadata      map[string]string `yaml:"metadata"`
	AllowedTools  string            `yaml:"allowed-tools"`

	// Dir is the skill directory; Body is SKILL.md after the frontmatter.
	Dir  string `yaml:"-"`
	Body string `yaml:"-"`
	// Source says where it was found, e.g. "repo .agents/skills" or
	// "global".
	Source string `yaml:"-"`
}

// Dir is a directory of skills and a label for where it is.
type Dir struct {
	Path   string
	Source string
}

// RepoDirs are the skill directories a repository can carry, in order of
// preference. .agents/skills is the cross-tool convention; .claude/skills
// is read for compatibility.
var RepoDirs = []string{".agents/skills", ".claude/skills"}

// SessionDirs returns the skill directories for a session working in
// workDir: the repo's own (at workDir, then at its git root if that's
// different) followed by the global ones. Earlier directories win when two
// skills share a name, so a repo skill overrides a global one.
func SessionDirs(workDir string, global []string) []Dir {
	var out []Dir
	add := func(base, label string) {
		for _, rel := range RepoDirs {
			out = append(out, Dir{Path: filepath.Join(base, filepath.FromSlash(rel)), Source: label + " " + rel})
		}
	}
	if workDir != "" {
		add(workDir, "repo")
		if root := gitRoot(workDir); root != "" && root != filepath.Clean(workDir) {
			add(root, "repo root")
		}
	}
	for _, g := range global {
		out = append(out, Dir{Path: g, Source: "global"})
	}
	return out
}

// gitRoot returns the nearest ancestor of dir (or dir itself) containing
// .git, or "".
func gitRoot(dir string) string {
	dir = filepath.Clean(dir)
	for {
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}

// Load reads every skill directory in dirs. Later dirs don't override
// earlier ones: the first skill with a name wins. Invalid skills are
// skipped and reported in problems.
func Load(dirs []Dir) (list []Skill, problems []error) {
	seen := map[string]bool{}
	for _, d := range dirs {
		dir := d.Path
		entries, err := os.ReadDir(dir)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			problems = append(problems, err)
			continue
		}
		for _, e := range entries {
			if !e.IsDir() {
				continue
			}
			s, err := Read(filepath.Join(dir, e.Name()))
			if errors.Is(err, os.ErrNotExist) {
				continue
			}
			if err != nil {
				problems = append(problems, err)
				continue
			}
			if seen[s.Name] {
				continue
			}
			s.Source = d.Source
			seen[s.Name] = true
			list = append(list, s)
		}
	}
	slices.SortFunc(list, func(a, b Skill) int { return strings.Compare(a.Name, b.Name) })
	return list, problems
}

// Read reads and validates the skill in dir.
func Read(dir string) (Skill, error) {
	data, err := os.ReadFile(filepath.Join(dir, FileName))
	if err != nil {
		return Skill{}, err
	}
	s, err := parse(data, dir, filepath.Base(dir))
	if err != nil {
		return Skill{}, err
	}
	s.Dir = dir
	return s, nil
}

// parse reads a SKILL.md; where names it in errors and dirName is the name
// the skill must have.
func parse(data []byte, where, dirName string) (Skill, error) {
	dir := where
	data = bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	rest, ok := bytes.CutPrefix(data, []byte("---\n"))
	if !ok {
		return Skill{}, fmt.Errorf("%s: SKILL.md must start with YAML frontmatter", dir)
	}
	front, body, found := bytes.Cut(rest, []byte("\n---"))
	if !found {
		return Skill{}, fmt.Errorf("%s: frontmatter never ends", dir)
	}
	var s Skill
	if err := yaml.NewDecoder(bytes.NewReader(front)).Decode(&s); err != nil && !errors.Is(err, io.EOF) {
		return Skill{}, fmt.Errorf("%s: frontmatter: %w", dir, err)
	}
	if i := bytes.IndexByte(body, '\n'); i >= 0 {
		body = body[i+1:]
	} else {
		body = nil
	}
	s.Body = strings.TrimSpace(string(body))
	switch {
	case !nameRE.MatchString(s.Name) || len(s.Name) > 64:
		return Skill{}, fmt.Errorf("%s: name %q must be 1-64 lowercase letters, digits and single hyphens", dir, s.Name)
	case s.Name != dirName:
		return Skill{}, fmt.Errorf("%s: name %q must match the directory name", dir, s.Name)
	case strings.TrimSpace(s.Description) == "" || len(s.Description) > 1024:
		return Skill{}, fmt.Errorf("%s: description must be 1-1024 characters", dir)
	}
	return s, nil
}

// builtinFS holds the skills that ship with flit.
//
//go:embed builtin/*/SKILL.md
var builtinFS embed.FS

// BuiltinSource is the Source of skills that ship with flit.
const BuiltinSource = "built-in"

// Builtin returns the skills that ship with flit. They have no directory
// and no files besides their instructions.
func Builtin() []Skill {
	entries, _ := builtinFS.ReadDir("builtin")
	var out []Skill
	for _, e := range entries {
		data, err := builtinFS.ReadFile("builtin/" + e.Name() + "/" + FileName)
		if err != nil {
			panic(err)
		}
		s, err := parse(data, "built-in skill "+e.Name(), e.Name())
		if err != nil {
			panic(err) // tested
		}
		s.Source = BuiltinSource
		out = append(out, s)
	}
	return out
}

// WithBuiltin adds the built-in skills to list, below everything already
// in it: a repo or global skill with the same name wins.
func WithBuiltin(list []Skill) []Skill {
	seen := map[string]bool{}
	for _, s := range list {
		seen[s.Name] = true
	}
	out := slices.Clone(list)
	for _, s := range Builtin() {
		if !seen[s.Name] {
			out = append(out, s)
		}
	}
	slices.SortFunc(out, func(a, b Skill) int { return strings.Compare(a.Name, b.Name) })
	return out
}

// Files lists the skill's files other than SKILL.md, relative to its
// directory, up to limit.
func (s Skill) Files(limit int) []string {
	var out []string
	if s.Dir == "" {
		return nil
	}
	_ = filepath.WalkDir(s.Dir, func(p string, d os.DirEntry, err error) error {
		if err != nil || len(out) >= limit {
			return filepath.SkipAll
		}
		if d.IsDir() || p == filepath.Join(s.Dir, FileName) {
			return nil
		}
		if r, err := filepath.Rel(s.Dir, p); err == nil {
			out = append(out, filepath.ToSlash(r))
		}
		return nil
	})
	return out
}

// PromptSection is the system prompt text listing the skills.
func PromptSection(list []Skill) string {
	if len(list) == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString("\nSkills you can load with the skill tool when a task matches (load before acting on it). " +
		"A user message starting with /<name> (e.g. /init) asks for that skill: load it and follow it, " +
		"treating any text after the name as the user's input to it.\n")
	for _, s := range list {
		fmt.Fprintf(&b, "- %s: %s\n", s.Name, strings.Join(strings.Fields(s.Description), " "))
	}
	return b.String()
}
