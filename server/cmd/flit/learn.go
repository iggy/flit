package main

import (
	"bufio"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/learn"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

const learnUsage = `Usage: flit learn [flags] ID

Reads session ID (a unique prefix will do) and asks the learning model
(agent.tasks.learning, else the chat model) what is worth remembering:
lessons for the user, project or role memory files, and skills. Each
proposal is shown and nothing is written until you accept it:

  y  accept     n  reject     e  edit, then accept
  s  skip (leave it pending, e.g. for the app)     q  stop asking

With --pending, reviews the proposals already waiting (for ID, or every
session without one) instead of running a pass. See docs/learning.md.

Flags:
`

// stdin is where learn reads answers; tests replace it.
var stdin io.Reader = os.Stdin

func learnCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	fs := flag.NewFlagSet("learn", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, learnUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	yes := fs.Bool("yes", false, "accept every proposal without asking")
	dryRun := fs.Bool("dry-run", false, "show the proposals; store and write nothing")
	pending := fs.Bool("pending", false, "review stored pending proposals instead of running a pass")
	if err := fs.Parse(args); err != nil {
		return err
	}
	if fs.NArg() > 1 || (fs.NArg() == 0 && !*pending) {
		fs.Usage()
		return errors.New("usage: flit learn [flags] ID")
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

	sessionID := ""
	if fs.NArg() == 1 {
		sess, err := findSession(ctx, st, fs.Arg(0))
		if err != nil {
			return err
		}
		sessionID = sess.ID
	}

	configDir := filepath.Dir(*configPath)
	relToConfig := func(p string) string {
		if p == "" || filepath.IsAbs(p) {
			return p
		}
		return filepath.Join(configDir, p)
	}
	current := func() config.Config { return cfg }
	quiet := slog.New(slog.NewTextHandler(io.Discard, nil))
	svc := &learn.Service{
		Store: st, Config: current, DataDir: dataDir,
		RolesDir: func() string { return relToConfig(cfg.RolesDir) },
		SkillsDirs: func() []string {
			var dirs []string
			for _, d := range cfg.SkillsDirs {
				dirs = append(dirs, relToConfig(d))
			}
			return dirs
		},
		Catalog: models.NewCatalog(current, func() string { return relToConfig(cfg.ModelOverridesFile) }, quiet),
		Log:     quiet,
	}

	var list []store.Proposal
	if *pending {
		if list, err = st.ListProposals(ctx, sessionID, false); err != nil {
			return err
		}
		if len(list) == 0 {
			fmt.Fprintln(stdout, "No pending proposals.")
			return nil
		}
	} else {
		if task, ok := cfg.Task("learning"); ok {
			// For the context window and how to turn thinking off.
			_ = svc.Catalog.Refresh(ctx, task.Provider)
		}
		fmt.Fprintf(stderr, "Reading session %s...\n", sessionID)
		res, err := svc.Run(ctx, sessionID, *dryRun)
		if err != nil {
			return err
		}
		fmt.Fprintf(stderr, "Asked %s/%s.\n", res.Provider, res.Model)
		for _, d := range res.Dropped {
			fmt.Fprintf(stderr, "Left out: %s\n", d)
		}
		list = res.Proposals
		if len(list) == 0 {
			fmt.Fprintln(stdout, "Nothing worth keeping from this session.")
			return nil
		}
	}

	in := bufio.NewReader(stdin)
	accepted, rejected := 0, 0
	for i, p := range list {
		fmt.Fprintf(stdout, "\n[%d/%d] %s\n", i+1, len(list), describe(p))
		printDiff(stdout, p.OldText, p.NewText)
		if *dryRun {
			continue
		}
		answer := "y"
		if !*yes {
			if answer, err = ask(in, stdout, "Accept? [y]es / [n]o / [e]dit / [s]kip / [q]uit: "); err != nil {
				return err
			}
		}
		var text *string
		switch answer {
		case "q":
			fmt.Fprintf(stdout, "%d accepted, %d rejected; the rest stay pending.\n", accepted, rejected)
			return nil
		case "s", "":
			continue
		case "n":
			if _, err := svc.Reject(ctx, p.ID); err != nil {
				return err
			}
			rejected++
			continue
		case "e":
			edited, err := edit(in, stdout, p.NewText)
			if err != nil {
				return err
			}
			text = &edited
		}
		got, err := svc.Accept(ctx, p.ID, text)
		if err != nil {
			fmt.Fprintf(stdout, "Could not write it: %v (it stays pending)\n", err)
			continue
		}
		accepted++
		fmt.Fprintf(stdout, "Written to %s\n", got.Path)
	}
	if *dryRun {
		fmt.Fprintln(stdout, "\nDry run: nothing was stored or written.")
		return nil
	}
	fmt.Fprintf(stdout, "\n%d accepted, %d rejected.\n", accepted, rejected)
	return nil
}

func describe(p store.Proposal) string {
	where := p.Target + " memory"
	if p.Target == learn.TargetSkill {
		where = "skill " + p.Skill
	}
	s := fmt.Sprintf("%s → %s (%s)", p.Action, where, p.Path)
	if p.Evidence != "" {
		s += "\n    evidence: " + p.Evidence
	}
	return s
}

// printDiff shows old as - lines and new as + lines.
func printDiff(w io.Writer, old, new string) {
	for _, l := range splitLines(old) {
		fmt.Fprintln(w, "  - "+l)
	}
	for _, l := range splitLines(new) {
		fmt.Fprintln(w, "  + "+l)
	}
}

func splitLines(s string) []string {
	s = strings.TrimRight(s, "\n")
	if s == "" {
		return nil
	}
	return strings.Split(s, "\n")
}

func ask(in *bufio.Reader, w io.Writer, prompt string) (string, error) {
	for {
		fmt.Fprint(w, prompt)
		line, err := in.ReadString('\n')
		a := strings.ToLower(strings.TrimSpace(line))
		if len(a) > 1 {
			a = a[:1]
		}
		switch a {
		case "y", "n", "e", "s", "q":
			return a, nil
		case "":
			if err != nil {
				return "q", nil // end of input
			}
		}
		if err != nil {
			return "", err
		}
	}
}

// edit lets the user change text in $VISUAL or $EDITOR, or, without one,
// type a replacement ending with an empty line.
func edit(in *bufio.Reader, w io.Writer, text string) (string, error) {
	editor := os.Getenv("VISUAL")
	if editor == "" {
		editor = os.Getenv("EDITOR")
	}
	if editor == "" {
		fmt.Fprintln(w, "Type the new text; end with an empty line:")
		var lines []string
		for {
			line, err := in.ReadString('\n')
			line = strings.TrimRight(line, "\r\n")
			if line == "" {
				break
			}
			lines = append(lines, line)
			if err != nil {
				break
			}
		}
		return strings.Join(lines, "\n"), nil
	}
	f, err := os.CreateTemp("", "flit-learn-*.md")
	if err != nil {
		return "", err
	}
	defer os.Remove(f.Name())
	if _, err := f.WriteString(text); err != nil {
		f.Close()
		return "", err
	}
	f.Close()
	parts := strings.Fields(editor)
	cmd := exec.Command(parts[0], append(parts[1:], f.Name())...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("editor: %w", err)
	}
	data, err := os.ReadFile(f.Name())
	return string(data), err
}
