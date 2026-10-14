package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/iggy/flit/server/internal/skills"
)

// skillFileLimit caps how many files the skill tool lists.
const skillFileLimit = 200

// SkillTool loads skills on demand: a skill's SKILL.md instructions and file
// list, or one of its files.
func SkillTool(list []skills.Skill) Tool {
	byName := map[string]skills.Skill{}
	for _, s := range list {
		byName[s.Name] = s
	}
	return Tool{
		Name: "skill",
		Description: "Load a skill listed in the system prompt: returns its instructions and the files it comes with. " +
			"Pass file to read one of those files. Run a skill's scripts with shell using the absolute path shown.",
		Schema: `{"type":"object","properties":{
"name":{"type":"string","description":"Skill name"},
"file":{"type":"string","description":"A file inside the skill, e.g. references/REFERENCE.md"}
},"required":["name"]}`,
		Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
			var a struct {
				Name string `json:"name"`
				File string `json:"file"`
			}
			if err := decode(raw, &a); err != nil {
				return errorf("%v", err)
			}
			s, ok := byName[a.Name]
			if !ok {
				return errorf("no skill named %q", a.Name)
			}
			if a.File != "" {
				p, err := resolve(s.Dir, a.File)
				if err != nil {
					return errorf("%v", err)
				}
				b, err := os.ReadFile(p)
				if err != nil {
					return errorf("%v", err)
				}
				if isBinary(b) {
					return errorf("%s is a binary file; use it by path: %s", a.File, p)
				}
				return Result{Text: string(b)}
			}
			var b strings.Builder
			fmt.Fprintf(&b, "Skill %s (directory: %s)\n\n%s\n", s.Name, s.Dir, s.Body)
			if files := s.Files(skillFileLimit); len(files) > 0 {
				b.WriteString("\nFiles in this skill (read with file=..., run scripts by absolute path):\n")
				for _, f := range files {
					b.WriteString("- " + f + "\n")
				}
			}
			return Result{Text: b.String()}
		},
	}
}
