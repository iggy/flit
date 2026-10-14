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
	resp, err := hc.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
		return nil, &APIError{StatusCode: resp.StatusCode, Message: errorMessage(b)}
	}
	return readStream(resp.Body, h)
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
	Usage *Usage          `json:"usage"`
	Error json.RawMessage `json:"error"`
}

func readStream(r io.Reader, h Handler) (*Result, error) {
	var res Result
	var text, reasoning strings.Builder
	calls := map[int]*ToolCall{}

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
		for _, ch := range c.Choices {
			d := ch.Delta
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
