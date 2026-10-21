package learn

import (
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"go.yaml.in/yaml/v3"
)

// raw is one proposal as the model wrote it, before it is checked.
type raw struct {
	Action, Target, Entry, Cue, Lesson, Evidence string
	Skill, Description, Body                     string
}

var (
	thinkBlock    = regexp.MustCompile(`(?s)<think>.*?</think>`)
	fenced        = regexp.MustCompile("(?s)```[a-zA-Z]*\\s*\n(.*?)```")
	trailingComma = regexp.MustCompile(`,(\s*[}\]])`)
	nothingWords  = regexp.MustCompile(`(?i)\b(nothing|no (new )?(lessons?|proposals?))\b`)
)

// errUnreadable is returned when the answer holds no proposals in any form
// the parser understands.
var errUnreadable = errors.New("no JSON or YAML object with proposals found")

// parse reads the learning model's answer. Small models wrap JSON in prose
// or code fences, leave trailing commas, write YAML instead, or return a
// bare list or a single object; all of that is accepted.
func parse(text string) ([]raw, error) {
	text = thinkBlock.ReplaceAllString(text, "")
	if _, after, ok := strings.Cut(text, "</think>"); ok {
		text = after
	}
	text = strings.TrimSpace(text)
	candidates := []string{}
	for _, m := range fenced.FindAllStringSubmatch(text, -1) {
		candidates = append(candidates, m[1])
	}
	candidates = append(candidates, text)

	for _, c := range candidates {
		if v, ok := decode(c); ok {
			list, err := proposalList(v)
			if err == nil {
				return list, nil
			}
		}
	}
	if !strings.ContainsAny(text, "{[") && nothingWords.MatchString(text) {
		return nil, nil
	}
	return nil, errUnreadable
}

// decode tries the text as JSON (the outermost object or list in it, as
// is and without trailing commas), then as YAML.
func decode(s string) (any, bool) {
	s = strings.NewReplacer("“", `"`, "”", `"`).Replace(s)
	if js := outermost(s); js != "" {
		for _, try := range []string{js, trailingComma.ReplaceAllString(js, "$1")} {
			var v any
			if json.Unmarshal([]byte(try), &v) == nil {
				return v, true
			}
		}
	}
	var v any
	if yaml.Unmarshal([]byte(s), &v) == nil {
		switch v.(type) {
		case map[string]any, []any:
			return v, true
		}
	}
	return nil, false
}

// outermost returns s from its first { or [ to the last matching closer.
func outermost(s string) string {
	start := strings.IndexAny(s, "{[")
	if start < 0 {
		return ""
	}
	closer := "}"
	if s[start] == '[' {
		closer = "]"
	}
	end := strings.LastIndex(s, closer)
	if end < start {
		return ""
	}
	return s[start : end+1]
}

// proposalList finds the proposals in a decoded answer: {"proposals":
// [...]} (or another single list-valued key), a bare list, or one
// proposal object.
func proposalList(v any) ([]raw, error) {
	var items []any
	switch t := v.(type) {
	case []any:
		items = t
	case map[string]any:
		found := false
		for _, k := range []string{"proposals", "lessons", "items", "changes", "memories"} {
			if l, ok := lookup(t, k); ok {
				items, found = asList(l), true
				break
			}
		}
		if !found {
			if _, ok := lookup(t, "action"); ok {
				items = []any{t}
			} else if _, ok := lookup(t, "lesson"); ok {
				items = []any{t}
			} else if len(t) == 1 {
				for _, l := range t {
					if list, ok := l.([]any); ok {
						items, found = list, true
					}
				}
				if !found {
					return nil, errUnreadable
				}
			} else {
				return nil, errUnreadable
			}
		}
	default:
		return nil, errUnreadable
	}
	out := make([]raw, 0, len(items))
	for _, it := range items {
		m, ok := it.(map[string]any)
		if !ok {
			continue
		}
		out = append(out, raw{
			Action:      field(m, "action", "op"),
			Target:      field(m, "target", "layer", "where", "scope", "type"),
			Entry:       field(m, "entry", "id", "entry_id", "ref"),
			Cue:         field(m, "cue", "when", "trigger", "situation"),
			Lesson:      field(m, "lesson", "text", "content", "rule"),
			Evidence:    field(m, "evidence", "turns", "source"),
			Skill:       field(m, "skill", "name", "skill_name"),
			Description: field(m, "description", "desc"),
			Body:        field(m, "body", "instructions", "skill_md"),
		})
	}
	return out, nil
}

func asList(v any) []any {
	switch t := v.(type) {
	case []any:
		return t
	case map[string]any:
		return []any{t}
	}
	return nil
}

// lookup finds key in m ignoring case.
func lookup(m map[string]any, key string) (any, bool) {
	if v, ok := m[key]; ok {
		return v, true
	}
	for k, v := range m {
		if strings.EqualFold(strings.TrimSpace(k), key) {
			return v, true
		}
	}
	return nil, false
}

// field returns the first of keys present in m, as text.
func field(m map[string]any, keys ...string) string {
	for _, k := range keys {
		if v, ok := lookup(m, k); ok && v != nil {
			return strings.TrimSpace(text(v))
		}
	}
	return ""
}

func text(v any) string {
	switch t := v.(type) {
	case string:
		return t
	case []any:
		parts := make([]string, 0, len(t))
		for _, p := range t {
			parts = append(parts, text(p))
		}
		return strings.Join(parts, ", ")
	case float64:
		if t == float64(int64(t)) {
			return fmt.Sprintf("%d", int64(t))
		}
	}
	return fmt.Sprint(v)
}
