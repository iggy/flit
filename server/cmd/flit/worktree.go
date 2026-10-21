package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/gen/flit/v1/flitv1connect"
	"github.com/iggy/flit/server/internal/auth"
)

const worktreeUsage = `Usage:
  flit worktree remove [flags] SESSION   remove a session's git worktree

Deletes the worktree directory but no history: the session's branch stays
if it has commits no other branch, tag or remote has. Refuses while the
worktree has uncommitted changes. Talks to the running "flit serve" on this
machine (see docs/git.md).

Flags:
`

func worktreeCmd(ctx context.Context, stdout, stderr io.Writer, args []string, defaultConfig string) error {
	if len(args) == 0 || args[0] != "remove" {
		fmt.Fprint(stderr, worktreeUsage)
		return errors.New("usage: flit worktree remove SESSION")
	}
	fs := flag.NewFlagSet("worktree remove", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprint(stderr, worktreeUsage)
		fs.PrintDefaults()
	}
	configPath := fs.String("config", defaultConfig, "config file")
	dataDirFlag := fs.String("data-dir", "", "data directory")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if fs.NArg() != 1 {
		return errors.New("usage: flit worktree remove SESSION")
	}
	cfg, err := loadConfig(*configPath)
	if err != nil {
		return err
	}
	dataDir, err := resolveDataDir(*dataDirFlag, cfg)
	if err != nil {
		return err
	}
	token, err := auth.ReadToken(dataDir)
	if err != nil {
		return fmt.Errorf("read admin token from %s: %w (is this the machine running \"flit serve\"?)", dataDir, err)
	}
	base, hc := localURL(cfg)
	c := flitv1connect.NewSessionServiceClient(hc, base, connect.WithInterceptors(bearerInterceptor(token)))
	res, err := c.RemoveWorktree(ctx, connect.NewRequest(&flitv1.RemoveWorktreeRequest{SessionId: fs.Arg(0)}))
	if err != nil {
		return err
	}
	s := res.Msg.Session
	fmt.Fprintf(stdout, "removed %s\n", s.WorktreePath)
	if res.Msg.BranchKept {
		fmt.Fprintf(stdout, "kept branch %s (%d commits found nowhere else)\n", s.WorktreeBranch, res.Msg.Commits)
	} else {
		fmt.Fprintf(stdout, "deleted branch %s (nothing on it that isn't elsewhere)\n", s.WorktreeBranch)
	}
	return nil
}
