package config

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
)

// Amazon Bedrock, reached through its OpenAI-compatible endpoints with a
// Bedrock API key as the bearer token.
const (
	// KindBedrock is Provider.Kind for Amazon Bedrock.
	KindBedrock = "bedrock"
	// BedrockMantle and BedrockRuntime are the Provider.Endpoint values.
	BedrockMantle  = "mantle"
	BedrockRuntime = "runtime"
	// BedrockKeyEnv is where a bedrock provider's key is read from when
	// neither api_key nor api_key_env is set; the AWS SDKs use it too.
	BedrockKeyEnv = "AWS_BEARER_TOKEN_BEDROCK"
)

// awsRegion is an AWS region name, e.g. us-west-2 or ap-southeast-1.
var awsRegion = regexp.MustCompile(`^[a-z]{2}(-[a-z]+)+-[0-9]+$`)

// IsBedrock reports whether p is an Amazon Bedrock provider.
func (p Provider) IsBedrock() bool { return p.Kind == KindBedrock }

// fillBedrock derives a bedrock provider's base_url and key variable.
// Invalid settings are left for validateBedrock to report.
func (p *Provider) fillBedrock() {
	if !p.IsBedrock() {
		return
	}
	if p.BaseURL == "" && awsRegion.MatchString(p.Region) {
		switch p.Endpoint {
		case BedrockMantle:
			p.BaseURL = "https://bedrock-mantle." + p.Region + ".api.aws/v1"
		case BedrockRuntime:
			p.BaseURL = "https://bedrock-runtime." + p.Region + ".amazonaws.com/openai/v1"
		}
	}
	if p.APIKey == "" && p.APIKeyEnv == "" {
		p.APIKeyEnv = BedrockKeyEnv
	}
}

func (p Provider) validateBedrock() error {
	if !p.IsBedrock() {
		if p.Region != "" || p.Endpoint != "" {
			return errors.New("region and endpoint are only for kind bedrock")
		}
		return nil
	}
	if !awsRegion.MatchString(p.Region) {
		return fmt.Errorf("kind bedrock: region %q: want an AWS region such as us-west-2", p.Region)
	}
	if p.Endpoint != BedrockMantle && p.Endpoint != BedrockRuntime {
		return fmt.Errorf("kind bedrock: endpoint %q: want %s or %s", p.Endpoint, BedrockMantle, BedrockRuntime)
	}
	return nil
}

// AltBaseURL is a second API root to try for a model the base URL's route
// doesn't serve, or "". Bedrock Mantle serves most models under /v1 and
// some (GPT-5.x, Gemma 4, ...) only under /openai/v1, and doesn't say which
// is which.
func (p Provider) AltBaseURL() string {
	if !p.IsBedrock() || p.Endpoint != BedrockMantle {
		return ""
	}
	base := strings.TrimSuffix(p.BaseURL, "/")
	if root, ok := strings.CutSuffix(base, "/openai/v1"); ok {
		return root + "/v1"
	}
	if root, ok := strings.CutSuffix(base, "/v1"); ok {
		return root + "/openai/v1"
	}
	return ""
}

// BedrockControlURL is the root of the region's Bedrock control-plane API
// (ListFoundationModels, ListInferenceProfiles), or "" for other providers.
func (p Provider) BedrockControlURL() string {
	if !p.IsBedrock() {
		return ""
	}
	return "https://bedrock." + p.Region + ".amazonaws.com"
}
