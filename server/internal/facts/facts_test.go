package facts

import (
	"context"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/store"
	"github.com/iggy/flit/server/internal/tools"
)

// call is one shell call in a fixture: the command and how it ended.
type call struct {
	command string
	result  string
}

func ok(cmd string) call               { return call{cmd, "fine\n[exit code 0]"} }
func fail(cmd, out string, n int) call { return call{cmd, fmt.Sprintf("%s\n[exit code %d]", out, n)} }
func noModule(cmd string) call         { return fail(cmd, "ModuleNotFoundError: No module named 'pytest'", 1) }
func refused(host string) call {
	return fail("curl https://"+host+"/x", "curl: (7) Failed to connect to "+host+": Connection refused", 7)
}

type fixture struct {
	t    *testing.T
	st   *store.Store
	svc  *Service
	cfg  config.Config
	dir  string
	n    int
	sess []store.Session
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	st, err := store.Open(context.Background(), filepath.Join(t.TempDir(), store.FileName))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { st.Close() })
	f := &fixture{t: t, st: st, cfg: config.Default(), dir: "/work/repo"}
	f.svc = &Service{Store: st, Config: func() config.Config { return f.cfg }}
	if err := st.CreateProject(context.Background(), &store.Project{ID: "prj", TeamID: store.DefaultTeamID, Name: "repo"}); err != nil {
		t.Fatal(err)
	}
	return f
}

// session stores a session of the given turns and observes it.
func (f *fixture) session(turns ...[]call) store.Session {
	f.t.Helper()
	sess := f.write("prj", f.dir, turns...)
	if err := f.svc.Observe(context.Background(), sess.ID); err != nil {
		f.t.Fatal(err)
	}
	return sess
}

func (f *fixture) write(project, dir string, turns ...[]call) store.Session {
	f.t.Helper()
	ctx := context.Background()
	f.n++
	sess := store.Session{
		ID: fmt.Sprintf("ses_%04d", f.n), TeamID: store.DefaultTeamID, ProjectID: project, WorkingDir: dir,
		Provider: "p", Model: "m", State: flitv1.TaskState_TASK_STATE_DONE,
		CreatedAt: time.Unix(int64(f.n), 0),
	}
	if err := f.st.CreateSession(ctx, &sess); err != nil {
		f.t.Fatal(err)
	}
	var seq int64
	add := func(ev *flitv1.Event) {
		seq++
		ev.SessionId, ev.Seq, ev.Time = sess.ID, seq, timestamppb.Now()
		if err := f.st.AppendEvent(ctx, sess, ev); err != nil {
			f.t.Fatal(err)
		}
	}
	for i, calls := range turns {
		add(&flitv1.Event{Payload: &flitv1.Event_MessageStarted{MessageStarted: &flitv1.MessageStarted{
			MessageId: fmt.Sprintf("m%d", i), Role: flitv1.Role_ROLE_USER}}})
		for j, c := range calls {
			id := fmt.Sprintf("c%d", j)
			args, _ := json.Marshal(map[string]string{"command": c.command})
			add(&flitv1.Event{Payload: &flitv1.Event_ToolCallStarted{ToolCallStarted: &flitv1.ToolCallStarted{
				ToolCallId: id, Name: "shell", Arguments: string(args)}}})
			add(&flitv1.Event{Payload: &flitv1.Event_ToolCallDone{ToolCallDone: &flitv1.ToolCallDone{
				ToolCallId: id, Result: c.result}}})
		}
	}
	f.sess = append(f.sess, sess)
	return sess
}

func (f *fixture) list() []Fact {
	f.t.Helper()
	list, err := f.svc.List(context.Background(), "prj")
	if err != nil {
		f.t.Fatal(err)
	}
	return list
}

func (f *fixture) one(family string) Fact {
	f.t.Helper()
	var found []Fact
	for _, x := range f.list() {
		if x.Family == family {
			found = append(found, x)
		}
	}
	if len(found) != 1 {
		f.t.Fatalf("want one %s fact, got %+v", family, f.list())
	}
	return found[0]
}

func (f *fixture) prompt() string {
	f.t.Helper()
	block, err := f.svc.Prompt(context.Background(), store.Session{ID: "ses_new", ProjectID: "prj", WorkingDir: f.dir})
	if err != nil {
		f.t.Fatal(err)
	}
	return block
}

func repair() []call { return []call{noModule("pytest -q"), ok("python -m pytest -q")} }

func TestClassify(t *testing.T) {
	cases := []struct{ cmd, intent, form, tool string }{
		{"pytest -q tests/", intentTests, "pytest", "pytest"},
		{"python3 -m pytest -x", intentTests, "python3 -m pytest", "pytest"},
		{".venv/bin/pytest", intentTests, ".venv/bin/pytest", "pytest"},
		{"uv run pytest", intentTests, "uv run pytest", "pytest"},
		{"npx tsc --noEmit", intentBuild, "npx tsc", "tsc"},
		{"tsc", intentBuild, "tsc", "tsc"},
		{"go test ./...", intentTests, "go test", "go"},
		{"npm run test:unit", intentTests, "npm run test:unit", "npm"},
		{"npm test", intentTests, "npm test", "npm"},
		{"go vet ./...", intentBuild, "go vet", "go"},
		{"flutter analyze", intentBuild, "flutter analyze", "flutter"},
		{"pip install -r requirements.txt", intentPackage, "pip install", "pip"},
		{"python -m pip install x", intentPackage, "python -m pip", "pip"},
		{"python script.py", intentInterpreter, "python", "python"},
		{"timeout 60 pytest", intentTests, "pytest", "pytest"},
		{"env FOO=1 pytest", intentTests, "pytest", "pytest"},
		{"curl -s https://example.com/x", intentFetch, "curl", "curl"},
		{"git clone https://github.com/a/b", intentFetch, "git clone", "git"},
		{"git remote -v", intentVCSProbe, "git remote", "git"},
	}
	for _, c := range cases {
		parts, _, ok := tools.ShellParts(c.cmd)
		if !ok || len(parts) != 1 {
			t.Fatalf("%q: %v %v", c.cmd, parts, ok)
		}
		got, ok := classify(parts[0], "/work/repo")
		if !ok {
			t.Errorf("%q not classified", c.cmd)
			continue
		}
		if got.intent != c.intent || got.form != c.form || got.tool != c.tool {
			t.Errorf("%q = %s / %s / %s, want %s / %s / %s", c.cmd, got.intent, got.form, got.tool, c.intent, c.form, c.tool)
		}
	}
	for _, cmd := range []string{"ls -la", "./custom-script", "git status", "curl $HOST/x", "curl http://localhost:3000/"} {
		parts, _, _ := tools.ShellParts(cmd)
		if c, ok := classify(parts[0], "/work/repo"); ok {
			t.Errorf("%q classified as %+v", cmd, c)
		}
	}
}

func TestOutcomes(t *testing.T) {
	cases := []struct {
		name    string
		c       call
		outcome outcome
		class   string
		form    string
	}{
		{"exit 0", ok("pytest"), worked, "", "pytest"},
		{"command not found", fail("pytest", "bash: pytest: command not found", 127), failed, errCommand, "pytest"},
		{"module missing", noModule("pytest"), failed, errModule, "pytest"},
		{"tests ran and failed", fail("pytest", "1 failed, 2 passed", 1), worked, "", "pytest"},
		{"build error says nothing", fail("tsc", "src/a.ts(1,1): error TS1005", 2), unknown, "", "tsc"},
		{"piped, error shown", call{"pytest 2>&1 | tail -5", "bash: pytest: command not found\n[exit code 0]"}, failed, errCommand, "pytest"},
		{"piped, tests ran", call{"pytest | tail -5", "3 passed\n[exit code 0]"}, worked, "", "pytest"},
		{"piped, silent", call{"tsc | tail -5", "\n[exit code 0]"}, unknown, "", "tsc"},
		{"recipe's cc is missing, not make", call{"make build", "/bin/sh: 1: cc: not found\n[exit code 2]"}, unknown, "", "make build"},
		{"cd is part of the form", ok("cd app && pytest"), worked, "", "cd app && pytest"},
		{"absolute cd inside the session", ok("cd /work/repo/app && pytest"), worked, "", "cd app && pytest"},
		{"repeat note after the exit code", call{"pytest", "ok\n[exit code 0]\n\n[flit: you have now made this exact call]"}, worked, "", "pytest"},
	}
	for _, c := range cases {
		obs := observeCall(c.c.command, "", "/work/repo", c.c.result, 1, 1)
		if len(obs) != 1 {
			t.Errorf("%s: %+v", c.name, obs)
			continue
		}
		if o := obs[0]; o.outcome != c.outcome || o.class != c.class || o.form != c.form {
			t.Errorf("%s: got %v %q %q, want %v %q %q", c.name, o.outcome, o.class, o.form, c.outcome, c.class, c.form)
		}
	}
	if obs := observeCall("pytest", "", "/work/repo", "the user denied this command", 1, 1); len(obs) != 0 {
		t.Errorf("a call that didn't run: %+v", obs)
	}
	if obs := observeCall("cd /elsewhere && pytest", "", "/work/repo", "[exit code 0]", 1, 1); len(obs) != 0 {
		t.Errorf("a cd out of the session: %+v", obs)
	}
	// Two real commands: the error could be either's.
	obs := observeCall("./setup.sh && pytest", "", "/work/repo", "No module named foo\n[exit code 1]", 1, 1)
	if len(obs) != 1 || obs[0].outcome != unknown {
		t.Errorf("chain: %+v", obs)
	}
}

func TestFormRepairLifecycle(t *testing.T) {
	f := newFixture(t)
	f.session(repair())
	f.session(repair())
	if got := f.one(familyForm); got.State != StateForming || got.Confirmations != 2 {
		t.Fatalf("after 2 sessions: %+v", got)
	}
	f.session(repair())
	got := f.one(familyForm)
	if got.State != StateActive {
		t.Fatalf("after 3 sessions: %+v", got)
	}
	if got.Injected || f.prompt() != "" {
		t.Fatalf("injected before 4 sessions exercised it: %+v", got)
	}
	f.session(repair())
	got = f.one(familyForm)
	if !got.Injected || got.Exercised != 4 || got.Fired != 4 {
		t.Fatalf("after 4 sessions: %+v", got)
	}
	block := f.prompt()
	want := "- **When running the tests:** use `python -m pytest`; `pytest` fails here with a missing module error.\n"
	if !strings.Contains(block, want) || !strings.Contains(block, "<project-facts>") {
		t.Fatalf("prompt:\n%s", block)
	}
	if len(got.Evidence) != 4 || got.Evidence[0] != "ses_0001 T1" {
		t.Fatalf("evidence: %v", got.Evidence)
	}

	// One contradicting session isn't enough, and a session that says
	// nothing either way breaks the streak.
	f.session([]call{ok("pytest")})
	f.session([]call{ok("python -m pytest")})
	f.session([]call{ok("pytest")})
	if got := f.one(familyForm); got.State != StateActive {
		t.Fatalf("after broken streak: %+v", got)
	}
	f.session([]call{ok("pytest")})
	if got := f.one(familyForm); got.State != StateRetired || got.Injected {
		t.Fatalf("after 2 in a row: %+v", got)
	}
	if f.prompt() != "" {
		t.Fatal("a retired fact is still injected")
	}

	// The failure coming back starts it over.
	f.session(repair())
	if got := f.one(familyForm); got.State != StateForming || got.Confirmations != 1 {
		t.Fatalf("after coming back: %+v", got)
	}
}

func TestRepairs(t *testing.T) {
	cases := []struct {
		name  string
		calls []call
		want  string // the working form, "" for no fact
	}{
		{"tsc to npx tsc", []call{fail("tsc", "bash: tsc: command not found", 127), ok("npx tsc")}, "npx tsc"},
		{"same form working later", []call{noModule("pytest"), ok("pip install pytest"), ok("pytest")}, ""},
		{"another tool isn't a repair of a build", []call{fail("ruff check", "bash: ruff: command not found", 127), ok("make build")}, ""},
		{"another ecosystem's tests", []call{fail("pytest", "bash: pytest: command not found", 127), ok("go test ./...")}, ""},
		{"a test failure isn't a form error", []call{fail("pytest", "1 failed", 1), ok("python -m pytest")}, ""},
		{"needs a fuller spelling", []call{fail("pip install x", "bash: pip: command not found", 127), ok("pip3 install x")}, ""},
		{"an env prefix may be what helped", []call{noModule("pytest"), ok("PYTHONPATH=. python -m pytest")}, ""},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			f := newFixture(t)
			f.session(c.calls)
			list := f.list()
			if c.want == "" {
				if len(list) != 0 {
					t.Fatalf("unexpected: %+v", list)
				}
				return
			}
			if len(list) != 1 || !strings.Contains(list[0].Text, "`"+c.want+"`") {
				t.Fatalf("got %+v", list)
			}
		})
	}
	// Repairs must be in the same turn.
	f := newFixture(t)
	f.session([]call{noModule("pytest")}, []call{ok("python -m pytest")})
	if list := f.list(); len(list) != 0 {
		t.Fatalf("across turns: %+v", list)
	}
}

func TestFiringGate(t *testing.T) {
	f := newFixture(t)
	for range 3 {
		f.session(repair())
	}
	// Sessions that use the working form without having been told dilute
	// the rate: 3 of 8 is under 40%.
	for range 5 {
		f.session([]call{ok("python -m pytest")})
	}
	got := f.one(familyForm)
	if got.State != StateActive || got.Injected || got.Exercised != 8 || got.Fired != 3 {
		t.Fatalf("%+v", got)
	}
	if f.prompt() != "" {
		t.Fatal("injected under the gate")
	}
	// Live config: lowering the gate applies at once.
	f.cfg.Learning.FactsFireRate = 0.3
	if !f.one(familyForm).Injected {
		t.Fatal("the lower gate didn't apply")
	}
}

func TestPreventedCounts(t *testing.T) {
	f := newFixture(t)
	for range 4 {
		f.session(repair())
	}
	// The prompt records the injection for the session that gets it.
	for range 3 {
		sess := f.write("prj", f.dir, []call{ok("python -m pytest")})
		if block, err := f.svc.Prompt(context.Background(), sess); err != nil || block == "" {
			t.Fatalf("%q %v", block, err)
		}
		if err := f.svc.Observe(context.Background(), sess.ID); err != nil {
			t.Fatal(err)
		}
	}
	if got := f.one(familyForm); got.Fired != 7 || got.Exercised != 7 || !got.Injected {
		t.Fatalf("%+v", got)
	}
}

func TestBoundary(t *testing.T) {
	f := newFixture(t)
	for range 4 {
		f.session([]call{refused("pypi.internal")})
	}
	got := f.one(familyBoundary)
	if got.State != StateActive || !got.Injected {
		t.Fatalf("%+v", got)
	}
	if !strings.Contains(got.Text, "`pypi.internal`") || !strings.Contains(got.Text, "refused") {
		t.Fatalf("%s", got.Text)
	}
	// One success retires it at once.
	f.session([]call{ok("curl -s https://pypi.internal/x")})
	if got := f.one(familyBoundary); got.State != StateRetired {
		t.Fatalf("%+v", got)
	}

	// A host that sometimes answers is no boundary; nor is localhost.
	f = newFixture(t)
	f.session([]call{refused("flaky.example"), ok("curl https://flaky.example/x")})
	f.session([]call{refused("localhost")})
	if list := f.list(); len(list) != 0 {
		t.Fatalf("%+v", list)
	}

	// curl -s says nothing; its exit code does.
	f = newFixture(t)
	f.session([]call{fail("curl -s https://quiet.example/x", "", 6)})
	if got := f.one(familyBoundary); got.Confirmations != 1 || !strings.Contains(got.Text, "doesn't resolve") {
		t.Fatalf("%+v", got)
	}
}

func TestEnvValue(t *testing.T) {
	missing := fail("pytest", "KeyError: 'DJANGO_ENV'", 1)
	f := newFixture(t)
	for range 4 {
		f.session([]call{missing, ok("DJANGO_ENV=test pytest")})
	}
	got := f.one(familyEnv)
	if got.State != StateActive || !strings.Contains(got.Text, "set `DJANGO_ENV=test`; `pytest` fails here without it") {
		t.Fatalf("%+v", got)
	}
	// export counts as setting it, and a run without it working contradicts.
	f.session([]call{missing, ok("export DJANGO_ENV=test && pytest")})
	if got := f.one(familyEnv); got.Confirmations != 5 {
		t.Fatalf("%+v", got)
	}
	f.session([]call{ok("pytest")})
	f.session([]call{ok("pytest")})
	if got := f.one(familyEnv); got.State != StateRetired {
		t.Fatalf("%+v", got)
	}
}

func TestEnvValueKeepsSecretsOut(t *testing.T) {
	cases := []struct{ set, name string }{
		{"API_TOKEN=sk-live-abc", "API_TOKEN"},
		{"DATABASE_URL=postgres://u:hunter2@db/x", "DATABASE_URL"},
		{"BUILD_ID=abcdefghijklmnopqrstuvwxyz012345", "BUILD_ID"},
	}
	for _, c := range cases {
		f := newFixture(t)
		value := strings.SplitN(c.set, "=", 2)[1]
		f.session([]call{fail("pytest", c.name+" is not set", 1), ok(c.set + " pytest")})
		got := f.one(familyEnv)
		if !strings.Contains(got.Text, "`"+c.name+"` must be set") || strings.Contains(got.Text, value) {
			t.Errorf("%s: %s", c.name, got.Text)
		}
		list, _ := f.st.ListFacts(context.Background(), "prj")
		if strings.Contains(list[0].Detail, value) {
			t.Errorf("%s stored: %s", c.name, list[0].Detail)
		}
	}
}

func TestForgetAndRebuild(t *testing.T) {
	f := newFixture(t)
	for range 4 {
		f.session(repair())
		f.session([]call{refused("blocked.example")})
	}
	before := f.list()

	form := f.one(familyForm)
	if _, err := f.svc.Forget(context.Background(), form.ID[:10]); err != nil {
		t.Fatal(err)
	}
	if got := f.one(familyForm); got.State != StateForgotten || got.Injected {
		t.Fatalf("%+v", got)
	}
	if strings.Contains(f.prompt(), "pytest") {
		t.Fatal("a forgotten fact is injected")
	}
	// Seeing it again doesn't bring it back.
	f.session(repair())
	if got := f.one(familyForm); got.State != StateForgotten || got.Confirmations != 4 {
		t.Fatalf("%+v", got)
	}

	// Rebuilding gives what was learned live, and keeps it forgotten.
	n, err := f.svc.Rebuild(context.Background(), "prj")
	if err != nil || n != 9 {
		t.Fatalf("%d %v", n, err)
	}
	if got := f.one(familyForm); got.State != StateForgotten || got.ID != form.ID {
		t.Fatalf("%+v", got)
	}
	if got, was := f.one(familyBoundary), find(before, familyBoundary); got.State != was.State || got.Confirmations != was.Confirmations || got.ID != was.ID {
		t.Fatalf("rebuilt %+v, was %+v", got, was)
	}
	// Observing twice changes nothing.
	if err := f.svc.Observe(context.Background(), f.sess[0].ID); err != nil {
		t.Fatal(err)
	}
	if got := f.one(familyBoundary); got.Confirmations != 4 {
		t.Fatalf("%+v", got)
	}
}

func find(list []Fact, family string) Fact {
	for _, f := range list {
		if f.Family == family {
			return f
		}
	}
	return Fact{}
}

func TestModesAndCaps(t *testing.T) {
	f := newFixture(t)
	f.cfg.Learning.Facts = ModePropose
	for range 4 {
		f.session(repair(), []call{refused("a.example")}, []call{refused("b.example")})
	}
	if f.prompt() != "" {
		t.Fatal("propose injected")
	}
	if got := f.one(familyForm); got.State != StateActive || got.Injected {
		t.Fatalf("%+v", got)
	}

	f.cfg.Learning.Facts = ModeOn
	f.cfg.Learning.FactsMax = 2
	if got := strings.Count(f.prompt(), "\n- "); got != 2 {
		t.Fatalf("facts_max: %d\n%s", got, f.prompt())
	}
	f.cfg.Learning.FactsMax = 0
	f.cfg.Learning.FactsMaxBytes = 120
	if block := f.prompt(); strings.Count(block, "\n- ") != 1 || !strings.Contains(block, "pytest") {
		t.Fatalf("facts_max_bytes:\n%s", block)
	}

	f.cfg.Learning.Facts = ModeOff
	f.session(repair(), []call{refused("c.example")})
	for _, x := range f.list() {
		if strings.Contains(x.Text, "c.example") {
			t.Fatal("off still observes")
		}
	}
}

func TestOneFixPerFailingForm(t *testing.T) {
	f := newFixture(t)
	for range 4 {
		f.session(repair(), []call{noModule("pytest"), ok("python3 -m pytest")})
	}
	if got := strings.Count(f.prompt(), "`pytest` fails"); got != 1 {
		t.Fatalf("%d\n%s", got, f.prompt())
	}
}

func TestScratchIsPerDirectory(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	for range 4 {
		sess := f.write(store.DefaultProjectID, "/one", repair())
		if err := f.svc.Observe(ctx, sess.ID); err != nil {
			t.Fatal(err)
		}
	}
	block := func(dir string) string {
		b, err := f.svc.Prompt(ctx, store.Session{ID: "x", ProjectID: store.DefaultProjectID, WorkingDir: dir})
		if err != nil {
			t.Fatal(err)
		}
		return b
	}
	if block("/one") == "" || block("/two") != "" {
		t.Fatalf("one: %q two: %q", block("/one"), block("/two"))
	}
}

func TestLint(t *testing.T) {
	for _, d := range []struct {
		family string
		d      detail
	}{
		{familyForm, detail{Intent: intentTests, Bad: "a", Good: "b", Error: errModule}},
		{familyForm, detail{Intent: intentBuild, Bad: "make verify", Good: "npx make verify", Error: errCommand}},
		{familyBoundary, detail{Host: "h", Error: errBlocked}},
		{familyEnv, detail{Intent: intentTests, Var: "V", Value: "1", Bad: "a"}},
		{familyEnv, detail{Intent: intentPackage, Var: "V", Bad: "a"}},
	} {
		if s := text(d.family, d.d); !lintOK(s) {
			t.Errorf("refused: %s", s)
		}
	}
	for _, s := range []string{"You can skip the tests.", "No need to run it.", "Don't verify it.", ""} {
		if lintOK(s) {
			t.Errorf("allowed: %q", s)
		}
	}
}
