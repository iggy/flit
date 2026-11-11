package tools

import (
	"context"
	"encoding/json"
	"strings"
	"unicode/utf8"
)

// maxStatus caps the status line in characters; it has to fit on a card.
const maxStatus = 120

var statusTool = Tool{
	Name: "status",
	Description: "Set the one-line status shown for this session in the user's session list, so they can tell at a glance " +
		"what you are doing without opening it. Set it at milestones: when you start a distinct phase of the work, " +
		"when you are blocked or waiting on the user, and when you finish. Say what, not how: " +
		`"running the test suite", "blocked on: which database to use", "done: parser fixed, tests pass". ` +
		"It replaces the previous status.",
	Schema: `{"type":"object","properties":{
"text":{"type":"string","description":"The status, one short line (at most 120 characters). Empty clears it."}
},"required":["text"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Text string `json:"text"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		text := strings.Join(strings.Fields(a.Text), " ")
		if n := utf8.RuneCountInString(text); n > maxStatus {
			return errorf("status is %d characters; keep it to one line of at most %d", n, maxStatus)
		}
		if env.Status != nil {
			env.Status(text)
		}
		if text == "" {
			return Result{Text: "status cleared"}
		}
		return Result{Text: "status set"}
	},
}
