package agent

import (
	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm"
)

// historyKinds are the event kinds needed to rebuild the conversation.
var historyKinds = []string{"message_started", "message_done", "tool_call_started", "tool_call_done", "compaction_done"}

// notRun is the tool result recorded for a call whose turn ended before it
// produced one, so the conversation stays valid for the next model call.
const notRun = "[not run: the turn was interrupted]"

// buildMessages rebuilds the chat history the model sees from a session's
// events. Deltas aren't needed: MessageDone repeats the full text.
func buildMessages(events []*flitv1.Event) []llm.Message {
	var msgs []llm.Message
	roles := map[string]flitv1.Role{}
	assistantAt := map[string]int{} // message id -> index in msgs
	var pending []string            // tool call ids without a result yet
	done := map[string]bool{}

	flush := func() {
		for _, id := range pending {
			if !done[id] {
				msgs = append(msgs, llm.Message{Role: "tool", ToolCallID: id, Content: notRun})
			}
		}
		pending = nil
	}

	for _, ev := range events {
		switch p := ev.Payload.(type) {
		case *flitv1.Event_MessageStarted:
			roles[p.MessageStarted.MessageId] = p.MessageStarted.Role
		case *flitv1.Event_MessageDone:
			d := p.MessageDone
			flush()
			switch roles[d.MessageId] {
			case flitv1.Role_ROLE_USER:
				msgs = append(msgs, llm.Message{Role: "user", Content: d.Text})
			case flitv1.Role_ROLE_ASSISTANT:
				assistantAt[d.MessageId] = len(msgs)
				msgs = append(msgs, llm.Message{Role: "assistant", Content: d.Text})
			}
		case *flitv1.Event_ToolCallStarted:
			c := p.ToolCallStarted
			i, ok := assistantAt[c.MessageId]
			if !ok {
				continue
			}
			msgs[i].ToolCalls = append(msgs[i].ToolCalls, llm.ToolCall{
				ID: c.ToolCallId, Type: "function",
				// The log keeps what the model sent; the model gets valid JSON.
				Function: llm.FunctionCall{Name: c.Name, Arguments: llm.SafeArguments(c.Arguments)},
			})
			pending = append(pending, c.ToolCallId)
		case *flitv1.Event_ToolCallDone:
			d := p.ToolCallDone
			done[d.ToolCallId] = true
			msgs = append(msgs, llm.Message{Role: "tool", ToolCallID: d.ToolCallId, Content: d.Result})
		}
	}
	flush()

	// Drop assistant messages that ended up empty (e.g. interrupted before
	// any output); endpoints reject or misread them.
	out := msgs[:0]
	for _, m := range msgs {
		if m.Role == "assistant" && m.Content == "" && len(m.ToolCalls) == 0 {
			continue
		}
		out = append(out, m)
	}
	return out
}

// lastCompaction is the newest compaction that took effect, or nil.
func lastCompaction(events []*flitv1.Event) *flitv1.CompactionDone {
	var c *flitv1.CompactionDone
	for _, ev := range events {
		if d := ev.GetCompactionDone(); d != nil && d.Error == "" {
			c = d
		}
	}
	return c
}

// contextEvents is the part of events the model sees after compaction c
// (nil: all of them): the events after c.CoveredSeq and, when the cut fell
// inside a turn, before them the user message that started that turn.
func contextEvents(events []*flitv1.Event, c *flitv1.CompactionDone) []*flitv1.Event {
	if c == nil {
		return events
	}
	i := 0
	for i < len(events) && events[i].Seq <= c.CoveredSeq {
		i++
	}
	older, kept := events[:i], events[i:]
	for _, ev := range kept {
		if ms := ev.GetMessageStarted(); ms != nil {
			if ms.Role == flitv1.Role_ROLE_USER {
				return kept
			}
			// Cut inside a turn: keep the request it's working on.
			userID := ""
			for _, ev := range older {
				if ms := ev.GetMessageStarted(); ms != nil && ms.Role == flitv1.Role_ROLE_USER {
					userID = ms.MessageId
				}
			}
			if userID == "" {
				return kept
			}
			var out []*flitv1.Event
			for _, ev := range older {
				if ev.GetMessageStarted().GetMessageId() == userID || ev.GetMessageDone().GetMessageId() == userID {
					out = append(out, ev)
				}
			}
			return append(out, kept...)
		}
	}
	return kept
}

// upTo is the events with seq <= seq.
func upTo(events []*flitv1.Event, seq int64) []*flitv1.Event {
	i := 0
	for i < len(events) && events[i].Seq <= seq {
		i++
	}
	return events[:i]
}
