// Command flit is the flit coding agent server.
//
// Usage:
//
//	flit serve [--config FILE] [--data-dir DIR]
//	flit token [--config FILE] [--data-dir DIR]
//	flit pair [--url URL] [--config FILE] [--data-dir DIR]
//	flit devices [--all] | flit devices revoke ID
//	flit debug session [ID]
//	flit version
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/signal"
	"path/filepath"
	"reflect"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/iggy/flit/server/internal/agent"
	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/devices"
	"github.com/iggy/flit/server/internal/mcpclient"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/paths"
	"github.com/iggy/flit/server/internal/server"
	"github.com/iggy/flit/server/internal/store"
)

const usage = `flit is an open source coding agent.

Usage:
  flit serve [flags]          run the API server
  flit token [flags]          print the admin API token
  flit pair [--url URL]       pair a phone or another machine (shows a QR code)
  flit devices [--all]        list paired devices
  flit devices revoke ID      revoke a paired device
  flit export [flags]         write recorded sessions as JSONL (see docs/export.md)
  flit debug session [ID]     print a session's timeline, to see where a turn got stuck
  flit version                print version information

Flags for serve, token, pair and devices:
  --config FILE    config file (default: %s)
  --data-dir DIR   data directory; overrides data_dir in the config
`

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := run(ctx, os.Args[1:], os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintln(os.Stderr, "flit:", err)
		}
		os.Exit(2)
	}
}

func run(ctx context.Context, args []string, stdout, stderr io.Writer) error {
	defaultConfig, err := paths.ConfigFile()
	if err != nil {
		return fmt.Errorf("find config dir: %w", err)
	}
	if len(args) == 0 {
		fmt.Fprintf(stderr, usage, defaultConfig)
		return flag.ErrHelp
	}

	switch cmd, args := args[0], args[1:]; cmd {
	case "serve", "token", "pair", "devices":
		fs := flag.NewFlagSet(cmd, flag.ContinueOnError)
		fs.SetOutput(stderr)
		configPath := fs.String("config", defaultConfig, "config file")
		dataDir := fs.String("data-dir", "", "data directory")
		pairURL := fs.String("url", "", "server URL to put in the pairing code (pair only)")
		all := fs.Bool("all", false, "include revoked devices (devices only)")
		if cmd == "devices" && len(args) > 0 && args[0] == "revoke" {
			if err := fs.Parse(args[1:]); err != nil {
				return err
			}
			if fs.NArg() != 1 {
				return errors.New("usage: flit devices revoke ID")
			}
			return revokeDevice(ctx, stdout, *configPath, *dataDir, fs.Arg(0))
		}
		if err := fs.Parse(args); err != nil {
			return err
		}
		switch cmd {
		case "token":
			return printToken(stdout, *configPath, *dataDir)
		case "pair":
			return pair(ctx, stdout, *configPath, *dataDir, *pairURL)
		case "devices":
			return listDevices(ctx, stdout, *configPath, *dataDir, *all)
		}
		return serve(ctx, stderr, *configPath, *dataDir)
	case "version":
		bi := buildinfo.Get()
		fmt.Fprintf(stdout, "flit %s (commit %s, built %s, %s, %s/%s, API %s)\n",
			bi.Version, orUnknown(bi.Commit), orUnknown(bi.BuildTime), bi.GoVersion, bi.OS, bi.Arch, buildinfo.APIVersion)
		return nil
	case "export":
		return exportCmd(ctx, stdout, stderr, args, defaultConfig)
	case "debug":
		return debugCmd(ctx, stdout, stderr, args, defaultConfig)
	case "help", "-h", "--help":
		fmt.Fprintf(stdout, usage, defaultConfig)
		return nil
	default:
		fmt.Fprintf(stderr, usage, defaultConfig)
		return fmt.Errorf("unknown command %q", cmd)
	}
}

func orUnknown(s string) string {
	if s == "" {
		return "unknown"
	}
	return s
}

// resolveDataDir picks the data dir: the --data-dir flag, else the config's
// data_dir, else the platform default.
func resolveDataDir(flagValue string, cfg config.Config) (string, error) {
	if flagValue != "" {
		return flagValue, nil
	}
	if cfg.DataDir != "" {
		return cfg.DataDir, nil
	}
	return paths.DataDir()
}

func loadConfig(path string) (config.Config, error) {
	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return config.Default(), nil
	}
	return config.Load(path)
}

func printToken(stdout io.Writer, configPath, dataDirFlag string) error {
	cfg, err := loadConfig(configPath)
	if err != nil {
		return err
	}
	dataDir, err := resolveDataDir(dataDirFlag, cfg)
	if err != nil {
		return err
	}
	token, err := auth.ReadToken(dataDir)
	if errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("no token in %s yet; run \"flit serve\" once to create it", dataDir)
	}
	if err != nil {
		return err
	}
	fmt.Fprintln(stdout, token)
	return nil
}

func serve(ctx context.Context, stderr io.Writer, configPath, dataDirFlag string) error {
	level := new(slog.LevelVar)
	log := slog.New(slog.NewTextHandler(stderr, &slog.HandlerOptions{Level: level}))

	created, err := config.EnsureFile(configPath)
	if err != nil {
		return fmt.Errorf("create config: %w", err)
	}
	if created {
		log.Info("wrote default config", "path", configPath)
	}
	cfg, err := config.Load(configPath)
	if err != nil {
		return err
	}
	level.Set(cfg.Log.SlogLevel())

	dataDir, err := resolveDataDir(dataDirFlag, cfg)
	if err != nil {
		return fmt.Errorf("find data dir: %w", err)
	}
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return fmt.Errorf("create data dir: %w", err)
	}
	token, firstRun, err := auth.LoadOrCreateToken(dataDir)
	if err != nil {
		return fmt.Errorf("load token: %w", err)
	}
	if firstRun {
		// Shown once, on the terminal that ran first start. Later, use "flit token".
		fmt.Fprintf(stderr, "\nGenerated a new API token. Clients need it to connect:\n\n    %s\n\nIt is stored in %s. Print it again with \"flit token\".\n\n",
			token, dataDir)
	}

	bi := buildinfo.Get()
	log.Info("starting flit", "version", bi.Version, "config", configPath, "data_dir", dataDir)

	// The live config. Reloads swap it; readers see the latest on their next
	// call (the agent reads it per model call and tool run).
	var live atomic.Pointer[config.Config]
	live.Store(&cfg)
	current := func() config.Config { return *live.Load() }

	st, err := store.Open(ctx, filepath.Join(dataDir, store.FileName))
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer st.Close()
	sessions, err := agent.NewManager(ctx, st, current, log)
	if err != nil {
		return fmt.Errorf("load sessions: %w", err)
	}
	defer sessions.Close()

	// Paths in the config are relative to the config file.
	configDir := filepath.Dir(configPath)
	relToConfig := func(p string) string {
		if p == "" || filepath.IsAbs(p) {
			return p
		}
		return filepath.Join(configDir, p)
	}
	rolesDir := func() string { return relToConfig(current().RolesDir) }
	catalog := models.NewCatalog(current, func() string { return relToConfig(current().ModelOverridesFile) }, log)
	sessions.Catalog, sessions.RolesDir = catalog, rolesDir
	sessions.SkillsDirs = func() []string {
		var dirs []string
		for _, d := range current().SkillsDirs {
			dirs = append(dirs, relToConfig(d))
		}
		return dirs
	}
	mcpServers := mcpclient.New(current, log)
	defer mcpServers.Close()
	sessions.MCP = mcpServers
	go func() {
		if err := catalog.Refresh(ctx, ""); err != nil {
			log.Warn("model discovery", "err", err)
		}
	}()
	if len(cfg.Providers) == 0 {
		log.Warn("no providers configured; add one under providers in the config to run sessions", "config", configPath)
	}

	srv := server.New(server.NewHandler(token, server.Deps{Sessions: sessions, Devices: devices.New(st), Config: current, Catalog: catalog, RolesDir: rolesDir, Store: st}), log)
	if err := srv.Apply(cfg); err != nil {
		return err
	}

	watchErr := make(chan error, 1)
	go func() {
		watchErr <- config.Watch(ctx, configPath, log, func(next config.Config) {
			prev := *live.Load()
			live.Store(&next)
			level.Set(next.Log.SlogLevel())
			if !reflect.DeepEqual(prev.Providers, next.Providers) || prev.ModelOverridesFile != next.ModelOverridesFile {
				go func() { _ = catalog.Refresh(ctx, "") }()
			}
			if next.DataDir != cfg.DataDir && dataDirFlag == "" {
				log.Warn("data_dir changed; it takes effect the next time flit starts", "in_use", dataDir)
			}
			if err := srv.Apply(next); err != nil {
				log.Error("could not apply new listen/TLS settings; still serving the old ones", "err", err)
			}
		})
	}()

	select {
	case <-ctx.Done():
	case err := <-watchErr:
		if err != nil {
			log.Error("config watcher stopped; config changes will not be applied", "err", err)
		}
		<-ctx.Done()
	}

	log.Info("shutting down")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}
