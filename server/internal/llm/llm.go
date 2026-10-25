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
	"sync"
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
	// ChatTemplateKwargs are passed to the model's chat template by
	// llama.cpp, e.g. {"enable_thinking": false} to turn thinking off.
	ChatTemplateKwargs map[string]any `json:"chat_template_kwargs,omitempty"`
	// ReturnProgress asks llama.cpp to stream prompt processing progress
	// (Handler.Progress), which also keeps the watchdog fed while a long
	// prompt is read. Only send it to llama.cpp.
	ReturnProgress bool `json:"return_progress,omitempty"`
	// ReasoningControl lets llama.cpp end the reasoning block early while
	// the completion runs (llamacpp.Client.EndReasoning).
	ReasoningControl bool `json:"reasoning_control,omitempty"`
	// IDSlot pins the request to one llama.cpp slot (with CachePrompt, so
	// a cache restored into it is used).
	IDSlot      *int  `json:"id_slot,omitempty"`
	CachePrompt *bool `json:"cache_prompt,omitempty"`
	// MaxTokens caps the reply (thinking included on llama.cpp); 0 means
	// the provider's default.
	MaxTokens int `json:"max_tokens,omitempty"`
	// ToolChoice is "none" to offer the tools without letting the model
	// call them (the prompt stays the same, so caches still match).
	ToolChoice string `json:"tool_choice,omitempty"`
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

// Timings is the timings block llama.cpp's server adds to the last
// streamed chunk.
type Timings struct {
	// CacheN is how many prompt tokens came from the server's cache.
	CacheN             int64   `json:"cache_n"`
	PromptN            int64   `json:"prompt_n"`
	PromptMS           float64 `json:"prompt_ms"`
	PromptPerSecond    float64 `json:"prompt_per_second"`
	PredictedN         int64   `json:"predicted_n"`
	PredictedMS        float64 `json:"predicted_ms"`
	PredictedPerSecond float64 `json:"predicted_per_second"`
}

// Handler receives deltas as they stream in. Any func may be nil.
type Handler struct {
	Text      func(string)
	Reasoning func(string)
	// Progress reports prompt processing (llama.cpp with ReturnProgress).
	Progress func(PromptProgress)
	// ID receives the completion's id once, from the first chunk.
	ID func(string)
	// Queued is called when the call has to wait for its Limiter: limit
	// calls to the model are already in flight. Admitted follows when it
	// gets its turn (not if the context ends first).
	Queued   func(limit int)
	Admitted func()
}

// PromptProgress is how far the server has got reading the prompt.
type PromptProgress struct {
	Processed, Total, Cached int64
	Elapsed                  time.Duration
}

// Phases of a call, as Trace.Phase and StallError.Phase report them.
const (
	PhaseConnecting = "connecting"
	PhaseFirstByte  = "waiting_for_first_byte"
	PhasePrompt     = "processing_prompt"
	PhaseFirstToken = "waiting_for_first_token"
	PhaseStreaming  = "streaming"
	PhaseDone       = "done"
)

// Trace is the timeline of one call. StreamTrace fills it in even when the
// call fails, so it shows where a slow or stuck call got to.
type Trace struct {
	Sent, Headers, FirstByte, FirstToken, LastByte time.Time
	// Bytes is how much of the response body arrived.
	Bytes int64
	// Phase is where the call was when it ended.
	Phase string
	// Timings are llama.cpp's own, when it sent them.
	Timings *Timings
}

// StallError is the watchdog giving up: nothing arrived for Waited while
// the call was in Phase.
type StallError struct {
	Phase  string
	Waited time.Duration
}

func (e *StallError) Error() string {
	what := map[string]string{
		PhaseConnecting: "the model server didn't respond",
		PhaseFirstByte:  "the model server sent no data",
		PhasePrompt:     "the model server stopped reporting progress on the prompt",
		PhaseFirstToken: "the model didn't start answering",
		PhaseStreaming:  "the model stopped mid-reply",
	}[e.Phase]
	if what == "" {
		what = "no response from the model"
	}
	waited := e.Waited.Round(time.Second)
	if e.Waited < time.Second {
		waited = e.Waited.Round(time.Millisecond)
	}
	return fmt.Sprintf("%s for %s", what, waited)
}

// Started reports whether the model had started answering (or reporting
// prompt progress), which is when StallTimeout rather than
// FirstTokenTimeout applies.
func (e *StallError) Started() bool { return e.Phase == PhaseStreaming || e.Phase == PhasePrompt }

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
	var stall *StallError
	if errors.As(err, &stall) {
		return true
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
	// Header is sent with every request, replacing the client's own
	// (Authorization included).
	Header http.Header
	HTTP   *http.Client
	// The watchdog. FirstTokenTimeout is the longest the response may go
	// quiet before the model starts answering (connecting, reading the
	// prompt); StallTimeout is the longest once it has (tokens, or prompt
	// progress, are flowing). 0 turns a limit off.
	FirstTokenTimeout time.Duration
	StallTimeout      time.Duration
	// Limiter, if set, caps calls in flight to Provider's model (the
	// request's). A call holds its slot until its stream ends; the wait
	// for one comes before the watchdog starts.
	Limiter  *Limiter
	Provider string
}

// Stream sends req with streaming enabled, calls h for each delta and
// returns the assembled result. Cancel ctx to stop early.
func (c *Client) Stream(ctx context.Context, req Request, h Handler) (*Result, error) {
	res, _, err := c.StreamTrace(ctx, req, h)
	return res, err
}

// StreamTrace is Stream that also returns the call's timeline, which is
// non-nil even when err isn't. A call the watchdog stops fails with a
// *StallError.
func (c *Client) StreamTrace(ctx context.Context, req Request, h Handler) (*Result, *Trace, error) {
	w := &watch{first: c.FirstTokenTimeout, stall: c.StallTimeout, trace: &Trace{Phase: PhaseConnecting}}
	queued := false
	release, err := c.Limiter.Acquire(ctx, c.Provider, req.Model, func(limit int) {
		queued = true
		if h.Queued != nil {
			h.Queued(limit)
		}
	})
	if err != nil {
		return nil, w.finish(err), err
	}
	defer release()
	if queued && h.Admitted != nil {
		h.Admitted()
	}
	res, err := c.stream(ctx, req, h, w)
	return res, w.finish(err), err
}

func (c *Client) stream(ctx context.Context, req Request, h Handler, w *watch) (*Result, error) {
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
	for k, v := range c.Header {
		httpReq.Header[k] = v
	}
	hc := c.HTTP
	if hc == nil {
		hc = http.DefaultClient
	}
	ctx, cancel := context.WithCancelCause(ctx)
	defer cancel(nil)
	httpReq = httpReq.WithContext(ctx)
	start := w.start(cancel)
	resp, err := hc.Do(httpReq)
	if err != nil {
		return nil, stallCause(ctx, err)
	}
	defer resp.Body.Close()
	w.headers()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
		return nil, &APIError{StatusCode: resp.StatusCode, Message: errorMessage(b)}
	}
	res, err := readStream(&watchedReader{r: resp.Body, w: w}, h, start, w)
	if err != nil {
		return nil, stallCause(ctx, err)
	}
	return res, nil
}

// stallCause returns the watchdog's error if it is why ctx ended.
func stallCause(ctx context.Context, err error) error {
	var stall *StallError
	if errors.As(context.Cause(ctx), &stall) {
		return stall
	}
	return err
}

// watch is the watchdog and the trace it keeps. Its timer is reset by every
// byte of the response; how long it waits depends on the phase.
type watch struct {
	first, stall time.Duration

	mu       sync.Mutex
	cancel   context.CancelCauseFunc
	trace    *Trace
	progress bool // prompt progress seen
	timer    *time.Timer
	last     time.Time // last sign of life
}

func (w *watch) start(cancel context.CancelCauseFunc) time.Time {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := time.Now()
	w.trace.Sent, w.last, w.cancel = now, now, cancel
	w.armLocked()
	return now
}

// armLocked (re)starts the timer for the current limit.
func (w *watch) armLocked() {
	limit := w.limitLocked()
	switch {
	case limit <= 0 || w.cancel == nil:
	case w.timer == nil:
		w.timer = time.AfterFunc(limit, w.fire)
	default:
		w.timer.Reset(limit)
	}
}

// limitLocked is how long the response may now stay quiet.
func (w *watch) limitLocked() time.Duration {
	if !w.trace.FirstToken.IsZero() || w.progress {
		if w.stall > 0 {
			return w.stall
		}
	}
	return w.first
}

// fire runs when the timer runs out. Activity may have reset the deadline
// meanwhile, so it re-arms instead of cancelling in that case.
func (w *watch) fire() {
	w.mu.Lock()
	defer w.mu.Unlock()
	limit := w.limitLocked()
	if limit <= 0 {
		return
	}
	if idle := time.Since(w.last); idle < limit {
		w.timer.Reset(limit - idle)
		return
	}
	w.cancel(&StallError{Phase: w.phaseLocked(), Waited: limit})
}

func (w *watch) phaseLocked() string {
	t := w.trace
	switch {
	case t.Headers.IsZero():
		return PhaseConnecting
	case t.FirstByte.IsZero():
		return PhaseFirstByte
	case !t.FirstToken.IsZero():
		return PhaseStreaming
	case w.progress:
		return PhasePrompt
	}
	return PhaseFirstToken
}

func (w *watch) alive(f func(now time.Time)) {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := time.Now()
	w.last = now
	f(now)
	w.armLocked()
}

func (w *watch) headers() { w.alive(func(now time.Time) { w.trace.Headers = now }) }

func (w *watch) read(n int) {
	w.alive(func(now time.Time) {
		if w.trace.FirstByte.IsZero() {
			w.trace.FirstByte = now
		}
		w.trace.LastByte = now
		w.trace.Bytes += int64(n)
	})
}

func (w *watch) token() {
	w.alive(func(now time.Time) {
		if w.trace.FirstToken.IsZero() {
			w.trace.FirstToken = now
		}
	})
}

func (w *watch) promptProgress() { w.alive(func(time.Time) { w.progress = true }) }

func (w *watch) timings(t *Timings) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.trace.Timings = t
}

// finish stops the timer and returns the trace with its final phase.
func (w *watch) finish(err error) *Trace {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.timer != nil {
		w.timer.Stop()
	}
	w.cancel = nil // no re-arming after the call
	var stall *StallError
	switch {
	case err == nil:
		w.trace.Phase = PhaseDone
	case errors.As(err, &stall):
		w.trace.Phase = stall.Phase
	default:
		w.trace.Phase = w.phaseLocked()
	}
	t := *w.trace
	return &t
}

// watchedReader tells the watchdog about every byte read.
type watchedReader struct {
	r io.Reader
	w *watch
}

func (r *watchedReader) Read(p []byte) (int, error) {
	n, err := r.r.Read(p)
	if n > 0 {
		r.w.read(n)
	}
	return n, err
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
	ID             string   `json:"id"`
	Usage          *Usage   `json:"usage"`
	Timings        *Timings `json:"timings"`
	PromptProgress *struct {
		Total     int64   `json:"total"`
		Cache     int64   `json:"cache"`
		Processed int64   `json:"processed"`
		TimeMS    float64 `json:"time_ms"`
	} `json:"prompt_progress"`
	Error json.RawMessage `json:"error"`
}

func readStream(r io.Reader, h Handler, start time.Time, w *watch) (*Result, error) {
	var res Result
	var text, reasoning strings.Builder
	calls := map[int]*ToolCall{}
	var firstToken, lastToken time.Time
	var timings *Timings
	token := func() {
		lastToken = time.Now()
		if firstToken.IsZero() {
			firstToken = lastToken
		}
		w.token()
	}

	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 64<<10), 16<<20)
	done, sawID := false, false
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
		if c.ID != "" && !sawID {
			sawID = true
			if h.ID != nil {
				h.ID(c.ID)
			}
		}
		if c.Usage != nil {
			res.Usage = c.Usage
		}
		if c.Timings != nil {
			timings = c.Timings
			w.timings(c.Timings)
		}
		if p := c.PromptProgress; p != nil {
			w.promptProgress()
			if h.Progress != nil {
				h.Progress(PromptProgress{
					Processed: p.Processed, Total: p.Total, Cached: p.Cache,
					Elapsed: time.Duration(p.TimeMS * float64(time.Millisecond)),
				})
			}
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
func metrics(start, first, last time.Time, u *Usage, t *Timings) Metrics {
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
