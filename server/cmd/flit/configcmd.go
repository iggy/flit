package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/iggy/flit/server/internal/config"
)

const configUsage = `Usage:
  flit config defaults                        print the default config
  flit config update [--config FILE] [--dry-run]
      add settings that are new since the config was written, with their
      comments; everything already in it is kept. Saves the old file as
      FILE.bak. --dry-run prints the change as a diff instead.
`

func configCmd(stdout, stderr io.Writer, args []string, defaultConfig string) error {
	if len(args) == 0 {
		fmt.Fprint(stderr, configUsage)
		return flag.ErrHelp
	}
	fs := flag.NewFlagSet("config "+args[0], flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() { fmt.Fprint(stderr, configUsage) }
	switch args[0] {
	case "defaults":
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		_, err := io.WriteString(stdout, config.DefaultFile())
		return err
	case "update":
		configPath := fs.String("config", defaultConfig, "config file")
		dryRun := fs.Bool("dry-run", false, "print a diff instead of writing")
		if err := fs.Parse(args[1:]); err != nil {
			return err
		}
		return updateConfig(stdout, *configPath, *dryRun)
	default:
		fmt.Fprint(stderr, configUsage)
		return fmt.Errorf("unknown config command %q", args[0])
	}
}

func updateConfig(stdout io.Writer, path string, dryRun bool) error {
	cur, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("no config at %s; \"flit serve\" writes the default one", path)
	}
	if err != nil {
		return err
	}
	out, added, err := config.Update(cur)
	if err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	if len(added) == 0 {
		fmt.Fprintf(stdout, "%s already has every setting.\n", path)
		return nil
	}
	if dryRun {
		fmt.Fprint(stdout, insertDiff(path, string(cur), string(out)))
		fmt.Fprintf(stdout, "Would add: %s\n", strings.Join(added, ", "))
		return nil
	}
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	if err := os.WriteFile(path+".bak", cur, info.Mode().Perm()); err != nil {
		return fmt.Errorf("back up config: %w", err)
	}
	// Write a temp file and rename it over the config, so the running
	// server never reads half a file.
	tmp, err := os.CreateTemp(filepath.Dir(path), ".flit-config-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(out); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Chmod(info.Mode().Perm()); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Rename(tmp.Name(), path); err != nil {
		return err
	}
	fmt.Fprintf(stdout, "Added to %s (old file saved as %s.bak): %s\n", path, path, strings.Join(added, ", "))
	return nil
}

// insertDiff is a unified diff from a to b, where b is a with lines
// inserted (what config.Update does), with three lines of context.
func insertDiff(path, a, b string) string {
	al := strings.Split(strings.TrimSuffix(a, "\n"), "\n")
	bl := strings.Split(strings.TrimSuffix(b, "\n"), "\n")
	// added[j] says whether b's line j is new.
	added := make([]bool, len(bl))
	i := 0
	for j, l := range bl {
		if i < len(al) && al[i] == l {
			i++
		} else {
			added[j] = true
		}
	}
	const ctx = 3
	var sb strings.Builder
	fmt.Fprintf(&sb, "--- %s\n+++ %s (updated)\n", path, path)
	// aLine[j] is the line number in a of b's line j, for unchanged lines.
	aLine := make([]int, len(bl)+1)
	n := 0
	for j := range bl {
		aLine[j] = n
		if !added[j] {
			n++
		}
	}
	aLine[len(bl)] = n
	for j := 0; j < len(bl); {
		if !added[j] {
			j++
			continue
		}
		start := max(0, j-ctx)
		end := j
		// Extend the hunk while the next insertion is within 2*ctx lines.
		for {
			for end < len(bl) && added[end] {
				end++
			}
			next := end
			for next < len(bl) && !added[next] && next-end < 2*ctx {
				next++
			}
			if next < len(bl) && added[next] {
				end = next
				continue
			}
			break
		}
		stop := min(len(bl), end+ctx)
		aCount := 0
		for k := start; k < stop; k++ {
			if !added[k] {
				aCount++
			}
		}
		fmt.Fprintf(&sb, "@@ -%d,%d +%d,%d @@\n", aLine[start]+1, aCount, start+1, stop-start)
		for k := start; k < stop; k++ {
			if added[k] {
				sb.WriteString("+")
			} else {
				sb.WriteString(" ")
			}
			sb.WriteString(bl[k])
			sb.WriteString("\n")
		}
		j = stop
	}
	return sb.String()
}
