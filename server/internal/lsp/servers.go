package lsp

import (
	"path/filepath"
	"slices"
	"strings"

	"github.com/iggy/flit/server/internal/config"
)

// candidates are the servers files may go to, in order (see
// config.LSP.Resolved).
func candidates(cfg config.LSP) []config.LSPServer {
	return cfg.Resolved()
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
