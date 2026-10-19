package models

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/iggy/flit/server/internal/config"
)

// Fixtures trimmed from real responses.
const (
	llamaRouter = `{"data":[
 {"id":"qwen/big","object":"model","owned_by":"llamacpp","status":{"value":"loaded","args":["/app/llama-server","--jinja","--reasoning-preserve","--ctx-size","262144","--parallel","1"]}},
 {"id":"tiny","object":"model","owned_by":"llamacpp","status":{"value":"unloaded","args":["--ctx-size=32768","--parallel","4"]}}
]}`
	llamaSingle = `{"object":"list","data":[{"id":"model.gguf","object":"model","owned_by":"llamacpp","meta":{"n_ctx_train":131072,"n_params":7000000000}}]}`
	openRouter  = `{"data":[
 {"id":"anthropic/x","name":"X","context_length":200000,"supported_parameters":["tools","reasoning","temperature"],"architecture":{"input_modalities":["text","image"]},"top_provider":{"context_length":200000}},
 {"id":"meta/y","name":"Y","context_length":8192,"supported_parameters":["temperature"],"architecture":{"input_modalities":["text"]}}
]}`
	goModel = `{"object":"list","data":[
 {"id":"gpt-x","object":"model","owned_by":"openai","metadata":{"display_name":"GPT X","context_window":400000,"capabilities":{"function_calling":true,"reasoning":true,"vision":true}}},
 {"id":"embed","object":"model","owned_by":"openai","metadata":{"capabilities":{"embedding":true}}}
]}`
	plainOpenAI = `{"object":"list","data":[{"id":"m1","object":"model","owned_by":"someone"}]}`
)

func byID(ms []Model) map[string]Model {
	out := map[string]Model{}
	for _, m := range ms {
		out[m.ID] = m
	}
	return out
}

func TestAdapters(t *testing.T) {
	kind, ms, err := parseModels("p", "http://x/v1", "", []byte(llamaRouter))
	if err != nil || kind != KindLlamaCpp {
		t.Fatalf("router: %v %v", kind, err)
	}
	m := byID(ms)
	if big := m["qwen/big"]; big.ContextLength != 262144 || !big.SupportsTools || !big.SupportsReasoning || !big.Loaded || len(big.Efforts) != 3 {
		t.Errorf("router big = %+v", big)
	}
	if tiny := m["tiny"]; tiny.ContextLength != 8192 || tiny.SupportsTools || tiny.Loaded {
		t.Errorf("router tiny (32768 over 4 slots) = %+v", tiny)
	}

	kind, ms, _ = parseModels("p", "http://x/v1", "", []byte(llamaSingle))
	if kind != KindLlamaCpp || ms[0].ContextLength != 131072 || !ms[0].SupportsTools {
		t.Errorf("single llama.cpp: %v %+v", kind, ms)
	}

	kind, ms, _ = parseModels("p", "https://openrouter.ai/api/v1", "", []byte(openRouter))
	m = byID(ms)
	if kind != KindOpenRouter || m["anthropic/x"].ContextLength != 200000 || !m["anthropic/x"].SupportsTools ||
		!m["anthropic/x"].SupportsReasoning || !m["anthropic/x"].SupportsVision || m["anthropic/x"].DisplayName != "X" {
		t.Errorf("openrouter x = %v %+v", kind, m["anthropic/x"])
	}
	if y := m["meta/y"]; y.SupportsTools || y.SupportsReasoning || y.ContextLength != 8192 {
		t.Errorf("openrouter y = %+v", y)
	}

	kind, ms, _ = parseModels("p", "http://gw/v1", "", []byte(goModel))
	m = byID(ms)
	if kind != KindGoModel || m["gpt-x"].ContextLength != 400000 || !m["gpt-x"].SupportsTools || m["gpt-x"].DisplayName != "GPT X" {
		t.Errorf("gomodel = %v %+v", kind, m["gpt-x"])
	}

	kind, ms, _ = parseModels("p", "http://x/v1", "", []byte(plainOpenAI))
	if kind != KindOpenAI || ms[0].ContextLength != 0 || ms[0].SupportsTools {
		t.Errorf("plain = %v %+v", kind, ms)
	}

	// An explicit kind wins over detection.
	if kind, _, _ := parseModels("p", "http://x/v1", KindOpenAI, []byte(llamaRouter)); kind != KindOpenAI {
		t.Errorf("explicit kind ignored: %v", kind)
	}
	if _, _, err := parseModels("p", "", "", []byte("not json")); err == nil {
		t.Error("bad JSON accepted")
	}
}

func TestCatalog(t *testing.T) {
	var fail bool
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/models" || r.Header.Get("Authorization") != "Bearer k" {
			http.Error(w, "bad request", http.StatusBadRequest)
			return
		}
		if fail {
			http.Error(w, "down", http.StatusServiceUnavailable)
			return
		}
		io.WriteString(w, llamaRouter)
	}))
	defer srv.Close()

	dir := t.TempDir()
	overridesPath := filepath.Join(dir, "models.yaml")
	if err := os.WriteFile(overridesPath, []byte(`
local:
  tiny:
    context_length: 4096
    reasoning: true
    efforts: [low, high]
  only-in-overrides:
    display_name: Manual
    context_length: 1000
    tools: true
`), 0o600); err != nil {
		t.Fatal(err)
	}
	cfg := config.Default()
	cfg.Providers = []config.Provider{
		{Name: "local", BaseURL: srv.URL + "/v1", APIKey: "k"},
		{Name: "dead", BaseURL: "http://127.0.0.1:1/v1"},
	}
	c := NewCatalog(func() config.Config { return cfg }, func() string { return overridesPath }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err := c.Refresh(context.Background(), ""); err != nil {
		t.Fatal(err)
	}

	m := byID(c.Models("local"))
	if len(m) != 3 {
		t.Fatalf("models = %+v", m)
	}
	if tiny := m["tiny"]; tiny.ContextLength != 4096 || !tiny.SupportsReasoning || len(tiny.Efforts) != 2 || !tiny.Overridden || !tiny.Discovered {
		t.Errorf("overridden tiny = %+v", tiny)
	}
	if o := m["only-in-overrides"]; o.Discovered || !o.Overridden || o.ContextLength != 1000 || !o.SupportsTools || o.DisplayName != "Manual" {
		t.Errorf("override-only = %+v", o)
	}
	if got, ok := c.Lookup("local", "qwen/big"); !ok || got.ContextLength != 262144 {
		t.Errorf("Lookup = %+v %v", got, ok)
	}

	provs := c.Providers()
	if len(provs) != 2 || provs[0].Kind != KindLlamaCpp || provs[0].ModelCount != 3 || provs[0].Err != "" {
		t.Errorf("local status = %+v", provs[0])
	}
	if provs[1].Err == "" || provs[1].ModelCount != 0 {
		t.Errorf("dead status = %+v", provs[1])
	}

	// A failed refresh keeps the last good list.
	fail = true
	if err := c.Refresh(context.Background(), "local"); err != nil {
		t.Fatal(err)
	}
	if st := c.Providers()[0]; st.Err == "" || st.ModelCount != 3 {
		t.Errorf("after failure = %+v", st)
	}
	if err := c.Refresh(context.Background(), "nope"); err == nil {
		t.Error("unknown provider refreshed")
	}

	// A broken override file is reported but discovery still works.
	os.WriteFile(overridesPath, []byte("local:\n  tiny:\n    bogus: 1\n"), 0o600)
	fail = false
	_ = c.Refresh(context.Background(), "local")
	if tiny := byID(c.Models("local"))["tiny"]; tiny.Overridden || tiny.ContextLength != 8192 {
		t.Errorf("with broken overrides = %+v", tiny)
	}
}

// A fake llama.cpp router: loading takes two /models polls.
type fakeRouter struct {
	mu    sync.Mutex
	state map[string]string
	polls int
	calls []string
}

func (f *fakeRouter) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.mu.Lock()
	defer f.mu.Unlock()
	switch r.URL.Path {
	case "/v1/models":
		f.polls++
		var data []map[string]any
		for _, id := range []string{"big", "tiny"} {
			st := f.state[id]
			if st == "loading" && f.polls > 2 {
				st, f.state[id] = "loaded", "loaded"
			}
			data = append(data, map[string]any{"id": id, "owned_by": "llamacpp", "status": map[string]any{"value": st, "args": []string{"--jinja"}}})
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"data": data})
	case "/models/load", "/models/unload":
		var body struct{ Model string }
		_ = json.NewDecoder(r.Body).Decode(&body)
		f.calls = append(f.calls, r.URL.Path+" "+body.Model)
		if _, ok := f.state[body.Model]; !ok {
			http.Error(w, `{"error":{"message":"model not found"}}`, http.StatusBadRequest)
			return
		}
		f.polls = 0
		if r.URL.Path == "/models/load" {
			f.state[body.Model] = "loading"
		} else {
			f.state[body.Model] = "unloaded"
		}
		_, _ = w.Write([]byte(`{"success":true}`))
	default:
		http.NotFound(w, r)
	}
}

func TestSetLoaded(t *testing.T) {
	router := &fakeRouter{state: map[string]string{"big": "loaded", "tiny": "unloaded"}}
	srv := httptest.NewServer(router)
	defer srv.Close()
	plain := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(plainOpenAI)) }))
	defer plain.Close()
	cfg := config.Default()
	cfg.Providers = []config.Provider{{Name: "llama", BaseURL: srv.URL + "/v1"}, {Name: "plain", BaseURL: plain.URL + "/v1"}}
	c := NewCatalog(func() config.Config { return cfg }, func() string { return "" }, slog.New(slog.NewTextHandler(io.Discard, nil)))
	ctx := context.Background()
	if err := c.Refresh(ctx, ""); err != nil {
		t.Fatal(err)
	}
	for _, p := range c.Providers() {
		if p.CanLoad != (p.Name == "llama") {
			t.Fatalf("%s CanLoad = %v", p.Name, p.CanLoad)
		}
	}
	if m, _ := c.Lookup("llama", "big"); m.State != StateLoaded || !m.Loaded {
		t.Fatalf("big = %+v", m)
	}

	orig := loadSettle
	t.Cleanup(func() { loadSettle = orig })
	loadSettle = 10 * time.Second
	m, err := c.SetLoaded(ctx, "llama", "tiny", true)
	if err != nil || m.State != StateLoaded {
		t.Fatalf("load = %+v, %v", m, err)
	}
	m, err = c.SetLoaded(ctx, "llama", "big", false)
	if err != nil || m.State != StateUnloaded || m.Loaded {
		t.Fatalf("unload = %+v, %v", m, err)
	}
	if got := strings.Join(router.calls, ","); got != "/models/load tiny,/models/unload big" {
		t.Fatalf("router calls %s", got)
	}
	if _, err := c.SetLoaded(ctx, "llama", "nope", true); err == nil || !strings.Contains(err.Error(), "model not found") {
		t.Fatalf("unknown model: %v", err)
	}
	if _, err := c.SetLoaded(ctx, "plain", "m1", false); !errors.Is(err, ErrCantLoad) {
		t.Fatalf("plain provider: %v", err)
	}
}
