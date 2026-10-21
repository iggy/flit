package agent

import (
	"context"
	"strings"
	"testing"

	"github.com/iggy/flit/server/internal/llm/llmtest"
	"github.com/iggy/flit/server/internal/memory"
)

func TestMemoryLayersInSystemPrompt(t *testing.T) {
	h := newHarness(t)
	h.m.DataDir = t.TempDir()
	h.mu.Lock()
	h.cfg.Learning.MemoryMaxBytes = 60
	h.mu.Unlock()
	sess := h.create()
	user := "- **When answering:** be brief.\n- " + strings.Repeat("x", 100) + "\n"
	if err := memory.WriteFile(memory.UserPath(h.m.DataDir), []byte(user)); err != nil {
		t.Fatal(err)
	}
	if err := memory.WriteFile(memory.ProjectPath(h.m.DataDir, sess.ProjectID), []byte("- Tests live in server/.\n")); err != nil {
		t.Fatal(err)
	}
	if err := memory.WriteFile(memory.ProjectPath(h.m.DataDir, "other-project"), []byte("- Not this one.\n")); err != nil {
		t.Fatal(err)
	}

	h.llm.Push(llmtest.Response{Chunks: llmtest.Text("ok")})
	w := h.watch(sess.ID, 0)
	if _, err := h.m.Send(context.Background(), sess.ID, "hi"); err != nil {
		t.Fatal(err)
	}
	w.waitTurnEnd()
	sys := h.llm.Requests()[0].Messages[0].Content
	for _, want := range []string{"<user-memory>\n- **When answering:** be brief.\n[... ", "more bytes in", "<project-memory>\n- Tests live in server/.\n</project-memory>"} {
		if !strings.Contains(sys, want) {
			t.Errorf("system prompt lacks %q:\n%s", want, sys)
		}
	}
	if strings.Contains(sys, "xxxxx") || strings.Contains(sys, "Not this one") {
		t.Errorf("system prompt has memory it shouldn't:\n%s", sys)
	}
}
