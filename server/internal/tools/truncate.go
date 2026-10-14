package tools

import (
	"fmt"
	"strings"
	"unicode/utf8"
)

// Truncate shortens s to at most maxLines lines and about maxBytes bytes by
// keeping its head and tail and replacing the middle with a note saying what
// was cut. Long output usually matters most at the start (what ran) and the
// end (how it finished). A limit of 0 means no limit.
func Truncate(s string, maxBytes, maxLines int) (out string, omittedBytes int64, truncated bool) {
	lineCount := strings.Count(s, "\n") + 1
	if (maxBytes <= 0 || len(s) <= maxBytes) && (maxLines <= 0 || lineCount <= maxLines) {
		return s, 0, false
	}

	headEnd, tailStart := len(s), 0
	if maxLines > 0 && lineCount > maxLines {
		headEnd = nthNewline(s, maxLines/2)
		tailStart = nthNewlineFromEnd(s, maxLines-maxLines/2)
	}
	if maxBytes > 0 {
		if headEnd > maxBytes/2 {
			headEnd = cutBack(s, maxBytes/2)
		}
		if len(s)-tailStart > maxBytes-maxBytes/2 {
			tailStart = cutForward(s, len(s)-(maxBytes-maxBytes/2))
		}
	}
	if headEnd >= tailStart {
		return s, 0, false
	}

	mid := s[headEnd:tailStart]
	omittedLines := strings.Count(mid, "\n")
	note := fmt.Sprintf("\n[... %d bytes, %d lines omitted ...]\n", len(mid), omittedLines)
	return s[:headEnd] + note + s[tailStart:], int64(len(mid)), true
}

// nthNewline returns the index just past the n-th newline (n >= 0), or 0
// for n == 0.
func nthNewline(s string, n int) int {
	i := 0
	for ; n > 0; n-- {
		j := strings.IndexByte(s[i:], '\n')
		if j < 0 {
			return len(s)
		}
		i += j + 1
	}
	return i
}

// nthNewlineFromEnd returns the start of the last n lines.
func nthNewlineFromEnd(s string, n int) int {
	i := len(s)
	if strings.HasSuffix(s, "\n") {
		i--
	}
	for ; n > 0; n-- {
		j := strings.LastIndexByte(s[:i], '\n')
		if j < 0 {
			return 0
		}
		i = j
	}
	return i + 1
}

// cutBack returns an index <= n that ends a line if one is reasonably close,
// and is a rune boundary.
func cutBack(s string, n int) int {
	if j := strings.LastIndexByte(s[:n], '\n'); j >= 0 && n-j < 200 {
		return j + 1
	}
	for n > 0 && !utf8.RuneStart(s[n]) {
		n--
	}
	return n
}

// cutForward returns an index >= n that starts a line if one is reasonably
// close, and is a rune boundary.
func cutForward(s string, n int) int {
	if j := strings.IndexByte(s[n:], '\n'); j >= 0 && j < 200 {
		return n + j + 1
	}
	for n < len(s) && !utf8.RuneStart(s[n]) {
		n++
	}
	return n
}
