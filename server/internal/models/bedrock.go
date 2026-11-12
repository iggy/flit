package models

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"regexp"
	"slices"
	"strings"

	"github.com/iggy/flit/server/internal/config"
)

// Amazon Bedrock discovery. Mantle has an OpenAI-style /models that lists
// ids only; Runtime has none. Both are described by the region's control
// plane (ListFoundationModels, which takes the same Bedrock API key), and
// Runtime's profile-only models are called through inference profiles
// (ListInferenceProfiles), e.g. us.openai.gpt-5.5.

// bedrockFM is one ListFoundationModels summary, as much as flit reads.
type bedrockFM struct {
	ModelID                 string   `json:"modelId"`
	ModelName               string   `json:"modelName"`
	InputModalities         []string `json:"inputModalities"`
	OutputModalities        []string `json:"outputModalities"`
	InferenceTypesSupported []string `json:"inferenceTypesSupported"`
	InferenceAPIsSupported  struct {
		OpenAIChatCompletions bool `json:"openAiChatCompletions"`
	} `json:"inferenceAPIsSupported"`
	Converse *struct {
		// MaxTokensMaximum is taken as the context window; Bedrock reports
		// nothing closer.
		MaxTokensMaximum int64           `json:"maxTokensMaximum"`
		ReasoningSup     json.RawMessage `json:"reasoningSupported"`
		// AdditionalRequestFieldsSchema is a JSON string, e.g.
		// {"reasoning_config":{"type":"enum","enum":["low","high"]}} or
		// {"reasoningConfig":{"enabled":{"type":"boolean"}}}.
		AdditionalRequestFieldsSchema string `json:"additionalRequestFieldsSchema"`
	} `json:"converse"`
}

// chat reports whether the model answers OpenAI chat completions with text.
func (f bedrockFM) chat() bool {
	return f.InferenceAPIsSupported.OpenAIChatCompletions && slices.Contains(f.OutputModalities, "TEXT")
}

// fill copies what Bedrock says about the model into m.
func (f bedrockFM) fill(m *Model) {
	m.DisplayName = f.ModelName
	if f.Converse != nil {
		m.ContextLength = f.Converse.MaxTokensMaximum
	}
	// Bedrock doesn't say; the chat-completions models flit lists are
	// tool-capable as a rule.
	m.SupportsTools = true
	m.SupportsVision = slices.Contains(f.InputModalities, "IMAGE")
	m.SupportsReasoning, m.Efforts = f.reasoning()
	if m.SupportsReasoning && len(m.Efforts) == 0 {
		m.Efforts = slices.Clone(defaultEfforts)
	}
}

func (f bedrockFM) reasoning() (bool, []string) {
	if f.Converse == nil {
		return false, nil
	}
	sup := len(f.Converse.ReasoningSup) > 0 && string(f.Converse.ReasoningSup) != "null"
	var schema map[string]json.RawMessage
	if json.Unmarshal([]byte(f.Converse.AdditionalRequestFieldsSchema), &schema) != nil {
		return sup, nil
	}
	if raw, ok := schema["reasoning_config"]; ok {
		var e struct {
			Enum []string `json:"enum"`
		}
		_ = json.Unmarshal(raw, &e)
		return true, effortLevels(e.Enum)
	}
	_, ok := schema["reasoningConfig"]
	return sup || ok, nil
}

type bedrockProfile struct {
	ID     string `json:"inferenceProfileId"`
	Name   string `json:"inferenceProfileName"`
	Status string `json:"status"`
	Models []struct {
		ARN string `json:"modelArn"`
	} `json:"models"`
}

// modelID is the foundation model a profile routes to, from the first
// model ARN (arn:aws:bedrock:REGION::foundation-model/ID).
func (p bedrockProfile) modelID() string {
	if len(p.Models) == 0 {
		return ""
	}
	_, id, _ := strings.Cut(p.Models[0].ARN, ":foundation-model/")
	return id
}

func (c *Catalog) discoverBedrock(ctx context.Context, p config.Provider) ([]Model, error) {
	ctx, cancel := context.WithTimeout(ctx, discoveryTimeout)
	defer cancel()
	fms, fmErr := c.foundationModels(ctx, p)
	if p.Endpoint == config.BedrockRuntime {
		if fmErr != nil {
			return nil, fmErr
		}
		profiles, err := c.inferenceProfiles(ctx, p)
		if err != nil {
			return nil, err
		}
		return runtimeModels(p.Name, fms, profiles), nil
	}
	body, err := c.get(ctx, p, strings.TrimSuffix(p.BaseURL, "/")+"/models")
	if err != nil {
		return nil, err
	}
	var resp struct {
		Data []struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("read /models response: %w", err)
	}
	ids := make([]string, 0, len(resp.Data))
	for _, d := range resp.Data {
		if d.ID != "" {
			ids = append(ids, d.ID)
		}
	}
	if fmErr != nil {
		// Model details are a bonus on Mantle; list the ids anyway.
		c.log.Warn("bedrock model details unavailable", "provider", p.Name, "err", fmErr)
	}
	return mantleModels(p.Name, ids, fms), nil
}

func (c *Catalog) foundationModels(ctx context.Context, p config.Provider) ([]bedrockFM, error) {
	body, err := c.get(ctx, p, p.BedrockControlURL()+"/foundation-models")
	if err != nil {
		return nil, err
	}
	var resp struct {
		ModelSummaries []bedrockFM `json:"modelSummaries"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, fmt.Errorf("read foundation-models response: %w", err)
	}
	return resp.ModelSummaries, nil
}

// maxProfilePages bounds ListInferenceProfiles paging, in case a server
// keeps handing back a token.
const maxProfilePages = 20

func (c *Catalog) inferenceProfiles(ctx context.Context, p config.Provider) ([]bedrockProfile, error) {
	var out []bedrockProfile
	token := ""
	for range maxProfilePages {
		q := url.Values{"maxResults": {"1000"}}
		if token != "" {
			q.Set("nextToken", token)
		}
		body, err := c.get(ctx, p, p.BedrockControlURL()+"/inference-profiles?"+q.Encode())
		if err != nil {
			return nil, err
		}
		var resp struct {
			Summaries []bedrockProfile `json:"inferenceProfileSummaries"`
			NextToken *string          `json:"nextToken"`
		}
		if err := json.Unmarshal(body, &resp); err != nil {
			return nil, fmt.Errorf("read inference-profiles response: %w", err)
		}
		out = append(out, resp.Summaries...)
		if resp.NextToken == nil || *resp.NextToken == "" {
			break
		}
		token = *resp.NextToken
	}
	return out, nil
}

// runtimeModels lists what Runtime can run over chat completions: models
// with on-demand throughput by their own id, and every active inference
// profile (us., global., ...) of a chat model. A profile-only model's bare
// id can't be called, so it isn't listed.
func runtimeModels(provider string, fms []bedrockFM, profiles []bedrockProfile) []Model {
	byID := map[string]bedrockFM{}
	var out []Model
	for _, f := range fms {
		byID[f.ModelID] = f
		if !f.chat() || !slices.Contains(f.InferenceTypesSupported, "ON_DEMAND") {
			continue
		}
		m := Model{Provider: provider, ID: f.ModelID, Discovered: true}
		f.fill(&m)
		out = append(out, m)
	}
	for _, pr := range profiles {
		f, ok := byID[pr.modelID()]
		if pr.ID == "" || pr.Status != "ACTIVE" || !ok || !f.chat() {
			continue
		}
		m := Model{Provider: provider, ID: pr.ID, Discovered: true}
		f.fill(&m)
		if pr.Name != "" {
			m.DisplayName = pr.Name
		}
		out = append(out, m)
	}
	return out
}

// versionSuffix is a foundation model id's version, as in
// openai.gpt-oss-20b-1:0 or qwen.qwen3-32b-v1:0; Mantle's ids drop it.
var versionSuffix = regexp.MustCompile(`-v?[0-9]+(:[0-9]+)?$|:[0-9]+$`)

// mantleModels lists Mantle's ids, with details from ListFoundationModels
// where an id matches (as is, or without its version suffix). Models that
// don't do chat completions are left out: those it marks so, and Claude
// (anthropic.*), which Mantle serves only over the Anthropic Messages API.
func mantleModels(provider string, ids []string, fms []bedrockFM) []Model {
	exact := map[string]bedrockFM{}
	loose := map[string]bedrockFM{}
	for _, f := range fms {
		exact[f.ModelID] = f
		if k := versionSuffix.ReplaceAllString(f.ModelID, ""); k != f.ModelID {
			if _, taken := loose[k]; !taken {
				loose[k] = f
			}
		}
	}
	out := make([]Model, 0, len(ids))
	for _, id := range ids {
		f, ok := exact[id]
		if !ok {
			f, ok = loose[id]
		}
		if ok && !f.chat() || !ok && strings.HasPrefix(id, "anthropic.") {
			continue
		}
		m := Model{Provider: provider, ID: id, Discovered: true}
		if ok {
			f.fill(&m)
		}
		out = append(out, m)
	}
	return out
}
