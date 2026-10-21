package tools

import (
	"context"
	"encoding/json"
)

// AgentToolName is the agent tool's name.
const AgentToolName = "agent"

// AgentTool hands a task to a subagent (see Env.Subagent).
func AgentTool() Tool { return agentTool }

var agentTool = Tool{
	Name: AgentToolName,
	Description: "Hand a self-contained task to a subagent that starts with an empty context; you get back only its final report. " +
		"kind explore: read-only (read, grep, list, git, web, read-only shell), never asks the user; use it to search or study code " +
		"without filling your own context. kind build: may change files and run commands, under the same approval rules as you. " +
		"The subagent sees nothing of this conversation, so say everything it needs in task.",
	Schema: `{"type":"object","properties":{
"kind":{"type":"string","enum":["explore","build"]},
"task":{"type":"string","description":"What to do or find out, and what to report back"},
"context":{"type":"string","description":"Background it needs: what you know, constraints, conventions"},
"files":{"type":"array","items":{"type":"string"},"description":"Paths worth starting from"}
},"required":["kind","task"]}`,
	Run: func(ctx context.Context, env *Env, raw json.RawMessage) Result {
		if env.Subagent == nil {
			return errorf("subagents can't start subagents; do the work yourself")
		}
		return env.Subagent(ctx, raw)
	},
}

// AgentArgs are the agent tool's arguments.
type AgentArgs struct {
	Kind    string   `json:"kind"`
	Task    string   `json:"task"`
	Context string   `json:"context"`
	Files   []string `json:"files"`
}

// DecodeAgentArgs reads the agent tool's arguments strictly.
func DecodeAgentArgs(raw json.RawMessage) (AgentArgs, error) {
	var a AgentArgs
	err := decode(raw, &a)
	return a, err
}
