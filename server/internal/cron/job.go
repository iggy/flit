// Package cron reads cron job files and their schedules.
//
// A job is a Markdown file in the crons directory: YAML frontmatter, and a
// body that is the prompt. The file name without .md is the job's name.
//
//	---
//	schedule: weekdays at 8:30     # or "30 8 * * 1-5", "every 2h", "@daily"
//	project: flit                  # name or id; default Scratch
//	dir: ~/projects/flit           # default the project's directory
//	role: qa
//	model: {provider: local, model: qwen3-4b, effort: off}
//	enabled: true
//	ask: deny                      # or wait
//	ask_timeout: 1h
//	yolo: false
//	timezone: Europe/Berlin        # default the server's
//	catch_up: 1h                   # 0 never catches up
//	keep_runs: 50
//	---
//	Check CI on main and the open PRs. Report anything red.
//
// Unknown keys are errors. Files are read when the scheduler rescans the
// directory, so edits apply within seconds.
package cron

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
	"time"

	"go.yaml.in/yaml/v3"

	"github.com/iggy/flit/server/internal/config"
)

// maxJobBytes caps a job file.
const maxJobBytes = 256 << 10

// Defaults for optional settings.
const (
	DefaultAskTimeout = time.Hour
	DefaultCatchUp    = time.Hour
	DefaultKeepRuns   = 50
)

// Ask modes: what happens to a prompt nobody is there to answer.
const (
	AskDeny = "deny"
	AskWait = "wait"
)

// Duration is a YAML duration: a string like "90s" or "1h", or 0.
type Duration time.Duration

// UnmarshalYAML implements yaml.Unmarshaler.
func (d *Duration) UnmarshalYAML(n *yaml.Node) error {
	if n.Kind == yaml.ScalarNode && n.Value == "0" {
		*d = 0
		return nil
	}
	var s string
	if err := n.Decode(&s); err != nil {
		return err
	}
	v, err := time.ParseDuration(strings.TrimSpace(s))
	if err != nil {
		return fmt.Errorf("line %d: %v", n.Line, err)
	}
	if v < 0 {
		return fmt.Errorf("line %d: duration must not be negative", n.Line)
	}
	*d = Duration(v)
	return nil
}

// Job is one job file.
type Job struct {
	// Name is the file name without .md.
	Name string `yaml:"-"`
	// Path is the file.
	Path string `yaml:"-"`
	// ModTime is when the file last changed.
	ModTime time.Time `yaml:"-"`

	Schedule string `yaml:"schedule"`
	// Project is a project's name or id; empty means Scratch.
	Project string `yaml:"project"`
	// Dir is the working directory; empty means the project's.
	Dir     string           `yaml:"dir"`
	Role    string           `yaml:"role"`
	Model   config.TaskModel `yaml:"model"`
	Enabled *bool            `yaml:"enabled"`
	// Ask is AskDeny (default) or AskWait.
	Ask        string    `yaml:"ask"`
	AskTimeout *Duration `yaml:"ask_timeout"`
	Yolo       bool      `yaml:"yolo"`
	Timezone   string    `yaml:"timezone"`
	CatchUp    *Duration `yaml:"catch_up"`
	KeepRuns   int       `yaml:"keep_runs"`

	// Prompt is the Markdown body.
	Prompt string `yaml:"-"`
	// Err is why the file can't be used; such a job never runs.
	Err error `yaml:"-"`
	// Sched is the parsed schedule (nil when Err is set).
	Sched Schedule `yaml:"-"`
	// Loc is the time zone the schedule is read in.
	Loc *time.Location `yaml:"-"`
}

// IsEnabled reports whether the job runs on its schedule.
func (j Job) IsEnabled() bool { return j.Enabled == nil || *j.Enabled }

// AskWaitFor is how long a held prompt waits for an answer.
func (j Job) AskWaitFor() time.Duration {
	if j.AskTimeout == nil {
		return DefaultAskTimeout
	}
	return time.Duration(*j.AskTimeout)
}

// CatchUpWindow is how late a missed run may still start; 0 means never.
func (j Job) CatchUpWindow() time.Duration {
	if j.CatchUp == nil {
		return DefaultCatchUp
	}
	return time.Duration(*j.CatchUp)
}

// Keep is how many runs' sessions stay in the session list.
func (j Job) Keep() int {
	if j.KeepRuns <= 0 {
		return DefaultKeepRuns
	}
	return j.KeepRuns
}

// nameRe is what a job name may be: it is a file name and shows in titles.
var nameRe = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`)

// ValidName reports whether name can be a job's name.
func ValidName(name string) error {
	if !nameRe.MatchString(name) || strings.HasSuffix(name, ".md") {
		return fmt.Errorf("job name %q: use 1-64 letters, digits, '.', '-' or '_', starting with a letter or digit", name)
	}
	return nil
}

// List reads every *.md file in dir, sorted by name. A missing dir means no
// jobs. Files that can't be used are returned with Err set.
func List(dir string) ([]Job, error) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var out []Job
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		out = append(out, Load(filepath.Join(dir, e.Name())))
	}
	slices.SortFunc(out, func(a, b Job) int { return strings.Compare(a.Name, b.Name) })
	return out, nil
}

// Load reads one job file. Problems are in the returned job's Err. "in ..."
// schedules count from when the file last changed.
func Load(path string) Job {
	j := Job{Name: strings.TrimSuffix(filepath.Base(path), ".md"), Path: path}
	fi, err := os.Stat(path)
	if err != nil {
		j.Err = err
		return j
	}
	j.ModTime = fi.ModTime()
	if fi.Size() > maxJobBytes {
		j.Err = fmt.Errorf("larger than %d bytes", maxJobBytes)
		return j
	}
	data, err := os.ReadFile(path)
	if err != nil {
		j.Err = err
		return j
	}
	parsed, err := Parse(data, j.ModTime)
	parsed.Name, parsed.Path, parsed.ModTime = j.Name, j.Path, j.ModTime
	if err == nil {
		err = ValidName(j.Name)
	}
	parsed.Err = err
	return parsed
}

// Parse reads a job from its file contents and checks it. now anchors
// "in ..." schedules.
func Parse(data []byte, now time.Time) (Job, error) {
	data = bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	front, body, err := split(data)
	if err != nil {
		return Job{}, err
	}
	var j Job
	dec := yaml.NewDecoder(bytes.NewReader(front))
	dec.KnownFields(true)
	if err := dec.Decode(&j); err != nil && !errors.Is(err, io.EOF) {
		return Job{}, fmt.Errorf("frontmatter: %w", err)
	}
	j.Prompt = strings.TrimSpace(string(body))
	return j, j.check(now)
}

// split separates the frontmatter from the body. Jobs need frontmatter
// (the schedule lives there).
func split(data []byte) (front, body []byte, err error) {
	rest, ok := bytes.CutPrefix(data, []byte("---\n"))
	if !ok {
		return nil, nil, errors.New("a job file starts with --- and YAML frontmatter holding at least schedule")
	}
	after, empty := bytes.CutPrefix(rest, []byte("---"))
	if !empty {
		var found bool
		if front, after, found = bytes.Cut(rest, []byte("\n---")); !found {
			return nil, nil, errors.New("frontmatter starts with --- but never ends")
		}
	}
	if i := bytes.IndexByte(after, '\n'); i >= 0 {
		body = after[i+1:] // drop the rest of the closing --- line
	}
	return front, body, nil
}

func (j *Job) check(now time.Time) error {
	j.Loc = time.Local
	if j.Timezone != "" {
		loc, err := time.LoadLocation(j.Timezone)
		if err != nil {
			return fmt.Errorf("timezone %q: %v", j.Timezone, err)
		}
		j.Loc = loc
	}
	if strings.TrimSpace(j.Schedule) == "" {
		return errors.New("schedule is required")
	}
	s, err := ParseSchedule(j.Schedule, now, j.Loc)
	if err != nil {
		return fmt.Errorf("schedule: %w", err)
	}
	j.Sched = s
	if j.Prompt == "" {
		return errors.New("the prompt (the file's body after the frontmatter) is empty")
	}
	switch j.Ask {
	case "":
		j.Ask = AskDeny
	case AskDeny, AskWait:
	default:
		return fmt.Errorf("ask %q: want deny or wait", j.Ask)
	}
	if j.KeepRuns < 0 {
		return errors.New("keep_runs must not be negative")
	}
	if (j.Model.Provider == "") != (j.Model.Model == "") {
		return errors.New("model: set both provider and model")
	}
	if j.Model.Provider == "" && j.Model.Effort != "" {
		return errors.New("model: effort needs a provider and model")
	}
	if j.Dir != "" {
		dir, err := ExpandDir(j.Dir)
		if err != nil {
			return err
		}
		j.Dir = dir
	}
	return nil
}

// ExpandDir resolves ~ and checks the directory is absolute.
func ExpandDir(dir string) (string, error) {
	if dir == "~" || strings.HasPrefix(dir, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("dir %q: %v", dir, err)
		}
		dir = filepath.Join(home, strings.TrimPrefix(dir, "~"))
	}
	if !filepath.IsAbs(dir) {
		return "", fmt.Errorf("dir %q must be an absolute path (or start with ~/)", dir)
	}
	return filepath.Clean(dir), nil
}

// Spec is what a job file says, for writing one.
type Spec struct {
	Schedule   string
	Project    string
	Dir        string
	Role       string
	Model      config.TaskModel
	Enabled    *bool
	Ask        string
	AskTimeout string
	Yolo       bool
	Timezone   string
	CatchUp    string
	KeepRuns   int
	Prompt     string
}

// Format renders a job file.
func Format(s Spec) []byte {
	var b strings.Builder
	b.WriteString("---\n")
	kv := func(k, v string) {
		if v != "" {
			fmt.Fprintf(&b, "%s: %s\n", k, yamlString(v))
		}
	}
	kv("schedule", s.Schedule)
	kv("project", s.Project)
	kv("dir", s.Dir)
	kv("role", s.Role)
	if s.Model.Provider != "" {
		fmt.Fprintf(&b, "model: {provider: %s, model: %s", yamlString(s.Model.Provider), yamlString(s.Model.Model))
		if s.Model.Effort != "" {
			fmt.Fprintf(&b, ", effort: %s", yamlString(s.Model.Effort))
		}
		b.WriteString("}\n")
	}
	if s.Enabled != nil {
		fmt.Fprintf(&b, "enabled: %t\n", *s.Enabled)
	}
	kv("ask", s.Ask)
	kv("ask_timeout", s.AskTimeout)
	if s.Yolo {
		b.WriteString("yolo: true\n")
	}
	kv("timezone", s.Timezone)
	kv("catch_up", s.CatchUp)
	if s.KeepRuns > 0 {
		fmt.Fprintf(&b, "keep_runs: %d\n", s.KeepRuns)
	}
	b.WriteString("---\n")
	b.WriteString(strings.TrimSpace(s.Prompt))
	b.WriteString("\n")
	return []byte(b.String())
}

// SpecOf is the Spec that writes j back as it is.
func SpecOf(j Job) Spec {
	s := Spec{
		Schedule: j.Schedule, Project: j.Project, Dir: j.Dir, Role: j.Role, Model: j.Model, Enabled: j.Enabled,
		Yolo: j.Yolo, Timezone: j.Timezone, KeepRuns: j.KeepRuns, Prompt: j.Prompt,
	}
	if j.Ask != AskDeny {
		s.Ask = j.Ask
	}
	if j.AskTimeout != nil {
		s.AskTimeout = time.Duration(*j.AskTimeout).String()
	}
	if j.CatchUp != nil {
		s.CatchUp = time.Duration(*j.CatchUp).String()
	}
	return s
}

// yamlString quotes v when YAML would read it as something else.
func yamlString(v string) string {
	var probe any
	if err := yaml.Unmarshal([]byte("v: "+v), &probe); err == nil {
		if m, ok := probe.(map[string]any); ok {
			if s, ok := m["v"].(string); ok && s == v && !strings.ContainsAny(v, "#{}[],&*!|>'\"%@`") {
				return v
			}
		}
	}
	out, _ := yaml.Marshal(v)
	return strings.TrimSpace(string(out))
}

// Write creates or replaces the job file name in dir, atomically.
func Write(dir, name string, data []byte) (string, error) {
	if err := ValidName(name); err != nil {
		return "", err
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return "", err
	}
	path := filepath.Join(dir, name+".md")
	tmp, err := os.CreateTemp(dir, ".tmp-"+name+"-*")
	if err != nil {
		return "", err
	}
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return "", err
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmp.Name())
		return "", err
	}
	if err := os.Rename(tmp.Name(), path); err != nil {
		os.Remove(tmp.Name())
		return "", err
	}
	return path, nil
}

// enabledLine is a top-level enabled: line in frontmatter.
var enabledLine = regexp.MustCompile(`(?m)^enabled:[^\n]*$`)

// SetEnabled rewrites the enabled: line of the job file at path, keeping
// the rest of the file (comments included) as it is.
func SetEnabled(path string, enabled bool) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	data = bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	front, _, err := split(data)
	if err != nil {
		return err
	}
	line := fmt.Sprintf("enabled: %t", enabled)
	var newFront []byte
	if enabledLine.Match(front) {
		newFront = enabledLine.ReplaceAll(front, []byte(line))
	} else if len(front) == 0 {
		newFront = []byte(line + "\n")
	} else {
		newFront = append(append(append([]byte{}, front...), '\n'), line...)
	}
	out := append([]byte("---\n"), newFront...)
	out = append(out, data[len("---\n")+len(front):]...)
	_, err = Write(filepath.Dir(path), strings.TrimSuffix(filepath.Base(path), ".md"), out)
	return err
}

// scheduleLine is a top-level schedule: line in frontmatter.
var scheduleLine = regexp.MustCompile(`(?m)^schedule:[^\n]*$`)

// FinishOneShot disables the one-shot job file at path once it has run. An
// "in ..." schedule is rewritten as the time it ran for, since it counts
// from the file's last change, which this is.
func FinishOneShot(path string, at time.Time) error {
	if err := SetEnabled(path, false); err != nil {
		return err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	front, _, err := split(bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n")))
	if err != nil {
		return err
	}
	line := scheduleLine.Find(front)
	value := strings.TrimSpace(strings.TrimPrefix(string(line), "schedule:"))
	if !strings.HasPrefix(strings.ToLower(strings.Trim(value, `"'`)), "in ") {
		return nil
	}
	layout := "2006-01-02 15:04"
	if at.Second() != 0 {
		layout += ":05"
	}
	pinned := []byte("schedule: at " + at.Format(layout))
	out := append([]byte("---\n"), scheduleLine.ReplaceAll(front, pinned)...)
	out = append(out, bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))[len("---\n")+len(front):]...)
	_, err = Write(filepath.Dir(path), strings.TrimSuffix(filepath.Base(path), ".md"), out)
	return err
}

// Remove deletes the job file name from dir.
func Remove(dir, name string) error {
	if err := ValidName(name); err != nil {
		return err
	}
	return os.Remove(filepath.Join(dir, name+".md"))
}
