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

	list, problems := Load([]string{a, b, filepath.Join(a, "missing")})
	if len(list) != 2 || list[0].Name != "git-flow" || list[1].Name != "pdf-tools" {
		t.Fatalf("list = %+v", list)
	}
	if len(problems) != 3 {
		t.Fatalf("problems = %v", problems)
	}
	pdf := list[1]
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
