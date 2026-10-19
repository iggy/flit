package llm_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

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

func TestStreamSendsHeader(t *testing.T) {
	got := make(chan http.Header, 1)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got <- r.Header.Clone()
		http.Error(w, "no", http.StatusTeapot)
	}))
	defer srv.Close()
	c := &llm.Client{BaseURL: srv.URL, APIKey: "k", Header: http.Header{"User-Agent": {"flit/test"}, "X-Extra": {"1"}}}
	if _, err := c.Stream(context.Background(), llm.Request{Model: "m"}, llm.Handler{}); err == nil {
		t.Fatal("want an error")
	}
	h := <-got
	if h.Get("User-Agent") != "flit/test" || h.Get("X-Extra") != "1" || h.Get("Authorization") != "Bearer k" || h.Get("Accept") != "text/event-stream" {
		t.Fatalf("headers = %v", h)
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

func TestMetrics(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(
		llmtest.Response{Chunks: llmtest.Text("a", "b", "c")},
		llmtest.Response{Chunks: append(llmtest.Text("x")[:1], llmtest.Finish("stop"), llmtest.Timings(120.5, 44.25))},
	)
	c := &llm.Client{BaseURL: srv.BaseURL()}

	res, err := c.Stream(context.Background(), llm.Request{Model: "m", ReasoningEffort: "high"}, llm.Handler{})
	if err != nil {
		t.Fatal(err)
	}
	if res.Metrics.Source != "measured" || res.Metrics.TimeToFirstToken <= 0 || res.Metrics.PromptPerSecond <= 0 {
		t.Fatalf("measured metrics = %+v", res.Metrics)
	}
	if got := srv.Requests()[0].ReasoningEffort; got != "high" {
		t.Fatalf("reasoning_effort sent = %q", got)
	}

	res, err = c.Stream(context.Background(), llm.Request{Model: "m"}, llm.Handler{})
	if err != nil {
		t.Fatal(err)
	}
	if res.Metrics.Source != "llama.cpp" || res.Metrics.PromptPerSecond != 120.5 || res.Metrics.GenerationPerSecond != 44.25 {
		t.Fatalf("llama.cpp metrics = %+v", res.Metrics)
	}
	if res.Usage == nil || res.Usage.PromptTokens != 40 {
		t.Fatalf("usage = %+v", res.Usage)
	}
}

func stream(t *testing.T, srv *llmtest.Server, first, stall time.Duration, h llm.Handler) (*llm.Result, *llm.Trace, error) {
	t.Helper()
	c := &llm.Client{BaseURL: srv.BaseURL(), FirstTokenTimeout: first, StallTimeout: stall}
	return c.StreamTrace(context.Background(), llm.Request{Model: "m"}, h)
}

func wantStall(t *testing.T, err error, phase string) {
	t.Helper()
	var stall *llm.StallError
	if !errors.As(err, &stall) || stall.Phase != phase {
		t.Fatalf("err = %v, want a stall in %s", err, phase)
	}
	if !llm.Retryable(err) {
		t.Fatal("stalls should be retryable")
	}
}

func TestWatchdogPhases(t *testing.T) {
	const short = 80 * time.Millisecond
	for _, tc := range []struct {
		name  string
		resp  llmtest.Response
		phase string
	}{
		{"no headers", llmtest.Response{HeaderDelay: time.Second, Chunks: llmtest.Text("x")}, llm.PhaseConnecting},
		{"no body", llmtest.Response{Chunks: append([]string{llmtest.Pause(time.Second)}, llmtest.Text("x")...)}, llm.PhaseFirstByte},
		{"stuck in the prompt", llmtest.Response{Chunks: []string{llmtest.Progress(0, 100, 0, 0), llmtest.Pause(time.Second)}}, llm.PhasePrompt},
		{"no first token", llmtest.Response{Chunks: []string{llmtest.Finish(""), llmtest.Pause(time.Second)}}, llm.PhaseFirstToken},
		{"mid-reply", llmtest.Response{Chunks: []string{llmtest.Text("a")[0], llmtest.Pause(time.Second)}}, llm.PhaseStreaming},
	} {
		t.Run(tc.name, func(t *testing.T) {
			srv := llmtest.New(t)
			srv.Push(tc.resp)
			start := time.Now()
			_, tr, err := stream(t, srv, short, short, llm.Handler{})
			wantStall(t, err, tc.phase)
			if time.Since(start) > 900*time.Millisecond {
				t.Fatalf("took %s", time.Since(start))
			}
			if tr == nil || tr.Phase != tc.phase || tr.Sent.IsZero() {
				t.Fatalf("trace = %+v", tr)
			}
		})
	}
}

// Before the first token the long limit applies; after it, the short one.
// Prompt progress counts as the model working.
func TestWatchdogLimits(t *testing.T) {
	srv := llmtest.New(t)
	slowStart := append([]string{llmtest.Pause(150 * time.Millisecond)}, llmtest.Text("ok")...)
	srv.Push(llmtest.Response{Chunks: slowStart})
	if _, _, err := stream(t, srv, 400*time.Millisecond, 50*time.Millisecond, llm.Handler{}); err != nil {
		t.Fatalf("slow first token within the first-token limit: %v", err)
	}

	var progress []llm.PromptProgress
	chunks := []string{}
	for i := int64(1); i <= 4; i++ {
		chunks = append(chunks, llmtest.Pause(40*time.Millisecond), llmtest.Progress(i*25, 100, 10, float64(i*40)))
	}
	srv.Push(llmtest.Response{Chunks: append(chunks, llmtest.Text("done")...)})
	res, tr, err := stream(t, srv, 100*time.Millisecond, 70*time.Millisecond, llm.Handler{Progress: func(p llm.PromptProgress) { progress = append(progress, p) }})
	if err != nil || res.Text != "done" {
		t.Fatalf("progress kept it alive? %v %+v", err, res)
	}
	if len(progress) != 4 || progress[3].Processed != 100 || progress[3].Total != 100 || progress[3].Cached != 10 || progress[3].Elapsed != 160*time.Millisecond {
		t.Fatalf("progress = %+v", progress)
	}
	if tr.Phase != llm.PhaseDone || tr.Headers.IsZero() || tr.FirstByte.IsZero() || tr.FirstToken.Before(tr.FirstByte) || tr.LastByte.Before(tr.FirstByte) || tr.Bytes == 0 {
		t.Fatalf("trace = %+v", tr)
	}
}

func TestWatchdogOff(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(llmtest.Response{Chunks: append([]string{llmtest.Pause(100 * time.Millisecond)}, llmtest.Text("ok")...)})
	if _, _, err := stream(t, srv, 0, 0, llm.Handler{}); err != nil {
		t.Fatal(err)
	}
}

func TestStreamTraceKeepsTimings(t *testing.T) {
	srv := llmtest.New(t)
	srv.Push(llmtest.Response{Chunks: append(llmtest.Text("hi"), llmtest.Timings(100, 20))})
	_, tr, err := stream(t, srv, time.Second, time.Second, llm.Handler{})
	if err != nil || tr.Timings == nil || tr.Timings.PromptN != 40 || tr.Timings.PredictedMS != 200 {
		t.Fatalf("trace = %+v, %v", tr, err)
	}
}
