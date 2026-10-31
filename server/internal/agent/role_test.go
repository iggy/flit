package agent

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

// writeRoles adds roles to a fresh roles directory for h's manager.
func writeRoles(t *testing.T, h *harness, files map[string]string) {
	t.Helper()
	dir := t.TempDir()
	for name, body := range files {
		if err := os.WriteFile(filepath.Join(dir, name+".md"), []byte(body), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	h.m.RolesDir = func() string { return dir }
}

func TestSetRoleSwitchesPromptAndModel(t *testing.T) {
	h := newHarness(t)
	writeRoles(t, h, map[string]string{
		"planner":     "---\nprovider: other\nmodel: plan-model\neffort: high\n---\nPlan only; don't edit files.",
		"implementer": "---\nprovider: fake\nmodel: build-model\nmemory_file: BUILD.md\n---\nImplement the plan.",
	})
	os.WriteFile(filepath.Join(h.dir, "BUILD.md"), []byte("Run go test."), 0o600)
	sess, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Role: "planner"})
	if err != nil {
		t.Fatal(err)
	}
	w := h.watch(sess.ID, 0)

	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("the plan")})
	if _, err := h.m.Send(context.Background(), sess.ID, "plan it"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()

	if _, err := h.m.SetRole(context.Background(), sess.ID, "nope", "phone"); !errors.Is(err, ErrInvalid) {
		t.Fatalf("unknown role: %v", err)
	}
	got, err := h.m.SetRole(context.Background(), sess.ID, "implementer", "phone")
	if err != nil {
		t.Fatal(err)
	}
	// The model followed the role (the session had the planner's); effort
	// too (the implementer names none, and the config's is empty).
	if got.Role != "implementer" || got.Provider != "fake" || got.Model != "build-model" || got.Effort != "" {
		t.Fatalf("after SetRole = %+v", got)
	}
	rc := w.waitFor("role change", func(ev *flitv1.Event) bool { return ev.GetRoleChanged() != nil }).GetRoleChanged()
	if rc.Role != "implementer" || rc.PreviousRole != "planner" || rc.Client != "phone" {
		t.Fatalf("role changed = %v", rc)
	}
	mc := w.waitFor("model change", func(ev *flitv1.Event) bool {
		return ev.GetModelChanged().GetModel() == "build-model"
	}).GetModelChanged()
	if mc.Provider != "fake" || mc.Effort != "" {
		t.Fatalf("model changed = %v", mc)
	}
	stored, _ := h.st.GetSession(context.Background(), sess.ID)
	if stored.Role != "implementer" || stored.Model != "build-model" {
		t.Fatalf("stored = %+v", stored)
	}

	cur, _ := h.m.Get(context.Background(), sess.ID)
	w = h.watch(sess.ID, cur.LastSeq+1)
	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("done")})
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	reqs := h.llm.Requests()
	if len(reqs) != 2 {
		t.Fatalf("%d requests", len(reqs))
	}
	first, next := reqs[0].Messages[0].Content, reqs[1].Messages[0].Content
	if !strings.Contains(first, "Plan only") || strings.Contains(first, "Implement the plan") {
		t.Fatalf("first system prompt:\n%s", first)
	}
	if strings.Contains(next, "Plan only") || !strings.Contains(next, "Implement the plan") ||
		!strings.Contains(next, `"implementer"`) || !strings.Contains(next, "Run go test.") {
		t.Fatalf("system prompt after SetRole:\n%s", next)
	}
	if reqs[1].Model != "build-model" || reqs[1].ReasoningEffort != "" {
		t.Fatalf("request after SetRole: model %q effort %q", reqs[1].Model, reqs[1].ReasoningEffort)
	}
	// Earlier messages are kept as they were.
	if msgs := reqs[1].Messages; len(msgs) != 4 || msgs[1].Content != "plan it" || msgs[2].Content != "the plan" {
		t.Fatalf("history after SetRole = %+v", msgs)
	}

	// The same role again is a no-op; none clears it and returns to the
	// config's model.
	cur, _ = h.m.Get(context.Background(), sess.ID)
	w = h.watch(sess.ID, cur.LastSeq+1)
	if _, err := h.m.SetRole(context.Background(), sess.ID, "implementer", ""); err != nil {
		t.Fatal(err)
	}
	got, err = h.m.SetRole(context.Background(), sess.ID, "", "")
	if err != nil || got.Role != "" || got.Model != "test-model" {
		t.Fatalf("clear role = %+v, %v", got, err)
	}
	rc = w.waitFor("role cleared", func(ev *flitv1.Event) bool {
		return ev.GetRoleChanged() != nil && ev.GetRoleChanged().Role == ""
	}).GetRoleChanged()
	if rc.PreviousRole != "implementer" {
		t.Fatalf("cleared = %v", rc)
	}
	n := 0
	for _, ev := range w.snapshot() {
		if ev.GetRoleChanged() != nil {
			n++
		}
	}
	if n != 1 {
		t.Fatalf("%d role changes after the no-op, want 1", n)
	}
}

func TestSetRoleKeepsChosenModel(t *testing.T) {
	h := newHarness(t)
	writeRoles(t, h, map[string]string{
		"planner":     "---\nprovider: other\nmodel: plan-model\neffort: high\n---\nPlan.",
		"implementer": "---\nprovider: fake\nmodel: build-model\neffort: low\n---\nBuild.",
	})
	sess, err := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Role: "planner"})
	if err != nil {
		t.Fatal(err)
	}
	// The user picked a model of their own; the effort is still the role's.
	if _, err := h.m.SetModel(context.Background(), sess.ID, "other", "my-model"); err != nil {
		t.Fatal(err)
	}
	got, err := h.m.SetRole(context.Background(), sess.ID, "implementer", "")
	if err != nil {
		t.Fatal(err)
	}
	if got.Provider != "other" || got.Model != "my-model" || got.Effort != "low" {
		t.Fatalf("after SetRole = %+v", got)
	}
}

func TestSetRoleUnknownSession(t *testing.T) {
	h := newHarness(t)
	writeRoles(t, h, map[string]string{"planner": "Plan."})
	if _, err := h.m.SetRole(context.Background(), "ses_nope", "planner", ""); !errors.Is(err, ErrNotFound) {
		t.Fatalf("unknown session: %v", err)
	}
}
