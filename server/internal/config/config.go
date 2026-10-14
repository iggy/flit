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
	"os"
	"path/filepath"
	"strings"

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
		Listen: DefaultListen,
		Log:    Log{Level: "info"},
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
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
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
