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
	// Provider and Model are used by sessions that don't pick their own.
	Provider string `yaml:"provider"`
	Model    string `yaml:"model"`
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
	// characters. Deny wins over Allow. A command with shell operators
	// (; & | < > ` $( and newlines) never matches Allow.
	Allow []string `yaml:"allow"`
	Deny  []string `yaml:"deny"`
	// Default is what happens to commands neither list matches: "ask"
	// (prompt the user), "allow" or "deny".
	Default string `yaml:"default"`
}

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
		Listen:    DefaultListen,
		Log:       Log{Level: "info"},
		Providers: []Provider{},
		Agent: Agent{
			MaxSteps:           50,
			ToolOutputMaxBytes: 32 * 1024,
			ToolOutputMaxLines: 500,
		},
		Shell: Shell{
			Timeout:    2 * time.Minute,
			MaxTimeout: 30 * time.Minute,
			Allow:      []string{"ls*", "pwd", "git status*", "git diff*", "git log*"},
			Deny:       []string{},
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
	}
	if c.Agent.Provider != "" && !seen[c.Agent.Provider] {
		return fmt.Errorf("agent.provider %q is not in providers", c.Agent.Provider)
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

# OpenAI-compatible endpoints. Several can be configured at once.
providers: []
#  - name: local
#    base_url: http://localhost:8080/v1   # e.g. llama.cpp's llama-server
#  - name: openai
#    base_url: https://api.openai.com/v1
#    api_key_env: OPENAI_API_KEY          # or api_key: sk-...

agent:
  # Defaults for sessions that don't choose their own.
  provider: ""
  model: ""
  # Maximum model calls in one turn.
  max_steps: 50
  # Longer tool output is cut to its head and tail before the model sees it.
  tool_output_max_bytes: 32768
  tool_output_max_lines: 500

shell:
  timeout: 2m
  max_timeout: 30m
  # Command patterns; "*" matches anything. deny wins over allow, and a
  # command using shell operators (; & | < > $( backticks) is never
  # auto-allowed.
  allow:
    - "ls*"
    - "pwd"
    - "git status*"
    - "git diff*"
    - "git log*"
  deny: []
  # For commands matching neither list: ask, allow or deny.
  default: ask
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
