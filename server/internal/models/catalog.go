// Package models discovers the models each configured provider offers, from
// its /models endpoint, with small adapters for the shapes OpenRouter,
// llama.cpp and gomodel return. There is no model database and no name
// matching: what the provider says, corrected by an optional YAML override
// file, is all flit knows.
package models

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"slices"
	"strings"
	"sync"
	"time"

	"go.yaml.in/yaml/v3"

	"github.com/iggy/flit/server/internal/config"
)

// Model is one model as flit knows it.
type Model struct {
	Provider          string
	ID                string
	DisplayName       string
	ContextLength     int64
	SupportsTools     bool
	SupportsReasoning bool
	SupportsVision    bool
	Efforts           []string
	Loaded            bool
	Discovered        bool
	Overridden        bool
}

// ProviderStatus is how discovery went for one provider.
type ProviderStatus struct {
	Name       string
	BaseURL    string
	Kind       Kind
	ModelCount int
	Refreshed  time.Time
	Err        string
}

// Override corrects or adds a model. Unset fields leave discovered values
// alone. YAML shape (file named by model_overrides_file):
//
//	local:                      # provider name
//	  qwen3-coder:              # model id
//	    context_length: 131072
//	    tools: true
//	    reasoning: true
//	    efforts: [low, medium, high]
type Override struct {
	DisplayName   string   `yaml:"display_name"`
	ContextLength *int64   `yaml:"context_length"`
	Tools         *bool    `yaml:"tools"`
	Reasoning     *bool    `yaml:"reasoning"`
	Vision        *bool    `yaml:"vision"`
	Efforts       []string `yaml:"efforts"`
}

// discoveryTimeout bounds one provider's /models call.
const discoveryTimeout = 20 * time.Second

// Catalog holds discovered models.
type Catalog struct {
	cfg           func() config.Config
	overridesPath func() string
	log           *slog.Logger
	http          *http.Client

	mu         sync.RWMutex
	discovered map[string][]Model // provider -> models as discovered
	status     map[string]ProviderStatus
	overrides  map[string]map[string]Override
	overErr    error
}

// NewCatalog returns an empty Catalog; call Refresh to fill it.
// overridesPath returns the override file's path (it may not exist).
func NewCatalog(cfg func() config.Config, overridesPath func() string, log *slog.Logger) *Catalog {
	return &Catalog{
		cfg:           cfg,
		overridesPath: overridesPath,
		log:           log,
		http:          &http.Client{Timeout: discoveryTimeout},
		discovered:    map[string][]Model{},
		status:        map[string]ProviderStatus{},
	}
}

// Refresh re-reads the override file and re-runs discovery for one provider,
// or all when name is empty. Providers are queried in parallel; a failing
// provider keeps its previous models and records the error.
func (c *Catalog) Refresh(ctx context.Context, name string) error {
	overrides, overErr := loadOverrides(c.overridesPath())
	c.mu.Lock()
	c.overrides, c.overErr = overrides, overErr
	c.mu.Unlock()
	if overErr != nil {
		c.log.Warn("model override file not applied", "err", overErr)
	}

	cfg := c.cfg()
	var wg sync.WaitGroup
	found := false
	for _, p := range cfg.Providers {
		if name != "" && p.Name != name {
			continue
		}
		found = true
		wg.Go(func() { c.refreshOne(ctx, p) })
	}
	wg.Wait()
	if name != "" && !found {
		return fmt.Errorf("provider %q is not configured", name)
	}
	return nil
}

func (c *Catalog) refreshOne(ctx context.Context, p config.Provider) {
	st := ProviderStatus{Name: p.Name, BaseURL: p.BaseURL}
	kind := Kind("")
	if p.Kind != "" && p.Kind != "auto" {
		kind = Kind(p.Kind)
	}
	kind, list, err := c.discover(ctx, p, kind)
	st.Kind, st.Refreshed = kind, time.Now()
	c.mu.Lock()
	defer c.mu.Unlock()
	if err != nil {
		st.Err = err.Error()
		if prev, ok := c.status[p.Name]; ok {
			st.Kind = prev.Kind
		}
		c.log.Warn("model discovery failed", "provider", p.Name, "err", err)
	} else {
		c.discovered[p.Name] = list
	}
	st.ModelCount = len(c.discovered[p.Name])
	c.status[p.Name] = st
}

func (c *Catalog) discover(ctx context.Context, p config.Provider, kind Kind) (Kind, []Model, error) {
	ctx, cancel := context.WithTimeout(ctx, discoveryTimeout)
	defer cancel()
	url := strings.TrimSuffix(p.BaseURL, "/") + "/models"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return kind, nil, err
	}
	if key := p.Key(); key != "" {
		req.Header.Set("Authorization", "Bearer "+key)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return kind, nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 32<<20))
	if err != nil {
		return kind, nil, err
	}
	if resp.StatusCode != http.StatusOK {
		msg := strings.TrimSpace(string(body))
		if len(msg) > 300 {
			msg = msg[:300] + "…"
		}
		return kind, nil, fmt.Errorf("GET %s: HTTP %d: %s", url, resp.StatusCode, msg)
	}
	return parseModels(p.Name, p.BaseURL, kind, body)
}

func loadOverrides(path string) (map[string]map[string]Override, error) {
	if path == "" {
		return nil, nil
	}
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var out map[string]map[string]Override
	dec := yaml.NewDecoder(strings.NewReader(string(data)))
	dec.KnownFields(true)
	if err := dec.Decode(&out); err != nil && !errors.Is(err, io.EOF) {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return out, nil
}

// Providers lists configured providers with their discovery status.
func (c *Catalog) Providers() []ProviderStatus {
	cfg := c.cfg()
	c.mu.RLock()
	defer c.mu.RUnlock()
	out := make([]ProviderStatus, 0, len(cfg.Providers))
	for _, p := range cfg.Providers {
		st, ok := c.status[p.Name]
		if !ok {
			st = ProviderStatus{Name: p.Name, BaseURL: p.BaseURL}
		}
		st.BaseURL = p.BaseURL
		st.ModelCount = len(c.mergedLocked(p.Name))
		out = append(out, st)
	}
	return out
}

// Kind is the provider's kind: as configured, else as discovery detected
// it; empty when unknown.
func (c *Catalog) Kind(provider string) Kind {
	if p, ok := c.cfg().Provider(provider); ok && p.Kind != "" && p.Kind != "auto" {
		return Kind(p.Kind)
	}
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.status[provider].Kind
}

// Models lists models for one provider, or all when provider is empty,
// with overrides applied, sorted by provider then id.
func (c *Catalog) Models(provider string) []Model {
	cfg := c.cfg()
	c.mu.RLock()
	defer c.mu.RUnlock()
	var out []Model
	for _, p := range cfg.Providers {
		if provider == "" || p.Name == provider {
			out = append(out, c.mergedLocked(p.Name)...)
		}
	}
	return out
}

// Lookup returns one model, with overrides applied.
func (c *Catalog) Lookup(provider, id string) (Model, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	for _, m := range c.mergedLocked(provider) {
		if m.ID == id {
			return m, true
		}
	}
	return Model{}, false
}

// mergedLocked applies overrides to a provider's discovered models and adds
// models that only exist in the override file.
func (c *Catalog) mergedLocked(provider string) []Model {
	over := c.overrides[provider]
	disc := c.discovered[provider]
	out := make([]Model, 0, len(disc)+len(over))
	seen := map[string]bool{}
	for _, m := range disc {
		m.Efforts = slices.Clone(m.Efforts)
		if o, ok := over[m.ID]; ok {
			applyOverride(&m, o)
		}
		seen[m.ID] = true
		out = append(out, m)
	}
	ids := make([]string, 0, len(over))
	for id := range over {
		if !seen[id] {
			ids = append(ids, id)
		}
	}
	slices.Sort(ids)
	for _, id := range ids {
		m := Model{Provider: provider, ID: id}
		applyOverride(&m, over[id])
		out = append(out, m)
	}
	slices.SortStableFunc(out, func(a, b Model) int { return strings.Compare(a.ID, b.ID) })
	return out
}

func applyOverride(m *Model, o Override) {
	m.Overridden = true
	if o.DisplayName != "" {
		m.DisplayName = o.DisplayName
	}
	if o.ContextLength != nil {
		m.ContextLength = *o.ContextLength
	}
	if o.Tools != nil {
		m.SupportsTools = *o.Tools
	}
	if o.Vision != nil {
		m.SupportsVision = *o.Vision
	}
	if o.Reasoning != nil {
		m.SupportsReasoning = *o.Reasoning
		if !m.SupportsReasoning {
			m.Efforts = nil
		} else if len(m.Efforts) == 0 {
			m.Efforts = slices.Clone(defaultEfforts)
		}
	}
	if o.Efforts != nil {
		m.Efforts = o.Efforts
	}
}
