package agent

import (
	"context"
	"fmt"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/notify"
	"github.com/iggy/flit/server/internal/store"
)

// noteLongTurn is called before model call number steps+1 of a turn (or,
// with subagentCallID, of a subagent). Each time steps reaches a multiple
// of every it records a LongTurn event and sends a notification. Nothing
// stops the turn: the person decides. The error is only for an event log
// that can't be written.
func (s *session) noteLongTurn(every, steps int, subagentCallID string) error {
	if every <= 0 || steps == 0 || steps%every != 0 {
		return nil
	}
	if _, err := s.append(&flitv1.Event{Payload: &flitv1.Event_LongTurn{LongTurn: &flitv1.LongTurn{
		Steps: int32(steps), SubagentToolCallId: subagentCallID,
	}}}); err != nil {
		return err
	}
	if send := s.m.Notify; send != nil {
		m := longTurnMessage(s.snapshot(), steps, subagentCallID != "")
		// The turn goes on; ntfy bounds its own post.
		go send(context.Background(), m)
	}
	return nil
}

// longTurnMessage is the notification for a LongTurn event.
func longTurnMessage(info store.Session, steps int, subagent bool) notify.Message {
	title := info.Title
	if title == "" {
		title = info.ID
	}
	who := "The turn"
	if subagent {
		who = "A subagent"
	}
	return notify.Message{
		Title: "Long turn: " + title,
		Body:  fmt.Sprintf("%s has made %d model calls. It may be working hard, or going round in circles.", who, steps),
		Tags:  []string{"hourglass_flowing_sand"},
	}
}
