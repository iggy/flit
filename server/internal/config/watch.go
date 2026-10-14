package config

import (
	"context"
	"log/slog"
	"path/filepath"
	"time"

	"github.com/fsnotify/fsnotify"
)

// debounce collapses the burst of events an editor save produces.
const debounce = 150 * time.Millisecond

// Watch reloads the config file at path whenever it changes and calls
// onChange with each new valid config, until ctx is done.
//
// It watches the file's directory rather than the file itself, so saves that
// replace the file (write to a temp file, then rename) are seen. A file that
// fails to load or validate is logged and skipped; the previous config stays
// in effect.
func Watch(ctx context.Context, path string, log *slog.Logger, onChange func(Config)) error {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return err
	}
	defer w.Close()

	path = filepath.Clean(path)
	if err := w.Add(filepath.Dir(path)); err != nil {
		return err
	}

	var timer *time.Timer
	var fire <-chan time.Time
	for {
		select {
		case <-ctx.Done():
			if timer != nil {
				timer.Stop()
			}
			return nil
		case ev, ok := <-w.Events:
			if !ok {
				return nil
			}
			if filepath.Clean(ev.Name) != path || ev.Op == fsnotify.Chmod {
				continue
			}
			if timer == nil {
				timer = time.NewTimer(debounce)
			} else {
				timer.Reset(debounce)
			}
			fire = timer.C
		case <-fire:
			fire = nil
			cfg, err := Load(path)
			if err != nil {
				log.Error("config reload failed; keeping previous config", "err", err)
				continue
			}
			log.Info("config reloaded", "path", path)
			onChange(cfg)
		case err, ok := <-w.Errors:
			if !ok {
				return nil
			}
			log.Warn("config watcher error", "err", err)
		}
	}
}
