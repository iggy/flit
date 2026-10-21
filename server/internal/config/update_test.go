package config

import (
	"reflect"
	"strings"
	"testing"
)

func TestUpdateDefaultIsNoop(t *testing.T) {
	out, added, err := Update([]byte(DefaultFile()))
	if err != nil || len(added) != 0 || string(out) != DefaultFile() {
		t.Fatalf("added %v, err %v", added, err)
	}
}

// From a one-line config, Update brings back every default setting and
// keeps the user's value and comment.
func TestUpdateFillsEverything(t *testing.T) {
	cur := "# mine\nlisten: 127.0.0.1:9999 # keep\n"
	out, added, err := Update([]byte(cur))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(string(out), cur) || !strings.Contains(string(out), "roles_dir: roles") {
		t.Fatalf("out:\n%s", out)
	}
	if !contains(added, "agent") || !contains(added, "shell") || contains(added, "listen") {
		t.Fatalf("added %v", added)
	}
	if _, again, err := Update(out); err != nil || len(again) != 0 {
		t.Fatalf("second update added %v, %v", again, err)
	}
	got, err := Parse(out)
	if err != nil {
		t.Fatal(err)
	}
	want := Default()
	want.Listen = "127.0.0.1:9999"
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("got %+v\nwant %+v", got, want)
	}
}

// Nested keys are added inside the user's mapping, at its indentation,
// and next to their default neighbours.
func TestUpdateNested(t *testing.T) {
	cur := `listen: 127.0.0.1:7433

agent:
    # my steps
    max_steps: 7

shell:
    timeout: 5m
`
	out, added, err := Update([]byte(cur))
	if err != nil {
		t.Fatal(err)
	}
	s := string(out)
	for _, want := range []string{
		"    # my steps\n    max_steps: 7\n",
		"    compaction:\n      # Compact on its own",
		"    timeout: 5m\n    max_timeout: 30m\n",
		"    model_retries: 1\n    # Compaction:",
	} {
		if !strings.Contains(s, want) {
			t.Errorf("missing %q in:\n%s", want, s)
		}
	}
	// Defaults that come before max_steps are inserted above its comment.
	if i, j := strings.Index(s, "    effort: \"\""), strings.Index(s, "    # my steps"); i < 0 || i > j {
		t.Errorf("effort not above max_steps:\n%s", s)
	}
	if !contains(added, "agent.compaction") || !contains(added, "shell.max_timeout") || !contains(added, "roles_dir") || contains(added, "agent.max_steps") {
		t.Fatalf("added %v", added)
	}
	got, err := Parse(out)
	if err != nil {
		t.Fatal(err)
	}
	if got.Agent.MaxSteps != 7 || got.Shell.Timeout.String() != "5m0s" {
		t.Fatalf("lost user values: %+v %+v", got.Agent, got.Shell)
	}
	if _, again, err := Update(out); err != nil || len(again) != 0 {
		t.Fatalf("second update added %v, %v\n%s", again, err, out)
	}
}

// A missing nested mapping is added whole, comments and examples included.
func TestUpdateKeepsExamples(t *testing.T) {
	out, _, err := Update([]byte("listen: 127.0.0.1:7433\n"))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"providers: []\n#  - name: local\n",
		"  tasks: {}\n  #   chat:",
		"  # Extra system prompt text",
	} {
		if !strings.Contains(string(out), want) {
			t.Errorf("missing %q", want)
		}
	}
}

func TestUpdateEmptyAndFlow(t *testing.T) {
	out, added, err := Update([]byte("# just a comment\n"))
	if err != nil || string(out) != "# just a comment\n\n"+DefaultFile() || len(added) == 0 {
		t.Fatalf("empty: %v %v\n%s", added, err, out)
	}
	// A flow mapping is left as it is.
	cur := "listen: 127.0.0.1:7433\nweb: {fetch: false}\n"
	out, added, err = Update([]byte(cur))
	if err != nil || contains(added, "web.search") || !strings.Contains(string(out), "web: {fetch: false}\n") {
		t.Fatalf("flow: %v %v\n%s", added, err, out)
	}
	if _, _, err := Update([]byte("bogus: 1\n")); err == nil {
		t.Fatal("invalid config accepted")
	}
}

func contains(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}
