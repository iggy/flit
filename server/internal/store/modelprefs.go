package store

import (
	"context"
	"database/sql"
	"time"
)

// ModelKey names a model: provider and model id.
type ModelKey struct{ Provider, Model string }

// ModelPref is what a team has said about a model: starred, and when a
// session last used it (zero if never).
type ModelPref struct {
	Favorite bool
	LastUsed time.Time
	// NoReasoningEnd: the model kept thinking after being asked to answer
	// now, so flit stops offering it.
	NoReasoningEnd bool
}

// SetFavorite stars or unstars a model for a team.
func (s *Store) SetFavorite(ctx context.Context, teamID string, m ModelKey, favorite bool) error {
	_, err := s.db.ExecContext(ctx, `
INSERT INTO model_prefs (team_id, provider, model, favorite) VALUES (?, ?, ?, ?)
ON CONFLICT (team_id, provider, model) DO UPDATE SET favorite = excluded.favorite`,
		teamID, m.Provider, m.Model, favorite)
	return err
}

// TouchModel records that a session in the team used a model at at.
func (s *Store) TouchModel(ctx context.Context, teamID string, m ModelKey, at time.Time) error {
	_, err := s.db.ExecContext(ctx, `
INSERT INTO model_prefs (team_id, provider, model, last_used) VALUES (?, ?, ?, ?)
ON CONFLICT (team_id, provider, model) DO UPDATE SET last_used = MAX(COALESCE(last_used, 0), excluded.last_used)`,
		teamID, m.Provider, m.Model, at.UnixNano())
	return err
}

// SetNoReasoningEnd records that the model ignores "answer now".
func (s *Store) SetNoReasoningEnd(ctx context.Context, teamID string, m ModelKey) error {
	_, err := s.db.ExecContext(ctx, `
INSERT INTO model_prefs (team_id, provider, model, no_reasoning_end) VALUES (?, ?, ?, 1)
ON CONFLICT (team_id, provider, model) DO UPDATE SET no_reasoning_end = 1`,
		teamID, m.Provider, m.Model)
	return err
}

// ModelPrefs returns the team's favorites and last-used times.
func (s *Store) ModelPrefs(ctx context.Context, teamID string) (map[ModelKey]ModelPref, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT provider, model, favorite, last_used, no_reasoning_end FROM model_prefs WHERE team_id = ?`, teamID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[ModelKey]ModelPref{}
	for rows.Next() {
		var k ModelKey
		var p ModelPref
		var used sql.NullInt64
		if err := rows.Scan(&k.Provider, &k.Model, &p.Favorite, &used, &p.NoReasoningEnd); err != nil {
			return nil, err
		}
		p.LastUsed = nullableTime(used)
		out[k] = p
	}
	return out, rows.Err()
}
