//go:build !windows

package lsp

import (
	"os/exec"
	"syscall"
)

// setGroup starts cmd in its own process group, so stopping it also stops
// whatever it started (tsserver, cargo check, ...).
func setGroup(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
}

// killGroup kills cmd's process group.
func killGroup(cmd *exec.Cmd) {
	if cmd.Process != nil {
		_ = syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
	}
}
