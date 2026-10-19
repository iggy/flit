package store

import (
	"context"
	"errors"
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
	list, err := s.ListSessions(ctx, "", 10, 0)
	if err != nil || len(list) != 1 || list[0].Model != "big" {
		t.Fatalf("list = %+v, %v", list, err)
	}
}

func TestProjects(t *testing.T) {
	s, _ := open(t)
	ctx := context.Background()
	p := Project{ID: "proj_a", TeamID: DefaultTeamID, Name: "alpha", Directory: "/src/a"}
	if err := s.CreateProject(ctx, &p); err != nil {
		t.Fatal(err)
	}
	dup := Project{ID: "proj_b", TeamID: DefaultTeamID, Name: "again", Directory: "/src/a"}
	if err := s.CreateProject(ctx, &dup); !errors.Is(err, ErrExists) {
		t.Fatalf("duplicate directory: %v", err)
	}
	sess := Session{ID: "ses_1", TeamID: DefaultTeamID, ProjectID: DefaultProjectID, WorkingDir: "/src/a", MCPServers: []string{"x", "y"}}
	if err := s.CreateSession(ctx, &sess); err != nil {
		t.Fatal(err)
	}
	if got, _ := s.GetSession(ctx, "ses_1"); len(got.MCPServers) != 2 || got.MCPServers[1] != "y" {
		t.Fatalf("mcp servers = %v", got.MCPServers)
	}
	if err := s.MoveSession(ctx, "ses_1", "proj_a"); err != nil {
		t.Fatal(err)
	}
	if err := s.SetMCPServers(ctx, "ses_1", nil); err != nil {
		t.Fatal(err)
	}
	if got, _ := s.GetSession(ctx, "ses_1"); got.ProjectID != "proj_a" || got.MCPServers != nil {
		t.Fatalf("after move = %+v", got)
	}
	list, err := s.ListProjects(ctx, DefaultTeamID)
	if err != nil || len(list) != 2 || list[0].ID != DefaultProjectID || list[1].SessionCount != 1 || list[0].SessionCount != 0 {
		t.Fatalf("projects = %+v, %v", list, err)
	}
	if in, _ := s.ListSessions(ctx, "proj_a", 10, 0); len(in) != 1 {
		t.Fatalf("filtered sessions = %v", in)
	}
	if in, _ := s.ListSessions(ctx, DefaultProjectID, 10, 0); len(in) != 0 {
		t.Fatalf("scratch sessions = %v", in)
	}
}

func TestModelPrefs(t *testing.T) {
	st, _ := open(t)
	must := func(t *testing.T, err error) {
		t.Helper()
		if err != nil {
			t.Fatal(err)
		}
	}
	ctx := context.Background()
	a, b := ModelKey{"local", "qwen"}, ModelKey{"or", "glm"}
	t1 := time.Unix(1000, 0)
	must(t, st.SetFavorite(ctx, DefaultTeamID, a, true))
	must(t, st.TouchModel(ctx, DefaultTeamID, a, t1))
	must(t, st.TouchModel(ctx, DefaultTeamID, b, t1.Add(time.Hour)))
	must(t, st.TouchModel(ctx, DefaultTeamID, b, t1)) // older use doesn't move it back
	must(t, st.SetFavorite(ctx, "team_other", b, true))
	prefs, err := st.ModelPrefs(ctx, DefaultTeamID)
	if err != nil {
		t.Fatal(err)
	}
	if p := prefs[a]; !p.Favorite || !p.LastUsed.Equal(t1) {
		t.Fatalf("a = %+v", p)
	}
	if p := prefs[b]; p.Favorite || !p.LastUsed.Equal(t1.Add(time.Hour)) {
		t.Fatalf("b = %+v (another team's star leaked?)", p)
	}
	must(t, st.SetFavorite(ctx, DefaultTeamID, a, false))
	prefs, _ = st.ModelPrefs(ctx, DefaultTeamID)
	if p := prefs[a]; p.Favorite || !p.LastUsed.Equal(t1) {
		t.Fatalf("unstarred a = %+v", p)
	}
}
