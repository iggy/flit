package models

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"slices"
	"testing"

	"github.com/iggy/flit/server/internal/config"
)

// Trimmed from real us-west-2 responses.
const (
	bedrockFoundationModels = `{"modelSummaries":[
	{"modelId":"openai.gpt-oss-20b-1:0","modelName":"gpt-oss-20b","inputModalities":["TEXT"],"outputModalities":["TEXT"],
	 "inferenceTypesSupported":["ON_DEMAND"],"inferenceAPIsSupported":{"openAiChatCompletions":true},
	 "converse":{"maxTokensMaximum":128000,"reasoningSupported":{"embedded":false},"additionalRequestFieldsSchema":null}},
	{"modelId":"openai.gpt-5.5","modelName":"GPT 5.5","inputModalities":["TEXT","IMAGE"],"outputModalities":["TEXT"],
	 "inferenceTypesSupported":["INFERENCE_PROFILE"],"inferenceAPIsSupported":{"openAiChatCompletions":true},
	 "converse":{"maxTokensMaximum":131072,"reasoningSupported":{"embedded":false},
	  "additionalRequestFieldsSchema":"{\"reasoning_config\":{\"type\":\"enum\",\"default\":\"medium\",\"enum\":[\"none\",\"low\",\"medium\",\"high\",\"xhigh\"]}}"}},
	{"modelId":"moonshotai.kimi-k2.5","modelName":"Kimi K2.5","inputModalities":["TEXT","IMAGE"],"outputModalities":["TEXT"],
	 "inferenceTypesSupported":["ON_DEMAND"],"inferenceAPIsSupported":{"openAiChatCompletions":true},
	 "converse":{"maxTokensMaximum":262144,"reasoningSupported":null,
	  "additionalRequestFieldsSchema":"{\"reasoningConfig\":{\"enabled\":{\"type\":\"boolean\",\"default\":false}}}"}},
	{"modelId":"mistral.devstral-2-123b","modelName":"Devstral 2 123B","inputModalities":["TEXT"],"outputModalities":["TEXT"],
	 "inferenceTypesSupported":["ON_DEMAND"],"inferenceAPIsSupported":{"openAiChatCompletions":true},
	 "converse":{"maxTokensMaximum":262144,"reasoningSupported":null,"additionalRequestFieldsSchema":"{}"}},
	{"modelId":"anthropic.claude-haiku-4-5-20251001-v1:0","modelName":"Claude Haiku 4.5","inputModalities":["TEXT","IMAGE"],"outputModalities":["TEXT"],
	 "inferenceTypesSupported":["INFERENCE_PROFILE"],"inferenceAPIsSupported":{"openAiChatCompletions":false}},
	{"modelId":"cohere.embed-v4:0","modelName":"Embed v4","inputModalities":["TEXT"],"outputModalities":["EMBEDDING"],
	 "inferenceTypesSupported":["ON_DEMAND"],"inferenceAPIsSupported":{"openAiChatCompletions":false}}
	]}`
	bedrockProfiles = `{"inferenceProfileSummaries":[
	{"inferenceProfileId":"us.openai.gpt-5.5","inferenceProfileName":"US GPT 5.5","status":"ACTIVE",
	 "models":[{"modelArn":"arn:aws:bedrock:us-east-1::foundation-model/openai.gpt-5.5"},{"modelArn":"arn:aws:bedrock:us-west-2::foundation-model/openai.gpt-5.5"}]},
	{"inferenceProfileId":"global.openai.gpt-5.5","inferenceProfileName":"Global GPT 5.5","status":"ACTIVE",
	 "models":[{"modelArn":"arn:aws:bedrock:::foundation-model/openai.gpt-5.5"}]},
	{"inferenceProfileId":"us.anthropic.claude-haiku-4-5-20251001-v1:0","inferenceProfileName":"US Claude Haiku 4.5","status":"ACTIVE",
	 "models":[{"modelArn":"arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"}]},
	{"inferenceProfileId":"us.cohere.embed-v4:0","status":"ACTIVE","models":[{"modelArn":"arn:aws:bedrock:us-west-2::foundation-model/cohere.embed-v4:0"}]}
	],"nextToken":"page2"}`
	bedrockProfiles2 = `{"inferenceProfileSummaries":[
	{"inferenceProfileId":"eu.openai.gpt-5.5","inferenceProfileName":"EU GPT 5.5","status":"INACTIVE",
	 "models":[{"modelArn":"arn:aws:bedrock:eu-west-1::foundation-model/openai.gpt-5.5"}]},
	{"inferenceProfileId":"us.moonshotai.kimi-k2.5","inferenceProfileName":"US Kimi K2.5","status":"ACTIVE",
	 "models":[{"modelArn":"arn:aws:bedrock:us-west-2::foundation-model/moonshotai.kimi-k2.5"}]}
	],"nextToken":null}`
	mantleModelList = `{"object":"list","data":[
	{"id":"openai.gpt-oss-20b","object":"model","owned_by":"system","status":"available"},
	{"id":"openai.gpt-5.5","object":"model","owned_by":"system","status":"available"},
	{"id":"moonshotai.kimi-k2.5","object":"model","owned_by":"system","status":"available"},
	{"id":"anthropic.claude-haiku-4-5","object":"model","owned_by":"system","status":"available"},
	{"id":"google.gemma-4-31b","object":"model","owned_by":"system","status":"available"}
	]}`
)

// hostRewriter sends every request to srv, recording the host it was for
// in X-Test-Host.
type hostRewriter struct{ srv *url.URL }

func (h hostRewriter) RoundTrip(r *http.Request) (*http.Response, error) {
	r = r.Clone(r.Context())
	r.Header.Set("X-Test-Host", r.URL.Host)
	r.URL.Scheme, r.URL.Host = h.srv.Scheme, h.srv.Host
	return http.DefaultTransport.RoundTrip(r)
}

func fakeBedrock(t *testing.T, controlUp bool) *Catalog {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer bk" {
			http.Error(w, "no key", http.StatusForbidden)
			return
		}
		host := r.Header.Get("X-Test-Host")
		switch {
		case host == "bedrock.us-west-2.amazonaws.com" && !controlUp:
			http.Error(w, "denied", http.StatusForbidden)
		case host == "bedrock.us-west-2.amazonaws.com" && r.URL.Path == "/foundation-models":
			_, _ = io.WriteString(w, bedrockFoundationModels)
		case host == "bedrock.us-west-2.amazonaws.com" && r.URL.Path == "/inference-profiles":
			if r.URL.Query().Get("nextToken") == "page2" {
				_, _ = io.WriteString(w, bedrockProfiles2)
			} else {
				_, _ = io.WriteString(w, bedrockProfiles)
			}
		case host == "bedrock-mantle.us-west-2.api.aws" && r.URL.Path == "/v1/models":
			_, _ = io.WriteString(w, mantleModelList)
		default:
			http.Error(w, "<UnknownOperationException/>", http.StatusNotFound)
		}
	}))
	t.Cleanup(srv.Close)
	u, _ := url.Parse(srv.URL)
	cfg, err := config.Parse([]byte(`
providers:
  - {name: mantle, kind: bedrock, region: us-west-2, endpoint: mantle, api_key: bk}
  - {name: runtime, kind: bedrock, region: us-west-2, endpoint: runtime, api_key: bk}
`))
	if err != nil {
		t.Fatal(err)
	}
	c := NewCatalog(func() config.Config { return cfg }, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	c.http.Transport = hostRewriter{u}
	if err := c.Refresh(context.Background(), ""); err != nil {
		t.Fatal(err)
	}
	return c
}

func ids(ms []Model) []string {
	out := make([]string, len(ms))
	for i, m := range ms {
		out[i] = m.ID
	}
	return out
}

func TestBedrockRuntimeDiscovery(t *testing.T) {
	c := fakeBedrock(t, true)
	for _, st := range c.Providers() {
		if st.Err != "" || st.Kind != KindBedrock {
			t.Errorf("%s: status %+v", st.Name, st)
		}
	}
	got := ids(c.Models("runtime"))
	want := []string{"global.openai.gpt-5.5", "mistral.devstral-2-123b", "moonshotai.kimi-k2.5", "openai.gpt-oss-20b-1:0", "us.moonshotai.kimi-k2.5", "us.openai.gpt-5.5"}
	if !slices.Equal(got, want) {
		t.Fatalf("runtime models = %v\nwant %v", got, want)
	}
	m, _ := c.Lookup("runtime", "us.openai.gpt-5.5")
	if m.DisplayName != "US GPT 5.5" || m.ContextLength != 131072 || !m.SupportsTools || !m.SupportsVision ||
		!m.SupportsReasoning || !slices.Equal(m.Efforts, []string{"low", "medium", "high", "xhigh"}) || !m.Discovered {
		t.Errorf("us.openai.gpt-5.5 = %+v", m)
	}
	m, _ = c.Lookup("runtime", "moonshotai.kimi-k2.5")
	if m.DisplayName != "Kimi K2.5" || !m.SupportsReasoning || !slices.Equal(m.Efforts, defaultEfforts) || !m.SupportsVision {
		t.Errorf("kimi = %+v", m)
	}
	m, _ = c.Lookup("runtime", "openai.gpt-oss-20b-1:0")
	if m.ContextLength != 128000 || !m.SupportsReasoning || m.SupportsVision {
		t.Errorf("gpt-oss = %+v", m)
	}
	m, _ = c.Lookup("runtime", "mistral.devstral-2-123b")
	if m.SupportsReasoning || len(m.Efforts) != 0 {
		t.Errorf("devstral = %+v", m)
	}
}

func TestBedrockMantleDiscovery(t *testing.T) {
	c := fakeBedrock(t, true)
	got := ids(c.Models("mantle"))
	want := []string{"google.gemma-4-31b", "moonshotai.kimi-k2.5", "openai.gpt-5.5", "openai.gpt-oss-20b"}
	if !slices.Equal(got, want) {
		t.Fatalf("mantle models = %v\nwant %v", got, want)
	}
	m, _ := c.Lookup("mantle", "openai.gpt-oss-20b") // matched without the -1:0
	if m.DisplayName != "gpt-oss-20b" || m.ContextLength != 128000 || !m.SupportsReasoning {
		t.Errorf("gpt-oss = %+v", m)
	}
	m, _ = c.Lookup("mantle", "google.gemma-4-31b") // no details
	if m.DisplayName != "" || m.ContextLength != 0 || !m.Discovered {
		t.Errorf("gemma = %+v", m)
	}
}

// Mantle lists its ids even when the control plane refuses; Runtime has
// nothing to go on and fails.
func TestBedrockControlPlaneDown(t *testing.T) {
	c := fakeBedrock(t, false)
	if got := ids(c.Models("mantle")); len(got) != 4 {
		t.Errorf("mantle models = %v", got)
	}
	m, _ := c.Lookup("mantle", "openai.gpt-oss-20b")
	if m.ContextLength != 0 {
		t.Errorf("gpt-oss = %+v", m)
	}
	for _, st := range c.Providers() {
		if (st.Err != "") != (st.Name == "runtime") {
			t.Errorf("%s: err = %q", st.Name, st.Err)
		}
	}
}
