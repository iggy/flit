package facts

import (
	"github.com/iggy/flit/server/internal/config"
	"github.com/iggy/flit/server/internal/store"
)

// Fact states.
const (
	StateForming   = "forming"
	StateActive    = "active"
	StateRetired   = "retired"
	StateForgotten = "forgotten"
)

// status is a fact's lifecycle, worked out from its per-session verdicts.
// Nothing but the verdicts is stored, so changing a threshold in the config
// applies right away, and replaying the log gives the same answer.
type status struct {
	state         string
	confirmations int
	exercised     int
	fired         int
}

// fold replays a fact's sessions, oldest first.
//
// A fact is forming until learning.facts_promote_sessions sessions confirm
// it. learning.facts_retire_sessions contradicting sessions in a row retire
// a spelling or variable fact; a session in which a boundary's host answers
// retires it at once. A retired fact starts over if the failure comes back.
func fold(family string, rows []store.FactSession, l config.Learning) status {
	limit := l.FactsRetireSessions
	if family == familyBoundary {
		limit = 1
	}
	st := status{state: StateForming}
	streak := 0
	for _, r := range rows {
		if st.state == StateRetired {
			if !r.Confirmed {
				continue
			}
			st, streak = status{state: StateForming}, 0
		}
		st.exercised++
		if r.Fired {
			st.fired++
		}
		switch {
		case r.Confirmed:
			st.confirmations++
			streak = 0
		case r.Contradicted:
			streak++
		default:
			streak = 0 // used, but it says nothing either way
		}
		if streak >= limit {
			st.state = StateRetired
			continue
		}
		if st.state == StateForming && st.confirmations >= l.FactsPromoteSessions {
			st.state = StateActive
		}
	}
	return st
}

// injectable says an active fact passes the firing gate.
func (st status) injectable(l config.Learning) bool {
	if st.state != StateActive || st.exercised < l.FactsFireMinSessions {
		return false
	}
	return float64(st.fired)/float64(st.exercised) >= l.FactsFireRate
}
