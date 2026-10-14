// Package llmtest is a scripted fake OpenAI-compatible chat completions
// server for tests.
package llmtest

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"github.com/iggy/flit/server/internal/llm"
)

// Response is one scripted reply.
type Response struct {
	// Status, if not 0 or 200, is sent with Body instead of a stream.
	Status int
	Body   string
	// Chunks are the JSON payloads of the stream's "data:" lines. [DONE] is
	// appended unless Hang is set.
	Chunks []string
	// Hang keeps the stream open after Chunks until the client goes away.
	Hang bool
	// Started, if set, is closed once Chunks have been sent.
	Started chan struct{}
}

// Server is a fake endpoint. Push responses; each request takes the next.
type Server struct {
	*httptest.Server

	mu        sync.Mutex
	responses []Response
	requests  []llm.Request
	auth      []string
}

// New starts a fake server that is closed when the test ends.
func New(t testing.TB) *Server {
	s := &Server{}
	s.Server = httptest.NewServer(http.HandlerFunc(s.handle))
	t.Cleanup(s.Close)
	return s
}

// BaseURL is the /v1 root to configure as a provider.
func (s *Server) BaseURL() string { return s.URL + "/v1" }

// Push queues responses.
func (s *Server) Push(rs ...Response) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.responses = append(s.responses, rs...)
}

// Requests returns the requests received so far.
func (s *Server) Requests() []llm.Request {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]llm.Request(nil), s.requests...)
}

// AuthHeaders returns the Authorization header of each request.
func (s *Server) AuthHeaders() []string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return append([]string(nil), s.auth...)
}

func (s *Server) handle(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/v1/chat/completions" || r.Method != http.MethodPost {
		http.NotFound(w, r)
		return
	}
	var req llm.Request
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	s.mu.Lock()
	s.requests = append(s.requests, req)
	s.auth = append(s.auth, r.Header.Get("Authorization"))
	if len(s.responses) == 0 {
		s.mu.Unlock()
		http.Error(w, `{"error":{"message":"llmtest: no scripted response"}}`, http.StatusInternalServerError)
		return
	}
	resp := s.responses[0]
	s.responses = s.responses[1:]
	s.mu.Unlock()

	if resp.Status != 0 && resp.Status != http.StatusOK {
		w.WriteHeader(resp.Status)
		fmt.Fprint(w, resp.Body)
		return
	}
	w.Header().Set("Content-Type", "text/event-stream")
	flusher := w.(http.Flusher)
	for _, c := range resp.Chunks {
		fmt.Fprintf(w, "data: %s\n\n", c)
		flusher.Flush()
	}
	if resp.Started != nil {
		close(resp.Started)
	}
	if resp.Hang {
		<-r.Context().Done()
		return
	}
	fmt.Fprint(w, "data: [DONE]\n\n")
}

func mustJSON(v any) string {
	b, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return string(b)
}

func delta(d map[string]any, finish any) string {
	return mustJSON(map[string]any{
		"choices": []any{map[string]any{"index": 0, "delta": d, "finish_reason": finish}},
	})
}

// Text returns chunks streaming parts as content, then finish_reason "stop"
// and a usage chunk.
func Text(parts ...string) []string {
	var out []string
	for _, p := range parts {
		out = append(out, delta(map[string]any{"content": p}, nil))
	}
	return append(out, delta(map[string]any{}, "stop"), Usage(10, 5))
}

// Reasoning returns a reasoning_content chunk.
func Reasoning(text string) string {
	return delta(map[string]any{"reasoning_content": text}, nil)
}

// ToolCall returns chunks for one tool call at index, with the arguments
// split across two chunks as real servers do.
func ToolCall(index int, id, name, args string) []string {
	half := len(args) / 2
	return []string{
		delta(map[string]any{"tool_calls": []any{map[string]any{
			"index": index, "id": id, "type": "function",
			"function": map[string]any{"name": name, "arguments": args[:half]},
		}}}, nil),
		delta(map[string]any{"tool_calls": []any{map[string]any{
			"index": index, "function": map[string]any{"arguments": args[half:]},
		}}}, nil),
	}
}

// Finish returns a chunk with the given finish_reason.
func Finish(reason string) string { return delta(map[string]any{}, reason) }

// Usage returns a usage-only chunk, as sent with stream_options.include_usage.
func Usage(prompt, completion int64) string {
	return mustJSON(map[string]any{
		"choices": []any{},
		"usage":   map[string]any{"prompt_tokens": prompt, "completion_tokens": completion, "total_tokens": prompt + completion},
	})
}

// ToolCalls returns a full response making the given calls, each a
// [id, name, args] triple.
func ToolCalls(calls ...[3]string) []string {
	var out []string
	for i, c := range calls {
		out = append(out, ToolCall(i, c[0], c[1], c[2])...)
	}
	return append(out, Finish("tool_calls"), Usage(20, 8))
}
