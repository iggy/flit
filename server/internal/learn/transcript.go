package learn

import (
	"encoding/json"
	"fmt"
	"strings"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/store"
)

// turn is one user message and everything the agent did for it.
type turn struct {
	id    string // the user message's id
	lines []line
}

// line is one step of a turn; text is cut to the current level's limit
// for its kind when rendered.
type line struct {
	kind string // "user", "assistant", "tool", "note"
	head string // e.g. "tool shell" with its arguments
	text string
}

// turns groups the events of a session's path (in seq order) into turns,
// with its ratings attached as notes.
func turns(events []*flitv1.Event, ratings []store.Rating) []turn {
	var out []turn
	roles := map[string]flitv1.Role{}
	turnOf := map[string]int{} // message id -> index in out
	toolName := map[string]string{}
	add := func(l line) {
		if len(out) == 0 {
			out = append(out, turn{})
		}
		out[len(out)-1].lines = append(out[len(out)-1].lines, l)
	}
	for _, ev := range events {
		switch p := ev.Payload.(type) {
		case *flitv1.Event_MessageStarted:
			roles[p.MessageStarted.MessageId] = p.MessageStarted.Role
			if p.MessageStarted.Role == flitv1.Role_ROLE_USER {
				out = append(out, turn{id: p.MessageStarted.MessageId})
			}
			turnOf[p.MessageStarted.MessageId] = max(len(out)-1, 0)
		case *flitv1.Event_MessageDone:
			d := p.MessageDone
			switch roles[d.MessageId] {
			case flitv1.Role_ROLE_USER:
				add(line{kind: "user", text: d.Text})
			case flitv1.Role_ROLE_ASSISTANT:
				if strings.TrimSpace(d.Text) != "" {
					add(line{kind: "assistant", text: d.Text})
				}
				if d.FinishReason == "interrupted" {
					add(line{kind: "note", text: "(the user interrupted the agent here)"})
				}
			}
		case *flitv1.Event_ToolCallStarted:
			c := p.ToolCallStarted
			toolName[c.ToolCallId] = c.Name
			add(line{kind: "call", head: c.Name, text: compactJSON(c.Arguments)})
		case *flitv1.Event_ToolCallDone:
			d := p.ToolCallDone
			head := "result"
			if d.IsError {
				head = "error"
			}
			add(line{kind: "tool", head: head, text: d.Result})
		case *flitv1.Event_CompactionDone:
			// The full log is rendered; summaries would only repeat it.
		}
	}
	for _, r := range ratings {
		i, ok := -1, false
		for j, t := range out {
			if t.id != "" && t.id == r.TurnID {
				i, ok = j, true
			}
		}
		if !ok {
			if i, ok = turnOf[r.ModelCallID]; !ok {
				continue // on another branch
			}
		}
		verdict := "bad"
		if r.Good {
			verdict = "good"
		}
		text := "the user rated this turn " + verdict
		if r.Target == "model" {
			text = "the user rated the model " + verdict
		}
		if n := strings.TrimSpace(r.Note); n != "" {
			text += fmt.Sprintf(": %q", n)
		}
		out[i].lines = append(out[i].lines, line{kind: "rating", text: text})
	}
	return out
}

func compactJSON(s string) string {
	var v any
	if json.Unmarshal([]byte(s), &v) != nil {
		return strings.TrimSpace(s)
	}
	b, _ := json.Marshal(v)
	return string(b)
}

// limits are the most bytes of each kind of text a level keeps.
type limits struct{ user, assistant, call, tool int }

var levels = []limits{
	{4000, 3000, 400, 1500},
	{2000, 1500, 250, 600},
	{1000, 700, 150, 250},
	{500, 300, 100, 100},
}

// render writes the turns as a compact transcript of at most budget bytes:
// long texts are cut harder until it fits, then turns in the middle are
// left out (the first and the latest are kept).
func render(ts []turn, budget int) string {
	var parts []string
	for _, lim := range levels {
		parts = renderTurns(ts, lim)
		if total(parts) <= budget {
			return strings.Join(parts, "")
		}
	}
	// Keep the first turn, then as many of the latest as fit.
	if len(parts) == 0 {
		return ""
	}
	keep := []string{parts[0]}
	size := len(parts[0])
	var tail []string
	i := len(parts) - 1
	for ; i > 0; i-- {
		if size+len(parts[i])+80 > budget {
			break
		}
		size += len(parts[i])
		tail = append([]string{parts[i]}, tail...)
	}
	if i > 0 {
		keep = append(keep, fmt.Sprintf("[... T2 to T%d left out to fit ...]\n\n", i+1))
	}
	out := strings.Join(append(keep, tail...), "")
	if len(out) > budget {
		out = cut(out, budget)
	}
	return out
}

func total(parts []string) int {
	n := 0
	for _, p := range parts {
		n += len(p)
	}
	return n
}

func renderTurns(ts []turn, lim limits) []string {
	out := make([]string, 0, len(ts))
	for i, t := range ts {
		var b strings.Builder
		ref := fmt.Sprintf("T%d", i+1)
		for _, l := range t.lines {
			switch l.kind {
			case "user":
				fmt.Fprintf(&b, "%s user: %s\n", ref, cut(l.text, lim.user))
			case "assistant":
				fmt.Fprintf(&b, "%s agent: %s\n", ref, cut(l.text, lim.assistant))
			case "call":
				fmt.Fprintf(&b, "%s tool %s %s\n", ref, l.head, cut(l.text, lim.call))
			case "tool":
				fmt.Fprintf(&b, "%s %s: %s\n", ref, l.head, cut(l.text, lim.tool))
			default:
				fmt.Fprintf(&b, "%s %s\n", ref, l.text)
			}
		}
		b.WriteString("\n")
		out = append(out, b.String())
	}
	return out
}

// cut shortens s to about n bytes, keeping its head and tail.
func cut(s string, n int) string {
	s = strings.TrimSpace(s)
	if len(s) <= n {
		return s
	}
	marker := fmt.Sprintf(" [... %d bytes cut ...] ", len(s)-n)
	if n <= len(marker)+20 {
		return validUTF8(s[:n]) + "…"
	}
	head := (n - len(marker)) * 2 / 3
	tail := n - len(marker) - head
	return validUTF8(s[:head]) + marker + validUTF8(s[len(s)-tail:])
}

func validUTF8(s string) string { return strings.ToValidUTF8(s, "") }
