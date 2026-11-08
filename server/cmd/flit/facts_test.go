package main

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
)

func TestFactsCommand(t *testing.T) {
	ctx := context.Background()
	dir := t.TempDir()
	dataDir := filepath.Join(dir, "data")
	configPath := filepath.Join(dir, "config.yaml")
	if err := os.WriteFile(configPath, []byte("data_dir: "+dataDir+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	os.MkdirAll(dataDir, 0o700)
	st, err := store.Open(ctx, filepath.Join(dataDir, store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	for i, id := range []string{"ses_a", "ses_b", "ses_c", "ses_d"} {
		sess := store.Session{ID: id, TeamID: store.DefaultTeamID, ProjectID: store.DefaultProjectID, WorkingDir: dir,
			State: flitv1.TaskState_TASK_STATE_DONE, CreatedAt: time.Unix(int64(i+1), 0)}
		if err := st.CreateSession(ctx, &sess); err != nil {
			t.Fatal(err)
		}
		var evs []*flitv1.Event
		add := func(call, cmd, result string) {
			args, _ := json.Marshal(map[string]string{"command": cmd})
			evs = append(evs,
				&flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{ToolCallId: call, Name: "shell", Arguments: string(args)}}},
				&flitv1.Event{Payload: &flitv1.Event_ToolCallDone{ToolCallDone: &flitv1.ToolCallDone{ToolCallId: call, Result: result}}},
			)
		}
		evs = append(evs, &flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{MessageId: "u", Role: flitv1.Role_ROLE_USER}}})
		add("c1", "tsc", "bash: tsc: command not found\n[exit code 127]")
		add("c2", "npx tsc", "[exit code 0]")
		for j, ev := range evs {
			ev.SessionId, ev.Seq, ev.Time = id, int64(j+1), timestamppb.Now()
			if err := st.AppendEvent(ctx, sess, ev); err != nil {
				t.Fatal(err)
			}
		}
	}
	st.Close()

	run := func(args ...string) string {
		t.Helper()
		var out, errOut bytes.Buffer
		if err := factsCmd(ctx, &out, &errOut, append(args, "--config", configPath), configPath); err != nil {
			t.Fatalf("%v: %v\n%s", args, err, errOut.String())
		}
		return out.String()
	}
	if got := run(); !strings.Contains(got, "No facts") {
		t.Fatalf("before rebuild:\n%s", got)
	}
	got := run("--rebuild", "--project", "Scratch")
	for _, want := range []string{"Read 4 sessions.", "active, in the prompt", "use `npx tsc`", "evidence: ses_a T1"} {
		if !strings.Contains(got, want) {
			t.Errorf("lacks %q:\n%s", want, got)
		}
	}
	id := got[strings.Index(got, "fct_"):]
	id = id[:strings.IndexByte(id, ' ')]

	var out, errOut bytes.Buffer
	if err := factsCmd(ctx, &out, &errOut, []string{"forget", "--config", configPath, id}, configPath); err != nil {
		t.Fatalf("forget: %v\n%s", err, errOut.String())
	}
	if got := run(); !strings.Contains(got, "forgotten") {
		t.Fatalf("after forget:\n%s", got)
	}
	if got := run("--rebuild"); !strings.Contains(got, "forgotten") {
		t.Fatalf("rebuild brought it back:\n%s", got)
	}
}
