package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/facts"
	"github.com/iggy/flit/server/internal/store"
)

const factsUsage = `Usage: flit facts [flags]
       flit facts forget ID

Lists the facts flit worked out from the shell commands in its sessions,
with no model calls, and the evidence for them. With --rebuild, first
works them all out again from the event logs. forget retires a fact for
good (a unique id prefix will do). See docs/learning.md.

Flags:
`

func factsCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	forget := len(args) > 0 && args[0] == "forget"
	if forget {
		args = args[1:]
	}
	fs := flag.NewFlagSet("facts", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, factsUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	project := fs.String("project", "", "only this project (id or name)")
	rebuild := fs.Bool("rebuild", false, "work the facts out again from every session's event log")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if forget != (fs.NArg() == 1) {
		fs.Usage()
		return errors.New("usage: flit facts [flags], or flit facts forget ID")
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
	svc := &facts.Service{Store: st, Config: func() config.Config { return cfg }}

	if forget {
		id, err := svc.Forget(ctx, fs.Arg(0))
		if errors.Is(err, store.ErrNotFound) {
			return fmt.Errorf("no fact %q (run flit facts to list them)", fs.Arg(0))
		}
		if err != nil {
			return err
		}
		fmt.Fprintf(stdout, "Forgot %s. flit won't learn it again.\n", id)
		return nil
	}

	projectID, names, err := resolveProject(ctx, st, *project)
	if err != nil {
		return err
	}
	if *rebuild {
		n, err := svc.Rebuild(ctx, projectID)
		if err != nil {
			return err
		}
		fmt.Fprintf(stdout, "Read %d sessions.\n", n)
	}
	list, err := svc.List(ctx, projectID)
	if err != nil {
		return err
	}
	printFacts(stdout, list, names, cfg.Learning.Facts)
	return nil
}

// resolveProject finds a project by id or name, and names every project.
func resolveProject(ctx context.Context, st *store.Store, want string) (string, map[string]string, error) {
	projects, err := st.ListProjects(ctx, store.DefaultTeamID)
	if err != nil {
		return "", nil, err
	}
	names := map[string]string{}
	found := ""
	for _, p := range projects {
		names[p.ID] = p.Name
		if want != "" && (p.ID == want || strings.EqualFold(p.Name, want)) {
			found = p.ID
		}
	}
	if want != "" && found == "" {
		return "", nil, fmt.Errorf("no project %q", want)
	}
	return found, names, nil
}

func printFacts(w io.Writer, list []facts.Fact, names map[string]string, mode string) {
	if len(list) == 0 {
		fmt.Fprintln(w, "No facts learned yet.")
		return
	}
	if mode != facts.ModeOn {
		fmt.Fprintf(w, "learning.facts is %s: nothing is added to the system prompt.\n", mode)
	}
	group := "\x00"
	for _, f := range list {
		where := names[f.ProjectID]
		if where == "" {
			where = f.ProjectID
		}
		if f.Scope != "" {
			where += " (" + f.Scope + ")"
		}
		if where != group {
			fmt.Fprintf(w, "\n%s\n", where)
			group = where
		}
		state := f.State
		if f.Injected {
			state += ", in the prompt"
		}
		fmt.Fprintf(w, "  %s  [%s, %s]\n    %s\n", f.ID, f.Family, state, f.Text)
		fmt.Fprintf(w, "    confirmed in %d sessions; failure seen or prevented in %d of %d that exercised it\n",
			f.Confirmations, f.Fired, f.Exercised)
		if len(f.Evidence) > 0 {
			fmt.Fprintf(w, "    evidence: %s\n", strings.Join(f.Evidence, "; "))
		}
	}
}
