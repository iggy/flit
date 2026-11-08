package store

import (
	"context"
	"database/sql"
	"time"
)

// Fact is a learned environment fact (see package facts). Detail is opaque
// here. Sessions are its per-session verdicts, oldest session first.
type Fact struct {
	ID        string
	TeamID    string
	ProjectID string
	// Scope narrows a fact within its project: the directory, for the
	// Scratch project; empty otherwise.
	Scope       string
	Family      string
	Detail      string
	CreatedAt   time.Time
	ForgottenAt time.Time // zero unless forgotten
	Sessions    []FactSession
}

// FactSession is what one session said about a fact. A row exists only for
// sessions that exercised it.
type FactSession struct {
	FactID           string
	SessionID        string
	SessionCreatedAt time.Time
	Confirmed        bool
	Contradicted     bool
	Fired            bool
	Turns            string // "2,5"
}

// ListFacts returns a project's facts (every project's for ""), with their
// sessions, oldest first.
func (s *Store) ListFacts(ctx context.Context, projectID string) ([]Fact, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT id, team_id, project_id, scope, family, detail, created_at, forgotten_at
		FROM learned_facts WHERE (? = '' OR project_id = ?) ORDER BY created_at, id`, projectID, projectID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Fact
	at := map[string]int{}
	for rows.Next() {
		var f Fact
		var created int64
		var forgotten sql.NullInt64
		if err := rows.Scan(&f.ID, &f.TeamID, &f.ProjectID, &f.Scope, &f.Family, &f.Detail, &created, &forgotten); err != nil {
			return nil, err
		}
		f.CreatedAt, f.ForgottenAt = time.Unix(0, created), nullableTime(forgotten)
		at[f.ID] = len(out)
		out = append(out, f)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	sessions, err := s.db.QueryContext(ctx, `SELECT s.fact_id, s.session_id, s.session_created_at, s.confirmed, s.contradicted, s.fired, s.turns
		FROM learned_fact_sessions s JOIN learned_facts f ON f.id = s.fact_id
		WHERE (? = '' OR f.project_id = ?) ORDER BY s.session_created_at, s.session_id`, projectID, projectID)
	if err != nil {
		return nil, err
	}
	defer sessions.Close()
	for sessions.Next() {
		var r FactSession
		var created int64
		if err := sessions.Scan(&r.FactID, &r.SessionID, &created, &r.Confirmed, &r.Contradicted, &r.Fired, &r.Turns); err != nil {
			return nil, err
		}
		r.SessionCreatedAt = time.Unix(0, created)
		if i, ok := at[r.FactID]; ok {
			out[i].Sessions = append(out[i].Sessions, r)
		}
	}
	return out, sessions.Err()
}

// ReplaceFactSession records what a session says about facts: it adds
// newFacts, replaces the session's verdicts on every fact not forgotten,
// and drops facts in projectID that nothing supports any more.
func (s *Store) ReplaceFactSession(ctx context.Context, sessionID, projectID string, newFacts []Fact, verdicts []FactSession) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	for _, f := range newFacts {
		if _, err := tx.ExecContext(ctx, `INSERT INTO learned_facts (id, team_id, project_id, scope, family, detail, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO NOTHING`,
			f.ID, f.TeamID, f.ProjectID, f.Scope, f.Family, f.Detail, f.CreatedAt.UnixNano()); err != nil {
			return err
		}
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM learned_fact_sessions WHERE session_id = ?
		AND fact_id IN (SELECT id FROM learned_facts WHERE forgotten_at IS NULL)`, sessionID); err != nil {
		return err
	}
	for _, r := range verdicts {
		if _, err := tx.ExecContext(ctx, `INSERT INTO learned_fact_sessions
			(fact_id, session_id, session_created_at, confirmed, contradicted, fired, turns) VALUES (?, ?, ?, ?, ?, ?, ?)`,
			r.FactID, sessionID, r.SessionCreatedAt.UnixNano(), r.Confirmed, r.Contradicted, r.Fired, r.Turns); err != nil {
			return err
		}
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM learned_facts WHERE project_id = ? AND forgotten_at IS NULL
		AND NOT EXISTS (SELECT 1 FROM learned_fact_sessions s WHERE s.fact_id = learned_facts.id)`, projectID); err != nil {
		return err
	}
	return tx.Commit()
}

// ForgetFact retires a fact for good: flit won't learn it again.
func (s *Store) ForgetFact(ctx context.Context, id string, at time.Time) error {
	res, err := s.db.ExecContext(ctx, `UPDATE learned_facts SET forgotten_at = ? WHERE id = ? AND forgotten_at IS NULL`, at.UnixNano(), id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// ClearFacts deletes what was learned for a project (every project for
// ""), except forgotten facts, and keeps the record of what was injected.
func (s *Store) ClearFacts(ctx context.Context, projectID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, `DELETE FROM learned_fact_sessions WHERE fact_id IN
		(SELECT id FROM learned_facts WHERE forgotten_at IS NULL AND (? = '' OR project_id = ?))`, projectID, projectID); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `DELETE FROM learned_facts WHERE forgotten_at IS NULL AND (? = '' OR project_id = ?)`, projectID, projectID); err != nil {
		return err
	}
	return tx.Commit()
}

// RecordFactInjections notes that a session's prompt carried these facts.
func (s *Store) RecordFactInjections(ctx context.Context, sessionID string, factIDs []string) error {
	for _, id := range factIDs {
		if _, err := s.db.ExecContext(ctx, `INSERT INTO learned_fact_injections (fact_id, session_id) VALUES (?, ?)
			ON CONFLICT DO NOTHING`, id, sessionID); err != nil {
			return err
		}
	}
	return nil
}

// FactInjections returns the ids of the facts a session's prompt carried.
func (s *Store) FactInjections(ctx context.Context, sessionID string) (map[string]bool, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT fact_id FROM learned_fact_injections WHERE session_id = ?`, sessionID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]bool{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out[id] = true
	}
	return out, rows.Err()
}
