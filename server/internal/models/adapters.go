package models

import (
	"encoding/json"
	"fmt"
	"slices"
	"strconv"
	"strings"
)

// Kind is how a provider's /models response is read.
type Kind string

const (
	KindOpenAI     Kind = "openai"
	KindOpenRouter Kind = "openrouter"
	KindLlamaCpp   Kind = "llamacpp"
	KindGoModel    Kind = "gomodel"
)

// defaultEfforts are offered for reasoning models whose provider doesn't
// list levels.
var defaultEfforts = []string{"low", "medium", "high"}

// rawModel is the union of the fields the adapters read from one entry of
// a /models "data" array.
type rawModel struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	OwnedBy string `json:"owned_by"`

	// OpenRouter.
	ContextLength       int64    `json:"context_length"`
	SupportedParameters []string `json:"supported_parameters"`
	Architecture        struct {
		InputModalities []string `json:"input_modalities"`
	} `json:"architecture"`
	TopProvider struct {
		ContextLength int64 `json:"context_length"`
	} `json:"top_provider"`

	// llama.cpp (single model: meta; router mode: status.args).
	Meta *struct {
		NCtxTrain int64 `json:"n_ctx_train"`
		NCtx      int64 `json:"n_ctx"`
	} `json:"meta"`
	Status *struct {
		Value  string   `json:"value"`
		Args   []string `json:"args"`
		Failed bool     `json:"failed"`
	} `json:"status"`

	// gomodel.
	Metadata *struct {
		DisplayName   string          `json:"display_name"`
		ContextWindow *int64          `json:"context_window"`
		Capabilities  map[string]bool `json:"capabilities"`
	} `json:"metadata"`
}

type modelsResponse struct {
	Data []json.RawMessage `json:"data"`
}

// detectKind guesses a provider's kind from its URL and /models response.
func detectKind(baseURL string, entries []rawModel) Kind {
	if strings.Contains(strings.ToLower(baseURL), "openrouter.ai") {
		return KindOpenRouter
	}
	for _, e := range entries {
		switch {
		case e.OwnedBy == "llamacpp" || e.Meta != nil || e.Status != nil:
			return KindLlamaCpp
		case e.Metadata != nil:
			return KindGoModel
		case len(e.SupportedParameters) > 0 || e.TopProvider.ContextLength > 0:
			return KindOpenRouter
		}
	}
	return KindOpenAI
}

// parseModels reads a /models response. kind "" means detect.
func parseModels(provider, baseURL string, kind Kind, body []byte) (Kind, []Model, error) {
	var resp modelsResponse
	if err := json.Unmarshal(body, &resp); err != nil {
		return kind, nil, fmt.Errorf("read /models response: %w", err)
	}
	entries := make([]rawModel, 0, len(resp.Data))
	for _, raw := range resp.Data {
		var e rawModel
		if err := json.Unmarshal(raw, &e); err != nil || e.ID == "" {
			continue // skip entries we can't read rather than fail the provider
		}
		entries = append(entries, e)
	}
	if kind == "" {
		kind = detectKind(baseURL, entries)
	}
	out := make([]Model, 0, len(entries))
	for _, e := range entries {
		m := Model{Provider: provider, ID: e.ID, DisplayName: e.Name, Discovered: true}
		switch kind {
		case KindOpenRouter:
			m.ContextLength = max(e.ContextLength, e.TopProvider.ContextLength)
			m.SupportsTools = slices.Contains(e.SupportedParameters, "tools")
			m.SupportsReasoning = slices.Contains(e.SupportedParameters, "reasoning") ||
				slices.Contains(e.SupportedParameters, "include_reasoning")
			m.SupportsVision = slices.Contains(e.Architecture.InputModalities, "image")
		case KindLlamaCpp:
			llamaCpp(&m, e)
		case KindGoModel:
			if md := e.Metadata; md != nil {
				if md.DisplayName != "" {
					m.DisplayName = md.DisplayName
				}
				if md.ContextWindow != nil {
					m.ContextLength = *md.ContextWindow
				}
				c := md.Capabilities
				m.SupportsTools = c["tools"] || c["function_calling"]
				m.SupportsReasoning = c["reasoning"]
				m.SupportsVision = c["vision"]
			}
		}
		if m.SupportsReasoning {
			m.Efforts = slices.Clone(defaultEfforts)
		}
		out = append(out, m)
	}
	return kind, out, nil
}

// llamaCpp fills in what llama-server reports. A single-model server puts
// the context size in meta; a router lists each model's launch arguments,
// where --ctx-size (split across --parallel slots) is the window and
// --jinja enables tool calls.
func llamaCpp(m *Model, e rawModel) {
	if e.Meta != nil {
		m.ContextLength = e.Meta.NCtx
		if m.ContextLength == 0 {
			m.ContextLength = e.Meta.NCtxTrain
		}
		m.SupportsTools = true // single-model servers report no flags; assume a tool-capable setup
		m.Loaded = true
	}
	if e.Status == nil {
		return
	}
	m.Loaded = e.Status.Value == "loaded"
	m.State = State(e.Status.Value)
	if e.Status.Failed {
		m.State = StateFailed
	}
	args := e.Status.Args
	ctx := argInt(args, "--ctx-size", "-c")
	if parallel := argInt(args, "--parallel", "-np"); parallel > 1 && !slices.Contains(args, "--kv-unified") {
		ctx /= parallel
	}
	if ctx > 0 {
		m.ContextLength = ctx
	}
	m.SupportsTools = slices.Contains(args, "--jinja")
	m.SupportsReasoning = slices.Contains(args, "--reasoning-preserve") ||
		slices.Contains(args, "--reasoning-format") || slices.Contains(args, "--reasoning-budget")
	m.SupportsVision = slices.Contains(args, "--mmproj")
}

// argInt returns the integer value of the first matching flag, or 0.
func argInt(args []string, names ...string) int64 {
	for i, a := range args {
		for _, n := range names {
			var v string
			switch {
			case a == n && i+1 < len(args):
				v = args[i+1]
			case strings.HasPrefix(a, n+"="):
				v = strings.TrimPrefix(a, n+"=")
			default:
				continue
			}
			if x, err := strconv.ParseInt(v, 10, 64); err == nil {
				return x
			}
		}
	}
	return 0
}
