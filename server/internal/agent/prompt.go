package agent

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/roles"
)

// instructionFiles are read from the session's working directory, in this
// order, and added to the system prompt.
var instructionFiles = []string{"AGENTS.md", "CLAUDE.md"}

// maxInstructionBytes caps each instruction file.
const maxInstructionBytes = 64 << 10

const basePrompt = `You are flit, a coding agent. You help the user with software engineering tasks in their working directory by reading and changing files and running commands with your tools.

- Use the tools to look before you change anything; don't guess at file contents.
- Prefer patch for edits to existing files and write for new files. Paths are relative to the working directory.
- Keep changes focused on what was asked. Run the project's build or tests when it helps confirm a change.
- Shell commands may need the user's approval. If one is denied, don't retry it unchanged.
- When you're done, reply briefly with what you did.`

// systemPrompt builds the system prompt for a session working in dir with
// an optional role. The instruction files, role and memory file are re-read
// each time, so edits apply on the next model call.
func systemPrompt(dir string, role *roles.Role) string {
	var b strings.Builder
	b.WriteString(basePrompt)
	writeEnvironment(&b, dir)
	writeInstructions(&b, dir)

	if role != nil {
		if role.Prompt != "" {
			fmt.Fprintf(&b, "\nYour role for this session is %q:\n\n<role>\n%s\n</role>\n", role.Name, role.Prompt)
		}
		if path := role.MemoryPath(dir); path != "" {
			if data, err := os.ReadFile(path); err == nil && strings.TrimSpace(string(data)) != "" {
				memory := strings.TrimSpace(string(data))
				if len(memory) > maxInstructionBytes {
					memory = memory[:maxInstructionBytes] + "\n[... truncated ...]"
				}
				fmt.Fprintf(&b, "\nYour memory file (%s) says:\n\n<memory>\n%s\n</memory>\n", path, memory)
			}
		}
	}
	return b.String()
}

// writeEnvironment adds the working directory, OS and date.
func writeEnvironment(b *strings.Builder, dir string) {
	fmt.Fprintf(b, "\n\nEnvironment:\n- Working directory: %s\n- OS: %s/%s\n- Date: %s\n",
		dir, runtime.GOOS, runtime.GOARCH, time.Now().Format("2006-01-02"))
}

// writeInstructions adds the working directory's instruction files.
func writeInstructions(b *strings.Builder, dir string) {
	seen := map[string]string{} // content -> first file name
	for _, name := range instructionFiles {
		data, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			continue
		}
		content := strings.TrimSpace(string(data))
		if content == "" {
			continue
		}
		if first, dup := seen[content]; dup {
			fmt.Fprintf(b, "\n(%s has the same content as %s.)\n", name, first)
			continue
		}
		seen[content] = name
		if len(content) > maxInstructionBytes {
			content = content[:maxInstructionBytes] + "\n[... truncated ...]"
		}
		fmt.Fprintf(b, "\nProject instructions from %s (follow them):\n\n<%s>\n%s\n</%s>\n", name, name, content, name)
	}
}
