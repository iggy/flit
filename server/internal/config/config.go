// Package config loads flit's YAML config file and watches it for changes.
//
// flit is configured with YAML only. Changes to the file are applied while the
// server runs; see Watch.
package config

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"go.yaml.in/yaml/v3"
)

// DefaultListen is the address flit serves on when the config sets none.
const DefaultListen = "127.0.0.1:7433"

// Config is the contents of config.yaml.
type Config struct {
	// Listen is the host:port the API server binds to.
	Listen string `yaml:"listen"`
	// DataDir holds flit's SQLite databases and flat files. Empty means the
	// platform default. Read at startup only: changing it while flit runs is
	// logged and ignored until the next start.
	DataDir string `yaml:"data_dir"`
	TLS     TLS    `yaml:"tls"`
	Log     Log    `yaml:"log"`
	// PublicURL is how clients reach this server, e.g.
	// https://flit.example.com or http://192.168.1.20:7433. "flit pair" puts
	// it in the QR code. Empty means a best guess from Listen.
	PublicURL string `yaml:"public_url"`
	// Providers are the OpenAI-compatible endpoints flit can use.
	Providers []Provider `yaml:"providers"`
	Agent     Agent      `yaml:"agent"`
	Shell     Shell      `yaml:"shell"`
	// ModelOverridesFile is a YAML file that corrects or fills in what
	// model discovery finds (context length, tool and reasoning support,
	// effort levels). Relative paths are relative to the config file.
	ModelOverridesFile string `yaml:"model_overrides_file"`
	// RolesDir holds role files (*.md with YAML frontmatter). Relative
	// paths are relative to the config file.
	RolesDir string `yaml:"roles_dir"`
	// MCPServers are MCP servers (stdio or HTTP). Configured here, never in an
	// mcp.json.
	MCPServers []MCPServer `yaml:"mcp_servers"`
	// SkillsDirs hold skills in the Agent Skills format (one directory per
	// skill with a SKILL.md). Relative paths are relative to the config
	// file.
	SkillsDirs []string `yaml:"skills_dirs"`
	Web        Web      `yaml:"web"`
	Git        Git      `yaml:"git"`
	LlamaCpp   LlamaCpp `yaml:"llamacpp"`
	// CronsDir holds cron job files (*.md with YAML frontmatter; see
	// docs/cron.md). Relative paths are relative to the config file.
	CronsDir string   `yaml:"crons_dir"`
	Notify   Notify   `yaml:"notify"`
	Learning Learning `yaml:"learning"`
	LSP      LSP      `yaml:"lsp"`
}

// Notify configures notifications flit sends itself (the app shows its
// own while it's connected).
type Notify struct {
	// Ntfy is an ntfy topic URL (e.g. https://ntfy.sh/my-topic) that cron
	// run results are posted to. Empty means none.
	Ntfy string `yaml:"ntfy"`
	// NtfyHeaders are sent with each post, e.g. Authorization. ${VAR} in a
	// value is replaced with that environment variable.
	NtfyHeaders map[string]string `yaml:"ntfy_headers"`
}

// Learning configures memory and the learning pass (see docs/learning.md).
type Learning struct {
	// MemoryMaxBytes caps each memory layer (user, project) in the system
	// prompt; the rest is cut with a marker. 0 means no cap.
	MemoryMaxBytes int `yaml:"memory_max_bytes"`
	// TranscriptMaxBytes caps the session transcript sent to the learning
	// model. 0 means from the model's context window (24000 when that is
	// unknown).
	TranscriptMaxBytes int `yaml:"transcript_max_bytes"`
}

// MCPServer returns the MCP server named name.
func (c Config) MCPServer(name string) (MCPServer, bool) {
	for _, m := range c.MCPServers {
		if m.Name == name {
			return m, true
		}
	}
	return MCPServer{}, false
}

// ChatModel is the default model for new sessions: tasks.chat if set,
// else the agent defaults.
func (c Config) ChatModel() TaskModel {
	if t, ok := c.Agent.Tasks["chat"]; ok && t.Provider != "" {
		return t
	}
	return TaskModel{Provider: c.Agent.Provider, Model: c.Agent.Model, Effort: c.Agent.Effort}
}

// Provider is an OpenAI-compatible chat completions endpoint.
type Provider struct {
	// Name identifies the provider in sessions and the API.
	Name string `yaml:"name"`
	// BaseURL is the API root, e.g. https://api.openai.com/v1 or
	// http://localhost:8080/v1 for llama.cpp.
	BaseURL string `yaml:"base_url"`
	// APIKey is the key itself; APIKeyEnv names an environment variable
	// holding it. Set at most one. Neither means no Authorization header.
	APIKey    string `yaml:"api_key"`
	APIKeyEnv string `yaml:"api_key_env"`
	// Kind says how to read the provider's /models response: auto (the
	// default: guess from the URL and the response), openai, openrouter,
	// llamacpp or gomodel. openrouter also fits endpoints that copy
	// OpenRouter's /models format, such as the Nous Portal.
	Kind string `yaml:"kind"`
	// PromptAppend is added to the system prompt for every model on this
	// provider.
	PromptAppend string `yaml:"prompt_append"`
	// Headers are sent with every request to the provider (chat, model
	// discovery, llama.cpp's own endpoints), replacing flit's own, e.g. a
	// User-Agent. ${VAR} in a value is replaced with that environment
	// variable; an unset one fails the request.
	Headers map[string]string `yaml:"headers"`
	// Concurrency caps how many requests flit sends to each of the
	// provider's models at once, across all sessions and subagents; more
	// wait their turn. 0 means no limit. Models can set their own.
	Concurrency int `yaml:"concurrency"`
	// Models holds per-model settings, keyed by model id.
	Models map[string]ProviderModel `yaml:"models"`
}

// ProviderModel is per-model settings on a provider.
type ProviderModel struct {
	// Concurrency, when set, replaces the provider's for this model; 0
	// means no limit for it.
	Concurrency *int `yaml:"concurrency"`
}

// MCPServer is an MCP server: either a subprocess flit starts and talks to
// over stdio (Command), or a remote one it reaches over HTTP (URL).
// Exactly one of the two is set.
type MCPServer struct {
	Name    string            `yaml:"name"`
	Command string            `yaml:"command"`
	Args    []string          `yaml:"args"`
	Env     map[string]string `yaml:"env"`
	// Dir is the working directory for the process; empty means flit's.
	Dir string `yaml:"dir"`
	// URL is a remote server's endpoint, spoken to with the streamable
	// HTTP transport, or legacy SSE if the server only speaks that.
	URL string `yaml:"url"`
	// Headers are sent with every HTTP request (e.g. Authorization).
	// ${VAR} in a value is replaced with that environment variable when
	// connecting; an unset one fails the server.
	Headers map[string]string `yaml:"headers"`
	// OAuth configures sign-in for url servers that need it. Servers that
	// support dynamic client registration need nothing here: run
	// "flit mcp login NAME" once.
	OAuth *MCPOAuth `yaml:"oauth"`
	// Enabled is whether new sessions start with it on. Default true.
	Enabled *bool `yaml:"enabled"`
}

// MCPOAuth is a client registered by hand with an MCP server's
// authorization server, for servers that don't support dynamic client
// registration. ${VAR} in client_secret is read from the environment.
type MCPOAuth struct {
	ClientID     string `yaml:"client_id"`
	ClientSecret string `yaml:"client_secret"`
	// Scopes replaces the scopes the server asks for.
	Scopes []string `yaml:"scopes"`
}

// EnabledByDefault reports whether new sessions get this server.
func (m MCPServer) EnabledByDefault() bool { return m.Enabled == nil || *m.Enabled }

// LlamaCpp configures what flit does with llama.cpp servers beyond the
// OpenAI API.
type LlamaCpp struct {
	// KVCache saves each session's prompt cache to the server's
	// --slot-save-path when a turn ends and restores it before the
	// session's next turn, so a long session doesn't re-read its whole
	// prompt after other requests used the server. Default true; skipped
	// quietly where the server can't save.
	KVCache *bool `yaml:"kv_cache"`
	// KVCacheFiles is how many save files flit uses per server, reused
	// least recently used first (llama.cpp can't delete them, and each can
	// be gigabytes).
	KVCacheFiles int `yaml:"kv_cache_files"`
}

// KVCacheOn reports whether prompt cache saving is on.
func (l LlamaCpp) KVCacheOn() bool { return l.KVCache == nil || *l.KVCache }

// Web configures the web tools.
type Web struct {
	// Fetch enables the web_fetch tool. Default true.
	Fetch *bool `yaml:"fetch"`
	// Search configures web_search; without a provider there is no search
	// tool.
	Search WebSearch `yaml:"search"`
}

// FetchEnabled reports whether web_fetch is offered.
func (w Web) FetchEnabled() bool { return w.Fetch == nil || *w.Fetch }

// WebSearch configures the web_search tool.
type WebSearch struct {
	// Provider is "searxng" (free, self-hostable) or empty for none.
	Provider string `yaml:"provider"`
	// URL is the SearXNG instance, e.g. http://localhost:8888. Its JSON
	// output format must be enabled.
	URL string `yaml:"url"`
}

// Git configures the git tools.
type Git struct {
	// Enabled offers git_status, git_diff, git_log and git_commit. Default
	// true. Nothing ever pushes.
	Enabled *bool `yaml:"enabled"`
	// Worktrees gives each new session its own git worktree.
	Worktrees Worktrees `yaml:"worktrees"`
}

// IsEnabled reports whether the git tools are offered.
func (g Git) IsEnabled() bool { return g.Enabled == nil || *g.Enabled }

// LSP configures the language servers that check files after the write
// and patch tools change them. One server runs per language for the whole
// flit server, shared by every session and project.
type LSP struct {
	// Enabled turns diagnostics on. Default true; files whose language
	// has no server on PATH are skipped quietly.
	Enabled *bool `yaml:"enabled"`
	// IdleTimeout stops a server nothing has used for this long; it starts
	// again on the next edit. Default 10m.
	IdleTimeout time.Duration `yaml:"idle_timeout"`
	// WaitTimeout is the longest an edit waits for a server's diagnostics
	// (starting it included). Default 3s. The edit itself never fails or
	// waits longer because of a language server.
	WaitTimeout time.Duration `yaml:"wait_timeout"`
	// Debounce is how long the diagnostics must stay unchanged before they
	// are reported, since servers often publish more than once. Default
	// 300ms.
	Debounce time.Duration `yaml:"debounce"`
	// Severity is the least severe diagnostic reported: error, warning,
	// info or hint. Default warning.
	Severity string `yaml:"severity"`
	// MaxLines caps the diagnostics shown per edit; the rest are counted.
	// Default 10.
	MaxLines int `yaml:"max_lines"`
	// Servers add to or change the built-in servers (see
	// BuiltinLSPServers). An entry named like a built-in one is merged
	// into it: the fields it sets win (env and init_options key by key),
	// the rest come from the built-in. Each file goes to the first server,
	// these before the built-ins, that handles its extension and whose
	// command is on PATH.
	Servers []LSPServer `yaml:"servers"`
}

// LSPServer is a language server flit starts and speaks LSP to over stdio.
type LSPServer struct {
	Name    string            `yaml:"name"`
	Command string            `yaml:"command"`
	Args    []string          `yaml:"args"`
	Env     map[string]string `yaml:"env"`
	// Languages maps LSP language ids to the file extensions they cover,
	// e.g. {typescript: [.ts, .mts], typescriptreact: [.tsx]}.
	Languages map[string][]string `yaml:"languages"`
	// RootMarkers are files or directories that mark a project root, e.g.
	// go.mod. The nearest directory above an edited file holding one
	// becomes a workspace folder of the server; without one, the
	// session's working directory does.
	RootMarkers []string `yaml:"root_markers"`
	// InitOptions are sent as initializationOptions.
	InitOptions map[string]any `yaml:"init_options"`
	// Enabled false turns the server off, e.g. to drop a built-in one.
	// Default true.
	Enabled *bool `yaml:"enabled"`
}

// IsEnabled reports whether diagnostics are on.
func (l LSP) IsEnabled() bool { return l.Enabled == nil || *l.Enabled }

// IsEnabled reports whether the server may be used.
func (s LSPServer) IsEnabled() bool { return s.Enabled == nil || *s.Enabled }

// BuiltinLSPServers are the servers used when their command is on PATH,
// unless the config turns them off. For Python, basedpyright is tried
// before pyright.
func BuiltinLSPServers() []LSPServer {
	python := map[string][]string{"python": {".py", ".pyi"}}
	pyRoots := []string{"pyproject.toml", "pyrightconfig.json", "setup.py", "setup.cfg", "requirements.txt"}
	return []LSPServer{
		{Name: "gopls", Command: "gopls", Languages: map[string][]string{"go": {".go"}},
			RootMarkers: []string{"go.mod", "go.work"}},
		{Name: "rust-analyzer", Command: "rust-analyzer", Languages: map[string][]string{"rust": {".rs"}},
			RootMarkers: []string{"Cargo.toml"}},
		{Name: "basedpyright", Command: "basedpyright-langserver", Args: []string{"--stdio"}, Languages: python,
			RootMarkers: pyRoots},
		{Name: "pyright", Command: "pyright-langserver", Args: []string{"--stdio"}, Languages: python,
			RootMarkers: pyRoots},
		{Name: "typescript-language-server", Command: "typescript-language-server", Args: []string{"--stdio"},
			Languages: map[string][]string{
				"typescript":      {".ts", ".mts", ".cts"},
				"typescriptreact": {".tsx"},
				"javascript":      {".js", ".mjs", ".cjs"},
				"javascriptreact": {".jsx"},
			},
			RootMarkers: []string{"tsconfig.json", "jsconfig.json", "package.json"}},
		{Name: "clangd", Command: "clangd", Languages: map[string][]string{
			"c":   {".c", ".h"},
			"cpp": {".cc", ".cpp", ".cxx", ".hh", ".hpp", ".hxx"},
		},
			RootMarkers: []string{"compile_commands.json", "compile_flags.txt", ".clangd"}},
	}
}

// Resolved returns the servers in the order files try them: the
// configured ones, merged into the built-in of the same name if any, then
// the built-ins nothing names. Servers turned off are left out.
func (l LSP) Resolved() []LSPServer {
	builtin := map[string]LSPServer{}
	for _, b := range BuiltinLSPServers() {
		builtin[b.Name] = b
	}
	var out []LSPServer
	for _, s := range l.Servers {
		if b, ok := builtin[s.Name]; ok {
			s = s.over(b)
			delete(builtin, s.Name)
		}
		if s.IsEnabled() {
			out = append(out, s)
		}
	}
	for _, b := range BuiltinLSPServers() {
		if _, ok := builtin[b.Name]; ok {
			out = append(out, b)
		}
	}
	return out
}

// over returns s with the fields it leaves unset taken from base. A list
// set to [] counts as set; env and init_options merge key by key.
func (s LSPServer) over(base LSPServer) LSPServer {
	if s.Command == "" {
		s.Command = base.Command
	}
	if s.Args == nil {
		s.Args = base.Args
	}
	if s.Languages == nil {
		s.Languages = base.Languages
	}
	if s.RootMarkers == nil {
		s.RootMarkers = base.RootMarkers
	}
	s.Env = mergeMaps(base.Env, s.Env)
	s.InitOptions = mergeMaps(base.InitOptions, s.InitOptions)
	return s
}

// mergeMaps returns base with over's keys set on top; nil if both are.
func mergeMaps[V any](base, over map[string]V) map[string]V {
	if base == nil && over == nil {
		return nil
	}
	out := make(map[string]V, len(base)+len(over))
	for k, v := range base {
		out[k] = v
	}
	for k, v := range over {
		out[k] = v
	}
	return out
}

// LSPSeverities are the accepted LSP.Severity values, most severe first.
var LSPSeverities = []string{"error", "warning", "info", "hint"}

// Worktrees configures per-session git worktrees: a session in a project
// that uses them works on its own branch in <data dir>/worktrees/<session
// id>, so the user's checkout is never touched.
type Worktrees struct {
	// Default is whether projects that haven't chosen use worktrees.
	// Default false.
	Default bool `yaml:"default"`
	// CopyIgnored names ignored directories (anywhere in the tree) copied
	// from the checkout into a new worktree, by reflink where the
	// filesystem can. Unset means DefaultCopyIgnored; [] copies nothing.
	CopyIgnored []string `yaml:"copy_ignored"`
}

// DefaultCopyIgnored are the directories copied into a new worktree when
// git.worktrees.copy_ignored is unset: dependencies and build output that
// are slow to recreate.
var DefaultCopyIgnored = []string{
	"node_modules", ".venv", "venv", "target", "build", "dist", ".dart_tool", ".gradle", "Pods", ".next",
}

// CopyIgnoredDirs is CopyIgnored with the default applied.
func (w Worktrees) CopyIgnoredDirs() []string {
	if w.CopyIgnored == nil {
		return DefaultCopyIgnored
	}
	return w.CopyIgnored
}

// ProviderKinds are the accepted Provider.Kind values.
var ProviderKinds = []string{"auto", "openai", "openrouter", "llamacpp", "gomodel"}

// Tasks are the kinds of work that can have their own model.
var Tasks = []string{"chat", "planning", "cron", "compaction", "search", "permission", "learning", "explore", "build"}

// TaskModel picks a model for one kind of work.
type TaskModel struct {
	Provider string `yaml:"provider"`
	Model    string `yaml:"model"`
	// Effort is the reasoning effort, e.g. low, medium or high; empty means
	// the model's default. "off" turns thinking off on llama.cpp
	// (chat_template_kwargs enable_thinking=false) and is ignored by other
	// providers.
	Effort string `yaml:"effort"`
}

// Task returns the model configured for task, if it names a provider and
// model.
func (c Config) Task(task string) (TaskModel, bool) {
	t, ok := c.Agent.Tasks[task]
	return t, ok && t.Provider != "" && t.Model != ""
}

// Key returns the provider's API key, if any.
func (p Provider) Key() string {
	if p.APIKeyEnv != "" {
		return os.Getenv(p.APIKeyEnv)
	}
	return p.APIKey
}

// Agent configures the agent loop.
type Agent struct {
	// Provider, Model and Effort are used by sessions that don't pick
	// their own (or get one from their role). tasks.chat, if set, wins.
	Provider string `yaml:"provider"`
	Model    string `yaml:"model"`
	Effort   string `yaml:"effort"`
	// Tasks sets a model per kind of work (see Tasks). chat is the
	// sessions' default model and permission rates shell commands before
	// flit asks the user (see docs/shell.md); compaction summarizes long
	// conversations (see Compaction; without it the session's own model
	// does); cron runs cron jobs that pick no model of their own (see
	// docs/cron.md); explore and build run the agent tool's subagents of
	// that kind (see Subagents; without one the session's own model does);
	// planning and search are for those features as they arrive.
	Tasks map[string]TaskModel `yaml:"tasks"`
	// ModelPromptAppends adds text to the system prompt for specific
	// models, keyed "provider/model".
	ModelPromptAppends map[string]string `yaml:"model_prompt_appends"`
	// MaxSteps caps model calls per turn.
	MaxSteps int `yaml:"max_steps"`
	// Tool output longer than this is cut down to its head and tail before
	// the model sees it.
	ToolOutputMaxBytes int `yaml:"tool_output_max_bytes"`
	ToolOutputMaxLines int `yaml:"tool_output_max_lines"`
	// The model call watchdog. ModelFirstTokenTimeout is the longest a
	// call may go quiet before the model starts answering (connecting,
	// reading the prompt); ModelStallTimeout is the longest once it has
	// (tokens or llama.cpp prompt progress are arriving). 0 turns one off.
	ModelFirstTokenTimeout time.Duration `yaml:"model_first_token_timeout"`
	ModelStallTimeout      time.Duration `yaml:"model_stall_timeout"`
	// ModelRetries is how many times a call that failed or stalled before
	// any output is tried again automatically. 0 means never.
	ModelRetries int `yaml:"model_retries"`
	// Compaction summarizes the older part of a long conversation so it
	// fits the model's context (tasks.compaction picks the model).
	Compaction Compaction `yaml:"compaction"`
	// Subagents configures the agent tool (tasks.explore and tasks.build
	// pick the models).
	Subagents Subagents `yaml:"subagents"`
}

// Subagents configures the agent tool, which runs a task in a fresh
// context (read-only "explore", or "build" with the session's tools and
// permission rules) and gives the agent only its final report.
type Subagents struct {
	// Enabled offers the agent tool. Default true.
	Enabled *bool `yaml:"enabled"`
	// MaxSteps caps a subagent's model calls (1-200); at the cap it is
	// told to stop and report. Default 20.
	MaxSteps int `yaml:"max_steps"`
}

// IsEnabled reports whether the agent tool is offered.
func (s Subagents) IsEnabled() bool { return s.Enabled == nil || *s.Enabled }

// Compaction configures context compaction.
type Compaction struct {
	// Auto compacts before a model call once the request would fill
	// Threshold of the model's context window. Default true. /compact
	// works either way.
	Auto *bool `yaml:"auto"`
	// Threshold is the fraction of the context window (0.1-1) at which
	// Auto kicks in. Default 0.8.
	Threshold float64 `yaml:"threshold"`
	// KeepTurns is how many of the latest turns stay verbatim after the
	// summary (1-50). Default 2. When those alone are too big, a running
	// turn is cut between its steps instead.
	KeepTurns int `yaml:"keep_turns"`
	// MaxSummaryTokens caps the summary's length (max_tokens, thinking
	// included); a summary cut off there counts as failed. 0 means no cap.
	// Default 4096.
	MaxSummaryTokens int `yaml:"max_summary_tokens"`
}

// AutoOn reports whether automatic compaction is on.
func (c Compaction) AutoOn() bool { return c.Auto == nil || *c.Auto }

// Shell configures the shell tool.
type Shell struct {
	// Timeout applies when the model doesn't ask for one; MaxTimeout caps
	// what it may ask for.
	Timeout    time.Duration `yaml:"timeout"`
	MaxTimeout time.Duration `yaml:"max_timeout"`
	// Allow and Deny are command patterns; "*" matches any run of
	// characters. Commands are split into their parts (chains, pipes,
	// loops); a command runs without asking when every part is allowed.
	// Deny is checked against the whole command and every part, and wins
	// over everything, yolo mode included.
	Allow []string `yaml:"allow"`
	Deny  []string `yaml:"deny"`
	// ReadOnly allows flit's built-in list of read-only commands (ls, cat,
	// grep, git status, ...; see docs/shell.md). Default true.
	ReadOnly *bool `yaml:"read_only"`
	// Default is what happens to commands nothing allows: "ask" (prompt
	// the user), "allow" or "deny".
	Default string `yaml:"default"`
	// Yolo is whether new sessions start in yolo mode, where every command
	// runs unless a deny rule matches. Sessions can turn it on or off.
	Yolo bool `yaml:"yolo"`
}

// ReadOnlyEnabled reports whether the built-in read-only list applies.
func (s Shell) ReadOnlyEnabled() bool { return s.ReadOnly == nil || *s.ReadOnly }

// Concurrency returns how many requests to model on provider may be in
// flight at once: the model's limit if it sets one, else the provider's;
// 0 means no limit.
func (c Config) Concurrency(provider, model string) int {
	p, ok := c.Provider(provider)
	if !ok {
		return 0
	}
	if m, ok := p.Models[model]; ok && m.Concurrency != nil {
		return *m.Concurrency
	}
	return p.Concurrency
}

// Provider returns the provider named name.
func (c Config) Provider(name string) (Provider, bool) {
	for _, p := range c.Providers {
		if p.Name == name {
			return p, true
		}
	}
	return Provider{}, false
}

// TLS enables HTTPS when both files are set. Both empty means plain HTTP.
type TLS struct {
	CertFile string `yaml:"cert_file"`
	KeyFile  string `yaml:"key_file"`
}

// Enabled reports whether TLS is configured.
func (t TLS) Enabled() bool { return t.CertFile != "" || t.KeyFile != "" }

// Log configures logging.
type Log struct {
	// Level is one of debug, info, warn, error.
	Level string `yaml:"level"`
}

// SlogLevel returns Level as a slog.Level. Call only on a validated Config.
func (l Log) SlogLevel() slog.Level {
	var lvl slog.Level
	_ = lvl.UnmarshalText([]byte(l.Level))
	return lvl
}

// Default returns the config used when the file sets nothing.
func Default() Config {
	return Config{
		Listen:             DefaultListen,
		Log:                Log{Level: "info"},
		Providers:          []Provider{},
		ModelOverridesFile: "models.yaml",
		RolesDir:           "roles",
		CronsDir:           "crons",
		Notify:             Notify{NtfyHeaders: map[string]string{}},
		MCPServers:         []MCPServer{},
		SkillsDirs:         []string{"skills"},
		Web:                Web{Fetch: ptr(true)},
		Git:                Git{Enabled: ptr(true), Worktrees: Worktrees{CopyIgnored: slices.Clone(DefaultCopyIgnored)}},
		LlamaCpp:           LlamaCpp{KVCache: ptr(true), KVCacheFiles: 4},
		Learning:           Learning{MemoryMaxBytes: 6000},
		LSP: LSP{
			Enabled:     ptr(true),
			IdleTimeout: 10 * time.Minute,
			WaitTimeout: 3 * time.Second,
			Debounce:    300 * time.Millisecond,
			Severity:    "warning",
			MaxLines:    10,
			Servers:     []LSPServer{},
		},
		Agent: Agent{
			Tasks:              map[string]TaskModel{},
			ModelPromptAppends: map[string]string{},
			MaxSteps:           50,
			ToolOutputMaxBytes: 32 * 1024,
			ToolOutputMaxLines: 500,
			// A big prompt on local hardware can take minutes to read;
			// llama.cpp's progress reports keep the shorter stall limit
			// in force while it does.
			ModelFirstTokenTimeout: 10 * time.Minute,
			ModelStallTimeout:      2 * time.Minute,
			ModelRetries:           1,
			Compaction: Compaction{
				Auto:             ptr(true),
				Threshold:        0.8,
				KeepTurns:        2,
				MaxSummaryTokens: 4096,
			},
			Subagents: Subagents{Enabled: ptr(true), MaxSteps: 20},
		},
		Shell: Shell{
			Timeout:    2 * time.Minute,
			MaxTimeout: 30 * time.Minute,
			Allow:      []string{},
			Deny:       []string{},
			ReadOnly:   ptr(true),
			Default:    "ask",
		},
	}
}

// Parse decodes YAML config, applies defaults and validates the result.
// Unknown keys are an error, so typos don't silently fall back to defaults.
func Parse(data []byte) (Config, error) {
	cfg := Default()
	dec := yaml.NewDecoder(bytes.NewReader(data))
	dec.KnownFields(true)
	if err := dec.Decode(&cfg); err != nil && !errors.Is(err, io.EOF) {
		return Config{}, fmt.Errorf("parse config: %w", err)
	}
	if cfg.Listen == "" {
		cfg.Listen = DefaultListen
	}
	if cfg.Log.Level == "" {
		cfg.Log.Level = "info"
	}
	cfg.fillDefaults()
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

// fillDefaults replaces zero values that YAML may have set explicitly.
func (c *Config) fillDefaults() {
	d := Default()
	if c.Agent.MaxSteps == 0 {
		c.Agent.MaxSteps = d.Agent.MaxSteps
	}
	if c.Agent.ToolOutputMaxBytes == 0 {
		c.Agent.ToolOutputMaxBytes = d.Agent.ToolOutputMaxBytes
	}
	if c.Agent.ToolOutputMaxLines == 0 {
		c.Agent.ToolOutputMaxLines = d.Agent.ToolOutputMaxLines
	}
	if c.Shell.Timeout == 0 {
		c.Shell.Timeout = d.Shell.Timeout
	}
	if c.Agent.Compaction.Threshold == 0 {
		c.Agent.Compaction.Threshold = d.Agent.Compaction.Threshold
	}
	if c.Agent.Subagents.MaxSteps == 0 {
		c.Agent.Subagents.MaxSteps = d.Agent.Subagents.MaxSteps
	}
	if c.Agent.Compaction.KeepTurns == 0 {
		c.Agent.Compaction.KeepTurns = d.Agent.Compaction.KeepTurns
	}
	if c.LlamaCpp.KVCacheFiles == 0 {
		c.LlamaCpp.KVCacheFiles = d.LlamaCpp.KVCacheFiles
	}
	if c.LSP.IdleTimeout == 0 {
		c.LSP.IdleTimeout = d.LSP.IdleTimeout
	}
	if c.LSP.WaitTimeout == 0 {
		c.LSP.WaitTimeout = d.LSP.WaitTimeout
	}
	if c.LSP.Debounce == 0 {
		c.LSP.Debounce = d.LSP.Debounce
	}
	if c.LSP.Severity == "" {
		c.LSP.Severity = d.LSP.Severity
	}
	if c.LSP.MaxLines == 0 {
		c.LSP.MaxLines = d.LSP.MaxLines
	}

	if c.Shell.MaxTimeout == 0 {
		c.Shell.MaxTimeout = d.Shell.MaxTimeout
	}
	if c.Shell.Default == "" {
		c.Shell.Default = d.Shell.Default
	}
	if c.ModelOverridesFile == "" {
		c.ModelOverridesFile = d.ModelOverridesFile
	}
	if c.RolesDir == "" {
		c.RolesDir = d.RolesDir
	}
	if c.CronsDir == "" {
		c.CronsDir = d.CronsDir
	}
}

// Load reads and parses the config file at path.
func Load(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Config{}, err
	}
	cfg, err := Parse(data)
	if err != nil {
		return Config{}, fmt.Errorf("%s: %w", path, err)
	}
	return cfg, nil
}

// Validate reports the first problem with c, if any.
func (c Config) Validate() error {
	for _, d := range c.Git.Worktrees.CopyIgnored {
		if d == "" || d == "." || d == ".." || strings.ContainsAny(d, `/\`) {
			return fmt.Errorf("git.worktrees.copy_ignored: %q must be a directory name, not a path", d)
		}
	}
	if _, _, err := net.SplitHostPort(c.Listen); err != nil {
		return fmt.Errorf("listen %q: %w", c.Listen, err)
	}
	if c.TLS.Enabled() && (c.TLS.CertFile == "" || c.TLS.KeyFile == "") {
		return errors.New("tls: cert_file and key_file must both be set")
	}
	var lvl slog.Level
	if err := lvl.UnmarshalText([]byte(c.Log.Level)); err != nil {
		return fmt.Errorf("log.level %q: want debug, info, warn or error", c.Log.Level)
	}
	if c.PublicURL != "" {
		u, err := url.Parse(c.PublicURL)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("public_url %q must be an http(s) URL", c.PublicURL)
		}
	}
	seen := map[string]bool{}
	for i, p := range c.Providers {
		if p.Name == "" {
			return fmt.Errorf("providers[%d]: name is required", i)
		}
		if seen[p.Name] {
			return fmt.Errorf("providers: duplicate name %q", p.Name)
		}
		seen[p.Name] = true
		u, err := url.Parse(p.BaseURL)
		if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("providers %q: base_url %q must be an http(s) URL", p.Name, p.BaseURL)
		}
		if p.APIKey != "" && p.APIKeyEnv != "" {
			return fmt.Errorf("providers %q: set api_key or api_key_env, not both", p.Name)
		}
		if p.Kind != "" && !slices.Contains(ProviderKinds, p.Kind) {
			return fmt.Errorf("providers %q: kind %q: want one of %s", p.Name, p.Kind, strings.Join(ProviderKinds, ", "))
		}
		for k := range p.Headers {
			if !headerName.MatchString(k) {
				return fmt.Errorf("providers %q: headers: %q is not a valid header name", p.Name, k)
			}
		}
		if p.Concurrency < 0 {
			return fmt.Errorf("providers %q: concurrency %d: want 0 (no limit) or more", p.Name, p.Concurrency)
		}
		for id, m := range p.Models {
			if m.Concurrency != nil && *m.Concurrency < 0 {
				return fmt.Errorf("providers %q: models %q: concurrency %d: want 0 (no limit) or more", p.Name, id, *m.Concurrency)
			}
		}
	}
	if c.Agent.Provider != "" && !seen[c.Agent.Provider] {
		return fmt.Errorf("agent.provider %q is not in providers", c.Agent.Provider)
	}
	mcpSeen := map[string]bool{}
	for i, m := range c.MCPServers {
		switch {
		case m.Name == "":
			return fmt.Errorf("mcp_servers[%d]: name is required", i)
		case !validToolPart(m.Name):
			return fmt.Errorf("mcp_servers %q: name may only use letters, digits, - and _", m.Name)
		case mcpSeen[m.Name]:
			return fmt.Errorf("mcp_servers: duplicate name %q", m.Name)
		case (m.Command == "") == (m.URL == ""):
			return fmt.Errorf("mcp_servers %q: set exactly one of command and url", m.Name)
		case m.URL != "" && (len(m.Args) > 0 || len(m.Env) > 0 || m.Dir != ""):
			return fmt.Errorf("mcp_servers %q: args, env and dir only apply to command servers", m.Name)
		case m.Command != "" && len(m.Headers) > 0:
			return fmt.Errorf("mcp_servers %q: headers only apply to url servers", m.Name)
		case m.Command != "" && m.OAuth != nil:
			return fmt.Errorf("mcp_servers %q: oauth only applies to url servers", m.Name)
		case m.OAuth != nil && m.OAuth.ClientID == "" && m.OAuth.ClientSecret != "":
			return fmt.Errorf("mcp_servers %q: oauth.client_secret needs oauth.client_id", m.Name)
		}
		if m.URL != "" {
			if u, err := url.Parse(m.URL); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
				return fmt.Errorf("mcp_servers %q: url must be an http(s) URL", m.Name)
			}
		}
		mcpSeen[m.Name] = true
	}
	switch c.Web.Search.Provider {
	case "":
	case "searxng":
		if u, err := url.Parse(c.Web.Search.URL); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("web.search.url %q must be an http(s) URL", c.Web.Search.URL)
		}
	default:
		return fmt.Errorf("web.search.provider %q: only searxng is supported", c.Web.Search.Provider)
	}
	for task, t := range c.Agent.Tasks {
		if !slices.Contains(Tasks, task) {
			return fmt.Errorf("agent.tasks: unknown task %q: want one of %s", task, strings.Join(Tasks, ", "))
		}
		if t.Provider != "" && !seen[t.Provider] {
			return fmt.Errorf("agent.tasks.%s.provider %q is not in providers", task, t.Provider)
		}
	}
	if c.Agent.MaxSteps < 0 || c.Agent.ToolOutputMaxBytes < 0 || c.Agent.ToolOutputMaxLines < 0 ||
		c.Agent.ModelFirstTokenTimeout < 0 || c.Agent.ModelStallTimeout < 0 {
		return errors.New("agent: limits must not be negative")
	}
	if c.LlamaCpp.KVCacheFiles < 0 || c.LlamaCpp.KVCacheFiles > 64 {
		return errors.New("llamacpp.kv_cache_files must be 1-64")
	}
	if err := c.LSP.validate(); err != nil {
		return err
	}
	if c.Agent.ModelRetries < 0 || c.Agent.ModelRetries > 5 {
		return errors.New("agent.model_retries must be between 0 and 5")
	}
	if cp := c.Agent.Compaction; cp.Threshold < 0.1 || cp.Threshold > 1 {
		return fmt.Errorf("agent.compaction.threshold %v must be between 0.1 and 1", cp.Threshold)
	}
	if cp := c.Agent.Compaction; cp.KeepTurns < 1 || cp.KeepTurns > 50 {
		return errors.New("agent.compaction.keep_turns must be between 1 and 50")
	}
	if n := c.Agent.Subagents.MaxSteps; n < 1 || n > 200 {
		return errors.New("agent.subagents.max_steps must be between 1 and 200")
	}
	if c.Learning.MemoryMaxBytes < 0 || c.Learning.TranscriptMaxBytes < 0 {
		return errors.New("learning: limits must not be negative")
	}
	if c.Agent.Compaction.MaxSummaryTokens < 0 {
		return errors.New("agent.compaction.max_summary_tokens must not be negative")
	}
	if c.Shell.Timeout < 0 || c.Shell.MaxTimeout < c.Shell.Timeout {
		return errors.New("shell: need 0 <= timeout <= max_timeout")
	}
	switch c.Shell.Default {
	case "ask", "allow", "deny":
	default:
		return fmt.Errorf("shell.default %q: want ask, allow or deny", c.Shell.Default)
	}
	if c.Notify.Ntfy != "" {
		if u, err := url.Parse(c.Notify.Ntfy); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
			return fmt.Errorf("notify.ntfy %q must be an http(s) URL", c.Notify.Ntfy)
		}
	}
	for k := range c.Notify.NtfyHeaders {
		if !headerName.MatchString(k) {
			return fmt.Errorf("notify.ntfy_headers: %q is not a valid header name", k)
		}
	}
	for _, pat := range append(append([]string{}, c.Shell.Allow...), c.Shell.Deny...) {
		if strings.TrimSpace(pat) == "" {
			return errors.New("shell: empty pattern in allow/deny")
		}
	}
	return nil
}

func (l LSP) validate() error {
	if l.IdleTimeout < 0 || l.WaitTimeout < 0 || l.Debounce < 0 || l.MaxLines < 0 {
		return errors.New("lsp: timeouts and max_lines must not be negative")
	}
	if !slices.Contains(LSPSeverities, l.Severity) {
		return fmt.Errorf("lsp.severity %q: want one of %s", l.Severity, strings.Join(LSPSeverities, ", "))
	}
	seen := map[string]bool{}
	builtin := map[string]LSPServer{}
	for _, b := range BuiltinLSPServers() {
		builtin[b.Name] = b
	}
	for i, s := range l.Servers {
		if b, ok := builtin[s.Name]; ok {
			s = s.over(b)
		}
		switch {
		case s.Name == "":
			return fmt.Errorf("lsp.servers[%d]: name is required", i)
		case seen[s.Name]:
			return fmt.Errorf("lsp.servers: duplicate name %q", s.Name)
		case s.Command == "" && s.IsEnabled():
			return fmt.Errorf("lsp.servers %q: command is required", s.Name)
		case len(s.Languages) == 0 && s.IsEnabled():
			return fmt.Errorf("lsp.servers %q: languages is required", s.Name)
		}
		for lang, exts := range s.Languages {
			if lang == "" || len(exts) == 0 {
				return fmt.Errorf("lsp.servers %q: languages: each language id needs extensions", s.Name)
			}
			for _, e := range exts {
				if !strings.HasPrefix(e, ".") || len(e) < 2 {
					return fmt.Errorf("lsp.servers %q: extension %q must start with a dot", s.Name, e)
				}
			}
		}
		seen[s.Name] = true
	}
	return nil
}

// defaultFile is written on first run so the available settings are
// discoverable.
const defaultFile = `# flit server configuration.
#
# Changes to this file are applied while flit runs; no restart needed.

# Address the API server listens on. Every API call requires the auth token
# (see "flit token"), even from localhost.
listen: ` + DefaultListen + `

# How phones and other machines reach this server, e.g.
# http://192.168.1.20:7433 or https://flit.example.com. "flit pair" puts it in
# the QR code. Empty means a guess based on listen. To pair a phone, listen on
# an address it can reach (e.g. 0.0.0.0:7433) and preferably use TLS.
public_url: ""

# Where flit keeps its databases and files. Empty means the platform default.
# Read at startup only.
data_dir: ""

# Serve HTTPS instead of HTTP. Set both, or leave both empty.
tls:
  cert_file: ""
  key_file: ""

log:
  # debug, info, warn or error.
  level: info

# OpenAI-compatible endpoints. Several can be configured at once. Models are
# discovered from each one's /models endpoint; kind says how to read it
# (auto, openai, openrouter, llamacpp, gomodel).
providers: []
#  - name: local
#    base_url: http://localhost:8080/v1   # e.g. llama.cpp's llama-server
#  - name: openrouter
#    base_url: https://openrouter.ai/api/v1
#    api_key_env: OPENROUTER_API_KEY      # or api_key: sk-...
#    headers:                            # sent with every request; ${VAR} is
#      User-Agent: my-agent/1.0          # read from the environment
#
# concurrency caps how many requests flit sends to each of a provider's models
# at once, across all sessions and subagents (0 or unset: no limit); more wait
# their turn. A model under models: can set its own, which wins (0: no limit):
#  - name: local
#    base_url: http://localhost:8080/v1
#    concurrency: 1                      # big local models: one at a time
#    models:
#      qwen3-4b:
#        concurrency: 8                  # a small one can take more

# Corrections and additions to discovered models (context length, tools,
# reasoning, effort levels), relative to this file.
model_overrides_file: models.yaml

# Role files (*.md with YAML frontmatter), relative to this file.
roles_dir: roles

# Cron jobs: one Markdown file per job (YAML frontmatter with the schedule,
# the body is the prompt), relative to this file. flit runs each job
# unattended on its schedule as a new session. See docs/cron.md.
crons_dir: crons

# Notifications flit sends itself, for when the app isn't open. ntfy posts
# cron run results (a report, needs attention, failed) to an ntfy topic,
# e.g. https://ntfy.sh/<a-long-random-topic> or your own server; runs with
# nothing to report stay quiet. Empty means off.
notify:
  ntfy: ""
  ntfy_headers: {}
  #  Authorization: Bearer ${NTFY_TOKEN}   # ${VAR} is read from the environment

# Skills in the Agent Skills format (a directory per skill with SKILL.md),
# relative to this file. The agent sees names and descriptions and loads a
# skill when it needs it.
skills_dirs: [skills]

# MCP servers, connected on demand. Each has either a command (started as a
# subprocess, spoken to over stdio) or a url (a remote server, spoken to with
# streamable HTTP, or legacy SSE if that's all it speaks). Sessions can turn
# each one on or off; enabled says whether new sessions start with it on.
mcp_servers: []
#  - name: fetch
#    command: uvx
#    args: [mcp-server-fetch]
#    env: {}
#    enabled: true
#  - name: docs
#    url: https://example.com/mcp
#    headers:                            # ${VAR} is read from the environment
#      Authorization: Bearer ${DOCS_MCP_TOKEN}
#    enabled: true
#  - name: tracker                       # a server that needs a browser
#    url: https://mcp.example.com/mcp    # sign-in: run "flit mcp login tracker"
#    oauth:                              # only for servers without dynamic
#      client_id: my-client-id           # client registration; register
#      client_secret: ${TRACKER_SECRET}  # http://127.0.0.1:7434/callback

web:
  # web_fetch: read a web page as text.
  fetch: true
  # web_search needs a search provider. Only SearXNG (free, self-hosted,
  # with its JSON format enabled) is supported.
  search:
    provider: ""
    url: ""

git:
  # git_status, git_diff, git_log and git_commit on the session's repo.
  # Nothing pushes.
  enabled: true
  worktrees:
    # Give each new session in a git repo its own worktree and branch
    # (flit/<id>) under <data dir>/worktrees, so your checkout is never
    # touched. This is the default for projects; each project can turn it
    # on or off for itself.
    default: false
    # Ignored directories (by name, anywhere in the tree) copied into a new
    # worktree, by reflink where the filesystem supports it. [] copies
    # nothing.
    copy_ignored: [node_modules, .venv, venv, target, build, dist, .dart_tool, .gradle, Pods, .next]

llamacpp:
  # Keep each session's prompt cache on llama.cpp servers started with
  # --slot-save-path: saved when a turn ends, restored before the session's
  # next turn. Coming back to a long session after other requests used the
  # server then skips re-reading its whole prompt. Servers that can't save
  # are skipped.
  kv_cache: true
  # Save files per server, reused least recently used first. Each holds a
  # whole context and can be gigabytes; llama.cpp can't delete them, so
  # flit sticks to flit-kv-0.bin .. flit-kv-<n-1>.bin.
  kv_cache_files: 4

lsp:
  # After write and patch change a file, ask its language server for errors
  # and warnings in that file and show them to the model with the tool
  # result (nothing is added when the file is clean). One server per
  # language runs for all sessions and projects. Built in, used when their
  # command is on PATH: gopls, rust-analyzer, basedpyright-langserver,
  # pyright-langserver, typescript-language-server, clangd.
  enabled: true
  # Stop a server nobody has used for this long; it restarts on the next
  # edit.
  idle_timeout: 10m
  # Longest an edit waits for diagnostics, starting the server included.
  # A slow or missing server never fails the edit.
  wait_timeout: 3s
  # Report once the diagnostics have stopped changing for this long.
  debounce: 300ms
  # Least severe diagnostic shown: error, warning, info or hint.
  severity: warning
  # Most diagnostics shown per edit; the rest are counted.
  max_lines: 10
  # Add servers, or change built-in ones by naming them: what you set wins
  # (env and init_options key by key), the rest is kept. enabled: false
  # turns one off. These are tried before the built-ins.
  servers: []
  #  - name: zls
  #    command: zls
  #    args: []
  #    languages: {zig: [.zig]}
  #    root_markers: [build.zig]
  #    init_options: {}
  #  - name: gopls
  #    init_options: {staticcheck: true}
  #  - name: clangd
  #    enabled: false

agent:
  # Defaults for sessions that don't choose their own (or get one from
  # their role).
  provider: ""
  model: ""
  # Reasoning effort: low, medium, high (or a level the model names), or
  # off to turn thinking off on llama.cpp. Empty means the model's default.
  effort: ""
  # A model per kind of work: chat, permission, planning, cron, compaction,
  # search, learning, explore, build. chat overrides the defaults above.
  # permission rates shell commands (safe, ask or block) before flit asks
  # you; without it, flit just asks. compaction writes the summary when a
  # long conversation is compacted; without it, the session's own model
  # does. cron runs cron jobs that don't pick a model (or get one from
  # their role); without it, they use the chat model. learning reads a
  # finished session and proposes lessons to remember ("flit learn", or
  # "Learn from this session" in the app); without it, the chat model
  # does. explore and build run the agent tool's subagents; without them,
  # the session's own model does. planning and search aren't used yet.
  tasks: {}
  #   chat:       {provider: local, model: qwen3-coder, effort: medium}
  #   cron:       {provider: local, model: qwen3-4b, effort: off}
  #   permission: {provider: local, model: qwen3-4b, effort: off}
  #   compaction: {provider: local, model: qwen3-4b, effort: off}
  #   explore:    {provider: local, model: qwen3-4b, effort: low}
  #   learning:   {provider: local, model: qwen3-coder, effort: off}
  # Extra system prompt text for specific models ("provider/model"); a
  # provider's prompt_append applies to all its models.
  model_prompt_appends: {}
  # Maximum model calls in one turn.
  max_steps: 50
  # Longer tool output is cut to its head and tail before the model sees it.
  tool_output_max_bytes: 32768
  tool_output_max_lines: 500
  # The model call watchdog stops a call that goes quiet: for
  # model_first_token_timeout before the model starts answering (sending
  # the request, reading the prompt), model_stall_timeout once it has. With
  # llama.cpp, flit asks for prompt progress, so the shorter limit applies
  # while a long prompt is read too. 0 turns a limit off.
  model_first_token_timeout: 10m
  model_stall_timeout: 2m
  # Automatic retries for a call that failed or stalled before any output.
  model_retries: 1
  # Compaction: when a conversation gets long, flit summarizes its older
  # part (with tasks.compaction, or the session's model) and from then on
  # sends the model the summary plus the latest turns. Nothing is deleted;
  # the app shows where it happened. /compact in the app does it on demand.
  compaction:
    # Compact on its own before a model call that would fill threshold of
    # the context window (exact counts on llama.cpp, estimates elsewhere;
    # models with an unknown window are never compacted automatically).
    auto: true
    threshold: 0.8
    # Latest turns kept word for word after the summary.
    keep_turns: 2
    # Longest summary, thinking included; a cut-off summary counts as
    # failed and the session goes on uncompacted. 0 means no cap.
    max_summary_tokens: 4096
  # The agent tool hands a task to a subagent with a fresh context and
  # gets back only its final report. explore subagents only read (files,
  # grep, git, web, read-only shell commands) and never ask you anything;
  # build subagents get the session's tools, and their commands follow the
  # session's shell rules and prompts. Subagents can't start subagents.
  subagents:
    enabled: true
    # Maximum model calls per subagent; at the cap it is told to report.
    max_steps: 20

# Memory: lessons flit keeps between sessions, as Markdown files you can
# edit: <data_dir>/memory/user.md (every session) and
# <data_dir>/memory/projects/<project id>.md (that project's sessions).
# "flit learn <session>" proposes additions; nothing is written until you
# accept. See docs/learning.md.
learning:
  # Each memory file is cut to this many bytes in the system prompt.
  # 0 means no cap.
  memory_max_bytes: 6000
  # Longest session transcript sent to the learning model; long tool
  # output is trimmed first. 0 means from the model's context window.
  transcript_max_bytes: 0

shell:
  timeout: 2m
  max_timeout: 30m
  # Commands are split into their parts (cd x && ls | head is three); a
  # command runs without asking when every part is allowed. Redirecting
  # output to a file, $(...) and backticks always ask.
  #
  # Command patterns; "*" matches anything, e.g. "go test*". deny is
  # checked against every part and wins over everything, yolo included.
  allow: []
  deny: []
  # Allow flit's built-in read-only commands: cd, ls, cat, head, tail, wc,
  # grep, rg, find (without -exec/-delete), git status/log/diff/show/branch
  # and more (see docs/shell.md).
  read_only: true
  # For commands nothing allows: ask, allow or deny.
  default: ask
  # Start new sessions in yolo mode: run everything except deny matches.
  # Each session can turn it on or off in the app.
  yolo: false
`

// EnsureFile writes the default config to path if no file exists there.
// It reports whether it created the file.
func EnsureFile(path string) (bool, error) {
	if _, err := os.Stat(path); err == nil {
		return false, nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return false, err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return false, err
	}
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if errors.Is(err, os.ErrExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if _, err := f.WriteString(strings.TrimLeft(defaultFile, "\n")); err != nil {
		f.Close()
		return false, err
	}
	return true, f.Close()
}

// validToolPart reports whether s can be part of a tool name sent to the
// model (letters, digits, - and _).
func validToolPart(s string) bool {
	for _, r := range s {
		if !(r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9' || r == '-' || r == '_') {
			return false
		}
	}
	return s != ""
}

func ptr[T any](v T) *T { return &v }
