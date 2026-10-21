package main

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/memory"
	"github.com/iggy/flit/server/internal/store"
)

func TestLearnCommand(t *testing.T) {
	ctx := context.Background()
	model := llmtest.New(t)
	dir := t.TempDir()
	dataDir := filepath.Join(dir, "data")
	configPath := filepath.Join(dir, "config.yaml")
	if err := os.WriteFile(configPath, []byte("data_dir: "+dataDir+"\nproviders:\n  - name: local\n    base_url: "+model.BaseURL()+
		"\nagent:\n  tasks:\n    learning: {provider: local, model: learner}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	os.MkdirAll(dataDir, 0o700)
	st, err := store.Open(ctx, filepath.Join(dataDir, store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	sess := store.Session{ID: "ses_cli1", TeamID: store.DefaultTeamID, ProjectID: store.DefaultProjectID, WorkingDir: dir, State: flitv1.TaskState_TASK_STATE_DONE}
	if err := st.CreateSession(ctx, &sess); err != nil {
		t.Fatal(err)
	}
	for i, ev := range []*flitv1.Event{
		{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: "u1", Role: flitv1.Role_ROLE_USER}}},
		{Payload: &flitv1.Event_MessageDone{MessageDone: &flitv1.MessageDone{MessageId: "u1", Text: "always answer in French"}}},
	} {
		ev.SessionId, ev.Seq, ev.Time = sess.ID, int64(i+1), timestamppb.New(time.Now())
		if err := st.AppendEvent(ctx, sess, ev); err != nil {
			t.Fatal(err)
		}
	}
	st.Close()

	answer := llmtest.Response{Chunks: llmtest.Text(`{"proposals": [
		{"target": "user", "cue": "When answering", "lesson": "Answer in French.", "evidence": "T1"},
		{"target": "project", "lesson": "Nothing useful."}]}`)}

	// Dry run: shown, nothing stored.
	model.Push(answer)
	var out, errOut bytes.Buffer
	if err := run(ctx, []string{"learn", "--config", configPath, "--dry-run", "ses_cli"}, &out, &errOut); err != nil {
		t.Fatal(err, errOut.String())
	}
	if !strings.Contains(out.String(), "  + - **When answering:** Answer in French.") || !strings.Contains(out.String(), "Dry run") {
		t.Fatalf("dry run output:\n%s", out.String())
	}

	// Accept the first, reject the second.
	model.Push(answer)
	stdin = strings.NewReader("y\nn\n")
	t.Cleanup(func() { stdin = os.Stdin })
	out.Reset()
	if err := run(ctx, []string{"learn", "--config", configPath, "ses_cli1"}, &out, &errOut); err != nil {
		t.Fatal(err, errOut.String())
	}
	if !strings.Contains(out.String(), "1 accepted, 1 rejected") {
		t.Fatalf("output:\n%s", out.String())
	}
	data, err := os.ReadFile(memory.UserPath(dataDir))
	if err != nil || !strings.Contains(string(data), "Answer in French.") {
		t.Fatalf("user memory: %s %v", data, err)
	}
	if _, err := os.Stat(memory.ProjectPath(dataDir, store.DefaultProjectID)); !os.IsNotExist(err) {
		t.Fatal("rejected proposal was written")
	}

	out.Reset()
	if err := run(ctx, []string{"learn", "--config", configPath, "--pending"}, &out, &errOut); err != nil || !strings.Contains(out.String(), "No pending") {
		t.Fatalf("pending: %v\n%s", err, out.String())
	}
}
