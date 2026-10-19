package agent

import (
	"context"

	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
)

// queuedMessage is a user message sent while a turn ran. The turn delivers
// it at its next step: after the current model call or tool, before the
// next model call. If the turn ends without another call, the queue starts
// the next turn; an interrupted turn leaves it for the next Send.
type queuedMessage struct {
	id, text, client string
}

// loadQueue rebuilds the queue from the log.
func (s *session) loadQueue(ctx context.Context) error {
	evs, err := s.m.store.EventsOfKinds(ctx, s.info.ID, "message_queued", "queued_message_updated", "queued_message_delivered")
	if err != nil {
		return err
	}
	for _, ev := range evs {
		switch {
		case ev.GetMessageQueued() != nil:
			q := ev.GetMessageQueued()
			s.queue = append(s.queue, queuedMessage{id: q.QueueId, text: q.Text, client: q.Client})
		case ev.GetQueuedMessageUpdated() != nil:
			u := ev.GetQueuedMessageUpdated()
			s.editQueue(u.QueueId, u.Text, u.Cancelled)
		case ev.GetQueuedMessageDelivered() != nil:
			s.editQueue(ev.GetQueuedMessageDelivered().QueueId, "", true)
		}
	}
	return nil
}

// editQueue changes or removes a queued message; it reports whether it was
// there.
func (s *session) editQueue(id, text string, remove bool) bool {
	for i, q := range s.queue {
		if q.id != id {
			continue
		}
		if remove {
			s.queue = append(s.queue[:i:i], s.queue[i+1:]...)
		} else {
			s.queue[i].text = text
		}
		return true
	}
	return false
}

func (s *session) updateQueued(id, text string, cancel bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	found := false
	for _, q := range s.queue {
		found = found || q.id == id
	}
	if !found {
		return ErrQueueGone
	}
	if _, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_QueuedMessageUpdated{QueuedMessageUpdated: &flitv1.QueuedMessageUpdated{
		QueueId: id, Text: text, Cancelled: cancel,
	}}}); err != nil {
		return err
	}
	s.editQueue(id, text, cancel)
	return nil
}

// deliverQueued delivers the queue at a step boundary of the running turn.
func (s *session) deliverQueued() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, _, err := s.deliverQueuedLocked()
	return err
}

// deliverQueuedLocked turns every queued message into a user message, in
// order. It returns the first event's seq and the first message's id (0
// and "" when the queue was empty).
func (s *session) deliverQueuedLocked() (int64, string, error) {
	var seq int64
	var firstID string
	for len(s.queue) > 0 {
		q := s.queue[0]
		msgID := newID("msg")
		ev, err := s.appendLocked(&flitv1.Event{Payload: &flitv1.Event_QueuedMessageDelivered{QueuedMessageDelivered: &flitv1.QueuedMessageDelivered{
			QueueId: q.id, MessageId: msgID,
		}}})
		if err != nil {
			return 0, "", err
		}
		if err := s.appendUserMessageLocked(msgID, q.text); err != nil {
			return 0, "", err
		}
		s.queue = s.queue[1:]
		if seq == 0 {
			seq, firstID = ev.Seq, msgID
		}
	}
	return seq, firstID, nil
}
