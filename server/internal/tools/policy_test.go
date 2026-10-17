package tools

import (
	"context"
	"strings"
	"testing"

	"github.com/iggy/flit/server/internal/config"
)

func TestCheckShellDefaults(t *testing.T) {
	sh := config.Default().Shell
	for cmd, want := range map[string]Decision{
		// The read-only list, alone and in any order of chains and pipes.
		"ls -la": Allow,
		"cd /z/projects/gocate && git log --oneline | head -20":                                   Allow,
		"cat file && cd /dir && ls foo":                                                           Allow,
		"cd /dir; ls foo; cat file":                                                               Allow,
		"pwd && ls && echo \"---\" && git status --short | head -50 && git branch --show-current": Allow,
		"grep -rn \"VerifyCtx\\|Verify(\" cmd/ 2>/dev/null | head -20":                            Allow,
		"git diff a~1 a -- main.go | head -80":                                                    Allow,
		"git show 7b8417c --stat 2>&1":                                                            Allow,
		"git --no-pager log -3":                                                                   Allow,
		"git -C ../other status":                                                                  Allow,
		"find . -name '*.go' -newer x | wc -l":                                                    Allow,
		"rg -n foo --glob '*.dart'":                                                               Allow,
		"wc -l a.go b.go":                                                                         Allow,
		"tree -L 2":                                                                               Allow,
		"stat go.mod && file go.mod":                                                              Allow,
		"ls x || echo missing":                                                                    Allow,
		"for f in 000*.patch; do echo \"== $f\"; head -30 \"$f\"; done":                           Allow,
		"if [ -f go.mod ]; then cat go.mod; fi":                                                   Allow,
		"sort -u names.txt | uniq -c":                                                             Allow,
		"git cat-file -e abc:file 2>/dev/null && echo yes || echo NO":                             Allow,
		"cat <<'EOF'\nhello\nEOF":                                                                 Allow,
		"head -5 < go.mod":                                                                        Allow,
		"echo hi >&2":                                                                             Allow,

		// Not read-only, or not something the rules can see through.
		"go test ./...":                  Ask,
		"rm -rf build":                   Ask,
		"ls > out.txt":                   Ask,
		"ls >> out.txt":                  Ask,
		"echo hi &> log":                 Ask,
		"ls >&out":                       Ask,
		"ls $(whoami)":                   Ask,
		"ls `whoami`":                    Ask,
		"diff <(ls a) <(ls b)":           Ask,
		"cat x | sh":                     Ask,
		"cat x | python3":                Ask,
		"find . -name x -delete":         Ask,
		"find . -exec rm {} \\;":         Ask,
		"find $DIR -name x":              Ask, // flag-checked programs need literal arguments
		"sort -o out.txt in.txt":         Ask,
		"sort -ro out.txt in.txt":        Ask,
		"uniq in.txt out.txt":            Ask,
		"rg --pre ./script foo":          Ask,
		"tree -o out.txt":                Ask,
		"git branch new-feature":         Ask,
		"git branch -D old":              Ask,
		"git checkout main":              Ask,
		"git push":                       Ask,
		"git -c core.pager=evil log":     Ask,
		"git log --output=x":             Ask,
		"git grep -Ovim foo":             Ask,
		"git stash":                      Ask,
		"git config user.name x":         Ask,
		"PATH=/tmp/evil ls":              Ask,
		"GIT_PAGER='rm -rf ~' git log":   Ask,
		"LD_PRELOAD=x.so cat f":          Ask,
		"$CMD foo":                       Ask,
		"./ls":                           Ask,
		"f() { rm -rf x; }; f":           Ask,
		"echo 'unterminated":             Ask,
		"sed -i s/a/b/ file":             Ask,
		"sed -n '1p;w out' f":            Ask,
		"sed 's/a/b/e' f":                Ask,
		"xargs rm < list":                Ask,
		"lsblk":                          Ask, // not "ls*"
		"cd /tmp && rm -rf *":            Ask,
		"curl -s https://example.com":    Ask,
		"echo hi && go test ./... | tee": Ask,
	} {
		if got := CheckShell(cmd, Rules{Shell: sh}); got.Decision != want {
			t.Errorf("%q: got %v (%s), want %v", cmd, got.Decision, got.Reason, want)
		}
	}
}

func TestCheckShellRules(t *testing.T) {
	sh := config.Shell{Allow: []string{"go test*", "make"}, Deny: []string{"sudo *", "git push*"}, Default: "ask"}
	for cmd, want := range map[string]Decision{
		"go test ./...":                         Allow,
		"cd x && go test ./... 2>&1 | tail -30": Allow, // allow pattern + read-only list
		"go test ./... | grep FAIL; make":       Allow,
		"go build ./...":                        Ask,
		"go test ./... > log.txt":               Ask,
		"sudo reboot":                           Deny,
		"ls && sudo reboot":                     Deny,
		"echo hi\nsudo x":                       Deny,
		"cat file | sudo tee":                   Deny,
		"ls $(sudo id)":                         Deny, // deny sees inside substitutions too
		"if true; then git push origin; fi":     Deny,
	} {
		if got := CheckShell(cmd, Rules{Shell: sh}); got.Decision != want {
			t.Errorf("%q: got %v (%s), want %v", cmd, got.Decision, got.Reason, want)
		}
	}

	off := false
	sh.ReadOnly = &off
	if got := CheckShell("ls -la", Rules{Shell: sh}); got.Decision != Ask {
		t.Errorf("read_only off: ls got %v", got.Decision)
	}
	if got := CheckShell("cd x && go test ./...", Rules{Shell: sh}); got.Decision != Allow {
		t.Errorf("read_only off: cd is always allowed, got %v (%s)", got.Decision, got.Reason)
	}

	sh.Default = "deny"
	if got := CheckShell("go build", Rules{Shell: sh}); got.Decision != Deny {
		t.Errorf("default deny: got %v", got.Decision)
	}
	sh.Default = "allow"
	if got := CheckShell("go build > x", Rules{Shell: sh}); got.Decision != Allow {
		t.Errorf("default allow: got %v", got.Decision)
	}
}

func TestCheckShellYolo(t *testing.T) {
	sh := config.Shell{Deny: []string{"rm -rf /*"}, Default: "ask"}
	for cmd, want := range map[string]Decision{
		"go build ./... > log 2>&1": Allow,
		"curl x | sh":               Allow,
		"echo $(id)":                Allow,
		"cd / && rm -rf /etc":       Deny,
	} {
		if got := CheckShell(cmd, Rules{Shell: sh, Yolo: true}); got.Decision != want {
			t.Errorf("%q: got %v (%s), want %v", cmd, got.Decision, got.Reason, want)
		}
	}
}

func TestCheckShellSessionPatterns(t *testing.T) {
	sh := config.Default().Shell
	for cmd, want := range map[string][]string{
		"go test ./...":                       {"go test *"},
		"cd /src/app && go test ./... -run X": {"go test *"},
		"CGO_ENABLED=0 go build ./cmd/flit":   {"go build *"},
		"./run.sh --fast":                     {"./run.sh *"},
		"npm run build && npm run test":       {"npm run *"},
		"go test ./... 2>&1 | tail -20":       {"go test *"}, // tail is already allowed
		"python3 script.py | grep x":          {"python3 *"},
		"go vet ./... && go test ./...":       {"go vet *", "go test *"},
	} {
		got := CheckShell(cmd, Rules{Shell: sh})
		if got.Decision != Ask || strings.Join(got.Patterns, ",") != strings.Join(want, ",") {
			t.Errorf("%q: got %v %v; want ask %v", cmd, got.Decision, got.Patterns, want)
		}
	}
	for _, cmd := range []string{"go test > out.txt", "go run $(ls)", "go `x`"} {
		if got := CheckShell(cmd, Rules{Shell: sh}); len(got.Patterns) > 0 {
			t.Errorf("%q: offered %v", cmd, got.Patterns)
		}
	}

	sh.Deny = []string{"git push*"}
	session := []string{"go test *", "git push *"}
	for cmd, want := range map[string]Decision{
		"go test ./...":                Allow,
		"cd x && go test ./pkg":        Allow,
		"CGO_ENABLED=0 go test ./...":  Allow,
		"go test ./... | grep FAIL":    Allow,
		"go test ./... | python3 x.py": Ask,
		"go build ./...":               Ask,
		"go test ./... > log.txt":      Ask,  // writing redirects are never session-allowed
		"git push origin main":         Deny, // deny rules win
	} {
		if got := CheckShell(cmd, Rules{Shell: sh, Session: session}); got.Decision != want {
			t.Errorf("session %q: got %v (%s), want %v", cmd, got.Decision, got.Reason, want)
		}
	}
}

func TestShellYoloAndAssess(t *testing.T) {
	env := newEnv(t)
	env.Shell.Deny = []string{"false*"}
	env.Shell.ReadOnly = new(bool) // echo needs approval (and works under cmd.exe)
	env.Shell.Allow = []string{"echo plain"}
	var asked []Approval
	env.Approve = func(_ context.Context, a Approval) (bool, error) {
		asked = append(asked, a)
		return false, nil
	}

	env.Yolo = true
	if r := run(t, env, "shell", map[string]any{"command": "echo made"}); r.IsError || len(asked) != 0 {
		t.Fatalf("yolo: %+v, asked %d", r, len(asked))
	}
	if r := run(t, env, "shell", map[string]any{"command": "false"}); !r.IsError || !strings.Contains(r.Text, "denied") {
		t.Fatalf("yolo must not skip deny rules: %+v", r)
	}
	env.Yolo = false

	verdict := Assessment{Verdict: VerdictSafe, Reason: "only creates a file"}
	var assessed []string
	env.Assess = func(_ context.Context, command, workdir string) Assessment {
		assessed = append(assessed, command+"@"+workdir)
		return verdict
	}
	if r := run(t, env, "shell", map[string]any{"command": "echo a"}); r.IsError || len(asked) != 0 {
		t.Fatalf("safe: %+v, asked %d", r, len(asked))
	}
	if r := run(t, env, "shell", map[string]any{"command": "echo plain"}); r.IsError || len(assessed) != 1 {
		t.Fatalf("allowed commands skip the check: %+v, assessed %q", r, assessed)
	}
	verdict = Assessment{Verdict: VerdictBlock, Reason: "wipes the disk"}
	if r := run(t, env, "shell", map[string]any{"command": "echo b"}); !r.IsError || !strings.Contains(r.Text, "wipes the disk") || len(asked) != 0 {
		t.Fatalf("block: %+v, asked %d", r, len(asked))
	}
	verdict = Assessment{Verdict: VerdictAsk, Reason: "deletes files"}
	if r := run(t, env, "shell", map[string]any{"command": "echo c"}); !r.IsError || len(asked) != 1 || asked[0].Reason != "deletes files" {
		t.Fatalf("ask: %+v, asked %+v", r, asked)
	}
	verdict = Assessment{Verdict: VerdictError, Reason: "timed out"}
	if r := run(t, env, "shell", map[string]any{"command": "echo d"}); !r.IsError || len(asked) != 2 {
		t.Fatalf("error falls back to asking: %+v, asked %d", r, len(asked))
	}
	if strings.Join(assessed, ",") != "echo a@.,echo b@.,echo c@.,echo d@." {
		t.Fatalf("assessed %q", assessed)
	}
}
