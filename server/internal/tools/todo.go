package tools

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

// TodoItem is one entry in the agent's task list.
type TodoItem struct {
	Content string `json:"content"`
	// Status is pending, in_progress or completed.
	Status string `json:"status"`
}

// maxTodos caps the list so a runaway model can't flood the log.
const maxTodos = 100

var todoTool = Tool{
	Name: "todo",
	Description: "Keep a task list for multi-step work so the user can follow along. Send the whole list every time " +
		"(it replaces the previous one). Mark one item in_progress while you work on it and completed when done.",
	Schema: `{"type":"object","properties":{
"items":{"type":"array","items":{"type":"object","properties":{
  "content":{"type":"string","description":"What to do, as a short imperative"},
  "status":{"type":"string","enum":["pending","in_progress","completed"]}
 },"required":["content","status"]}}
},"required":["items"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		var a struct {
			Items []TodoItem `json:"items"`
		}
		if err := decode(raw, &a); err != nil {
			return errorf("%v", err)
		}
		if len(a.Items) > maxTodos {
			return errorf("too many items (%d); keep the list under %d", len(a.Items), maxTodos)
		}
		counts := map[string]int{}
		for i, it := range a.Items {
			a.Items[i].Content = strings.TrimSpace(it.Content)
			if a.Items[i].Content == "" {
				return errorf("item %d has no content", i+1)
			}
			switch it.Status {
			case "pending", "in_progress", "completed":
				counts[it.Status]++
			default:
				return errorf("item %d: status %q must be pending, in_progress or completed", i+1, it.Status)
			}
		}
		if env.Todo != nil {
			env.Todo(a.Items)
		}
		return Result{Text: fmt.Sprintf("task list updated: %d pending, %d in progress, %d completed",
			counts["pending"], counts["in_progress"], counts["completed"])}
	},
}
