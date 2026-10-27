package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"strings"
	"time"

	"google.golang.org/protobuf/encoding/protojson"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

// debugDumpCmd is flit debug dump: the running server's live state.
func debugDumpCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	fs := flag.NewFlagSet("debug dump", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, debugUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	stacks := fs.Bool("stacks", false, "print every goroutine's stack")
	asJSON := fs.Bool("json", false, "print the dump as JSON")
	if err := fs.Parse(args); err != nil {
		return err
	}
	c, err := adminClient(*configPath, *dataDirFlag)
	if err != nil {
		return err
	}
	res, err := c.DebugDump(ctx, &flitv1.DebugDumpRequest{Goroutines: true})
	if err != nil {
		return fmt.Errorf("ask the server (is flit serve running?): %w", err)
	}
	if *asJSON {
		if !*stacks {
			res.Goroutines = ""
		}
		b, err := protojson.MarshalOptions{Multiline: true}.Marshal(res)
		if err != nil {
			return err
		}
		fmt.Fprintf(stdout, "%s\n", b)
		return nil
	}
	held := writeDump(stdout, res, res.Time.AsTime())
	n := strings.Count(res.Goroutines, "goroutine ")
	switch {
	case *stacks || held:
		if held && !*stacks {
			fmt.Fprintln(stdout, "\nA lock is held; the stacks below show what holds it (taken before the dump waited on any lock):")
		}
		fmt.Fprintf(stdout, "\n%s", res.Goroutines)
	default:
		fmt.Fprintf(stdout, "\n%d goroutines; --stacks prints them.\n", n)
	}
	return nil
}

// writeDump prints the dump readably and reports whether any lock was
// held.
func writeDump(w io.Writer, res *flitv1.DebugDumpResponse, now time.Time) (held bool) {
	if !res.SessionsLockFree {
		held = true
		fmt.Fprintln(w, "The session table's lock is held: something in flit is stuck (see the stacks).")
	}
	if len(res.Limits) > 0 {
		fmt.Fprintln(w, "Model concurrency (providers[].concurrency):")
		for _, l := range res.Limits {
			limit := "no limit"
			if l.Limit > 0 {
				limit = fmt.Sprintf("limit %d", l.Limit)
			}
			fmt.Fprintf(w, "  %s/%s: %d in flight, %d waiting (%s)\n", l.Provider, l.Model, l.InUse, l.Waiting, limit)
		}
		fmt.Fprintln(w)
	}
	busy := 0
	for _, s := range res.Sessions {
		if !s.LockFree {
			held = true
			fmt.Fprintf(w, "Session %s: its lock is held (couldn't take it in 2s): flit is stuck on it, see the stacks\n", s.SessionId)
			continue
		}
		if !s.TurnRunning && s.Call == nil && s.Tool == nil && len(s.SubagentCalls) == 0 && s.PendingPrompts == 0 {
			continue
		}
		busy++
		title := s.Title
		if title == "" {
			title = "(untitled)"
		}
		fmt.Fprintf(w, "Session %s %q: %s", s.SessionId, title, strings.ToLower(strings.TrimPrefix(s.State.String(), "TASK_STATE_")))
		if s.TurnRunning {
			fmt.Fprint(w, ", turn running")
		}
		if s.LastEventTime != nil {
			fmt.Fprintf(w, ", last event #%d %s ago", s.LastSeq, ago(now, s.LastEventTime.AsTime()))
		}
		fmt.Fprintln(w)
		if s.Call != nil {
			fmt.Fprintf(w, "  model call: %s\n", callText(s.Call, now))
		}
		for _, c := range s.SubagentCalls {
			fmt.Fprintf(w, "  subagent model call: %s\n", callText(c, now))
		}
		if t := s.Tool; t != nil {
			fmt.Fprintf(w, "  running tool %s (%s) for %s\n", t.Name, t.ToolCallId, ago(now, t.StartTime.AsTime()))
		}
		if s.PendingPrompts > 0 {
			fmt.Fprintf(w, "  waiting for the user to answer %d prompt(s)\n", s.PendingPrompts)
		}
		if s.QueuedMessages > 0 {
			fmt.Fprintf(w, "  %d queued message(s)\n", s.QueuedMessages)
		}
		if s.TurnRunning && s.Call == nil && s.Tool == nil && len(s.SubagentCalls) == 0 && s.PendingPrompts == 0 {
			fmt.Fprintln(w, "  turn running but no model call or tool in flight: between steps (compaction, saving the prompt cache), or stuck in flit itself (see --stacks)")
		}
	}
	if busy == 0 && !held {
		fmt.Fprintf(w, "No session is doing anything (%d loaded).\n", len(res.Sessions))
	}
	return held
}

func callText(c *flitv1.ModelCallDebug, now time.Time) string {
	s := fmt.Sprintf("%s/%s (%s)", c.Provider, c.Model, c.MessageId)
	switch {
	case c.Queued:
		return s + ": waiting for its turn under the concurrency limit"
	case c.SentTime == nil:
		return s + ": not sent yet"
	}
	s += fmt.Sprintf(": %s, sent %s ago", strings.ReplaceAll(c.Phase, "_", " "), ago(now, c.SentTime.AsTime()))
	if c.PromptTotal > 0 {
		s += fmt.Sprintf(", prompt %d/%d", c.PromptProcessed, c.PromptTotal)
	}
	s += fmt.Sprintf(", %d output chunks, %d bytes", c.StreamedTokens, c.Bytes)
	idle := time.Duration(c.IdleMs) * time.Millisecond
	s += fmt.Sprintf("; quiet for %s", idle.Round(100*time.Millisecond))
	if c.WatchdogMs > 0 {
		s += fmt.Sprintf(" (watchdog gives up at %s)", (time.Duration(c.WatchdogMs) * time.Millisecond).Round(time.Second))
	}
	return s
}

func ago(now, t time.Time) string {
	return now.Sub(t).Round(100 * time.Millisecond).String()
}
