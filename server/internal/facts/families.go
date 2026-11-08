package facts

import (
	"encoding/json"
	"fmt"
	"regexp"
	"slices"
	"strconv"
	"strings"
)

// Fact families.
const (
	familyForm     = "form_repair"
	familyBoundary = "boundary"
	familyEnv      = "env_value"
)

// detail is what a fact claims; stored as JSON.
type detail struct {
	Intent   string `json:"intent,omitempty"`
	Bad      string `json:"bad,omitempty"`
	Good     string `json:"good,omitempty"`
	Tool     string `json:"tool,omitempty"`
	GoodTool string `json:"good_tool,omitempty"`
	Error    string `json:"error,omitempty"`
	Host     string `json:"host,omitempty"`
	Var      string `json:"var,omitempty"`
	Value    string `json:"value,omitempty"`
}

func (d detail) json() string {
	b, _ := json.Marshal(d) // only strings
	return string(b)
}

// candidate is a fact a session suggests.
type candidate struct {
	family, key string
	detail      detail
}

// verdict is what one session says about one fact.
type verdict struct {
	confirmed, contradicted, fired bool
	turns                          []int
}

// discover finds the facts a session's observations suggest.
func discover(obs []observation) []candidate {
	var out []candidate
	seen := map[string]bool{}
	add := func(c candidate) {
		k := c.family + "|" + c.key
		if !seen[k] {
			seen[k] = true
			out = append(out, c)
		}
	}
	for i, a := range obs {
		if a.outcome != failed {
			continue
		}
		if b, ok := repairOf(obs, i); ok {
			add(candidate{familyForm, a.intent + "|" + a.form + "|" + b.form, detail{
				Intent: a.intent, Bad: a.form, Good: b.form, Tool: a.tool, GoodTool: b.tool, Error: a.class,
			}})
		}
		for _, v := range a.missing {
			if value, ok := envRepairOf(obs, i, v); ok {
				add(candidate{familyEnv, a.intent + "|" + a.tool + "|" + v, detail{
					Intent: a.intent, Bad: a.form, Tool: a.tool, Var: v, Value: value,
				}})
			}
		}
	}
	// A host is suggested by a session in which every fetch to it failed.
	for _, h := range fetchedHosts(obs) {
		if v := evaluateBoundary(detail{Host: h}, obs); v != nil && v.confirmed {
			add(candidate{familyBoundary, h, detail{Host: h, Error: boundaryError(obs, h)}})
		}
	}
	return out
}

// repairOf finds a working form that repairs the failed observation
// obs[i], later in the same turn.
func repairOf(obs []observation, i int) (observation, bool) {
	a := obs[i]
	if !isFormError(a.class) || a.intent == intentFetch || a.intent == intentVCSProbe {
		return observation{}, false
	}
	needFuller := a.intent == intentPackage || a.intent == intentInterpreter
	if needFuller && !a.bare {
		return observation{}, false // an explicit path that fails isn't a spelling problem
	}
	for _, b := range obs[i+1:] {
		if b.turn != a.turn || b.call <= a.call || b.intent != a.intent || b.form == a.form || !b.typedOK() {
			continue
		}
		if needFuller && b.bare {
			continue
		}
		if compatible(a.intent, a.tool, b.tool) {
			return b, true
		}
	}
	return observation{}, false
}

// envRepairOf finds a later run of the same tool that set v and worked, and
// returns the value to remember.
func envRepairOf(obs []observation, i int, v string) (string, bool) {
	a := obs[i]
	for _, b := range obs[i+1:] {
		if b.call <= a.call || b.intent != a.intent || b.tool != a.tool || b.outcome != worked {
			continue
		}
		if s, ok := b.env[v]; ok {
			if s.literal && safeEnvValue(v, s.value) {
				return s.value, true
			}
			return "", true
		}
	}
	return "", false
}

var (
	secretNameRE   = regexp.MustCompile(`(?i)KEY|TOKEN|SECRET|PASS|PWD|CRED|AUTH|COOKIE|PRIVATE|SESSION|DSN|SIGNATURE`)
	safeEnvValueRE = regexp.MustCompile(`^[A-Za-z0-9_./:+-]{1,64}$`)
	opaqueEnvValRE = regexp.MustCompile(`^[A-Za-z0-9_+-]{24,}$`)
)

// safeEnvValue says whether a variable's value may be stored and put in a
// prompt. Anything that might be a secret is remembered by name only.
func safeEnvValue(name, value string) bool {
	return !secretNameRE.MatchString(name) && safeEnvValueRE.MatchString(value) && !opaqueEnvValRE.MatchString(value)
}

func fetchedHosts(obs []observation) []string {
	var out []string
	for _, o := range obs {
		if o.intent == intentFetch && len(o.hosts) == 1 && !slices.Contains(out, o.hosts[0]) {
			out = append(out, o.hosts[0])
		}
	}
	return out
}

func boundaryError(obs []observation, host string) string {
	for _, o := range obs {
		if o.intent == intentFetch && slices.Contains(o.hosts, host) && o.outcome == failed {
			return o.class
		}
	}
	return ""
}

// evaluate is what a session's observations say about a fact: nil when the
// session didn't exercise it.
func evaluate(family string, d detail, obs []observation, injected bool) *verdict {
	switch family {
	case familyForm:
		return evaluateForm(d, obs, injected)
	case familyBoundary:
		return evaluateBoundary(d, obs)
	case familyEnv:
		return evaluateEnv(d, obs, injected)
	}
	return nil
}

func evaluateForm(d detail, obs []observation, injected bool) *verdict {
	var (
		exercised, badFailed, goodWorked, repaired bool
		last                                       *observation
		v                                          verdict
	)
	for i := range obs {
		o := &obs[i]
		if o.intent != d.Intent {
			continue
		}
		isBad, isGood := o.form == d.Bad, o.form == d.Good
		if isBad || isGood || o.tool == d.Tool || o.tool == d.GoodTool {
			exercised = true
		}
		if isBad && o.outcome != unknown {
			last = o
		}
		if isBad && o.outcome == failed && isFormError(o.class) {
			badFailed = true
			v.turns = append(v.turns, o.turn)
			for _, b := range obs[i+1:] {
				if b.turn == o.turn && b.call > o.call && b.form == d.Good && b.typedOK() {
					repaired = true
				}
			}
		}
		if isGood && o.typedOK() {
			goodWorked = true
		}
	}
	if !exercised {
		return nil
	}
	v.confirmed = repaired && last != nil && last.outcome == failed
	v.contradicted = last != nil && last.typedOK()
	v.fired = badFailed || (injected && goodWorked)
	if v.contradicted {
		v.turns = append(v.turns, last.turn)
	}
	if len(v.turns) == 0 {
		v.turns = turnsWhere(obs, func(o observation) bool {
			return o.intent == d.Intent && (o.form == d.Good || o.tool == d.Tool || o.tool == d.GoodTool)
		})
	}
	return &v
}

func evaluateBoundary(d detail, obs []observation) *verdict {
	var v verdict
	attempts := 0
	anyWorked := false
	for _, o := range obs {
		if o.intent != intentFetch || !slices.Contains(o.hosts, d.Host) || o.outcome == unknown {
			continue
		}
		attempts++
		v.turns = append(v.turns, o.turn)
		if o.outcome == worked {
			anyWorked = true
		}
	}
	if attempts == 0 {
		return nil
	}
	v.contradicted = anyWorked
	v.confirmed = !anyWorked
	v.fired = !anyWorked
	return &v
}

func evaluateEnv(d detail, obs []observation, injected bool) *verdict {
	var (
		exercised, varFailed, setWorked, repaired bool
		last                                      *observation
		v                                         verdict
	)
	for i := range obs {
		o := &obs[i]
		if o.intent != d.Intent || o.tool != d.Tool {
			continue
		}
		exercised = true
		if o.outcome != unknown {
			last = o
		}
		_, set := o.env[d.Var]
		if o.outcome == failed && slices.Contains(o.missing, d.Var) {
			varFailed = true
			v.turns = append(v.turns, o.turn)
			for _, b := range obs[i+1:] {
				if _, ok := b.env[d.Var]; ok && b.call > o.call && b.intent == d.Intent && b.tool == d.Tool && b.outcome == worked {
					repaired = true
				}
			}
		}
		if set && o.outcome == worked {
			setWorked = true
		}
	}
	if !exercised {
		return nil
	}
	lastUnsetWorked := false
	if last != nil && last.outcome == worked {
		_, set := last.env[d.Var]
		lastUnsetWorked = !set
	}
	v.contradicted = lastUnsetWorked
	v.confirmed = repaired && !lastUnsetWorked
	v.fired = varFailed || (injected && setWorked)
	if len(v.turns) == 0 {
		v.turns = turnsWhere(obs, func(o observation) bool { return o.intent == d.Intent && o.tool == d.Tool })
	}
	return &v
}

func turnsWhere(obs []observation, keep func(observation) bool) []int {
	var out []int
	for _, o := range obs {
		if keep(o) {
			out = append(out, o.turn)
		}
	}
	return out
}

func turnsText(turns []int) string {
	slices.Sort(turns)
	turns = slices.Compact(turns)
	parts := make([]string, len(turns))
	for i, t := range turns {
		parts[i] = strconv.Itoa(t)
	}
	return strings.Join(parts, ",")
}

var (
	errorPhrases = map[string]string{
		errModule:     "a missing module error",
		errCommand:    "command not found",
		errPermission: "permission denied",
	}
	boundaryPhrases = map[string]string{
		errRefused: "connections are refused here",
		errResolve: "the host name doesn't resolve here",
		errUnreach: "the network can't reach it from here",
		errBlocked: "the network blocks it here",
	}
	cues = map[string]string{
		intentTests:       "When running the tests",
		intentBuild:       "When building or checking the code",
		intentPackage:     "When using the package tool",
		intentInterpreter: "When running code",
	}
	// adviceRE keeps completion and verification advice out of the prompt,
	// whatever a template or a future family says. Code spans don't count:
	// `make verify` is a command, not advice.
	adviceRE = regexp.MustCompile(`(?i)\b(skip|no need|don'?t|do not|stop|done|complete[ds]?|finish(?:ed)?|verify|verification)\b`)
	codeRE   = regexp.MustCompile("`[^`]*`")
)

// text is the fact as a cue and a lesson, the way flit writes lessons.
func text(family string, d detail) string {
	switch family {
	case familyForm:
		return fmt.Sprintf("**%s:** use `%s`; `%s` fails here with %s.", cues[d.Intent], d.Good, d.Bad, errorPhrases[d.Error])
	case familyBoundary:
		phrase, ok := boundaryPhrases[d.Error]
		if !ok {
			phrase = "connections fail here"
		}
		return fmt.Sprintf("**When fetching from `%s`:** %s, so nothing can be fetched from it.", d.Host, phrase)
	case familyEnv:
		if d.Value != "" {
			return fmt.Sprintf("**%s:** set `%s=%s`; `%s` fails here without it.", cues[d.Intent], d.Var, d.Value, d.Bad)
		}
		return fmt.Sprintf("**%s:** `%s` must be set; `%s` fails here without it.", cues[d.Intent], d.Var, d.Bad)
	}
	return ""
}

// lintOK says text may go in a prompt.
func lintOK(s string) bool {
	return s != "" && !adviceRE.MatchString(codeRE.ReplaceAllString(s, ""))
}
