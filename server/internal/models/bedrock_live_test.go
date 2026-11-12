package models

import (
	"context"
	"io"
	"log/slog"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/llm"
)

// TestBedrockLive runs discovery and a short chat against real Amazon
// Bedrock endpoints. It needs FLIT_TEST_BEDROCK_KEY (a Bedrock API key) and
// FLIT_TEST_BEDROCK_REGION, e.g. us-west-2.
func TestBedrockLive(t *testing.T) {
	key, region := os.Getenv("FLIT_TEST_BEDROCK_KEY"), os.Getenv("FLIT_TEST_BEDROCK_REGION")
	if key == "" || region == "" {
		t.Skip("set FLIT_TEST_BEDROCK_KEY and FLIT_TEST_BEDROCK_REGION to run against Amazon Bedrock")
	}
	cfg, err := config.Parse([]byte(`
providers:
  - {name: mantle, kind: bedrock, region: ` + region + `, endpoint: mantle, api_key_env: FLIT_TEST_BEDROCK_KEY}
  - {name: runtime, kind: bedrock, region: ` + region + `, endpoint: runtime, api_key_env: FLIT_TEST_BEDROCK_KEY}
`))
	if err != nil {
		t.Fatal(err)
	}
	c := NewCatalog(func() config.Config { return cfg }, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err := c.Refresh(context.Background(), ""); err != nil {
		t.Fatal(err)
	}
	for _, st := range c.Providers() {
		if st.Err != "" || st.ModelCount == 0 {
			t.Fatalf("%s: %d models, err %q", st.Name, st.ModelCount, st.Err)
		}
		t.Logf("%s (%s): %d models", st.Name, st.BaseURL, st.ModelCount)
	}

	// One model per route: Mantle /v1, Mantle /openai/v1 (found by the
	// retry), Runtime on-demand and Runtime through an inference profile.
	// Models the region doesn't list are skipped.
	chats := []struct{ provider, prefix string }{
		{"mantle", "openai.gpt-oss-20b"},
		{"mantle", "google.gemma-4"},
		{"runtime", "openai.gpt-oss-20b"},
		{"runtime", "us.openai.gpt-5"},
	}
	for _, ch := range chats {
		var model string
		for _, m := range c.Models(ch.provider) {
			if strings.HasPrefix(m.ID, ch.prefix) {
				model = m.ID
				break
			}
		}
		if model == "" {
			t.Logf("%s: no %s* model listed; skipped", ch.provider, ch.prefix)
			continue
		}
		p, _ := cfg.Provider(ch.provider)
		client := &llm.Client{BaseURL: p.BaseURL, AltBaseURL: p.AltBaseURL(), APIKey: p.Key()}
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
		res, err := client.Stream(ctx, llm.Request{Model: model, Messages: []llm.Message{{Role: "user", Content: "Reply with the word ok."}}}, llm.Handler{})
		cancel()
		if err != nil {
			t.Errorf("%s %s: %v", ch.provider, model, err)
			continue
		}
		t.Logf("%s %s: %q", ch.provider, model, res.Text)
	}
}
