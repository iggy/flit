package export

import (
	"bytes"
	"context"
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/store"
)

func setup(t *testing.T) *store.Store {
	t.Helper()
	ctx := context.Background()
	st, err := store.Open(ctx, filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { st.Close() })
	priv := store.Project{ID: "proj_priv", TeamID: store.DefaultTeamID, Name: "private", Directory: "/srv/private"}
	if err := st.CreateProject(ctx, &priv); err != nil {
		t.Fatal(err)
	}
	if err := st.SetProjectExport(ctx, "proj_priv", false); err != nil {
		t.Fatal(err)
	}
	for _, s := range []store.Session{
		{ID: "ses_a", TeamID: store.DefaultTeamID, ProjectID: store.DefaultProjectID, WorkingDir: "/home/me/code/app"},
		{ID: "ses_p", TeamID: store.DefaultTeamID, ProjectID: "proj_priv", WorkingDir: "/srv/private"},
	} {
		if err := st.CreateSession(ctx, &s); err != nil {
			t.Fatal(err)
		}
	}
	base := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)
	sys := []byte(`{"role":"system","content":"You work in /home/me/code/app"}`)
	user := []byte(`{"role":"user","content":"read config, my key is sk-abcdefghijklmnopqrstuv"}`)
	call1 := []byte(`{"role":"assistant","content":"","tool_calls":[{"id":"c1","type":"function","function":{"name":"read","arguments":"{\"path\":\"/home/me/code/app/config.yaml\"}"}}]}`)
	tool1 := []byte(`{"role":"tool","content":"api_key: hunter2hunter2","tool_call_id":"c1"}`)
	tools := []byte(`[{"type":"function","function":{"name":"read","description":"Read","parameters":{"type":"object"}}}]`)
	rec := func(c store.ModelCall, msgs ...[]byte) {
		t.Helper()
		c.TeamID, c.Provider, c.FlitVersion = store.DefaultTeamID, "llama", "test"
		c.Params = json.RawMessage(`{"model":"` + c.Model + `"}`)
		if err := st.RecordModelCall(ctx, &c, msgs, tools); err != nil {
			t.Fatal(err)
		}
	}
	rec(store.ModelCall{ID: "msg_1", SessionID: "ses_a", ProjectID: store.DefaultProjectID, TurnID: "turn_1", CreatedAt: base,
		Model: "qwen", Response: json.RawMessage(call1), FinishReason: "tool_calls"}, sys, user)
	rec(store.ModelCall{ID: "msg_2", SessionID: "ses_a", ProjectID: store.DefaultProjectID, TurnID: "turn_1", CreatedAt: base.Add(time.Minute),
		Model: "qwen", Response: json.RawMessage(`{"role":"assistant","content":"Done."}`), FinishReason: "stop"}, sys, user, call1, tool1)
	rec(store.ModelCall{ID: "msg_3", SessionID: "ses_a", ProjectID: store.DefaultProjectID, TurnID: "turn_2", CreatedAt: base.Add(48 * time.Hour),
		Model: "big", Response: json.RawMessage(`{"role":"assistant","content":"Later."}`), FinishReason: "stop"}, sys)
	rec(store.ModelCall{ID: "msg_p", SessionID: "ses_p", ProjectID: "proj_priv", TurnID: "turn_p", CreatedAt: base,
		Model: "qwen", Response: json.RawMessage(`{"role":"assistant","content":"secret project"}`)}, sys)
	for _, r := range []store.Rating{
		{ID: "r1", SessionID: "ses_a", ProjectID: store.DefaultProjectID, TurnID: "turn_1", ModelCallID: "msg_2", Target: "turn", Good: true, Note: "solid", Model: "qwen"},
		{ID: "r2", SessionID: "ses_a", ProjectID: store.DefaultProjectID, TurnID: "turn_2", ModelCallID: "msg_3", Target: "model", Good: false, Model: "big"},
	} {
		if err := st.AddRating(ctx, &r); err != nil {
			t.Fatal(err)
		}
	}
	return st
}

func export(t *testing.T, st *store.Store, opts Options) ([]map[string]any, string) {
	t.Helper()
	var buf bytes.Buffer
	if _, err := Write(context.Background(), st, &buf, opts); err != nil {
		t.Fatal(err)
	}
	var out []map[string]any
	for _, line := range strings.Split(strings.TrimSpace(buf.String()), "\n") {
		if line == "" {
			continue
		}
		var m map[string]any
		if err := json.Unmarshal([]byte(line), &m); err != nil {
			t.Fatalf("bad JSONL line %q: %v", line, err)
		}
		out = append(out, m)
	}
	return out, buf.String()
}

func count(recs []map[string]any, typ string) int {
	n := 0
	for _, r := range recs {
		if r["type"] == typ {
			n++
		}
	}
	return n
}

func TestExport(t *testing.T) {
	st := setup(t)

	recs, raw := export(t, st, Options{})
	if count(recs, "model_call") != 3 || count(recs, "turn") != 2 || count(recs, "session") != 1 {
		t.Fatalf("counts: %d calls, %d turns, %d sessions", count(recs, "model_call"), count(recs, "turn"), count(recs, "session"))
	}
	if strings.Contains(raw, "secret project") {
		t.Fatal("opted-out project exported")
	}

	// The second call carries the full request, rebuilt from blobs.
	call2 := recs[1]
	if msgs := call2["messages"].([]any); len(msgs) != 4 || msgs[2].(map[string]any)["tool_calls"] == nil {
		t.Fatalf("call 2 messages = %v", call2["messages"])
	}
	if len(call2["tools"].([]any)) != 1 || call2["turn_ratings"].([]any)[0].(map[string]any)["note"] != "solid" {
		t.Fatalf("call 2 = %v", call2)
	}
	// The turn is the whole conversation in OpenAI chat format.
	var turn1 map[string]any
	for _, r := range recs {
		if r["type"] == "turn" && r["turn_id"] == "turn_1" {
			turn1 = r
		}
	}
	msgs := turn1["messages"].([]any)
	if len(msgs) != 5 || msgs[4].(map[string]any)["content"] != "Done." || len(turn1["model_calls"].([]any)) != 2 {
		t.Fatalf("turn 1 = %v", turn1)
	}

	// Filters.
	if recs, _ := export(t, st, Options{Rating: "good"}); count(recs, "turn") != 1 || count(recs, "model_call") != 2 {
		t.Errorf("good: %d turns %d calls", count(recs, "turn"), count(recs, "model_call"))
	}
	if recs, _ := export(t, st, Options{Rating: "bad", Records: []string{"model_call"}}); len(recs) != 1 || recs[0]["id"] != "msg_3" {
		t.Errorf("bad calls = %v", recs)
	}
	if recs, _ := export(t, st, Options{ExportFilter: store.ExportFilter{Model: "llama/big"}}); count(recs, "model_call") != 1 {
		t.Errorf("model filter = %d", count(recs, "model_call"))
	}
	until := time.Date(2026, 10, 2, 0, 0, 0, 0, time.UTC)
	if recs, _ := export(t, st, Options{ExportFilter: store.ExportFilter{Until: until}, Records: []string{"turn"}}); len(recs) != 1 {
		t.Errorf("until filter = %d turns", len(recs))
	}
	if recs, _ := export(t, st, Options{ExportFilter: store.ExportFilter{Project: "private"}}); len(recs) != 0 {
		t.Errorf("opted-out project by name = %d records", len(recs))
	}
	if _, err := Write(context.Background(), st, &bytes.Buffer{}, Options{Rating: "meh"}); err == nil {
		t.Error("bad rating filter accepted")
	}

	// Redaction.
	_, red := export(t, st, Options{Redact: true, Paths: map[string]string{"/home/me": "<home>"}})
	for _, leak := range []string{"/home/me", "sk-abcdefghijklmnopqrstuv", "hunter2hunter2"} {
		if strings.Contains(red, leak) {
			t.Errorf("redacted export contains %q", leak)
		}
	}
	for _, want := range []string{"<workdir>/config.yaml", "<redacted>", "api_key: <redacted>"} {
		if !strings.Contains(red, want) {
			t.Errorf("redacted export lacks %q", want)
		}
	}
	if !strings.Contains(raw, "/home/me/code/app") {
		t.Error("unredacted export lost paths")
	}
}

func TestRedact(t *testing.T) {
	for in, want := range map[string]string{
		`token ghp_abcdefghijklmnopqrstuvwxyz0123`:           `token <redacted>`,
		`AWS AKIAABCDEFGHIJKLMNOP here`:                      `AWS <redacted> here`,
		`Authorization: Bearer abcdefghijklmnopqrstu`:        `Authorization: <redacted>`,
		`"password": "correct-horse-battery"`:                `"password": "<redacted>"`,
		`C:\\Users\\me\\proj\\main.go`:                       `<home>\\proj\\main.go`,
		`plain text with no secrets and /usr/bin/env intact`: `plain text with no secrets and /usr/bin/env intact`,
	} {
		if got := Redact(in, map[string]string{`C:\Users\me`: "<home>"}); got != want {
			t.Errorf("Redact(%q) = %q, want %q", in, got, want)
		}
	}
}
