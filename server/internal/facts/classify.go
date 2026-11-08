package facts

import (
	"net/url"
	"path"
	"regexp"
	"strings"

	"github.com/iggy/flit/server/internal/tools"
)

// classified is what classify makes of one part of a command.
type classified struct {
	intent string
	form   string
	tool   string
	head   string // the executable as typed
	bare   bool
	hosts  []string
	env    []tools.ShellAssign // from an env prefix
}

func set(words ...string) map[string]bool {
	m := make(map[string]bool, len(words))
	for _, w := range words {
		m[w] = true
	}
	return m
}

var (
	// Prefixes that run the command after them unchanged.
	transparentHeads = set("sudo", "env", "time", "exec", "nice", "nohup", "timeout", "command")

	interpreters = set("python", "python2", "python3", "pypy", "pypy3", "node", "nodejs", "deno", "bun",
		"ruby", "perl", "php", "lua", "julia", "Rscript", "elixir")
	testRunners = set("pytest", "py.test", "tox", "nox", "nosetests", "trial", "unittest",
		"jest", "vitest", "mocha", "playwright", "cypress", "ava", "karma",
		"rspec", "phpunit", "ctest", "bats")
	// Tools whose `<tool> test` runs the tests and `<tool> build` builds.
	taskHeads = set("make", "npm", "yarn", "pnpm", "bun", "deno", "cargo", "go", "mvn", "gradle", "gradlew",
		"dotnet", "mix", "swift", "rake", "flutter", "dart", "task", "just")
	buildHeads = set("make", "cmake", "ninja", "bazel", "tsc", "eslint", "prettier", "ruff", "flake8", "pylint",
		"mypy", "pyright", "black", "isort", "golangci-lint", "gcc", "g++", "clang", "javac", "webpack", "vite",
		"pre-commit", "shellcheck")
	buildSubs = set("build", "check", "compile", "lint", "vet", "typecheck", "type-check", "clippy", "package",
		"fmt", "format", "analyze")
	packageTools = set("pip", "pip3", "conda", "mamba", "poetry", "pipenv", "uv", "apt", "apt-get",
		"npm", "yarn", "pnpm", "corepack", "gem", "bundle", "composer", "cargo", "go", "mvn", "gradle",
		"dotnet", "brew", "rustup", "pyenv", "nvm", "asdf")
	fetchHeads   = set("curl", "wget", "http", "https", "xh")
	gitFetchSubs = set("clone", "fetch", "pull", "ls-remote")
	gitProbeSubs = set("remote", "branch", "tag", "fsck", "stash", "show-ref", "for-each-ref")

	// Runners that take a command, with how many words they use up.
	runnerPrefixes = [][]string{
		{"uv", "run"}, {"poetry", "run"}, {"pipenv", "run"}, {"pnpm", "exec"}, {"pnpm", "dlx"},
		{"yarn", "exec"}, {"yarn", "dlx"}, {"bundle", "exec"}, {"uv", "tool", "run"}, {"pipx", "run"},
		{"uvx"}, {"npx"}, {"bunx"},
	}

	ecosystems = map[string]string{
		"pytest": "python", "py.test": "python", "tox": "python", "nox": "python", "nosetests": "python",
		"trial": "python", "unittest": "python", "django": "python",
		"jest": "node", "vitest": "node", "mocha": "node", "playwright": "node", "cypress": "node",
		"ava": "node", "karma": "node", "npm": "node", "yarn": "node", "pnpm": "node", "bun": "node", "deno": "node",
		"go": "go", "cargo": "rust", "rspec": "ruby", "rake": "ruby", "phpunit": "php",
		"flutter": "dart", "dart": "dart", "mvn": "jvm", "gradle": "jvm", "gradlew": "jvm",
		"dotnet": "dotnet", "mix": "elixir", "swift": "swift",
	}

	versionSuffixRE = regexp.MustCompile(`[0-9.]+$`)
	scpHostRE       = regexp.MustCompile(`^(?:[\w.-]+@)([A-Za-z0-9.-]+):`)
	validHostRE     = regexp.MustCompile(`^[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?$`)
)

// compatible says whether a working form could be a repair for a failing
// one: test runners of the same ecosystem, otherwise the same tool.
func compatible(intent, badTool, goodTool string) bool {
	if intent == intentTests {
		a, b := ecosystems[badTool], ecosystems[goodTool]
		return a == "" || b == "" || a == b
	}
	return versionSuffixRE.ReplaceAllString(badTool, "") == versionSuffixRE.ReplaceAllString(goodTool, "")
}

// classify says what one part of a command is for and how it was spelled.
// Forms never include arguments (which can hold anything), so they are safe
// to store and to put in a prompt.
func classify(p tools.ShellPart, sessionDir string) (classified, bool) {
	words := []string{p.Name}
	for _, a := range p.Args {
		if !a.Literal {
			words = append(words, "")
			continue
		}
		words = append(words, a.Value)
	}

	var env []tools.ShellAssign
	for len(words) > 1 && transparentHeads[words[0]] {
		head := words[0]
		words = words[1:]
		for len(words) > 0 {
			w := words[0]
			if head == "env" {
				if n, v, ok := strings.Cut(w, "="); ok && n != "" && !strings.HasPrefix(w, "-") {
					env = append(env, tools.ShellAssign{Name: n, Value: v, Literal: true})
					words = words[1:]
					continue
				}
			}
			if head == "timeout" && w != "" && strings.Trim(w, "0123456789.smhd") == "" {
				words = words[1:]
				continue
			}
			if strings.HasPrefix(w, "-") {
				return classified{}, false
			}
			break
		}
		if len(words) == 0 {
			return classified{}, false
		}
	}
	if words[0] == "" {
		return classified{}, false
	}

	c, ok := classifyWords(words, sessionDir)
	if !ok {
		return classified{}, false
	}
	c.env = env
	return c, true
}

func classifyWords(words []string, sessionDir string) (classified, bool) {
	// fetch and git first: they have no spelling worth comparing.
	if fetchHeads[words[0]] {
		hosts := fetchHosts(words[1:])
		if len(hosts) != 1 {
			return classified{}, false
		}
		return classified{intent: intentFetch, form: words[0], tool: words[0], head: words[0], hosts: hosts}, true
	}
	if words[0] == "git" && len(words) > 1 {
		switch {
		case gitFetchSubs[words[1]]:
			hosts := fetchHosts(words[2:])
			if len(hosts) != 1 {
				return classified{}, false
			}
			return classified{intent: intentFetch, form: "git " + words[1], tool: "git", head: "git", hosts: hosts}, true
		case gitProbeSubs[words[1]]:
			return classified{intent: intentVCSProbe, form: "git " + words[1], tool: "git", head: "git"}, true
		}
		return classified{}, false
	}

	var prefix []string
	rest := words
	for _, rp := range runnerPrefixes {
		if len(rest) > len(rp) && slicesEqual(rest[:len(rp)], rp) {
			prefix = append(prefix, rp...)
			rest = rest[len(rp):]
			for len(rest) > 1 && strings.HasPrefix(rest[0], "-") {
				rest = rest[1:]
			}
			break
		}
	}

	head := rest[0]
	if strings.Contains(head, "/") {
		rel, ok := headPath(head, sessionDir)
		if !ok {
			return classified{}, false
		}
		head = rel
	}
	base := path.Base(head)
	args := rest[1:]

	if interpreters[base] && len(args) >= 2 && args[0] == "-m" && args[1] != "" {
		mod := args[1]
		form := strings.Join(append(append([]string{}, prefix...), head, "-m", mod), " ")
		c := classified{form: form, tool: mod, head: head}
		switch {
		case testRunners[mod] || mod == "django":
			c.intent = intentTests
		case mod == "pip" || mod == "ensurepip" || mod == "venv":
			c.intent = intentPackage
		default:
			c.intent = intentInterpreter
			c.tool = base
		}
		return finish(c)
	}

	join := func(extra ...string) string {
		return strings.Join(append(append(append([]string{}, prefix...), head), extra...), " ")
	}
	sub := firstWord(args)
	isBare := len(prefix) == 0 && head == base

	if testRunners[base] {
		return finish(classified{intent: intentTests, form: join(), tool: base, head: head, bare: isBare})
	}
	if taskHeads[base] {
		script := sub
		var form string
		if sub == "run" && len(args) > 1 {
			script = firstWord(args[1:])
			form = join("run", script)
		} else if script != "" {
			form = join(script)
		}
		switch {
		case strings.HasPrefix(script, "test"):
			return finish(classified{intent: intentTests, form: form, tool: base, head: head, bare: isBare})
		case buildSubs[script]:
			return finish(classified{intent: intentBuild, form: form, tool: base, head: head, bare: isBare})
		}
	}
	if buildHeads[base] {
		return finish(classified{intent: intentBuild, form: join(), tool: base, head: head, bare: isBare})
	}
	if packageTools[base] {
		form := join()
		if sub != "" {
			form = join(sub)
		}
		return finish(classified{intent: intentPackage, form: form, tool: base, head: head, bare: isBare})
	}
	if interpreters[base] {
		return finish(classified{intent: intentInterpreter, form: join(), tool: base, head: head, bare: isBare})
	}
	return classified{}, false
}

// finish refuses forms that contain anything but plain command words.
func finish(c classified) (classified, bool) {
	if len(c.form) == 0 || len(c.form) > 120 {
		return classified{}, false
	}
	for _, w := range strings.Fields(c.form) {
		if !safeWordRE.MatchString(w) {
			return classified{}, false
		}
	}
	return c, true
}

func firstWord(args []string) string {
	for _, a := range args {
		if a == "" {
			return ""
		}
		if !strings.HasPrefix(a, "-") {
			return a
		}
	}
	return ""
}

// headPath is a command given by path, relative to the session's directory
// when it is inside it.
func headPath(head, sessionDir string) (string, bool) {
	if !safeWordRE.MatchString(head) {
		return "", false
	}
	if path.IsAbs(head) {
		if rest, ok := strings.CutPrefix(head, path.Clean(sessionDir)+"/"); ok {
			return rest, true
		}
	}
	return head, true
}

func slicesEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// fetchHosts are the distinct non-local hosts named in args.
func fetchHosts(args []string) []string {
	var out []string
	seen := map[string]bool{}
	for _, a := range args {
		h := hostOf(a)
		if h == "" || seen[h] || isLocalHost(h) {
			continue
		}
		seen[h] = true
		out = append(out, h)
	}
	return out
}

func hostOf(arg string) string {
	h := ""
	if strings.Contains(arg, "://") {
		u, err := url.Parse(arg)
		if err != nil {
			return ""
		}
		h = u.Hostname()
	} else if m := scpHostRE.FindStringSubmatch(arg); m != nil {
		h = m[1]
	}
	if !validHostRE.MatchString(h) {
		return ""
	}
	return strings.ToLower(h)
}

func isLocalHost(h string) bool {
	switch h {
	case "localhost", "0.0.0.0", "::1":
		return true
	}
	return strings.HasPrefix(h, "127.") || strings.HasSuffix(h, ".localhost")
}
