//go:build windows

package lsp

import "os/exec"

func setGroup(cmd *exec.Cmd) {}

// killGroup kills the server. Processes it started may outlive it (no job
// object yet).
func killGroup(cmd *exec.Cmd) {
	if cmd.Process != nil {
		_ = cmd.Process.Kill()
	}
}
