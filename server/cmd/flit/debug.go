package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	"google.golang.org/protobuf/encoding/protojson"

	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/timeline"
)

const debugUsage = `Usage: flit debug session [flags] [ID]

Prints a session's timeline from its event log: model calls with their
phases (sent, first byte, first token, last byte), prompt progress, tool
runs and prompts with how long each took, and at the end anything that
never finished, which is where a frozen turn is stuck. ID may be a unique
prefix; without one, lists the most recent sessions.

Flags:
`

func debugCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	if len(args) == 0 || args[0] != "session" {
		fmt.Fprint(stderr, debugUsage)
		return errors.New("usage: flit debug session [ID]")
	}
	fs := flag.NewFlagSet("debug session", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, debugUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	raw := fs.Bool("events", false, "print the raw events as JSON lines instead")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if fs.NArg() > 1 {
		return errors.New("usage: flit debug session [ID]")
	}

	cfg, err := loadConfig(*configPath)
	if err != nil {
		return err
	}
	dataDir, err := resolveDataDir(*dataDirFlag, cfg)
	if err != nil {
		return err
	}
	dbPath := filepath.Join(dataDir, store.FileName)
	if _, err := os.Stat(dbPath); err != nil {
		return fmt.Errorf("no flit database at %s: %w", dbPath, err)
	}
	st, err := store.Open(ctx, dbPath)
	if err != nil {
		return err
	}
	defer st.Close()

	if fs.NArg() == 0 {
		return listRecentSessions(ctx, stdout, st)
	}
	sess, err := findSession(ctx, st, fs.Arg(0))
	if err != nil {
		return err
	}
	events, err := st.Events(ctx, sess.ID, 0, math.MaxInt64)
	if err != nil {
		return err
	}
	if *raw {
		for _, ev := range events {
			b, err := protojson.Marshal(ev)
			if err != nil {
				return err
			}
			fmt.Fprintf(stdout, "%s\n", b)
		}
		return nil
	}
	return timeline.Write(stdout, sess, events, time.Now())
}

// findSession finds a session by id or unique id prefix.
func findSession(ctx context.Context, st *store.Store, id string) (store.Session, error) {
	if s, err := st.GetSession(ctx, id); err == nil {
		return s, nil
	} else if !errors.Is(err, store.ErrNotFound) {
		return store.Session{}, err
	}
	all, err := st.ListSessions(ctx, "", 100000, 0)
	if err != nil {
		return store.Session{}, err
	}
	var found []store.Session
	for _, s := range all {
		if strings.HasPrefix(s.ID, id) {
			found = append(found, s)
		}
	}
	switch len(found) {
	case 1:
		return found[0], nil
	case 0:
		return store.Session{}, fmt.Errorf("no session %q (run flit debug session to list them)", id)
	}
	return store.Session{}, fmt.Errorf("%q matches %d sessions; give more of the id", id, len(found))
}

func listRecentSessions(ctx context.Context, w io.Writer, st *store.Store) error {
	list, err := st.ListSessions(ctx, "", 20, 0)
	if err != nil {
		return err
	}
	if len(list) == 0 {
		fmt.Fprintln(w, "no sessions")
		return nil
	}
	for _, s := range list {
		state := strings.ToLower(strings.TrimPrefix(s.State.String(), "TASK_STATE_"))
		title := s.Title
		if title == "" {
			title = "(untitled)"
		}
		fmt.Fprintf(w, "%s  %-8s  %s  %s\n", s.ID, state, s.UpdatedAt.Local().Format("2006-01-02 15:04"), title)
	}
	return nil
}
