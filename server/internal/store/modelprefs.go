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

// ModelPrefs returns the team's favorites and last-used times.
func (s *Store) ModelPrefs(ctx context.Context, teamID string) (map[ModelKey]ModelPref, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT provider, model, favorite, last_used FROM model_prefs WHERE team_id = ?`, teamID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[ModelKey]ModelPref{}
	for rows.Next() {
		var k ModelKey
		var p ModelPref
		var used sql.NullInt64
		if err := rows.Scan(&k.Provider, &k.Model, &p.Favorite, &used); err != nil {
			return nil, err
		}
		p.LastUsed = nullableTime(used)
		out[k] = p
	}
	return out, rows.Err()
}
