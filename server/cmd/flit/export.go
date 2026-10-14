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
	"time"

	"github.com/iggy/flit/server/internal/export"
	"github.com/iggy/flit/server/internal/store"
)

const exportUsage = `Usage: flit export [flags]

Writes recorded model calls, turns and sessions as JSONL (one JSON object
per line) in OpenAI chat format. Projects that opted out are left out.
See docs/export.md for the record format.

Flags:
`

func exportCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	fs := flag.NewFlagSet("export", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, exportUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	out := fs.String("out", "-", "output file, - for stdout")
	since := fs.String("since", "", "only records from this date on (YYYY-MM-DD or RFC 3339)")
	until := fs.String("until", "", "only records before this date (YYYY-MM-DD or RFC 3339)")
	project := fs.String("project", "", "only this project (id or name)")
	model := fs.String("model", "", "only this model (model id or provider/model)")
	rating := fs.String("rating", "", "only rated records: good, bad or rated (any rating)")
	records := fs.String("records", "", "record types to write, comma-separated: session, turn, model_call (default all)")
	redact := fs.Bool("redact", false, "replace working directories, your home and flit's own paths with placeholders, and secret-looking strings with <redacted>")
	if err := fs.Parse(args); err != nil {
		return err
	}

	opts := export.Options{
		ExportFilter: store.ExportFilter{Project: *project, Model: *model},
		Rating:       *rating,
		Redact:       *redact,
	}
	var err error
	if opts.Since, err = parseDate(*since); err != nil {
		return fmt.Errorf("--since: %w", err)
	}
	if opts.Until, err = parseDate(*until); err != nil {
		return fmt.Errorf("--until: %w", err)
	}
	if *records != "" {
		for _, r := range strings.Split(*records, ",") {
			opts.Records = append(opts.Records, strings.TrimSpace(r))
		}
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
	if opts.Redact {
		opts.Paths = map[string]string{dataDir: "<flit-data>", filepath.Dir(*configPath): "<flit-config>"}
		if home, err := os.UserHomeDir(); err == nil {
			opts.Paths[home] = "<home>"
		}
	}

	st, err := store.Open(ctx, dbPath)
	if err != nil {
		return err
	}
	defer st.Close()

	w := stdout
	if *out != "-" {
		f, err := os.Create(*out)
		if err != nil {
			return err
		}
		defer f.Close()
		w = f
	}
	stats, err := export.Write(ctx, st, w, opts)
	if err != nil {
		return err
	}
	fmt.Fprintf(stderr, "exported %d sessions, %d turns, %d model calls\n", stats.Sessions, stats.Turns, stats.ModelCalls)
	return nil
}

func parseDate(s string) (time.Time, error) {
	if s == "" {
		return time.Time{}, nil
	}
	if t, err := time.ParseInLocation(time.DateOnly, s, time.Local); err == nil {
		return t, nil
	}
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	return time.Time{}, errors.New("want YYYY-MM-DD or RFC 3339")
}
