package agent

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/memory"
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
// an optional role and the user and project memory layers. The instruction
// files, role and memory files are re-read each time, so edits apply on the
// next model call.
func systemPrompt(dir string, role *roles.Role, layers []memory.Layer) string {
	var b strings.Builder
	b.WriteString(basePrompt)
	fmt.Fprintf(&b, "\n\nEnvironment:\n- Working directory: %s\n- OS: %s/%s\n- Date: %s\n",
		dir, runtime.GOOS, runtime.GOARCH, time.Now().Format("2006-01-02"))

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
			fmt.Fprintf(&b, "\n(%s has the same content as %s.)\n", name, first)
			continue
		}
		seen[content] = name
		if len(content) > maxInstructionBytes {
			content = content[:maxInstructionBytes] + "\n[... truncated ...]"
		}
		fmt.Fprintf(&b, "\nProject instructions from %s (follow them):\n\n<%s>\n%s\n</%s>\n", name, name, content, name)
	}

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
	for _, l := range layers {
		if l.Content == "" {
			continue
		}
		what := "the user, in every project"
		if l.Kind == memory.Project {
			what = "this project"
		}
		fmt.Fprintf(&b, "\nLessons from earlier sessions about %s (%s). Follow them when their situation applies:\n\n<%s-memory>\n%s\n</%s-memory>\n",
			what, l.Path, l.Kind, l.Content, l.Kind)
	}
	return b.String()
}

// memoryLayers reads the user memory and, for a session in a project, the
// project's, each cut to the configured budget. Unreadable files are
// logged and skipped.
func (m *Manager) memoryLayers(cfg config.Config, projectID string) []memory.Layer {
	if m.DataDir == "" {
		return nil
	}
	paths := []memory.Layer{{Kind: memory.User, Path: memory.UserPath(m.DataDir)}}
	if projectID != "" {
		paths = append(paths, memory.Layer{Kind: memory.Project, Path: memory.ProjectPath(m.DataDir, projectID)})
	}
	var out []memory.Layer
	for _, l := range paths {
		content, cut, err := memory.ReadCapped(l.Path, cfg.Learning.MemoryMaxBytes)
		if err != nil {
			m.log.Warn("could not read memory file", "path", l.Path, "err", err)
			continue
		}
		l.Content, l.Truncated = content, cut
		out = append(out, l)
	}
	return out
}
