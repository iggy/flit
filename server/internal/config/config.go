// Package config loads flit's YAML config file and watches it for changes.
//
// flit is configured with YAML only. Changes to the file are applied while the
// server runs; see Watch.
package config

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"go.yaml.in/yaml/v3"
)

// DefaultListen is the address flit serves on when the config sets none.
const DefaultListen = "127.0.0.1:7433"

// Config is the contents of config.yaml.
type Config struct {
	// Listen is the host:port the API server binds to.
	Listen string `yaml:"listen"`
	// DataDir holds flit's SQLite databases and flat files. Empty means the
	// platform default. Read at startup only: changing it while flit runs is
	// logged and ignored until the next start.
	DataDir string `yaml:"data_dir"`
	TLS     TLS    `yaml:"tls"`
	Log     Log    `yaml:"log"`
	// PublicURL is how clients reach this server, e.g.
	// https://flit.example.com or http://192.168.1.20:7433. "flit pair" puts
	// it in the QR code. Empty means a best guess from Listen.
	PublicURL string `yaml:"public_url"`
	// Providers are the OpenAI-compatible endpoints flit can use.
	Providers []Provider `yaml:"providers"`
	Agent     Agent      `yaml:"agent"`
	Shell     Shell      `yaml:"shell"`
	// ModelOverridesFile is a YAML file that corrects or fills in what
	// model discovery finds (context length, tool and reasoning support,
	// effort levels). Relative paths are relative to the config file.
	ModelOverridesFile string `yaml:"model_overrides_file"`
	// RolesDir holds role files (*.md with YAML frontmatter). Relative
	// paths are relative to the config file.
	RolesDir string `yaml:"roles_dir"`
	// MCPServers are MCP servers (stdio or HTTP). Configured here, never in an
	// mcp.json.
	MCPServers []MCPServer `yaml:"mcp_servers"`
	// SkillsDirs hold skills in the Agent Skills format (one directory per
	// skill with a SKILL.md). Relative paths are relative to the config
	// file.
	SkillsDirs []string `yaml:"skills_dirs"`
	Web        Web      `yaml:"web"`
	Git        Git      `yaml:"git"`
}

// MCPServer returns the MCP server named name.
func (c Config) MCPServer(name string) (MCPServer, bool) {
	for _, m := range c.MCPServers {
		if m.Name == name {
			return m, true
		}
	}
	return MCPServer{}, false
}

// ChatModel is the default model for new sessions: tasks.chat if set,
// else the agent defaults.
func (c Config) ChatModel() TaskModel {
	if t, ok := c.Agent.Tasks["chat"]; ok && t.Provider != "" {
		return t
	}
	return TaskModel{Provider: c.Agent.Provider, Model: c.Agent.Model, Effort: c.Agent.Effort}
}

// Provider is an OpenAI-compatible chat completions endpoint.
type Provider struct {
	// Name identifies the provider in sessions and the API.
	Name string `yaml:"name"`
	// BaseURL is the API root, e.g. https://api.openai.com/v1 or
	// http://localhost:8080/v1 for llama.cpp.
	BaseURL string `yaml:"base_url"`
	// APIKey is the key itself; APIKeyEnv names an environment variable
	// holding it. Set at most one. Neither means no Authorization header.
	APIKey    string `yaml:"api_key"`
	APIKeyEnv string `yaml:"api_key_env"`
	// Kind says how to read the provider's /models response: auto (the
	// default: guess from the URL and the response), openai, openrouter,
	// llamacpp or gomodel.
	Kind string `yaml:"kind"`
	// PromptAppend is added to the system prompt for every model on this
	// provider.
	PromptAppend string `yaml:"prompt_append"`
}

// MCPServer is an MCP server: either a subprocess flit starts and talks to
// over stdio (Command), or a remote one it reaches over HTTP (URL).
// Exactly one of the two is set.
type MCPServer struct {
	Name    string            `yaml:"name"`
	Command string            `yaml:"command"`
	Args    []string          `yaml:"args"`
	Env     map[string]string `yaml:"env"`
	// Dir is the working directory for the process; empty means flit's.
	Dir string `yaml:"dir"`
	// URL is a remote server's endpoint, spoken to with the streamable
	// HTTP transport, or legacy SSE if the server only speaks that.
	URL string `yaml:"url"`
	// Headers are sent with every HTTP request (e.g. Authorization).
	// ${VAR} in a value is replaced with that environment variable when
	// connecting; an unset one fails the server.
	Headers map[string]string `yaml:"headers"`
	// Enabled is whether new sessions start with it on. Default true.
	Enabled *bool `yaml:"enabled"`
}

// EnabledByDefault reports whether new sessions get this server.
func (m MCPServer) EnabledByDefault() bool { return m.Enabled == nil || *m.Enabled }

// Web configures the web tools.
type Web struct {
	// Fetch enables the web_fetch tool. Default true.
	Fetch *bool `yaml:"fetch"`
	// Search configures web_search; without a provider there is no search
	// tool.
	Search WebSearch `yaml:"search"`
}

// FetchEnabled reports whether web_fetch is offered.
func (w Web) FetchEnabled() bool { return w.Fetch == nil || *w.Fetch }

// WebSearch configures the web_search tool.
type WebSearch struct {
	// Provider is "searxng" (free, self-hostable) or empty for none.
	Provider string `yaml:"provider"`
	// URL is the SearXNG instance, e.g. http://localhost:8888. Its JSON
	// output format must be enabled.
	URL string `yaml:"url"`
}

// Git configures the git tools.
type Git struct {
	// Enabled offers git_status, git_diff, git_log and git_commit. Default
	// true. Nothing ever pushes.
	Enabled *bool `yaml:"enabled"`
}

// IsEnabled reports whether the git tools are offered.
func (g Git) IsEnabled() bool { return g.Enabled == nil || *g.Enabled }

// ProviderKinds are the accepted Provider.Kind values.
var ProviderKinds = []string{"auto", "openai", "openrouter", "llamacpp", "gomodel"}

// Tasks are the kinds of work that can have their own model.
var Tasks = []string{"chat", "planning", "cron", "compaction", "search", "permission"}

// TaskModel picks a model for one kind of work.
type TaskModel struct {
	Provider string `yaml:"provider"`
	Model    string `yaml:"model"`
	// Effort is the reasoning effort, e.g. low, medium or high; empty means
	// the model's default. "off" turns thinking off on llama.cpp
	// (chat_template_kwargs enable_thinking=false) and is ignored by other
	// providers.
	Effort string `yaml:"effort"`
}

// Task returns the model configured for task, if it names a provider and
// model.
func (c Config) Task(task string) (TaskModel, bool) {
	t, ok := c.Agent.Tasks[task]
	return t, ok && t.Provider != "" && t.Model != ""
}

// Key returns the provider's API key, if any.
func (p Provider) Key() string {
	if p.APIKeyEnv != "" {
		return os.Getenv(p.APIKeyEnv)
	}
	return p.APIKey
}

// Agent configures the agent loop.
type Agent struct {
	// Provider, Model and Effort are used by sessions that don't pick
	// their own (or get one from their role). tasks.chat, if set, wins.
	Provider string `yaml:"provider"`
	Model    string `yaml:"model"`
	Effort   string `yaml:"effort"`
	// Tasks sets a model per kind of work (see Tasks). chat is the
	// sessions' default model and permission rates shell commands before
	// flit asks the user (see docs/shell.md); planning, cron, compaction
	// and search are for those features as they arrive.
	Tasks map[string]TaskModel `yaml:"tasks"`
	// ModelPromptAppends adds text to the system prompt for specific
	// models, keyed "provider/model".
	ModelPromptAppends map[string]string `yaml:"model_prompt_appends"`
	// MaxSteps caps model calls per turn.
	MaxSteps int `yaml:"max_steps"`
	// Tool output longer than this is cut down to its head and tail before
	// the model sees it.
	ToolOutputMaxBytes int `yaml:"tool_output_max_bytes"`
	ToolOutputMaxLines int `yaml:"tool_output_max_lines"`
}

// Shell configures the shell tool.
type Shell struct {
	// Timeout applies when the model doesn't ask for one; MaxTimeout caps
	// what it may ask for.
	Timeout    time.Duration `yaml:"timeout"`
	MaxTimeout time.Duration `yaml:"max_timeout"`
	// Allow and Deny are command patterns; "*" matches any run of
	// characters. Commands are split into their parts (chains, pipes,
	// loops); a command runs without asking when every part is allowed.
	// Deny is checked against the whole command and every part, and wins
	// over everything, yolo mode included.
	Allow []string `yaml:"allow"`
	Deny  []string `yaml:"deny"`
	// ReadOnly allows flit's built-in list of read-only commands (ls, cat,
	// grep, git status, ...; see docs/shell.md). Default true.
	ReadOnly *bool `yaml:"read_only"`
	// Default is what happens to commands nothing allows: "ask" (prompt
	// the user), "allow" or "deny".
	Default string `yaml:"default"`
	// Yolo is whether new sessions start in yolo mode, where every command
	// runs unless a deny rule matches. Sessions can turn it on or off.
	Yolo bool `yaml:"yolo"`
}

// ReadOnlyEnabled reports whether the built-in read-only list applies.
func (s Shell) ReadOnlyEnabled() bool { return s.ReadOnly == nil || *s.ReadOnly }

// Provider returns the provider named name.
func (c Config) Provider(name string) (Provider, bool) {
	for _, p := range c.Providers {
		if p.Name == name {
			return p, true
		}
	}
	return Provider{}, false
}

// TLS enables HTTPS when both files are set. Both empty means plain HTTP.
type TLS struct {
	CertFile string `yaml:"cert_file"`
	KeyFile  string `yaml:"key_file"`
}

// Enabled reports whether TLS is configured.
func (t TLS) Enabled() bool { return t.CertFile != "" || t.KeyFile != "" }

// Log configures logging.
type Log struct {
	// Level is one of debug, info, warn, error.
	Level string `yaml:"level"`
}

// SlogLevel returns Level as a slog.Level. Call only on a validated Config.
func (l Log) SlogLevel() slog.Level {
	var lvl slog.Level
	_ = lvl.UnmarshalText([]byte(l.Level))
	return lvl
}

// Default returns the config used when the file sets nothing.
func Default() Config {
	return Config{
		Listen:             DefaultListen,
		Log:                Log{Level: "info"},
		Providers:          []Provider{},
		ModelOverridesFile: "models.yaml",
		RolesDir:           "roles",
		MCPServers:         []MCPServer{},
		SkillsDirs:         []string{"skills"},
		Web:                Web{Fetch: ptr(true)},
		Git:                Git{Enabled: ptr(true)},
		Agent: Agent{
			Tasks:              map[string]TaskModel{},
			ModelPromptAppends: map[string]string{},
			MaxSteps:           50,
			ToolOutputMaxBytes: 32 * 1024,
			ToolOutputMaxLines: 500,
		},
		Shell: Shell{
			Timeout:    2 * time.Minute,
			MaxTimeout: 30 * time.Minute,
			Allow:      []string{},
			Deny:       []string{},
			ReadOnly:   ptr(true),
			Default:    "ask",
		},
	}
}

// Parse decodes YAML config, applies defaults and validates the result.
// Unknown keys are an error, so typos don't silently fall back to defaults.
func Parse(data []byte) (Config, error) {
	cfg := Default()
	dec := yaml.NewDecoder(bytes.NewReader(data))
	dec.KnownFields(true)
	if err := dec.Decode(&cfg); err != nil && !errors.Is(err, io.EOF) {
		return Config{}, fmt.Errorf("parse config: %w", err)
	}
	if cfg.Listen == "" {
		cfg.Listen = DefaultListen
	}
	if cfg.Log.Level == "" {
		cfg.Log.Level = "info"
	}
	cfg.fillDefaults()
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

// fillDefaults replaces zero values that YAML may have set explicitly.
func (c *Config) fillDefaults() {
	d := Default()
	if c.Agent.MaxSteps == 0 {
		c.Agent.MaxSteps = d.Agent.MaxSteps
	}
	if c.Agent.ToolOutputMaxBytes == 0 {
		c.Agent.ToolOutputMaxBytes = d.Agent.ToolOutputMaxBytes
	}
	if c.Agent.ToolOutputMaxLines == 0 {
		c.Agent.ToolOutputMaxLines = d.Agent.ToolOutputMaxLines
	}
	if c.Shell.Timeout == 0 {
		c.Shell.Timeout = d.Shell.Timeout
	}
	if c.Shell.MaxTimeout == 0 {
		c.Shell.MaxTimeout = d.Shell.MaxTimeout
	}
	if c.Shell.Default == "" {
		c.Shell.Default = d.Shell.Default
	}
	if c.ModelOverridesFile == "" {
		c.ModelOverridesFile = d.ModelOverridesFile
	}
	if c.RolesDir == "" {
		c.RolesDir = d.RolesDir
	}
}

// Load reads and parses the config file at path.
func Load(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}
	cfg, err := Parse(data)
	if err != nil {
		return Config{}, fmt.Errorf("%s: %w", path, err)
	}
	return cfg, nil
}

// Validate reports the first problem with c, if any.
func (c Config) Validate() error {
	if _, _, err := net.SplitHostPort(c.Listen); err != nil {
		return fmt.Errorf("listen %q: %w", c.Listen, err)
	}
	if c.TLS.Enabled() && (c.TLS.CertFile == "" || c.TLS.KeyFile == "") {
		return errors.New("tls: cert_file and key_file must both be set")
	}
	var lvl slog.Level
	if err := lvl.UnmarshalText([]byte(c.Log.Level)); err != nil {
		return fmt.Errorf("log.level %q: want debug, info, warn or error", c.Log.Level)
	}
	if c.PublicURL != "" {
		u, err := url.Parse(c.PublicURL)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("public_url %q must be an http(s) URL", c.PublicURL)
		}
	}
	seen := map[string]bool{}
	for i, p := range c.Providers {
		if p.Name == "" {
			return fmt.Errorf("providers[%d]: name is required", i)
		}
		if seen[p.Name] {
			return fmt.Errorf("providers: duplicate name %q", p.Name)
		}
		seen[p.Name] = true
		u, err := url.Parse(p.BaseURL)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("providers %q: base_url %q must be an http(s) URL", p.Name, p.BaseURL)
		}
		if p.APIKey != "" && p.APIKeyEnv != "" {
			return fmt.Errorf("providers %q: set api_key or api_key_env, not both", p.Name)
		}
		if p.Kind != "" && !slices.Contains(ProviderKinds, p.Kind) {
			return fmt.Errorf("providers %q: kind %q: want one of %s", p.Name, p.Kind, strings.Join(ProviderKinds, ", "))
		}
	}
	if c.Agent.Provider != "" && !seen[c.Agent.Provider] {
		return fmt.Errorf("agent.provider %q is not in providers", c.Agent.Provider)
	}
	mcpSeen := map[string]bool{}
	for i, m := range c.MCPServers {
		switch {
		case m.Name == "":
			return fmt.Errorf("mcp_servers[%d]: name is required", i)
		case !validToolPart(m.Name):
			return fmt.Errorf("mcp_servers %q: name may only use letters, digits, - and _", m.Name)
		case mcpSeen[m.Name]:
			return fmt.Errorf("mcp_servers: duplicate name %q", m.Name)
		case (m.Command == "") == (m.URL == ""):
			return fmt.Errorf("mcp_servers %q: set exactly one of command and url", m.Name)
		case m.URL != "" && (len(m.Args) > 0 || len(m.Env) > 0 || m.Dir != ""):
			return fmt.Errorf("mcp_servers %q: args, env and dir only apply to command servers", m.Name)
		case m.Command != "" && len(m.Headers) > 0:
			return fmt.Errorf("mcp_servers %q: headers only apply to url servers", m.Name)
		}
		if m.URL != "" {
			if u, err := url.Parse(m.URL); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
				return fmt.Errorf("mcp_servers %q: url must be an http(s) URL", m.Name)
			}
		}
		mcpSeen[m.Name] = true
	}
	switch c.Web.Search.Provider {
	case "":
	case "searxng":
		if u, err := url.Parse(c.Web.Search.URL); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("web.search.url %q must be an http(s) URL", c.Web.Search.URL)
		}
	default:
		return fmt.Errorf("web.search.provider %q: only searxng is supported", c.Web.Search.Provider)
	}
	for task, t := range c.Agent.Tasks {
		if !slices.Contains(Tasks, task) {
			return fmt.Errorf("agent.tasks: unknown task %q: want one of %s", task, strings.Join(Tasks, ", "))
		}
		if t.Provider != "" && !seen[t.Provider] {
			return fmt.Errorf("agent.tasks.%s.provider %q is not in providers", task, t.Provider)
		}
	}
	if c.Agent.MaxSteps < 0 || c.Agent.ToolOutputMaxBytes < 0 || c.Agent.ToolOutputMaxLines < 0 {
		return errors.New("agent: limits must not be negative")
	}
	if c.Shell.Timeout < 0 || c.Shell.MaxTimeout < c.Shell.Timeout {
		return errors.New("shell: need 0 <= timeout <= max_timeout")
	}
	switch c.Shell.Default {
	case "ask", "allow", "deny":
	default:
		return fmt.Errorf("shell.default %q: want ask, allow or deny", c.Shell.Default)
	}
	for _, pat := range append(append([]string{}, c.Shell.Allow...), c.Shell.Deny...) {
		if strings.TrimSpace(pat) == "" {
			return errors.New("shell: empty pattern in allow/deny")
		}
	}
	return nil
}

// defaultFile is written on first run so the available settings are
// discoverable.
const defaultFile = `# flit server configuration.
#
# Changes to this file are applied while flit runs; no restart needed.

# Address the API server listens on. Every API call requires the auth token
# (see "flit token"), even from localhost.
listen: ` + DefaultListen + `

# How phones and other machines reach this server, e.g.
# http://192.168.1.20:7433 or https://flit.example.com. "flit pair" puts it in
# the QR code. Empty means a guess based on listen. To pair a phone, listen on
# an address it can reach (e.g. 0.0.0.0:7433) and preferably use TLS.
public_url: ""

# Where flit keeps its databases and files. Empty means the platform default.
# Read at startup only.
data_dir: ""

# Serve HTTPS instead of HTTP. Set both, or leave both empty.
tls:
  cert_file: ""
  key_file: ""

log:
  # debug, info, warn or error.
  level: info

# OpenAI-compatible endpoints. Several can be configured at once. Models are
# discovered from each one's /models endpoint; kind says how to read it
# (auto, openai, openrouter, llamacpp, gomodel).
providers: []
#  - name: local
#    base_url: http://localhost:8080/v1   # e.g. llama.cpp's llama-server
#  - name: openrouter
#    base_url: https://openrouter.ai/api/v1
#    api_key_env: OPENROUTER_API_KEY      # or api_key: sk-...

# Corrections and additions to discovered models (context length, tools,
# reasoning, effort levels), relative to this file.
model_overrides_file: models.yaml

# Role files (*.md with YAML frontmatter), relative to this file.
roles_dir: roles

# Skills in the Agent Skills format (a directory per skill with SKILL.md),
# relative to this file. The agent sees names and descriptions and loads a
# skill when it needs it.
skills_dirs: [skills]

# MCP servers, connected on demand. Each has either a command (started as a
# subprocess, spoken to over stdio) or a url (a remote server, spoken to with
# streamable HTTP, or legacy SSE if that's all it speaks). Sessions can turn
# each one on or off; enabled says whether new sessions start with it on.
mcp_servers: []
#  - name: fetch
#    command: uvx
#    args: [mcp-server-fetch]
#    env: {}
#    enabled: true
#  - name: docs
#    url: https://example.com/mcp
#    headers:                            # ${VAR} is read from the environment
#      Authorization: Bearer ${DOCS_MCP_TOKEN}
#    enabled: true

web:
  # web_fetch: read a web page as text.
  fetch: true
  # web_search needs a search provider. Only SearXNG (free, self-hosted,
  # with its JSON format enabled) is supported.
  search:
    provider: ""
    url: ""

git:
  # git_status, git_diff, git_log and git_commit on the session's repo.
  # Nothing pushes.
  enabled: true

agent:
  # Defaults for sessions that don't choose their own (or get one from
  # their role).
  provider: ""
  model: ""
  # Reasoning effort: low, medium, high (or a level the model names), or
  # off to turn thinking off on llama.cpp. Empty means the model's default.
  effort: ""
  # A model per kind of work: chat, permission, planning, cron, compaction,
  # search. chat overrides the defaults above. permission rates shell
  # commands (safe, ask or block) before flit asks you; without it, flit
  # just asks. planning, cron, compaction and search aren't used yet.
  tasks: {}
  #   chat:       {provider: local, model: qwen3-coder, effort: medium}
  #   permission: {provider: local, model: qwen3-4b, effort: off}
  # Extra system prompt text for specific models ("provider/model"); a
  # provider's prompt_append applies to all its models.
  model_prompt_appends: {}
  # Maximum model calls in one turn.
  max_steps: 50
  # Longer tool output is cut to its head and tail before the model sees it.
  tool_output_max_bytes: 32768
  tool_output_max_lines: 500

shell:
  timeout: 2m
  max_timeout: 30m
  # Commands are split into their parts (cd x && ls | head is three); a
  # command runs without asking when every part is allowed. Redirecting
  # output to a file, $(...) and backticks always ask.
  #
  # Command patterns; "*" matches anything, e.g. "go test*". deny is
  # checked against every part and wins over everything, yolo included.
  allow: []
  deny: []
  # Allow flit's built-in read-only commands: cd, ls, cat, head, tail, wc,
  # grep, rg, find (without -exec/-delete), git status/log/diff/show/branch
  # and more (see docs/shell.md).
  read_only: true
  # For commands nothing allows: ask, allow or deny.
  default: ask
  # Start new sessions in yolo mode: run everything except deny matches.
  # Each session can turn it on or off in the app.
  yolo: false
`

// EnsureFile writes the default config to path if no file exists there.
// It reports whether it created the file.
func EnsureFile(path string) (bool, error) {
	if _, err := os.Stat(path); err == nil {
		return false, nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return false, err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return false, err
	}
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if errors.Is(err, os.ErrExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if _, err := f.WriteString(strings.TrimLeft(defaultFile, "\n")); err != nil {
		f.Close()
		return false, err
	}
	return true, f.Close()
}

// validToolPart reports whether s can be part of a tool name sent to the
// model (letters, digits, - and _).
func validToolPart(s string) bool {
	for _, r := range s {
		if !(r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9' || r == '-' || r == '_') {
			return false
		}
	}
	return s != ""
}

func ptr[T any](v T) *T { return &v }
