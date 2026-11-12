package config

import (
	"strings"
	"testing"
)

func TestBedrockProviders(t *testing.T) {
	cfg, err := Parse([]byte(`
providers:
  - name: mantle
    kind: bedrock
    region: us-west-2
    endpoint: mantle
  - name: runtime
    kind: bedrock
    region: eu-central-1
    endpoint: runtime
    api_key_env: MY_KEY
  - name: proxied
    kind: bedrock
    region: us-east-1
    endpoint: mantle
    base_url: https://proxy.example/openai/v1/
`))
	if err != nil {
		t.Fatal(err)
	}
	m, _ := cfg.Provider("mantle")
	if m.BaseURL != "https://bedrock-mantle.us-west-2.api.aws/v1" || m.APIKeyEnv != BedrockKeyEnv {
		t.Errorf("mantle = %+v", m)
	}
	if got := m.AltBaseURL(); got != "https://bedrock-mantle.us-west-2.api.aws/openai/v1" {
		t.Errorf("mantle alt = %q", got)
	}
	if got := m.BedrockControlURL(); got != "https://bedrock.us-west-2.amazonaws.com" {
		t.Errorf("mantle control = %q", got)
	}
	r, _ := cfg.Provider("runtime")
	if r.BaseURL != "https://bedrock-runtime.eu-central-1.amazonaws.com/openai/v1" || r.APIKeyEnv != "MY_KEY" || r.AltBaseURL() != "" {
		t.Errorf("runtime = %+v, alt %q", r, r.AltBaseURL())
	}
	p, _ := cfg.Provider("proxied")
	if p.BaseURL != "https://proxy.example/openai/v1/" || p.AltBaseURL() != "https://proxy.example/v1" {
		t.Errorf("proxied = %+v, alt %q", p, p.AltBaseURL())
	}
	if (Provider{Name: "x", BaseURL: "http://h/v1"}).AltBaseURL() != "" {
		t.Error("non-bedrock provider has an alt base URL")
	}
}

func TestBedrockProviderErrors(t *testing.T) {
	for _, tc := range []struct{ yaml, want string }{
		{"kind: bedrock\n    endpoint: mantle", "region"},
		{"kind: bedrock\n    region: Oregon\n    endpoint: mantle", "region"},
		{"kind: bedrock\n    region: us-west-2", "endpoint"},
		{"kind: bedrock\n    region: us-west-2\n    endpoint: converse", "endpoint"},
		{"base_url: http://h/v1\n    region: us-west-2", "only for kind bedrock"},
	} {
		_, err := Parse([]byte("providers:\n  - name: b\n    " + tc.yaml + "\n"))
		if err == nil || !strings.Contains(err.Error(), tc.want) {
			t.Errorf("%q: err = %v, want %q", tc.yaml, err, tc.want)
		}
	}
}
