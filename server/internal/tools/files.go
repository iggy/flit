package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const (
	readDefaultLimit = 2000
	listMaxEntries   = 1000
	grepMaxMatches   = 200
	grepMaxFileSize  = 2 << 20
	grepMaxLineLen   = 300
)

// skipDir reports directories the list and grep tools don't descend into.
func skipDir(name string) bool {
	switch name {
	case ".git", ".hg", ".svn", "node_modules", ".dart_tool":
		return true
	}
	return false
}

var readTool = Tool{
	Name:        "read",
	ReadOnly:    true,
	Description: "Read a text file. Returns lines prefixed with their line numbers. Use offset and limit to page through large files.",
	Schema: `{"type":"object","properties":{
"path":{"type":"string","description":"File path, relative to the working directory"},
"offset":{"type":"integer","description":"First line to return, 1-based (default 1)"},
"limit":{"type":"integer","description":"Maximum lines to return (default 2000)"}
},"required":["path"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Path   string `json:"path"`
			Offset int    `json:"offset"`
			Limit  int    `json:"limit"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		p, err := resolve(env.Dir, a.Path)
		if err != nil {
			return errorf("%v", err)
		}
		b, err := os.ReadFile(p)
		if err != nil {
			return errorf("%v", err)
		}
		if isBinary(b) {
			return errorf("%s looks like a binary file", rel(env.Dir, p))
		}
		if a.Offset < 1 {
			a.Offset = 1
		}
		if a.Limit <= 0 {
			a.Limit = readDefaultLimit
		}
		lines := strings.Split(strings.TrimSuffix(string(b), "\n"), "\n")
		if len(b) == 0 {
			return Result{Text: "(empty file)"}
		}
		if a.Offset > len(lines) {
			return errorf("offset %d is past the end of the file (%d lines)", a.Offset, len(lines))
		}
		end := min(a.Offset-1+a.Limit, len(lines))
		var out strings.Builder
		for i := a.Offset - 1; i < end; i++ {
			fmt.Fprintf(&out, "%6d\t%s\n", i+1, lines[i])
		}
		if end < len(lines) {
			fmt.Fprintf(&out, "[%d more lines; continue with offset %d]\n", len(lines)-end, end+1)
		}
		return Result{Text: out.String()}
	},
}

var writeTool = Tool{
	Name:        "write",
	Description: "Write a file, replacing it if it exists. Creates parent directories. Prefer patch for changing part of an existing file.",
	Schema: `{"type":"object","properties":{
"path":{"type":"string","description":"File path, relative to the working directory"},
"content":{"type":"string","description":"The complete new file content"}
},"required":["path","content"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Path    string `json:"path"`
			Content string `json:"content"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		p, err := resolve(env.Dir, a.Path)
		if err != nil {
			return errorf("%v", err)
		}
		if err := writeFile(p, []byte(a.Content)); err != nil {
			return errorf("%v", err)
		}
		return Result{Text: fmt.Sprintf("wrote %d bytes to %s", len(a.Content), rel(env.Dir, p))}
	},
}

// writeFile writes data to p, keeping an existing file's permissions.
func writeFile(p string, data []byte) error {
	mode := os.FileMode(0o644)
	if fi, err := os.Stat(p); err == nil {
		if fi.IsDir() {
			return fmt.Errorf("%s is a directory", p)
		}
		mode = fi.Mode().Perm()
	}
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		return err
	}
	return os.WriteFile(p, data, mode)
}

var patchTool = Tool{
	Name: "patch",
	Description: "Edit a file with exact search/replace edits, applied in order. Each old_string must match the file exactly " +
		"(including whitespace) and exactly once, unless replace_all is set. Include enough surrounding lines to make it unique. " +
		"If any edit fails, the file is left unchanged.",
	Schema: `{"type":"object","properties":{
"path":{"type":"string","description":"File path, relative to the working directory"},
"edits":{"type":"array","items":{"type":"object","properties":{
  "old_string":{"type":"string","description":"Exact text to replace"},
  "new_string":{"type":"string","description":"Replacement text"},
  "replace_all":{"type":"boolean","description":"Replace every occurrence (default false)"}
 },"required":["old_string","new_string"]}}
},"required":["path","edits"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Path  string `json:"path"`
			Edits []struct {
				Old        string `json:"old_string"`
				New        string `json:"new_string"`
				ReplaceAll bool   `json:"replace_all"`
			} `json:"edits"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if len(a.Edits) == 0 {
			return errorf("no edits given")
		}
		p, err := resolve(env.Dir, a.Path)
		if err != nil {
			return errorf("%v", err)
		}
		b, err := os.ReadFile(p)
		if err != nil {
			return errorf("%v", err)
		}
		s := string(b)
		for i, e := range a.Edits {
			if e.Old == "" {
				return errorf("edit %d: old_string is empty; use write to create a file", i+1)
			}
			if e.Old == e.New {
				return errorf("edit %d: old_string and new_string are the same", i+1)
			}
			n := strings.Count(s, e.Old)
			switch {
			case n == 0:
				return errorf("edit %d: old_string not found in %s; the file was not changed", i+1, rel(env.Dir, p))
			case n > 1 && !e.ReplaceAll:
				return errorf("edit %d: old_string matches %d times in %s; add context to make it unique or set replace_all. The file was not changed", i+1, n, rel(env.Dir, p))
			}
			if e.ReplaceAll {
				s = strings.ReplaceAll(s, e.Old, e.New)
			} else {
				s = strings.Replace(s, e.Old, e.New, 1)
			}
		}
		if err := writeFile(p, []byte(s)); err != nil {
			return errorf("%v", err)
		}
		return Result{Text: fmt.Sprintf("applied %d edit(s) to %s", len(a.Edits), rel(env.Dir, p))}
	},
}

var listTool = Tool{
	Name:        "list",
	ReadOnly:    true,
	Description: "List a directory. Directories end in /. Skips .git and node_modules.",
	Schema: `{"type":"object","properties":{
"path":{"type":"string","description":"Directory, relative to the working directory (default .)"},
"depth":{"type":"integer","description":"How many levels to descend, 1-5 (default 1)"}
}}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Path  string `json:"path"`
			Depth int    `json:"depth"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		a.Depth = max(1, min(a.Depth, 5))
		root, err := resolve(env.Dir, a.Path)
		if err != nil {
			return errorf("%v", err)
		}
		var entries []string
		more := false
		err = filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
			if err != nil {
				if p == root {
					return err
				}
				return nil
			}
			if p == root {
				if !d.IsDir() {
					return fmt.Errorf("%s is not a directory", rel(env.Dir, p))
				}
				return nil
			}
			if ctx.Err() != nil {
				return ctx.Err()
			}
			r := rel(root, p)
			if d.IsDir() && skipDir(d.Name()) {
				return filepath.SkipDir
			}
			if len(entries) >= listMaxEntries {
				more = true
				return filepath.SkipAll
			}
			if d.IsDir() {
				entries = append(entries, r+"/")
				if strings.Count(r, "/")+1 >= a.Depth {
					return filepath.SkipDir
				}
			} else {
				entries = append(entries, r)
			}
			return nil
		})
		if err != nil {
			return errorf("%v", err)
		}
		sort.Strings(entries)
		out := strings.Join(entries, "\n")
		if len(entries) == 0 {
			out = "(empty directory)"
		}
		if more {
			out += fmt.Sprintf("\n[stopped after %d entries]", listMaxEntries)
		}
		return Result{Text: out}
	},
}
