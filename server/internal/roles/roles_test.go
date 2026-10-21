package roles

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	r, err := Parse([]byte("---\r\ndescription: Reviewer\r\nmodel: big\r\neffort: high\r\nmemory_file: NOTES.md\r\ntasks:\r\n  planning: {provider: p, model: huge}\r\n---\r\nBe careful.\r\n\r\nCheck tests.\r\n"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Description != "Reviewer" || r.Model != "big" || r.Effort != "high" || r.Tasks["planning"].Model != "huge" {
		t.Fatalf("role = %+v", r)
	}
	if r.Prompt != "Be careful.\n\nCheck tests." {
		t.Fatalf("prompt = %q", r.Prompt)
	}
	if got := r.MemoryPath("/w"); got != filepath.Join("/w", "NOTES.md") {
		t.Fatalf("memory path = %s", got)
	}

	plain, err := Parse([]byte("Just a prompt."))
	if err != nil || plain.Prompt != "Just a prompt." {
		t.Fatalf("plain = %+v, %v", plain, err)
	}
	for name, in := range map[string]string{
		"unterminated": "---\nmodel: x\nno end",
		"unknown key":  "---\nmodle: x\n---\nhi",
		"unknown task": "---\ntasks:\n  dreaming: {model: x}\n---\nhi",
	} {
		if _, err := Parse([]byte(in)); err == nil {
			t.Errorf("%s: accepted", name)
		}
	}
}

func TestListAndGet(t *testing.T) {
	dir := t.TempDir()
	os.WriteFile(filepath.Join(dir, "coder.md"), []byte("---\ndescription: Writes code\n---\nWrite code."), 0o600)
	os.WriteFile(filepath.Join(dir, "named.md"), []byte("---\nname: architect\n---\nPlan."), 0o600)
	os.WriteFile(filepath.Join(dir, "broken.md"), []byte("---\nbogus: 1\n---\n"), 0o600)
	os.WriteFile(filepath.Join(dir, "notes.txt"), []byte("ignored"), 0o600)

	list, err := listDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	slices.SortFunc(list, func(a, b Role) int { return strings.Compare(a.Name, b.Name) })
	if len(list) != 3 || list[0].Name != "architect" || list[1].Name != "broken" || list[1].Err == nil || list[2].Name != "coder" {
		t.Fatalf("list = %+v", list)
	}
	if r, err := Get(dir, "coder"); err != nil || r.Prompt != "Write code." {
		t.Fatalf("Get coder = %+v, %v", r, err)
	}
	if _, err := Get(dir, "broken"); err == nil {
		t.Fatal("broken role usable")
	}
	if _, err := Get(dir, "missing"); err == nil {
		t.Fatal("missing role found")
	}
	if list, err := List(filepath.Join(dir, "nope")); err != nil || len(list) != len(Builtin()) {
		t.Fatalf("missing dir = %v, %v", list, err)
	}
}

func TestBuiltin(t *testing.T) {
	var names []string
	for _, r := range Builtin() {
		if !r.Builtin || r.Path != "" || r.Prompt == "" || r.Description == "" || r.Model != "" || r.Provider != "" {
			t.Fatalf("built-in %+v", r)
		}
		names = append(names, r.Name)
	}
	if got := strings.Join(names, ","); got != "backend-dev,frontend-dev,pm,qa" {
		t.Fatalf("built-in roles = %s", got)
	}
}

// A role file with a built-in's name replaces it.
func TestBuiltinOverride(t *testing.T) {
	dir := t.TempDir()
	os.WriteFile(filepath.Join(dir, "qa.md"), []byte("---\ndescription: Mine\n---\nMy QA."), 0o600)
	os.WriteFile(filepath.Join(dir, "coder.md"), []byte("Write code."), 0o600)
	list, err := List(dir)
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, r := range list {
		names = append(names, fmt.Sprintf("%s:%v", r.Name, r.Builtin))
	}
	if got := strings.Join(names, ","); got != "backend-dev:true,coder:false,frontend-dev:true,pm:true,qa:false" {
		t.Fatalf("list = %s", got)
	}
	if r, err := Get(dir, "qa"); err != nil || r.Prompt != "My QA." || r.Builtin {
		t.Fatalf("Get qa = %+v, %v", r, err)
	}
	if r, err := Get(dir, "pm"); err != nil || !r.Builtin || !strings.Contains(r.Prompt, "product manager") {
		t.Fatalf("Get pm = %+v, %v", r, err)
	}
}
