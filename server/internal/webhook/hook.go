// Package webhook reads webhook files and makes sense of deliveries.
//
// A hook is a Markdown file in the webhooks directory: YAML frontmatter, and
// a body that is the prompt. The file name without .md is the hook's name,
// and deliveries for it arrive at <public_url>/webhooks/<name>.
//
//	---
//	source: github                 # required; github is the only one so far
//	secret: ${FLIT_GITHUB_SECRET}  # required; ${VAR} is read from the environment
//	events: [pull_request.opened, pull_request.ready_for_review, issues]
//	repos: [iggy/flit]             # default any
//	ignore_senders: ["*[bot]"]     # default none
//	project: flit                  # name or id; default Scratch
//	dir: ~/projects/flit           # default the project's directory
//	role: reviewer
//	model: {provider: local, model: qwen3-coder}
//	enabled: true
//	ask: deny                      # or wait
//	ask_timeout: 1h
//	yolo: false
//	concurrency: 1                 # runs of this hook at once; more queue
//	keep_runs: 50
//	---
//	Check the pull request: does it build, are there tests, is it ready?
//
// Unknown keys are errors. Files are read on each delivery, so edits apply
// at once.
package webhook

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
	"github.com/iggy/flit/server/internal/cron"
)

// maxHookBytes caps a hook file.
const maxHookBytes = 256 << 10

// Defaults for optional settings.
const (
	DefaultAskTimeout  = time.Hour
	DefaultKeepRuns    = 50
	DefaultConcurrency = 1
)

// Sources a hook can take deliveries from.
const (
	SourceGitHub = "github"
)

// Hook is one webhook file.
type Hook struct {
	// Name is the file name without .md.
	Name string `yaml:"-"`
	// Path is the file.
	Path string `yaml:"-"`

	// Source says who sends the deliveries and how they are signed.
	Source string `yaml:"source"`
	// Secret checks the deliveries' signatures; ${VAR} is expanded.
	Secret string `yaml:"secret"`
	// Events are what start a run: "pull_request" (any action),
	// "pull_request.opened" (one action), or "*" (everything).
	Events []string `yaml:"events"`
	// Repos limits runs to these repositories (owner/name); empty is any.
	Repos []string `yaml:"repos"`
	// IgnoreSenders are logins whose events never start a run; "*x"
	// matches logins ending in x.
	IgnoreSenders []string `yaml:"ignore_senders"`

	// Project is a project's name or id; empty means Scratch.
	Project string `yaml:"project"`
	// Dir is the working directory; empty means the project's.
	Dir     string           `yaml:"dir"`
	Role    string           `yaml:"role"`
	Model   config.TaskModel `yaml:"model"`
	Enabled *bool            `yaml:"enabled"`
	// Ask is cron.AskDeny (default) or cron.AskWait.
	Ask        string         `yaml:"ask"`
	AskTimeout *cron.Duration `yaml:"ask_timeout"`
	Yolo       bool           `yaml:"yolo"`
	// Concurrency is how many runs of the hook may go at once; deliveries
	// beyond it wait their turn.
	Concurrency int `yaml:"concurrency"`
	KeepRuns    int `yaml:"keep_runs"`

	// Prompt is the Markdown body.
	Prompt string `yaml:"-"`
	// Err is why the file can't be used; such a hook takes no deliveries.
	Err error `yaml:"-"`
}

// IsEnabled reports whether the hook takes deliveries.
func (h Hook) IsEnabled() bool { return h.Enabled == nil || *h.Enabled }

// AskWaitFor is how long a held prompt waits for an answer.
func (h Hook) AskWaitFor() time.Duration {
	if h.AskTimeout == nil {
		return DefaultAskTimeout
	}
	return time.Duration(*h.AskTimeout)
}

// Keep is how many runs' sessions stay in the session list.
func (h Hook) Keep() int {
	if h.KeepRuns <= 0 {
		return DefaultKeepRuns
	}
	return h.KeepRuns
}

// Slots is how many runs may go at once.
func (h Hook) Slots() int {
	if h.Concurrency <= 0 {
		return DefaultConcurrency
	}
	return h.Concurrency
}

// Wants reports whether event (with action, which may be empty) is one of
// the hook's events.
func (h Hook) Wants(event, action string) bool {
	for _, e := range h.Events {
		if e == "*" || e == event || (action != "" && e == event+"."+action) {
			return true
		}
	}
	return false
}

// WantsRepo reports whether repo (owner/name, may be empty) passes the
// repos filter.
func (h Hook) WantsRepo(repo string) bool {
	return len(h.Repos) == 0 || slices.ContainsFunc(h.Repos, func(r string) bool { return strings.EqualFold(r, repo) })
}

// Ignores reports whether events sent by login are ignored.
func (h Hook) Ignores(login string) bool {
	if login == "" {
		return false
	}
	login = strings.ToLower(login)
	for _, p := range h.IgnoreSenders {
		p = strings.ToLower(p)
		if suffix, ok := strings.CutPrefix(p, "*"); ok && strings.HasSuffix(login, suffix) || p == login {
			return true
		}
	}
	return false
}

// nameRe is what a hook name may be: it is a file name and a URL path
// segment.
var nameRe = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`)

// ValidName reports whether name can be a hook's name.
func ValidName(name string) error {
	if !nameRe.MatchString(name) || strings.HasSuffix(name, ".md") {
		return fmt.Errorf("hook name %q: use 1-64 letters, digits, '.', '-' or '_', starting with a letter or digit", name)
	}
	return nil
}

// List reads every *.md file in dir, sorted by name. A missing dir means no
// hooks. Files that can't be used are returned with Err set.
func List(dir string) ([]Hook, error) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var out []Hook
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		out = append(out, Load(filepath.Join(dir, e.Name())))
	}
	slices.SortFunc(out, func(a, b Hook) int { return strings.Compare(a.Name, b.Name) })
	return out, nil
}

// ErrNotFound is Get's error for a hook with no file.
var ErrNotFound = errors.New("no such webhook")

// Get reads hook name from dir. A name with no file is ErrNotFound;
// other problems are in the hook's Err.
func Get(dir, name string) (Hook, error) {
	if ValidName(name) != nil {
		return Hook{}, ErrNotFound
	}
	path := filepath.Join(dir, name+".md")
	if fi, err := os.Stat(path); errors.Is(err, os.ErrNotExist) || (err == nil && fi.IsDir()) {
		return Hook{}, ErrNotFound
	}
	return Load(path), nil
}

// Load reads one hook file. Problems are in the returned hook's Err.
func Load(path string) Hook {
	h := Hook{Name: strings.TrimSuffix(filepath.Base(path), ".md"), Path: path}
	fi, err := os.Stat(path)
	if err != nil {
		h.Err = err
		return h
	}
	if fi.Size() > maxHookBytes {
		h.Err = fmt.Errorf("larger than %d bytes", maxHookBytes)
		return h
	}
	data, err := os.ReadFile(path)
	if err != nil {
		h.Err = err
		return h
	}
	parsed, err := Parse(data)
	parsed.Name, parsed.Path = h.Name, h.Path
	if err == nil {
		err = ValidName(h.Name)
	}
	parsed.Err = err
	return parsed
}

// eventRe is an entry of events.
var eventRe = regexp.MustCompile(`^(\*|[a-z_]+(\.[a-z_]+)?)$`)

// Parse reads a hook from its file contents and checks it. ${VAR} in the
// secret is expanded from the environment.
func Parse(data []byte) (Hook, error) {
	data = bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n"))
	front, body, err := split(data)
	if err != nil {
		return Hook{}, err
	}
	var h Hook
	dec := yaml.NewDecoder(bytes.NewReader(front))
	dec.KnownFields(true)
	if err := dec.Decode(&h); err != nil && !errors.Is(err, io.EOF) {
		return Hook{}, fmt.Errorf("frontmatter: %w", err)
	}
	h.Prompt = strings.TrimSpace(string(body))
	return h, h.check()
}

// split separates the frontmatter from the body.
func split(data []byte) (front, body []byte, err error) {
	rest, ok := bytes.CutPrefix(data, []byte("---\n"))
	if !ok {
		return nil, nil, errors.New("a webhook file starts with --- and YAML frontmatter holding at least source, secret and events")
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

func (h *Hook) check() error {
	switch h.Source {
	case "":
		return errors.New("source is required (github)")
	case SourceGitHub:
	default:
		return fmt.Errorf("source %q: want github", h.Source)
	}
	if strings.TrimSpace(h.Secret) == "" {
		return errors.New("secret is required: the same secret you give the sender, or ${VAR} to read it from the environment")
	}
	secret, err := config.ExpandEnv(h.Secret)
	if err != nil {
		return fmt.Errorf("secret: %w", err)
	}
	h.Secret = secret
	if strings.TrimSpace(h.Secret) == "" {
		return errors.New("secret is empty once ${VAR} is expanded")
	}
	if len(h.Events) == 0 {
		return errors.New(`events is required, e.g. [pull_request.opened] or [issues, pull_request] ("*" is every event)`)
	}
	for _, e := range h.Events {
		if !eventRe.MatchString(e) {
			return fmt.Errorf("events: %q: want an event (pull_request), an event and action (pull_request.opened) or *", e)
		}
	}
	for _, r := range h.Repos {
		if owner, name, ok := strings.Cut(r, "/"); !ok || owner == "" || name == "" || strings.Contains(name, "/") {
			return fmt.Errorf("repos: %q: want owner/name", r)
		}
	}
	if h.Prompt == "" {
		return errors.New("the prompt (the file's body after the frontmatter) is empty")
	}
	switch h.Ask {
	case "":
		h.Ask = cron.AskDeny
	case cron.AskDeny, cron.AskWait:
	default:
		return fmt.Errorf("ask %q: want deny or wait", h.Ask)
	}
	if h.KeepRuns < 0 {
		return errors.New("keep_runs must not be negative")
	}
	if h.Concurrency < 0 {
		return errors.New("concurrency must not be negative")
	}
	if (h.Model.Provider == "") != (h.Model.Model == "") {
		return errors.New("model: set both provider and model")
	}
	if h.Model.Provider == "" && h.Model.Effort != "" {
		return errors.New("model: effort needs a provider and model")
	}
	if h.Dir != "" {
		dir, err := cron.ExpandDir(h.Dir)
		if err != nil {
			return err
		}
		h.Dir = dir
	}
	return nil
}
