//go:build windows

package lsp

import (
	"os/exec"
	"strings"
)

func alive(pid string) bool {
	out, err := exec.Command("tasklist", "/FI", "PID eq "+pid, "/NH").Output()
	return err == nil && strings.Contains(string(out), " "+pid+" ")
}
