// Package llamacpp talks to llama.cpp's own server endpoints, beside the
// OpenAI-compatible API: slot state, prompt (KV) cache save and restore,
// and live control of a running completion. In router mode every call
// names the model, which picks the instance.
package llamacpp

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Client is one llama.cpp server (or router).
type Client struct {
	// BaseURL is the provider's OpenAI base URL, e.g. http://host:8080/v1;
	// llama.cpp's own endpoints sit at its root.
	BaseURL string
	APIKey  string
	// Router: a router serving several models, which every request must
	// name.
	Router bool
	// Header is sent with every request, replacing the client's own
	// (Authorization included).
	Header http.Header
	HTTP   *http.Client
}

// timeout bounds status and control calls; slot save and restore can move
// gigabytes and get longer.
const (
	timeout     = 10 * time.Second
	slotTimeout = 5 * time.Minute
)

func (c *Client) root() string {
	return strings.TrimSuffix(strings.TrimSuffix(c.BaseURL, "/"), "/v1")
}

func (c *Client) do(ctx context.Context, method, path string, query url.Values, body any, limit time.Duration, out any) error {
	ctx, cancel := context.WithTimeout(ctx, limit)
	defer cancel()
	var r io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return err
		}
		r = bytes.NewReader(b)
	}
	u := c.root() + path
	if len(query) > 0 {
		u += "?" + query.Encode()
	}
	req, err := http.NewRequestWithContext(ctx, method, u, r)
	if err != nil {
		return err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.APIKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.APIKey)
	}
	for k, v := range c.Header {
		req.Header[k] = v
	}
	hc := c.HTTP
	if hc == nil {
		hc = http.DefaultClient
	}
	resp, err := hc.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, 16<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return &Error{Status: resp.StatusCode, Message: message(data)}
	}
	if out == nil {
		return nil
	}
	return json.Unmarshal(data, out)
}

// Error is an error response from the server.
type Error struct {
	Status  int
	Message string
}

func (e *Error) Error() string { return fmt.Sprintf("llama.cpp: HTTP %d: %s", e.Status, e.Message) }

// Unsupported reports whether err means the server doesn't offer the
// endpoint (not built in, or turned off, e.g. no --slot-save-path).
func Unsupported(err error) bool {
	var e *Error
	return errors.As(err, &e) && (e.Status == http.StatusNotFound || e.Status == http.StatusNotImplemented ||
		e.Status == http.StatusBadRequest && strings.Contains(strings.ToLower(e.Message), "not supported"))
}

func message(b []byte) string {
	var e struct {
		Error struct {
			Message string `json:"message"`
		} `json:"error"`
	}
	if json.Unmarshal(b, &e) == nil && e.Error.Message != "" {
		return e.Error.Message
	}
	s := strings.TrimSpace(string(b))
	if len(s) > 300 {
		s = s[:300] + "…"
	}
	return s
}

func (c *Client) modelQuery(model string) url.Values {
	if !c.Router {
		return nil
	}
	return url.Values{"model": {model}}
}

func (c *Client) withModel(model string, body map[string]any) map[string]any {
	if c.Router {
		body["model"] = model
	}
	return body
}

// Slot is one of the server's parallel slots.
type Slot struct {
	ID           int  `json:"id"`
	NCtx         int  `json:"n_ctx"`
	IsProcessing bool `json:"is_processing"`
}

// Slots lists the model's slots.
func (c *Client) Slots(ctx context.Context, model string) ([]Slot, error) {
	var out []Slot
	err := c.do(ctx, http.MethodGet, "/slots", c.modelQuery(model), nil, timeout, &out)
	return out, err
}

// State is how the server has the model: "loaded", "loading", "sleeping",
// "unloaded" (router), or "" when it doesn't say.
func (c *Client) State(ctx context.Context, model string) (string, error) {
	if !c.Router {
		var props struct {
			IsSleeping bool `json:"is_sleeping"`
		}
		if err := c.do(ctx, http.MethodGet, "/props", nil, nil, timeout, &props); err != nil {
			return "", err
		}
		if props.IsSleeping {
			return "sleeping", nil
		}
		return "loaded", nil
	}
	// GET /models doesn't wake a sleeping model or reset its idle timer.
	var list struct {
		Data []struct {
			ID     string `json:"id"`
			Status struct {
				Value string `json:"value"`
			} `json:"status"`
		} `json:"data"`
	}
	if err := c.do(ctx, http.MethodGet, "/models", nil, nil, timeout, &list); err != nil {
		return "", err
	}
	for _, m := range list.Data {
		if m.ID == model {
			return m.Status.Value, nil
		}
	}
	return "", nil
}

// SaveSlot writes slot's prompt cache to filename in the server's
// --slot-save-path and returns how many tokens it saved.
func (c *Client) SaveSlot(ctx context.Context, model string, slot int, filename string) (int, error) {
	var out struct {
		NSaved int `json:"n_saved"`
	}
	err := c.do(ctx, http.MethodPost, fmt.Sprintf("/slots/%d", slot), url.Values{"action": {"save"}},
		c.withModel(model, map[string]any{"filename": filename}), slotTimeout, &out)
	return out.NSaved, err
}

// RestoreSlot loads filename into slot and returns how many tokens it
// restored.
func (c *Client) RestoreSlot(ctx context.Context, model string, slot int, filename string) (int, error) {
	var out struct {
		NRestored int `json:"n_restored"`
	}
	err := c.do(ctx, http.MethodPost, fmt.Sprintf("/slots/%d", slot), url.Values{"action": {"restore"}},
		c.withModel(model, map[string]any{"filename": filename}), slotTimeout, &out)
	return out.NRestored, err
}

// InputTokens counts the prompt tokens of a chat completion request (the
// model's template applied, tools included) without running it. req is
// the request body; in router mode it must name the model.
func (c *Client) InputTokens(ctx context.Context, req any) (int64, error) {
	var out struct {
		InputTokens *int64 `json:"input_tokens"`
	}
	if err := c.do(ctx, http.MethodPost, "/v1/chat/completions/input_tokens", nil, req, timeout, &out); err != nil {
		return 0, err
	}
	if out.InputTokens == nil {
		return 0, errors.New("llama.cpp: no input_tokens in the reply")
	}
	return *out.InputTokens, nil
}

// EndReasoning asks the server to end the reasoning block of running
// completion id (one sent with reasoning_control). The server accepts it
// even for models whose template it can't cut short; watch the stream to
// see whether it took.
func (c *Client) EndReasoning(ctx context.Context, model, id string) error {
	var out struct {
		Success bool   `json:"success"`
		Message string `json:"message"`
	}
	if err := c.do(ctx, http.MethodPost, "/v1/chat/completions/control", nil,
		c.withModel(model, map[string]any{"id": id, "action": "reasoning_end"}), timeout, &out); err != nil {
		return err
	}
	if !out.Success {
		return fmt.Errorf("llama.cpp: %s", out.Message)
	}
	return nil
}
