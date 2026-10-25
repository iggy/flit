package agent

import (
	flitv1 "github.com/iggy/flit/server/gen/flit/v1"
	"github.com/iggy/flit/server/internal/llm"
)

// Per-model concurrency (providers[].concurrency): every model call any
// session, subagent or background task makes goes through the Manager's
// llm.Limiter, which holds calls over the limit back until one ends.

// Limiter is the limiter every model call flit makes shares. Other
// packages making model calls (learning) use it too, and the config
// watcher calls its Changed.
func (m *Manager) Limiter() *llm.Limiter { return m.limiter }

// limitHandlers returns the llm.Handler Queued and Admitted funcs for a
// call: while it waits for a slot it is marked queued on call (so
// watchWait doesn't report llama.cpp's view of the wait over flit's own)
// and the wait is logged and recorded as ModelCallWaiting events through
// appendEv. call may be nil.
func (s *session) limitHandlers(msgID string, attempt int32, provider, model string, call *liveCall,
	appendEv func(*flitv1.Event) error, appendErr *error) (queued func(int), admitted func()) {
	waiting := func(reason flitv1.ModelWaitReason, limit int) {
		if err := appendEv(&flitv1.Event{Payload: &flitv1.Event_ModelCallWaiting{ModelCallWaiting: &flitv1.ModelCallWaiting{
			MessageId: msgID, Attempt: attempt, Reason: reason, TotalSlots: int32(limit),
		}}}); err != nil && *appendErr == nil {
			*appendErr = err
		}
	}
	queued = func(limit int) {
		s.setQueued(call, true)
		s.m.log.Info("model call waiting for its turn (concurrency limit)", "session", s.snapshot().ID, "message", msgID,
			"provider", provider, "model", model, "limit", limit)
		waiting(flitv1.ModelWaitReason_MODEL_WAIT_REASON_CONCURRENCY_LIMIT, limit)
	}
	admitted = func() {
		s.setQueued(call, false)
		s.m.log.Info("model call got its turn", "session", s.snapshot().ID, "message", msgID, "provider", provider, "model", model)
		waiting(flitv1.ModelWaitReason_MODEL_WAIT_REASON_UNSPECIFIED, 0)
	}
	return queued, admitted
}

func (s *session) setQueued(c *liveCall, queued bool) {
	if c == nil {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	c.queued = queued
}

// appendFunc adapts s.append for limitHandlers.
func (s *session) appendFunc(ev *flitv1.Event) error {
	_, err := s.append(ev)
	return err
}

func (s *session) callQueued(c *liveCall) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return c.queued
}
