// Package llm is a client for OpenAI-compatible chat completions endpoints
// (OpenAI, llama.cpp's llama-server, vLLM, ...), streaming, with native tool
// calls.
package llm

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"
)

// Message is a chat message in OpenAI wire format.
type Message struct {
	Role       string     `json:"role"` // system, user, assistant, tool
	Content    string     `json:"content"`
	ToolCalls  []ToolCall `json:"tool_calls,omitempty"`
	ToolCallID string     `json:"tool_call_id,omitempty"`
}

// ToolCall is a function call made by the model.
type ToolCall struct {
	ID       string       `json:"id"`
	Type     string       `json:"type"` // always "function"
	Function FunctionCall `json:"function"`
}

// FunctionCall names the function and carries its JSON arguments.
type FunctionCall struct {
	Name      string `json:"name"`
	Arguments string `json:"arguments"`
}

// Tool describes a function the model may call.
type Tool struct {
	Type     string       `json:"type"` // always "function"
	Function ToolFunction `json:"function"`
}

// ToolFunction is a tool's name, description and JSON Schema parameters.
type ToolFunction struct {
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Parameters  json.RawMessage `json:"parameters"`
}

// Request is a chat completion request.
type Request struct {
	Model    string    `json:"model"`
	Messages []Message `json:"messages"`
	Tools    []Tool    `json:"tools,omitempty"`
	// ReasoningEffort ("low", "medium", "high", …) is sent as
	// reasoning_effort when set; OpenAI, OpenRouter and llama.cpp accept it.
	ReasoningEffort string `json:"reasoning_effort,omitempty"`
}

// Usage is token usage reported by the endpoint.
type Usage struct {
	PromptTokens     int64 `json:"prompt_tokens"`
	CompletionTokens int64 `json:"completion_tokens"`
	TotalTokens      int64 `json:"total_tokens"`
}

// Result is a completed streamed response.
type Result struct {
	Text         string
	Reasoning    string
	ToolCalls    []ToolCall
	FinishReason string
	// Usage is nil if the endpoint didn't report it.
	Usage *Usage
	// Metrics is how fast the call was.
	Metrics Metrics
}

// Metrics is the speed of one call.
type Metrics struct {
	// TimeToFirstToken is from sending the request to the first streamed
	// token (text, reasoning or tool call).
	TimeToFirstToken time.Duration
	// Tokens per second for reading the prompt and for generating; 0 when
	// unknown.
	PromptPerSecond     float64
	GenerationPerSecond float64
	// Source is "llama.cpp" when the server reported its own timings,
	// "measured" when flit timed the stream, "" when neither worked.
	Source string
}

// llamaTimings is the timings block llama.cpp's server adds to the last
// streamed chunk.
type llamaTimings struct {
	PromptN            int64   `json:"prompt_n"`
	PromptMS           float64 `json:"prompt_ms"`
	PromptPerSecond    float64 `json:"prompt_per_second"`
	PredictedN         int64   `json:"predicted_n"`
	PredictedMS        float64 `json:"predicted_ms"`
	PredictedPerSecond float64 `json:"predicted_per_second"`
}

// Handler receives deltas as they stream in. Either func may be nil.
type Handler struct {
	Text      func(string)
	Reasoning func(string)
}

// APIError is an error response from the endpoint.
type APIError struct {
	StatusCode int
	Message    string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("model endpoint returned HTTP %d: %s", e.StatusCode, e.Message)
}

// Retryable reports whether err is likely transient (rate limits, server
// errors, network trouble), so trying again later may work.
func Retryable(err error) bool {
	if errors.Is(err, context.Canceled) {
		return false
	}
	var apiErr *APIError
	if errors.As(err, &apiErr) {
		return apiErr.StatusCode == http.StatusTooManyRequests || apiErr.StatusCode >= 500 || apiErr.StatusCode == 0
	}
	return true // transport errors
}

// Client talks to one endpoint.
type Client struct {
	BaseURL string // e.g. http://localhost:8080/v1
	APIKey  string // optional
	HTTP    *http.Client
}

// Stream sends req with streaming enabled, calls h for each delta and
// returns the assembled result. Cancel ctx to stop early.
func (c *Client) Stream(ctx context.Context, req Request, h Handler) (*Result, error) {
	body, err := json.Marshal(struct {
		Request
		Stream        bool `json:"stream"`
		StreamOptions any  `json:"stream_options"`
	}{req, true, map[string]bool{"include_usage": true}})
	if err != nil {
		return nil, err
	}
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, strings.TrimSuffix(c.BaseURL, "/")+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Accept", "text/event-stream")
	if c.APIKey != "" {
		httpReq.Header.Set("Authorization", "Bearer "+c.APIKey)
	}
	hc := c.HTTP
	if hc == nil {
		hc = http.DefaultClient
	}
	start := time.Now()
	resp, err := hc.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
		return nil, &APIError{StatusCode: resp.StatusCode, Message: errorMessage(b)}
	}
	return readStream(resp.Body, h, start)
}

type chunk struct {
	Choices []struct {
		Delta struct {
			Content          string `json:"content"`
			ReasoningContent string `json:"reasoning_content"` // llama.cpp, DeepSeek
			Reasoning        string `json:"reasoning"`         // OpenRouter, vLLM
			ToolCalls        []struct {
				Index    int    `json:"index"`
				ID       string `json:"id"`
				Type     string `json:"type"`
				Function struct {
					Name      string `json:"name"`
					Arguments string `json:"arguments"`
				} `json:"function"`
			} `json:"tool_calls"`
		} `json:"delta"`
		FinishReason *string `json:"finish_reason"`
	} `json:"choices"`
	Usage   *Usage          `json:"usage"`
	Timings *llamaTimings   `json:"timings"`
	Error   json.RawMessage `json:"error"`
}

func readStream(r io.Reader, h Handler, start time.Time) (*Result, error) {
	var res Result
	var text, reasoning strings.Builder
	calls := map[int]*ToolCall{}
	var firstToken, lastToken time.Time
	var timings *llamaTimings
	token := func() {
		lastToken = time.Now()
		if firstToken.IsZero() {
			firstToken = lastToken
		}
	}

	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64<<10), 16<<20)
	done := false
	for !done && sc.Scan() {
		line := sc.Text()
		data, ok := strings.CutPrefix(line, "data:")
		if !ok {
			continue // blank lines, comments, event: lines
		}
		data = strings.TrimSpace(data)
		if data == "[DONE]" {
			done = true
			break
		}
		var c chunk
		if err := json.Unmarshal([]byte(data), &c); err != nil {
			return nil, fmt.Errorf("bad stream chunk: %w", err)
		}
		if len(c.Error) > 0 && string(c.Error) != "null" {
			return nil, &APIError{StatusCode: 0, Message: errorMessage([]byte(data))}
		}
		if c.Usage != nil {
			res.Usage = c.Usage
		}
		if c.Timings != nil {
			timings = c.Timings
		}
		for _, ch := range c.Choices {
			d := ch.Delta
			if d.Content != "" || d.ReasoningContent != "" || d.Reasoning != "" || len(d.ToolCalls) > 0 {
				token()
			}
			if d.Content != "" {
				text.WriteString(d.Content)
				if h.Text != nil {
					h.Text(d.Content)
				}
			}
			if r := d.ReasoningContent + d.Reasoning; r != "" {
				reasoning.WriteString(r)
				if h.Reasoning != nil {
					h.Reasoning(r)
				}
			}
			for _, tc := range d.ToolCalls {
				call := calls[tc.Index]
				if call == nil {
					call = &ToolCall{Type: "function"}
					calls[tc.Index] = call
				}
				if tc.ID != "" {
					call.ID = tc.ID
				}
				call.Function.Name += tc.Function.Name
				call.Function.Arguments += tc.Function.Arguments
			}
			if ch.FinishReason != nil && *ch.FinishReason != "" {
				res.FinishReason = *ch.FinishReason
			}
		}
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	if !done && res.FinishReason == "" {
		return nil, io.ErrUnexpectedEOF
	}

	res.Text, res.Reasoning = text.String(), reasoning.String()
	res.Metrics = metrics(start, firstToken, lastToken, res.Usage, timings)
	idx := make([]int, 0, len(calls))
	for i := range calls {
		idx = append(idx, i)
	}
	sort.Ints(idx)
	for n, i := range idx {
		call := *calls[i]
		if call.ID == "" {
			call.ID = fmt.Sprintf("call_%d", n)
		}
		if call.Function.Arguments == "" {
			call.Function.Arguments = "{}"
		}
		res.ToolCalls = append(res.ToolCalls, call)
	}
	return &res, nil
}

// errorMessage pulls a readable message out of an error body.
func errorMessage(b []byte) string {
	var e struct {
		Error json.RawMessage `json:"error"`
	}
	if json.Unmarshal(b, &e) == nil && len(e.Error) > 0 {
		var obj struct {
			Message string `json:"message"`
		}
		if json.Unmarshal(e.Error, &obj) == nil && obj.Message != "" {
			return obj.Message
		}
		var s string
		if json.Unmarshal(e.Error, &s) == nil && s != "" {
			return s
		}
	}
	msg := strings.TrimSpace(string(b))
	if len(msg) > 500 {
		msg = msg[:500] + "…"
	}
	if msg == "" {
		msg = "(empty body)"
	}
	return msg
}

// metrics prefers llama.cpp's own timings (server-side, so no network time)
// and otherwise times the stream: prompt speed is prompt tokens over the
// time to the first token, generation speed is the remaining tokens over
// the time from the first to the last token.
func metrics(start, first, last time.Time, u *Usage, t *llamaTimings) Metrics {
	var m Metrics
	if !first.IsZero() {
		m.TimeToFirstToken = first.Sub(start)
	}
	if t != nil && (t.PromptPerSecond > 0 || t.PredictedPerSecond > 0) {
		m.Source = "llama.cpp"
		m.PromptPerSecond = t.PromptPerSecond
		m.GenerationPerSecond = t.PredictedPerSecond
		return m
	}
	if first.IsZero() || u == nil {
		return m
	}
	m.Source = "measured"
	if s := m.TimeToFirstToken.Seconds(); s > 0 && u.PromptTokens > 0 {
		m.PromptPerSecond = float64(u.PromptTokens) / s
	}
	if s := last.Sub(first).Seconds(); s > 0 && u.CompletionTokens > 1 {
		m.GenerationPerSecond = float64(u.CompletionTokens-1) / s
	}
	return m
}
