// Package paths resolves flit's default config file and data directory.
package paths

import (
	"errors"
	"os"
	"path/filepath"
	"runtime"
)

const appName = "flit"

// ConfigFile returns the default config file path:
// $XDG_CONFIG_HOME/flit/config.yaml on Linux, the equivalent per-user config
// directory elsewhere (see os.UserConfigDir).
func ConfigFile() (string, error) {
	dir, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, appName, "config.yaml"), nil
}

// DataDir returns the default data directory, where flit keeps its SQLite
// databases and flat files:
//
//   - Linux and other Unix: $XDG_DATA_HOME/flit, else ~/.local/share/flit
//   - macOS: ~/Library/Application Support/flit
//   - Windows: %LocalAppData%\flit
func DataDir() (string, error) {
	switch runtime.GOOS {
	case "windows":
		if dir := os.Getenv("LocalAppData"); dir != "" {
			return filepath.Join(dir, appName), nil
		}
		return "", errors.New("%LocalAppData% is not set")
	case "darwin", "ios":
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		return filepath.Join(home, "Library", "Application Support", appName), nil
	default:
		if dir := os.Getenv("XDG_DATA_HOME"); filepath.IsAbs(dir) {
			return filepath.Join(dir, appName), nil
		}
		home, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		return filepath.Join(home, ".local", "share", appName), nil
	}
}
