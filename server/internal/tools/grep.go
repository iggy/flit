package tools

import (
	"bufio"
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"strings"
)

// rgPath finds ripgrep. The grep tool uses it when present (faster, and it
// respects .gitignore) and falls back to a pure-Go search otherwise, so
// static builds need nothing extra. A var so tests can pick either path.
var rgPath = func() string {
	p, _ := exec.LookPath("rg")
	return p
}

type grepArgs struct {
	Pattern    string `json:"pattern"`
	Path       string `json:"path"`
	Glob       string `json:"glob"`
	IgnoreCase bool   `json:"ignore_case"`
}

// grepMatch is one matching line; path is absolute.
type grepMatch struct {
	path string
	line int
	text string
}

// errGrepFull stops a search at grepMaxMatches.
var errGrepFull = errors.New("full")

var grepTool = Tool{
	Name:        "grep",
	Description: "Search file contents with a regular expression (RE2 syntax). Returns path:line: text for each match. Skips binary files, .git and node_modules (and .gitignored files when ripgrep is installed).",
	Schema: `{"type":"object","properties":{
"pattern":{"type":"string","description":"Regular expression"},
"path":{"type":"string","description":"File or directory to search, relative to the working directory (default .)"},
"glob":{"type":"string","description":"Only search files whose name matches this glob, e.g. *.go"},
"ignore_case":{"type":"boolean"}
},"required":["pattern"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a grepArgs
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		expr := a.Pattern
		if a.IgnoreCase {
			expr = "(?i)" + expr
		}
		re, err := regexp.Compile(expr)
		if err != nil {
			return errorf("bad pattern: %v", err)
		}
		if a.Glob != "" {
			if _, err := path.Match(a.Glob, ""); err != nil {
				return errorf("bad glob: %v", err)
			}
		}
		root, err := resolve(env.Dir, a.Path)
		if err != nil {
			return errorf("%v", err)
		}

		var matches []grepMatch
		ok := false
		if rg := rgPath(); rg != "" {
			matches, err, ok = grepRipgrep(ctx, rg, a, root)
		}
		if !ok {
			matches, err = grepWalk(ctx, re, a, root)
		}
		if err != nil && !errors.Is(err, errGrepFull) {
			return errorf("%v", err)
		}
		if len(matches) == 0 {
			return Result{Text: "no matches"}
		}
		var out strings.Builder
		for _, m := range matches {
			text := m.text
			if len(text) > grepMaxLineLen {
				text = text[:grepMaxLineLen] + "…"
			}
			fmt.Fprintf(&out, "%s:%d: %s\n", rel(env.Dir, m.path), m.line, text)
		}
		if errors.Is(err, errGrepFull) {
			fmt.Fprintf(&out, "[stopped after %d matches; narrow the pattern or path]\n", grepMaxMatches)
		}
		return Result{Text: out.String()}
	},
}

// grepWalk is the pure-Go search: files in lexical order, skipping
// skipDir directories, binary files, symlinks and files over
// grepMaxFileSize.
func grepWalk(ctx context.Context, re *regexp.Regexp, a grepArgs, root string) ([]grepMatch, error) {
	var matches []grepMatch
	err := filepath.WalkDir(root, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			if p == root {
				return err
			}
			return nil
		}
		if ctx.Err() != nil {
			return ctx.Err()
		}
		if d.IsDir() {
			if p != root && skipDir(d.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if a.Glob != "" {
			if ok, _ := path.Match(a.Glob, d.Name()); !ok {
				return nil
			}
		}
		if info, err := d.Info(); err != nil || !info.Mode().IsRegular() || info.Size() > grepMaxFileSize {
			return nil
		}
		b, err := os.ReadFile(p)
		if err != nil || isBinary(b) {
			return nil
		}
		sc := bufio.NewScanner(bytes.NewReader(b))
		sc.Buffer(make([]byte, 64<<10), grepMaxFileSize)
		for n := 1; sc.Scan(); n++ {
			if line := sc.Text(); re.MatchString(line) {
				matches = append(matches, grepMatch{path: p, line: n, text: line})
				if len(matches) >= grepMaxMatches {
					return errGrepFull
				}
			}
		}
		return nil
	})
	return matches, err
}

// grepRipgrep runs rg with the walk's rules (hidden files searched, the
// skipDir directories and big files left out, sorted by path) plus
// .gitignore. ok is false when rg failed without reporting anything (say
// it rejected an RE2 pattern), so the caller falls back to the walk.
func grepRipgrep(ctx context.Context, rg string, a grepArgs, root string) (matches []grepMatch, err error, ok bool) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	args := []string{"--json", "--hidden", "--sort", "path", "--no-config",
		"--max-filesize", fmt.Sprint(grepMaxFileSize)}
	for _, d := range []string{".git", ".hg", ".svn", "node_modules", ".dart_tool"} {
		args = append(args, "--glob", "!"+d+"/")
	}
	if a.Glob != "" {
		args = append(args, "--glob", a.Glob)
	}
	if a.IgnoreCase {
		args = append(args, "--ignore-case")
	}
	args = append(args, "--regexp", a.Pattern, "--", root)
	cmd := exec.CommandContext(ctx, rg, args...)
	cmd.Dir = root
	if fi, statErr := os.Stat(root); statErr == nil && !fi.IsDir() {
		cmd.Dir = filepath.Dir(root)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, nil, false
	}
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	if err := cmd.Start(); err != nil {
		return nil, nil, false
	}
	dec := json.NewDecoder(stdout)
	for {
		var msg rgMessage
		if derr := dec.Decode(&msg); derr != nil {
			if !errors.Is(derr, io.EOF) {
				err = derr
			}
			break
		}
		if msg.Type != "match" {
			continue
		}
		matches = append(matches, grepMatch{
			path: msg.Data.Path.String(),
			line: msg.Data.LineNumber,
			text: strings.TrimRight(msg.Data.Lines.String(), "\r\n"),
		})
		if len(matches) >= grepMaxMatches {
			err = errGrepFull
			cancel()
			break
		}
	}
	_, _ = io.Copy(io.Discard, stdout)
	waitErr := cmd.Wait()
	if errors.Is(err, errGrepFull) {
		return matches, err, true
	}
	if ctx.Err() != nil {
		return matches, ctx.Err(), true
	}
	if err != nil {
		return nil, nil, false
	}
	// rg exits 1 for no matches, 2 for errors (some files unreadable, or
	// a bad pattern). Matches with exit 2 are still matches.
	var exit *exec.ExitError
	if waitErr != nil && !(errors.As(waitErr, &exit) && (exit.ExitCode() == 1 || len(matches) > 0)) {
		return nil, nil, false
	}
	return matches, nil, true
}

// rgMessage is one line of rg --json output; only matches are used.
type rgMessage struct {
	Type string `json:"type"`
	Data struct {
		Path       rgText `json:"path"`
		Lines      rgText `json:"lines"`
		LineNumber int    `json:"line_number"`
	} `json:"data"`
}

// rgText is rg's text-or-bytes value: text when it is valid UTF-8,
// otherwise base64 bytes.
type rgText struct {
	Text  *string `json:"text"`
	Bytes string  `json:"bytes"`
}

func (t rgText) String() string {
	if t.Text != nil {
		return *t.Text
	}
	b, _ := base64.StdEncoding.DecodeString(t.Bytes)
	return string(b)
}
