// Command flit is the flit coding agent server.
//
// Usage:
//
//	flit serve [--config FILE] [--data-dir DIR]
//	flit token [--config FILE] [--data-dir DIR]
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
	"syscall"
	"time"

	"github.com/iggy/flit/server/internal/auth"
	"github.com/iggy/flit/server/internal/buildinfo"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/paths"
	"github.com/iggy/flit/server/internal/server"
)

const usage = `flit is an open source coding agent.

Usage:
  flit serve [flags]   run the API server
  flit token [flags]   print the API token
  flit version         print version information

Flags for serve and token:
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
	case "serve", "token":
		fs := flag.NewFlagSet(cmd, flag.ContinueOnError)
		fs.SetOutput(stderr)
		configPath := fs.String("config", defaultConfig, "config file")
		dataDir := fs.String("data-dir", "", "data directory")
		if err := fs.Parse(args); err != nil {
			return err
		}
		if cmd == "token" {
			return printToken(stdout, *configPath, *dataDir)
		}
		return serve(ctx, stderr, *configPath, *dataDir)
	case "version":
		bi := buildinfo.Get()
		fmt.Fprintf(stdout, "flit %s (commit %s, built %s, %s, %s/%s, API %s)\n",
			bi.Version, orUnknown(bi.Commit), orUnknown(bi.BuildTime), bi.GoVersion, bi.OS, bi.Arch, buildinfo.APIVersion)
		return nil
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

	srv := server.New(server.NewHandler(token), log)
	if err := srv.Apply(cfg); err != nil {
		return err
	}

	watchErr := make(chan error, 1)
	go func() {
		watchErr <- config.Watch(ctx, configPath, log, func(next config.Config) {
			level.Set(next.Log.SlogLevel())
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
