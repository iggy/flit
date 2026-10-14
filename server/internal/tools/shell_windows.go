//go:build windows

package tools

import (
	"context"
	"os/exec"
)

// shellCommand runs command with cmd.exe. Cancelling kills cmd.exe; child
// processes it started may outlive it (no job object yet).
func shellCommand(ctx context.Context, command string) *exec.Cmd {
	return exec.CommandContext(ctx, "cmd", "/C", command)
}
