package sessionsvc_test

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"connectrpc.com/connect"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func gitCmd(t *testing.T, dir string, args ...string) string {
	t.Helper()
	out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).CombinedOutput()
	if err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, out)
	}
	return strings.TrimSpace(string(out))
}

func TestGitStatusAndDiff(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git is not installed")
	}
	cfg, fake := fakeConfig(t)
	c := start(t, cfg)
	ctx := context.Background()

	dir := t.TempDir()
	gitCmd(t, dir, "init", "-q", "-b", "main")
	gitCmd(t, dir, "config", "user.email", "test@example.com")
	gitCmd(t, dir, "config", "user.name", "Test")
	gitCmd(t, dir, "config", "commit.gpgsign", "false")
	gitCmd(t, dir, "config", "core.autocrlf", "false")
	if err := os.WriteFile(filepath.Join(dir, "a.txt"), []byte("a\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	gitCmd(t, dir, "add", "a.txt")
	gitCmd(t, dir, "commit", "-q", "-m", "first")
	base := gitCmd(t, dir, "rev-parse", "HEAD")

	created, err := c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: dir}))
	if err != nil {
		t.Fatal(err)
	}
	s := created.Msg.Session
	if s.BaseCommit != base {
		t.Fatalf("base_commit = %q, want %q", s.BaseCommit, base)
	}

	// The agent writes a file and commits it, then writes another.
	fake.Push(
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c1", "write", `{"path":"new.txt","content":"hello\n"}`})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c2", "git_commit", `{"message":"add new","paths":["new.txt"]}`})},
		llmtest.Response{Chunks: llmtest.ToolCalls([3]string{"c3", "write", `{"path":"later.txt","content":"x\ny\n"}`})},
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	runTurn(t, c, s.Id, "go", flitv1.PromptDecision_PROMPT_DECISION_ALLOW, 10*time.Second)

	st, err := c.GitStatus(ctx, connect.NewRequest(&flitv1.GitStatusRequest{SessionId: s.Id}))
	if err != nil {
		t.Fatal(err)
	}
	g := st.Msg
	if !g.IsRepo || g.Branch != "main" || g.BaseCommit != base || g.DiffBase != base ||
		g.DiffBaseKind != flitv1.GitDiffBase_GIT_DIFF_BASE_SESSION_START || g.UntrackedCount != 1 || g.Head == base {
		t.Fatalf("status = %v", g)
	}
	got := map[string]*flitv1.GitFileChange{}
	for _, f := range g.Files {
		got[f.Path] = f
	}
	if f := got["new.txt"]; f == nil || f.Status != flitv1.GitFileStatus_GIT_FILE_STATUS_ADDED || f.Untracked || f.Additions != 1 {
		t.Errorf("new.txt = %v", f)
	}
	if f := got["later.txt"]; f == nil || !f.Untracked || f.Additions != 2 {
		t.Errorf("later.txt = %v", f)
	}

	d, err := c.GitDiff(ctx, connect.NewRequest(&flitv1.GitDiffRequest{SessionId: s.Id, Path: "later.txt"}))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(d.Msg.Diff, "+++ b/later.txt") || strings.Contains(d.Msg.Diff, "new.txt") || d.Msg.Truncated {
		t.Errorf("diff = %v", d.Msg)
	}
	_, err = c.GitDiff(ctx, connect.NewRequest(&flitv1.GitDiffRequest{SessionId: s.Id, Path: "../escape"}))
	if connect.CodeOf(err) != connect.CodeInvalidArgument {
		t.Errorf("escaping path: %v", err)
	}
}

func TestGitStatusNotARepo(t *testing.T) {
	cfg, _ := fakeConfig(t)
	c := start(t, cfg)
	ctx := context.Background()
	created, err := c.CreateSession(ctx, connect.NewRequest(&flitv1.CreateSessionRequest{WorkingDir: t.TempDir()}))
	if err != nil {
		t.Fatal(err)
	}
	if b := created.Msg.Session.BaseCommit; b != "" {
		t.Fatalf("base_commit = %q", b)
	}
	st, err := c.GitStatus(ctx, connect.NewRequest(&flitv1.GitStatusRequest{SessionId: created.Msg.Session.Id}))
	if err != nil {
		t.Fatal(err)
	}
	if st.Msg.IsRepo || len(st.Msg.Files) != 0 {
		t.Fatalf("status = %v", st.Msg)
	}
	if _, err := c.GitStatus(ctx, connect.NewRequest(&flitv1.GitStatusRequest{SessionId: "ses_nope"})); connect.CodeOf(err) != connect.CodeNotFound {
		t.Fatalf("unknown session: %v", err)
	}
}
