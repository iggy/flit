package learn

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/memory"
	"github.com/iggy/flit/server/internal/store"
)

type fixture struct {
	svc     *Service
	st      *store.Store
	model   *llmtest.Server
	sess    store.Session
	repo    string
	dataDir string
}

// setup makes a store with one session in a git repo: the user asks for
// the tests, the agent runs them in the wrong place, the user corrects it.
func setup(t *testing.T, cfgMod func(*config.Config)) *fixture {
	t.Helper()
	ctx := context.Background()
	f := &fixture{dataDir: t.TempDir(), repo: t.TempDir(), model: llmtest.New(t)}
	if err := os.Mkdir(filepath.Join(f.repo, ".git"), 0o755); err != nil {
		t.Fatal(err)
	}
	st, err := store.Open(ctx, filepath.Join(f.dataDir, store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { st.Close() })
	f.st = st
	f.sess = store.Session{ID: "ses_test1", TeamID: store.DefaultTeamID, ProjectID: store.DefaultProjectID,
		WorkingDir: f.repo, Provider: "local", Model: "chat-model", State: flitv1.TaskState_TASK_STATE_DONE}
	if err := st.CreateSession(ctx, &f.sess); err != nil {
		t.Fatal(err)
	}
	var seq int64
	add := func(ev *flitv1.Event) {
		seq++
		ev.SessionId, ev.Seq, ev.Time = f.sess.ID, seq, timestamppb.New(time.Now())
		if err := st.AppendEvent(ctx, f.sess, ev); err != nil {
			t.Fatal(err)
		}
	}
	msg := func(id string, role flitv1.Role, text string) {
		add(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: id, Role: role}}})
		add(&flitv1.Event{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: id, Text: text}}})
	}
	msg("u1", flitv1.Role_ROLE_USER, "run the tests")
	msg("a1", flitv1.Role_ROLE_ASSISTANT, "Running them.")
	add(&flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{MessageId: "a1", ToolCallId: "c1", Name: "shell", Arguments: `{"command": "go test ./..."}`}}})
	add(&flitv1.Event{Payload: &flitv1.Event_ToolCallDone{ToolCallDone: &flitv1.ToolCallDone{ToolCallId: "c1", IsError: true, Result: "go: cannot find main module" + strings.Repeat(" padding", 2000)}}})
	msg("u2", flitv1.Role_ROLE_USER, "the go module is in server/, run it from there")
	msg("a2", flitv1.Role_ROLE_ASSISTANT, "All tests pass in server/.")
	if err := st.AddRating(ctx, &store.Rating{ID: "r1", SessionID: f.sess.ID, TeamID: f.sess.TeamID, ProjectID: f.sess.ProjectID,
		TurnID: "u1", Target: "turn", Good: false, Note: "wrong directory"}); err != nil {
		t.Fatal(err)
	}

	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "local", BaseURL: f.model.BaseURL()}}
	if cfgMod != nil {
		cfgMod(&cfg)
	}
	f.svc = &Service{Store: st, Config: func() config.Config { return cfg }, DataDir: f.dataDir}
	return f
}

func answer(text string) llmtest.Response { return llmtest.Response{Chunks: llmtest.Text(text)} }

func TestRunStoresProposals(t *testing.T) {
	f := setup(t, func(c *config.Config) {
		c.Agent.Tasks = map[string]config.TaskModel{"learning": {Provider: "local", Model: "learner"}}
	})
	f.model.Push(answer(`{"proposals": [
		{"action": "add", "target": "project", "cue": "When running the Go tests", "lesson": "Run go test from server/, where go.mod is.", "evidence": "T1, T2"},
		{"action": "add", "target": "user", "cue": "", "lesson": "", "evidence": "T1"},
		{"action": "update", "target": "project", "entry": "P7", "lesson": "x"},
		{"action": "add", "target": "skill", "skill": "Run Go Tests", "description": "Run the server's Go tests.", "body": "1. cd server\n2. go test ./..."}
	]}`))
	res, err := f.svc.Run(context.Background(), f.sess.ID, false)
	if err != nil {
		t.Fatal(err)
	}
	if res.Model != "learner" {
		t.Errorf("model = %q, want the learning task's", res.Model)
	}
	if len(res.Proposals) != 2 || len(res.Dropped) != 2 {
		t.Fatalf("proposals %+v, dropped %q", res.Proposals, res.Dropped)
	}

	// What the model saw: memory, transcript with trimmed tool output and
	// the rating.
	reqs := f.model.Requests()
	user := reqs[0].Messages[1].Content
	for _, want := range []string{"### user\n(empty)", "### project (Scratch)", "T1 user: run the tests", "T1 tool shell {\"command\":\"go test ./...\"}",
		"T1 error: go: cannot find main module", "bytes cut", `the user rated this turn bad: "wrong directory"`, "T2 user: the go module is in server/"} {
		if !strings.Contains(user, want) {
			t.Errorf("prompt lacks %q:\n%s", want, user)
		}
	}

	p := res.Proposals[0]
	if p.Target != TargetProject || p.Path != memory.ProjectPath(f.dataDir, f.sess.ProjectID) ||
		p.NewText != "- **When running the Go tests:** Run go test from server/, where go.mod is. _(evidence: ses_test1 T1, T2)_" {
		t.Errorf("memory proposal = %+v", p)
	}
	sk := res.Proposals[1]
	if sk.Skill != "run-go-tests" || sk.Action != "add" || sk.Path != filepath.Join(f.repo, ".agents", "skills", "run-go-tests", "SKILL.md") ||
		!strings.HasPrefix(sk.NewText, "---\nname: run-go-tests\ndescription: \"Run the server's Go tests.\"\n---\n\n1. cd server") {
		t.Errorf("skill proposal = %+v", sk)
	}

	// Stored as pending; nothing written yet.
	pending, err := f.st.ListProposals(context.Background(), f.sess.ID, false)
	if err != nil || len(pending) != 2 {
		t.Fatalf("pending = %d, %v", len(pending), err)
	}
	if _, err := os.Stat(p.Path); !os.IsNotExist(err) {
		t.Fatalf("memory file written before accepting: %v", err)
	}

	// Accept writes; reject doesn't.
	if _, err := f.svc.Accept(context.Background(), p.ID, nil); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(p.Path)
	if !strings.Contains(string(data), "# Project memory: Scratch") || !strings.HasSuffix(string(data), p.NewText+"\n") {
		t.Fatalf("project memory:\n%s", data)
	}
	if _, err := f.svc.Accept(context.Background(), p.ID, nil); err != ErrDecided {
		t.Fatalf("second accept: %v", err)
	}
	if _, err := f.svc.Reject(context.Background(), sk.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(sk.Path); !os.IsNotExist(err) {
		t.Fatal("rejected skill was written")
	}
	all, _ := f.st.ListProposals(context.Background(), "", true)
	if len(all) != 2 || all[0].Status != store.ProposalAccepted || all[1].Status != store.ProposalRejected {
		t.Fatalf("after deciding: %+v", all)
	}
}

func TestRunUpdatesAndRemovesEntries(t *testing.T) {
	f := setup(t, nil)
	userPath := memory.UserPath(f.dataDir)
	if err := memory.WriteFile(userPath, []byte("# User memory\n\n- Prefers tabs.\n- Likes long answers.\n")); err != nil {
		t.Fatal(err)
	}
	f.model.Push(answer(`{"proposals": [
		{"action": "update", "target": "user", "entry": "U1", "cue": "When formatting", "lesson": "Prefers tabs in Go and Makefiles only."},
		{"action": "remove", "target": "user", "entry": "u2", "evidence": "T2"},
		{"action": "update", "target": "user", "entry": "U2", "lesson": "Likes long answers."}
	]}`))
	res, err := f.svc.Run(context.Background(), f.sess.ID, false)
	if err != nil {
		t.Fatal(err)
	}
	if res.Model != "chat-model" {
		t.Errorf("without a learning task the session's model should run it, got %q", res.Model)
	}
	if len(res.Proposals) != 2 || len(res.Dropped) != 1 {
		t.Fatalf("proposals %+v dropped %q (a no-op update should be dropped)", res.Proposals, res.Dropped)
	}
	if !strings.Contains(f.model.Requests()[0].Messages[1].Content, "U1. Prefers tabs.\nU2. Likes long answers.") {
		t.Errorf("entries aren't numbered in the prompt")
	}
	edited := "- **When formatting:** tabs in Go only."
	if _, err := f.svc.Accept(context.Background(), res.Proposals[0].ID, &edited); err != nil {
		t.Fatal(err)
	}
	if _, err := f.svc.Accept(context.Background(), res.Proposals[1].ID, nil); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(userPath)
	if got := string(data); got != "# User memory\n\n"+edited+"\n" {
		t.Fatalf("user memory:\n%q", got)
	}
}

func TestAcceptFailsWhenEntryChanged(t *testing.T) {
	f := setup(t, nil)
	userPath := memory.UserPath(f.dataDir)
	_ = memory.WriteFile(userPath, []byte("- old\n"))
	f.model.Push(answer(`{"proposals": [{"action": "remove", "target": "user", "entry": "U1"}]}`))
	res, err := f.svc.Run(context.Background(), f.sess.ID, false)
	if err != nil || len(res.Proposals) != 1 {
		t.Fatal(err, res)
	}
	_ = memory.WriteFile(userPath, []byte("- edited by hand\n"))
	if _, err := f.svc.Accept(context.Background(), res.Proposals[0].ID, nil); err != memory.ErrChanged {
		t.Fatalf("accept after a hand edit: %v", err)
	}
	if got, _ := f.st.GetProposal(context.Background(), res.Proposals[0].ID); got.Status != store.ProposalPending {
		t.Fatalf("status = %s", got.Status)
	}
}

func TestRunRetriesOnceThenFails(t *testing.T) {
	f := setup(t, nil)
	f.model.Push(answer("The session went fine, the agent fixed it."), answer("```json\n{\"proposals\": []}\n```"))
	res, err := f.svc.Run(context.Background(), f.sess.ID, false)
	if err != nil || len(res.Proposals) != 0 {
		t.Fatalf("retry: %v %+v", err, res)
	}
	reqs := f.model.Requests()
	if len(reqs) != 2 || !strings.Contains(reqs[1].Messages[3].Content, "couldn't be read") {
		t.Fatalf("retry request: %+v", reqs)
	}

	f.model.Push(answer("hmm"), answer("still not json"))
	if _, err := f.svc.Run(context.Background(), f.sess.ID, false); err == nil {
		t.Fatal("two unreadable answers should fail")
	}
}

func TestDryRunStoresNothing(t *testing.T) {
	f := setup(t, nil)
	f.model.Push(answer(`{"proposals": [{"target": "project", "lesson": "Run go test from server/."}]}`))
	res, err := f.svc.Run(context.Background(), f.sess.ID, true)
	if err != nil || len(res.Proposals) != 1 || res.Proposals[0].Action != "add" {
		t.Fatalf("dry run: %v %+v", err, res)
	}
	if list, _ := f.st.ListProposals(context.Background(), "", true); len(list) != 0 {
		t.Fatalf("dry run stored %d proposals", len(list))
	}
}

func TestSkillUpdateAndAccept(t *testing.T) {
	f := setup(t, nil)
	dir := filepath.Join(f.repo, ".agents", "skills", "deploy")
	old := "---\nname: deploy\ndescription: Deploy it.\n---\n\nRun make deploy.\n"
	if err := memory.WriteFile(filepath.Join(dir, "SKILL.md"), []byte(old)); err != nil {
		t.Fatal(err)
	}
	f.model.Push(answer(`{"proposals": [{"action": "add", "target": "skill", "skill": "deploy", "description": "Deploy the app.", "body": "1. make test\n2. make deploy"}]}`))
	res, err := f.svc.Run(context.Background(), f.sess.ID, false)
	if err != nil || len(res.Proposals) != 1 {
		t.Fatal(err, res)
	}
	p := res.Proposals[0]
	if p.Action != "update" || p.OldText != old || p.Path != filepath.Join(dir, "SKILL.md") {
		t.Fatalf("an add of an existing skill should be an update of it: %+v", p)
	}
	bad := "no frontmatter"
	if _, err := f.svc.Accept(context.Background(), p.ID, &bad); err == nil {
		t.Fatal("an invalid SKILL.md was accepted")
	}
	if _, err := f.svc.Accept(context.Background(), p.ID, nil); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(p.Path)
	if !strings.Contains(string(data), "1. make test") {
		t.Fatalf("SKILL.md:\n%s", data)
	}
}

func TestRenderFitsBudget(t *testing.T) {
	var ts []turn
	for i := range 40 {
		ts = append(ts, turn{lines: []line{
			{kind: "user", text: fmt.Sprintf("request %d", i)},
			{kind: "tool", head: "result", text: strings.Repeat("x", 5000)},
		}})
	}
	out := render(ts, 3000)
	if len(out) > 3000 {
		t.Fatalf("rendered %d bytes", len(out))
	}
	for _, want := range []string{"T1 user: request 0", "left out to fit", "T40 user: request 39"} {
		if !strings.Contains(out, want) {
			t.Errorf("render lacks %q:\n%s", want, out)
		}
	}
	if small := render(ts[:2], 100000); !strings.Contains(small, strings.Repeat("x", 500)) {
		t.Errorf("a roomy budget should keep more tool output")
	}
}
