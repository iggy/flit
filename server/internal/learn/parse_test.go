package learn

import (
	"testing"
)

func TestParse(t *testing.T) {
	cases := []struct {
		name string
		in   string
		want []raw // nil with wantErr false means no proposals
		err  bool
	}{
		{name: "plain", in: `{"proposals": [{"action": "add", "target": "project", "cue": "When testing", "lesson": "Run go test ./...", "evidence": "T2"}]}`,
			want: []raw{{Action: "add", Target: "project", Cue: "When testing", Lesson: "Run go test ./...", Evidence: "T2"}}},
		{name: "empty", in: `{"proposals": []}`},
		{name: "prose and fence", in: "Here you go:\n```json\n{\"proposals\": [{\"action\": \"add\", \"target\": \"user\", \"lesson\": \"Be brief\"}]}\n```\nHope that helps.",
			want: []raw{{Action: "add", Target: "user", Lesson: "Be brief"}}},
		{name: "think block and trailing comma", in: "<think>hmm {not json}</think>\n{\"proposals\": [{\"lesson\": \"x\", \"evidence\": [\"T1\", 3],},],}",
			want: []raw{{Lesson: "x", Evidence: "T1, 3"}}},
		{name: "bare list", in: `[{"action": "remove", "target": "user", "entry": "U2"}]`,
			want: []raw{{Action: "remove", Target: "user", Entry: "U2"}}},
		{name: "single object", in: `{"action": "add", "target": "skill", "name": "release", "description": "d", "body": "1. tag"}`,
			want: []raw{{Action: "add", Target: "skill", Skill: "release", Description: "d", Body: "1. tag"}}},
		{name: "yaml", in: "proposals:\n  - action: add\n    target: project\n    lesson: |\n      Use task build.\n    evidence: T4\n",
			want: []raw{{Action: "add", Target: "project", Lesson: "Use task build.", Evidence: "T4"}}},
		{name: "other key and case", in: `{"Lessons": [{"Lesson": "y", "When": "always"}]}`,
			want: []raw{{Lesson: "y", Cue: "always"}}},
		{name: "says nothing", in: "Nothing worth keeping from this session."},
		{name: "garbage", in: "I think the agent did well.", err: true},
		{name: "unrelated json", in: `{"verdict": "safe", "reason": "x"}`, err: true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, err := parse(c.in)
			if (err != nil) != c.err {
				t.Fatalf("err = %v", err)
			}
			if len(got) != len(c.want) {
				t.Fatalf("got %+v, want %+v", got, c.want)
			}
			for i := range got {
				if got[i] != c.want[i] {
					t.Errorf("proposal %d = %+v, want %+v", i, got[i], c.want[i])
				}
			}
		})
	}
}
