package llm

import (
	"encoding/json"
	"strings"
)

// InvalidArgumentsKey is the key under which SafeArguments keeps tool call
// arguments that could not be repaired into valid JSON.
const InvalidArgumentsKey = "invalid_json_arguments"

// RepairArguments returns args with raw control characters (U+0000 to
// U+001F) inside JSON strings escaped, which JSON forbids but models often
// emit (a literal tab or newline in file contents, say). Nothing else is
// changed. ok reports whether the result is valid JSON.
func RepairArguments(args string) (repaired string, ok bool) {
	if json.Valid([]byte(args)) {
		return args, true
	}
	var b strings.Builder
	b.Grow(len(args) + 8)
	inString, escaped := false, false
	for i := 0; i < len(args); i++ {
		c := args[i]
		switch {
		case !inString:
			if c == '"' {
				inString = true
			}
		case escaped:
			escaped = false
		case c == '\\':
			escaped = true
		case c == '"':
			inString = false
		case c < 0x20:
			b.WriteString(escapeControl(c))
			continue
		}
		b.WriteByte(c)
	}
	repaired = b.String()
	return repaired, json.Valid([]byte(repaired))
}

func escapeControl(c byte) string {
	switch c {
	case '\t':
		return `\t`
	case '\n':
		return `\n`
	case '\r':
		return `\r`
	case '\b':
		return `\b`
	case '\f':
		return `\f`
	}
	const hex = "0123456789abcdef"
	return `\u00` + string([]byte{hex[c>>4], hex[c&0xf]})
}

// SafeArguments returns tool call arguments that are always valid JSON, for
// sending back to the model in the conversation history. Endpoints such as
// llama.cpp parse the arguments of earlier calls when applying the chat
// template and reject the whole request when they aren't JSON. Empty
// arguments become {}; arguments RepairArguments can fix are repaired; the
// rest are kept, as a string, in an object under InvalidArgumentsKey (the
// tool result of such a call already told the model they were not valid
// JSON).
func SafeArguments(args string) string {
	if strings.TrimSpace(args) == "" {
		return "{}"
	}
	if r, ok := RepairArguments(args); ok {
		return r
	}
	b, _ := json.Marshal(map[string]string{InvalidArgumentsKey: args})
	return string(b)
}
