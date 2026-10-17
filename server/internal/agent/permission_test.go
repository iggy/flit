package agent

import (
	"context"
	"io"
	"log/slog"
	"strings"
	"testing"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/models"
	"github.com/iggy/flit/server/internal/store"
)

func TestYolo(t *testing.T) {
	h := newHarness(t)
	h.cfg.Shell.Deny = []string{"rm *"}
	sess := h.create()
	if sess.Yolo {
		t.Fatal("yolo on by default")
	}
	got, err := h.m.SetYolo(context.Background(), sess.ID, true, "phone")
	if err != nil || !got.Yolo {
		t.Fatalf("SetYolo: %+v, %v", got, err)
	}
	if again, _ := h.m.Get(context.Background(), sess.ID); !again.Yolo {
		t.Fatal("yolo not stored")
	}

	h.llm.Push(shellCall("echo yolo-ran"), shellCall("rm -f nothing"), llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	if y, ok := find(evs, (*flitv1.Event).GetYoloChanged, notNil); !ok || !y.Yolo || y.Client != "phone" {
		t.Fatalf("yolo_changed %+v", y)
	}
	if _, ok := find(evs, (*flitv1.Event).GetPromptRequested, notNil); ok {
		t.Fatal("yolo session prompted")
	}
	var results []string
	for _, ev := range evs {
		if d := ev.GetToolCallDone(); d != nil {
			results = append(results, d.Result)
		}
	}
	if len(results) != 2 || !strings.Contains(results[0], "yolo-ran") || !strings.Contains(results[1], "denied") {
		t.Fatalf("results %q", results)
	}

	h.cfg.Shell.Yolo = true
	if s := h.create(); !s.Yolo {
		t.Fatal("shell.yolo not applied to new sessions")
	}
	off := false
	if s, _ := h.m.Create(context.Background(), CreateOptions{WorkingDir: h.dir, Yolo: &off}); s.Yolo {
		t.Fatal("CreateOptions.Yolo ignored")
	}
}

func TestPermissionCheck(t *testing.T) {
	h := newHarness(t)
	h.cfg.Agent.Tasks = map[string]config.TaskModel{"permission": {Provider: "fake", Model: "guard", Reasoning: "off"}}
	h.cfg.Shell.Allow = []string{"echo plain"}
	verdict := func(v, reason string) llmtest.Response {
		return llmtest.Response{Chunks: llmtest.Text(`{"verdict": "` + v + `", "reason": "` + reason + `"}`)}
	}
	h.llm.Push(
		shellCall("echo checked"), verdict("safe", "just prints"),
		shellCall("echo blocked"), verdict("block", "looks evil"),
		shellCall("echo plain"), // allowed: no check
		llmtest.Response{Chunks: llmtest.Text("done")},
	)
	sess := h.create()
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	evs := w.snapshot()
	if _, ok := find(evs, (*flitv1.Event).GetPromptRequested, notNil); ok {
		t.Fatal("prompted")
	}
	var checks []*flitv1.PermissionCheck
	var results []*flitv1.ToolCallDone
	for _, ev := range evs {
		if c := ev.GetPermissionCheck(); c != nil {
			checks = append(checks, c)
		}
		if d := ev.GetToolCallDone(); d != nil {
			results = append(results, d)
		}
	}
	if len(checks) != 2 || checks[0].Verdict != flitv1.PermissionVerdict_PERMISSION_VERDICT_SAFE ||
		checks[0].Command != "echo checked" || checks[0].Model != "guard" || checks[0].ModelCallId == "" || checks[0].TurnId == "" ||
		checks[1].Verdict != flitv1.PermissionVerdict_PERMISSION_VERDICT_BLOCK || checks[1].Reason != "looks evil" {
		t.Fatalf("checks %+v", checks)
	}
	if len(results) != 3 || results[0].IsError || !results[1].IsError || !strings.Contains(results[1].Result, "looks evil") || results[2].IsError {
		t.Fatalf("results %+v", results)
	}
	reqs := h.llm.Requests()
	if len(reqs) != 6 || reqs[1].Model != "guard" || len(reqs[1].Tools) != 0 || !strings.Contains(reqs[1].Messages[1].Content, "echo checked") {
		t.Fatalf("requests %+v", reqs)
	}

	// The check's model calls are recorded as task "permission".
	var tasks []string
	if err := h.st.ExportModelCalls(context.Background(), store.ExportFilter{}, func(c store.ExportCall) error {
		tasks = append(tasks, c.Task)
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	if strings.Join(tasks, ",") != "chat,permission,chat,permission,chat,chat" {
		t.Fatalf("recorded tasks %q", tasks)
	}
}

func TestPermissionCheckAsks(t *testing.T) {
	for _, tc := range []struct{ answer, reason string }{
		{`{"verdict":"ask","reason":"deletes files"}`, "deletes files"},
		{"I think it is fine", "the safety check gave no readable answer"},
	} {
		h := newHarness(t)
		h.cfg.Agent.Tasks = map[string]config.TaskModel{"permission": {Provider: "fake", Model: "guard"}}
		h.llm.Push(shellCall("echo hi"), llmtest.Response{Chunks: llmtest.Text(tc.answer)}, llmtest.Response{Chunks: llmtest.Text("ok")})
		sess := h.create()
		w := h.watch(sess.ID, 0)
		if _, err := h.m.Send(context.Background(), sess.ID, "go"); err != nil {
			t.Fatal(err)
		}
		req := w.waitFor("prompt", func(ev *flitv1.Event) bool { return ev.GetPromptRequested() != nil }).GetPromptRequested()
		if req.SafetyReason != tc.reason {
			t.Fatalf("%q: safety reason %q", tc.answer, req.SafetyReason)
		}
		if err := h.m.AnswerPrompt(context.Background(), sess.ID, req.PromptId, Answer{Allow: true}); err != nil {
			t.Fatal(err)
		}
		w.waitTurnEnd()
	}
}

func TestParseVerdict(t *testing.T) {
	for text, want := range map[string]string{
		`{"verdict":"safe","reason":"reads"}`:                       "safe",
		"```json\n{\"verdict\": \"BLOCK\", \"reason\": \"x\"}\n```": "block",
		`{"verdict":"maybe"}`:                                       "error",
		``:                                                          "error",
	} {
		if got := parseVerdict(text).Verdict.String(); got != want {
			t.Errorf("%q: got %s, want %s", text, got, want)
		}
	}
}

func TestApplyReasoning(t *testing.T) {
	cfg := config.Default()
	cfg.Providers = []config.Provider{
		{Name: "llama", BaseURL: "http://localhost:8080/v1", Kind: "llamacpp"},
		{Name: "oai", BaseURL: "https://api.openai.com/v1", Kind: "openai"},
	}
	m := &Manager{Catalog: models.NewCatalog(func() config.Config { return cfg }, func() string { return "" },
		slog.New(slog.NewTextHandler(io.Discard, nil)))}
	for _, tc := range []struct {
		provider, effort string
		want             string
	}{
		{"llama", "off", `{"enable_thinking":false}|`},
		{"oai", "off", `|`},
		{"llama", "low", `|low`},
		{"oai", "high", `|high`}, // unknown model: sent
		{"oai", "", `|`},
	} {
		var req llm.Request
		m.applyReasoning(&req, tc.provider, "m", tc.effort)
		got := "|" + req.ReasoningEffort
		if req.ChatTemplateKwargs != nil {
			got = `{"enable_thinking":false}` + got
		}
		if got != tc.want {
			t.Errorf("%s %q: got %s, want %s", tc.provider, tc.effort, got, tc.want)
		}
	}
}
