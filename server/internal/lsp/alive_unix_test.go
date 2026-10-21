//go:build !windows

package lsp

import (
	"os"
	"strconv"
	"strings"
	"syscall"
)

// alive reports whether the process is running (zombies count as gone).
func alive(pid string) bool {
	n, err := strconv.Atoi(pid)
	if err != nil {
		return false
	}
	if b, err := os.ReadFile("/proc/" + pid + "/stat"); err == nil {
		// state follows the parenthesized command name.
		s := string(b)
		if i := strings.LastIndexByte(s, ')'); i >= 0 && len(s) > i+2 {
			return s[i+2] != 'Z'
		}
	}
	return syscall.Kill(n, 0) == nil
}
