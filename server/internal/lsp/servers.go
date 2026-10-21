package lsp

import (
	"path/filepath"
	"slices"
	"strings"

	"github.com/iggy/flit/server/internal/config"
)

// Builtin are the servers used when their command is on PATH, unless the
// config replaces or turns them off by name. For Python, basedpyright is
// tried before pyright.
func Builtin() []config.LSPServer {
	python := map[string][]string{"python": {".py", ".pyi"}}
	pyRoots := []string{"pyproject.toml", "pyrightconfig.json", "setup.py", "setup.cfg", "requirements.txt"}
	return []config.LSPServer{
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

// candidates are the configured servers followed by the built-ins they
// don't replace, minus those turned off.
func candidates(cfg config.LSP) []config.LSPServer {
	var out []config.LSPServer
	named := map[string]bool{}
	for _, s := range cfg.Servers {
		named[s.Name] = true
		if s.IsEnabled() {
			out = append(out, s)
		}
	}
	for _, s := range Builtin() {
		if !named[s.Name] {
			out = append(out, s)
		}
	}
	return out
}

// pick returns the server for path and the file's language id: the first
// candidate handling its extension whose command can be found.
func pick(cfg config.LSP, path string, lookPath func(string) (string, error)) (config.LSPServer, string, bool) {
	ext := strings.ToLower(filepath.Ext(path))
	if ext == "" {
		return config.LSPServer{}, "", false
	}
	for _, s := range candidates(cfg) {
		for lang, exts := range s.Languages {
			if !slices.Contains(exts, ext) {
				continue
			}
			if _, err := lookPath(s.Command); err != nil {
				break // try the next server
			}
			return s, lang, true
		}
	}
	return config.LSPServer{}, "", false
}

// findRoot is the nearest directory at or above path's holding one of
// markers, or workDir when there is none.
func findRoot(path, workDir string, markers []string) string {
	dir := filepath.Dir(path)
	for {
		for _, mk := range markers {
			if exists(filepath.Join(dir, mk)) {
				return dir
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return workDir
		}
		dir = parent
	}
}
