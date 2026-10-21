package store

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// Cron run states, as stored.
const (
	CronRunning        = "running"
	CronOK             = "ok"
	CronNeedsAttention = "needs_attention"
	CronFailed         = "failed"
	CronSkipped        = "skipped"
)

// What started a cron run, as stored.
const (
	CronCauseSchedule = "schedule"
	CronCauseCatchUp  = "catch_up"
	CronCauseManual   = "manual"
)

// CronRun is one run of a cron job (see package cron).
type CronRun struct {
	ID        string
	TeamID    string
	Job       string
	ProjectID string
	// SessionID is empty for skipped runs and runs that failed to start.
	SessionID   string
	Cause       string
	State       string
	ScheduledAt time.Time
	StartedAt   time.Time
	// FinishedAt is zero while running.
	FinishedAt time.Time
	// Summary is the first line of the final reply, or why it failed or
	// was skipped.
	Summary string
	// Refused are commands refused because nobody could approve them.
	Refused []string
	// Quiet is set when the report was "nothing to report".
	Quiet bool
}

const cronRunCols = `id, team_id, job, project_id, session_id, cause, state, scheduled_at, started_at, finished_at, summary, refused, quiet`

func scanCronRun(row interface{ Scan(...any) error }) (CronRun, error) {
	var r CronRun
	var scheduled, started int64
	var finished sql.NullInt64
	var refused string
	err := row.Scan(&r.ID, &r.TeamID, &r.Job, &r.ProjectID, &r.SessionID, &r.Cause, &r.State, &scheduled, &started,
		&finished, &r.Summary, &refused, &r.Quiet)
	if errors.Is(err, sql.ErrNoRows) {
		return CronRun{}, ErrNotFound
	}
	r.ScheduledAt, r.StartedAt, r.FinishedAt = time.Unix(0, scheduled), time.Unix(0, started), nullableTime(finished)
	r.Refused = splitNames(refused)
	return r, err
}

// CreateCronRun stores a new run.
func (s *Store) CreateCronRun(ctx context.Context, r *CronRun) error {
	var finished sql.NullInt64
	if !r.FinishedAt.IsZero() {
		finished = sql.NullInt64{Int64: r.FinishedAt.UnixNano(), Valid: true}
	}
	_, err := s.db.ExecContext(ctx, `INSERT INTO cron_runs (`+cronRunCols+`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		r.ID, r.TeamID, r.Job, r.ProjectID, r.SessionID, r.Cause, r.State, r.ScheduledAt.UnixNano(), r.StartedAt.UnixNano(),
		finished, r.Summary, joinNames(r.Refused), r.Quiet)
	return err
}

// UpdateCronRun stores a run's session, state and outcome.
func (s *Store) UpdateCronRun(ctx context.Context, r CronRun) error {
	var finished sql.NullInt64
	if !r.FinishedAt.IsZero() {
		finished = sql.NullInt64{Int64: r.FinishedAt.UnixNano(), Valid: true}
	}
	res, err := s.db.ExecContext(ctx, `UPDATE cron_runs SET session_id = ?, project_id = ?, state = ?, finished_at = ?, summary = ?, refused = ?, quiet = ? WHERE id = ?`,
		r.SessionID, r.ProjectID, r.State, finished, r.Summary, joinNames(r.Refused), r.Quiet, r.ID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// GetCronRun returns one run.
func (s *Store) GetCronRun(ctx context.Context, id string) (CronRun, error) {
	return scanCronRun(s.db.QueryRowContext(ctx, `SELECT `+cronRunCols+` FROM cron_runs WHERE id = ?`, id))
}

// ListCronRuns returns a team's runs of job (all jobs if empty), newest
// first.
func (s *Store) ListCronRuns(ctx context.Context, teamID, job string, limit, offset int) ([]CronRun, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT `+cronRunCols+` FROM cron_runs WHERE team_id = ? AND (? = '' OR job = ?)
		ORDER BY started_at DESC, id DESC LIMIT ? OFFSET ?`, teamID, job, job, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []CronRun
	for rows.Next() {
		r, err := scanCronRun(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// LastCronRuns returns each job's latest run.
func (s *Store) LastCronRuns(ctx context.Context, teamID string) (map[string]CronRun, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT `+cronRunCols+` FROM cron_runs r WHERE team_id = ? AND started_at =
		(SELECT max(started_at) FROM cron_runs WHERE team_id = r.team_id AND job = r.job)`, teamID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]CronRun{}
	for rows.Next() {
		r, err := scanCronRun(rows)
		if err != nil {
			return nil, err
		}
		out[r.Job] = r
	}
	return out, rows.Err()
}

// LastCronSlots returns, per job, the latest slot a run was recorded for
// (run, skipped or failed), so a slot is never run twice.
func (s *Store) LastCronSlots(ctx context.Context, teamID string) (map[string]time.Time, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT job, max(scheduled_at) FROM cron_runs WHERE team_id = ? AND cause != ? GROUP BY job`,
		teamID, CronCauseManual)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]time.Time{}
	for rows.Next() {
		var job string
		var at int64
		if err := rows.Scan(&job, &at); err != nil {
			return nil, err
		}
		out[job] = time.Unix(0, at)
	}
	return out, rows.Err()
}

// FailUnfinishedCronRuns marks runs left running (by a previous flit that
// stopped) as failed.
func (s *Store) FailUnfinishedCronRuns(ctx context.Context, summary string) (int64, error) {
	res, err := s.db.ExecContext(ctx, `UPDATE cron_runs SET state = ?, finished_at = ?, summary = ? WHERE state = ?`,
		CronFailed, time.Now().UnixNano(), summary, CronRunning)
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// ArchiveCronSessions archives the sessions of job's runs beyond the newest
// keep. It returns the ids it archived.
func (s *Store) ArchiveCronSessions(ctx context.Context, teamID, job string, keep int) ([]string, error) {
	rows, err := s.db.QueryContext(ctx, `UPDATE sessions SET archived = 1 WHERE team_id = ? AND cron_id = ? AND NOT archived AND id NOT IN
		(SELECT id FROM sessions WHERE team_id = ? AND cron_id = ? ORDER BY created_at DESC, id DESC LIMIT ?) RETURNING id`,
		teamID, job, teamID, job, keep)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}
