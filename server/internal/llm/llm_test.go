package llm_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/iggy/flit/server/internal/llm"
	"github.com/iggy/flit/server/internal/llm/llmtest"
)

func TestStreamText(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(llmtest.Response{Chunks: append([]string{llmtest.Reasoning("hmm")}, llmtest.Text("Hel", "lo")...)})

	var deltas, thinking []string
	c := &llm.Client{BaseURL: srv.BaseURL(), APIKey: "k"}
	res, err := c.Stream(context.Background(), llm.Request{Model: "m", Messages: []llm.Message{{Role: "user", Content: "hi"}}},
		llm.Handler{Text: func(s string) { deltas = append(deltas, s) }, Reasoning: func(s string) { thinking = append(thinking, s) }})
	if err != nil {
		t.Fatal(err)
	}
	if res.Text != "Hello" || strings.Join(deltas, "|") != "Hel|lo" || res.Reasoning != "hmm" || len(thinking) != 1 {
		t.Fatalf("res = %+v, deltas = %q, thinking = %q", res, deltas, thinking)
	}
	if res.FinishReason != "stop" || res.Usage == nil || res.Usage.TotalTokens != 15 {
		t.Fatalf("finish/usage = %q, %+v", res.FinishReason, res.Usage)
	}
	if got := srv.AuthHeaders()[0]; got != "Bearer k" {
		t.Fatalf("auth header = %q", got)
	}
	if req := srv.Requests()[0]; req.Model != "m" || req.Messages[0].Content != "hi" {
		t.Fatalf("request = %+v", req)
	}
}

func TestStreamToolCalls(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(llmtest.Response{Chunks: llmtest.ToolCalls(
		[3]string{"c1", "read", `{"path":"a.go"}`},
		[3]string{"c2", "list", `{"path":"."}`},
	)})
	c := &llm.Client{BaseURL: srv.BaseURL()}
	res, err := c.Stream(context.Background(), llm.Request{Model: "m"}, llm.Handler{})
	if err != nil {
		t.Fatal(err)
	}
	if len(res.ToolCalls) != 2 || res.FinishReason != "tool_calls" {
		t.Fatalf("res = %+v", res)
	}
	if tc := res.ToolCalls[0]; tc.ID != "c1" || tc.Function.Name != "read" || tc.Function.Arguments != `{"path":"a.go"}` {
		t.Fatalf("call 0 = %+v", tc)
	}
	if tc := res.ToolCalls[1]; tc.ID != "c2" || tc.Function.Name != "list" {
		t.Fatalf("call 1 = %+v", tc)
	}
	if got := srv.AuthHeaders()[0]; got != "" {
		t.Fatalf("auth header without key = %q", got)
	}
}

func TestStreamErrors(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(
		llmtest.Response{Status: 404, Body: `{"error":{"message":"model not found"}}`},
		llmtest.Response{Status: 503, Body: `overloaded`},
		llmtest.Response{Chunks: []string{`{"error":{"message":"boom"}}`}},
		llmtest.Response{Chunks: []string{llmtest.Text("cut")[0]}, Hang: true},
	)
	c := &llm.Client{BaseURL: srv.BaseURL()}
	ctx := context.Background()

	_, err := c.Stream(ctx, llm.Request{}, llm.Handler{})
	var apiErr *llm.APIError
	if !errors.As(err, &apiErr) || apiErr.StatusCode != 404 || apiErr.Message != "model not found" || llm.Retryable(err) {
		t.Fatalf("404: err = %v", err)
	}
	if _, err = c.Stream(ctx, llm.Request{}, llm.Handler{}); !llm.Retryable(err) {
		t.Fatalf("503 should be retryable: %v", err)
	}
	if _, err = c.Stream(ctx, llm.Request{}, llm.Handler{}); err == nil || !strings.Contains(err.Error(), "boom") {
		t.Fatalf("in-stream error: %v", err)
	}

	ctx, cancel := context.WithCancel(ctx)
	got := make(chan string, 1)
	go func() {
		_, err := c.Stream(ctx, llm.Request{}, llm.Handler{Text: func(s string) { got <- s }})
		got <- "err:" + errString(err)
	}()
	<-got
	cancel()
	if e := <-got; !strings.Contains(e, "context canceled") {
		t.Fatalf("cancel: %s", e)
	}
	if llm.Retryable(context.Canceled) {
		t.Fatal("cancel must not be retryable")
	}
}

func errString(err error) string {
	if err == nil {
		return "<nil>"
	}
	return err.Error()
}
