package skills

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func write(t *testing.T, path, content string) {
	t.Helper()
	os.MkdirAll(filepath.Dir(path), 0o755)
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestLoad(t *testing.T) {
	a, b := t.TempDir(), t.TempDir()
	write(t, filepath.Join(a, "pdf-tools", "SKILL.md"), "---\nname: pdf-tools\ndescription: Work with PDFs.\nlicense: MIT\nmetadata:\n  author: x\n---\n# PDF\nUse scripts/extract.py.\n")
	write(t, filepath.Join(a, "pdf-tools", "scripts", "extract.py"), "print(1)")
	write(t, filepath.Join(a, "Bad-Name", "SKILL.md"), "---\nname: Bad-Name\ndescription: x\n---\n")
	write(t, filepath.Join(a, "mismatch", "SKILL.md"), "---\nname: other\ndescription: x\n---\n")
	write(t, filepath.Join(a, "nodesc", "SKILL.md"), "---\nname: nodesc\n---\n")
	write(t, filepath.Join(a, "not-a-skill", "README.md"), "hi")
	write(t, filepath.Join(b, "pdf-tools", "SKILL.md"), "---\nname: pdf-tools\ndescription: Shadowed.\n---\n")
	write(t, filepath.Join(b, "git-flow", "SKILL.md"), "---\nname: git-flow\ndescription: |\n  Branch and\n  commit rules.\n---\nBody")

	list, problems := Load([]Dir{{Path: a, Source: "a"}, {Path: b, Source: "b"}, {Path: filepath.Join(a, "missing")}})
	if len(list) != 2 || list[0].Name != "git-flow" || list[1].Name != "pdf-tools" {
		t.Fatalf("list = %+v", list)
	}
	if len(problems) != 3 {
		t.Fatalf("problems = %v", problems)
	}
	pdf := list[1]
	if pdf.Source != "a" || list[0].Source != "b" {
		t.Fatalf("sources = %q, %q", pdf.Source, list[0].Source)
	}
	if pdf.Description != "Work with PDFs." || pdf.Body != "# PDF\nUse scripts/extract.py." || pdf.License != "MIT" {
		t.Fatalf("pdf = %+v", pdf)
	}
	if files := pdf.Files(10); len(files) != 1 || files[0] != "scripts/extract.py" {
		t.Fatalf("files = %v", files)
	}
	p := PromptSection(list)
	if !strings.Contains(p, "- git-flow: Branch and commit rules.") || !strings.Contains(p, "- pdf-tools: Work with PDFs.") {
		t.Fatalf("prompt = %s", p)
	}
	if PromptSection(nil) != "" {
		t.Fatal("empty list has a prompt section")
	}
}

func TestSessionDirs(t *testing.T) {
	root := t.TempDir()
	os.Mkdir(filepath.Join(root, ".git"), 0o755)
	sub := filepath.Join(root, "services", "api")
	os.MkdirAll(sub, 0o755)
	global := t.TempDir()

	write(t, filepath.Join(root, ".agents", "skills", "deploy", "SKILL.md"), "---\nname: deploy\ndescription: Repo deploy.\n---\nrepo")
	write(t, filepath.Join(root, ".claude", "skills", "review", "SKILL.md"), "---\nname: review\ndescription: Claude-style review.\n---\n")
	write(t, filepath.Join(sub, ".agents", "skills", "api-tests", "SKILL.md"), "---\nname: api-tests\ndescription: API tests.\n---\n")
	write(t, filepath.Join(global, "deploy", "SKILL.md"), "---\nname: deploy\ndescription: Global deploy.\n---\nglobal")
	write(t, filepath.Join(global, "notes", "SKILL.md"), "---\nname: notes\ndescription: Global notes.\n---\n")

	list, problems := Load(SessionDirs(sub, []string{global}))
	if len(problems) > 0 {
		t.Fatal(problems)
	}
	got := map[string]string{}
	for _, s := range list {
		got[s.Name] = s.Source + "|" + s.Body
	}
	want := map[string]string{
		"api-tests": "repo .agents/skills|",
		"deploy":    "repo root .agents/skills|repo",
		"review":    "repo root .claude/skills|",
		"notes":     "global|",
	}
	for k, v := range want {
		if got[k] != v {
			t.Errorf("%s = %q, want %q", k, got[k], v)
		}
	}
	if len(got) != 4 {
		t.Errorf("skills = %v", got)
	}
	// Outside a repo only the working dir and global count.
	if dirs := SessionDirs(global, nil); len(dirs) != 2 {
		t.Errorf("non-repo dirs = %+v", dirs)
	}
}

func TestBuiltin(t *testing.T) {
	list := Builtin()
	var init Skill
	for _, s := range list {
		if s.Source != BuiltinSource || s.Dir != "" || s.Files(10) != nil {
			t.Fatalf("built-in %+v", s)
		}
		if s.Name == "init" {
			init = s
		}
	}
	if init.Name == "" || !strings.Contains(init.Body, "AGENTS.md") || !strings.Contains(init.Body, "ask the user") {
		t.Fatalf("init = %+v", init)
	}
}

// A repo or global skill with a built-in's name replaces it.
func TestWithBuiltin(t *testing.T) {
	got := WithBuiltin([]Skill{{Name: "zeta"}, {Name: "init", Source: "repo .agents/skills"}})
	var names []string
	for _, s := range got {
		names = append(names, s.Name+"@"+s.Source)
	}
	if strings.Join(names, ",") != "init@repo .agents/skills,zeta@" {
		t.Fatalf("got %v", names)
	}
	if got := WithBuiltin(nil); len(got) == 0 || got[0].Source != BuiltinSource {
		t.Fatalf("WithBuiltin(nil) = %+v", got)
	}
}
