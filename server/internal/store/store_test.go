package store

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

func open(t *testing.T) (*Store, string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), FileName)
	s, err := Open(context.Background(), path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { s.Close() })
	return s, path
}

func TestDefaultsAndReopen(t *testing.T) {
	s, path := open(t)
	ctx := context.Background()
	var team, project string
	if err := s.db.QueryRowContext(ctx, `SELECT t.name, p.name FROM projects p JOIN teams t ON t.id = p.team_id WHERE p.id = ?`,
		DefaultProjectID).Scan(&team, &project); err != nil {
		t.Fatal(err)
	}
	if team != "Personal" || project != "Scratch" {
		t.Fatalf("defaults = %q/%q", team, project)
	}
	s.Close()

	// Reopening is a no-op migration and doesn't duplicate defaults.
	s2, err := Open(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	defer s2.Close()
	var n int
	if err := s2.db.QueryRowContext(ctx, `SELECT count(*) FROM teams`).Scan(&n); err != nil || n != 1 {
		t.Fatalf("teams = %d, %v", n, err)
	}
}

func TestSessionsAndEvents(t *testing.T) {
	s, _ := open(t)
	ctx := context.Background()

	sess := Session{ID: "ses_1", TeamID: DefaultTeamID, ProjectID: DefaultProjectID, Title: "t",
		WorkingDir: "/tmp", Provider: "local", Model: "m", State: flitv1.TaskState_TASK_STATE_IDLE}
	if err := s.CreateSession(ctx, &sess); err != nil {
		t.Fatal(err)
	}
	if _, err := s.GetSession(ctx, "nope"); err != ErrNotFound {
		t.Fatalf("missing session err = %v", err)
	}

	evs := []*flitv1.Event{
		{Payload: &flitv1.Event_TaskStateChanged{TaskStateChanged: &flitv1.TaskStateChanged{State: flitv1.TaskState_TASK_STATE_WORKING}}},
		{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: "m", Text: "hi"}}},
		{Payload: &flitv1.Event_TextDelta{TextDelta: &flitv1.TextDelta{MessageId: "m", Text: " there"}}},
	}
	for i, ev := range evs {
		ev.SessionId, ev.Seq, ev.Time = sess.ID, int64(i+1), timestamppb.New(time.Now())
		if err := s.AppendEvent(ctx, sess, ev); err != nil {
			t.Fatal(err)
		}
	}

	// Gaps and replays are rejected.
	bad := proto.Clone(evs[0]).(*flitv1.Event)
	bad.Seq = 9
	if err := s.AppendEvent(ctx, sess, bad); err == nil {
		t.Fatal("out-of-order append succeeded")
	}
	bad.Seq = 2
	if err := s.AppendEvent(ctx, sess, bad); err == nil {
		t.Fatal("duplicate seq append succeeded")
	}

	got, err := s.GetSession(ctx, sess.ID)
	if err != nil {
		t.Fatal(err)
	}
	if got.LastSeq != 3 || got.State != flitv1.TaskState_TASK_STATE_WORKING {
		t.Fatalf("session after appends = %+v", got)
	}

	tail, err := s.Events(ctx, sess.ID, 2, 1<<62)
	if err != nil {
		t.Fatal(err)
	}
	if len(tail) != 2 || !proto.Equal(tail[0], evs[1]) || !proto.Equal(tail[1], evs[2]) {
		t.Fatalf("events from 2 = %v", tail)
	}
	if k := Kind(evs[1]); k != "text_delta" {
		t.Fatalf("Kind = %q", k)
	}

	if err := s.SetModel(ctx, sess.ID, "cloud", "big"); err != nil {
		t.Fatal(err)
	}
	list, err := s.ListSessions(ctx, 10, 0)
	if err != nil || len(list) != 1 || list[0].Model != "big" {
		t.Fatalf("list = %+v, %v", list, err)
	}
}
