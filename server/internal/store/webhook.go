package store

import (
	"context"
	"database/sql"
	"errors"
	"time"
)

// Webhook run states, as stored. A run is queued until a slot is free (see
// the hook's concurrency), then running; it ends like a cron run.
const (
	WebhookQueued         = "queued"
	WebhookRunning        = CronRunning
	WebhookOK             = CronOK
	WebhookNeedsAttention = CronNeedsAttention
	WebhookFailed         = CronFailed
	WebhookSkipped        = CronSkipped
)

// WebhookRun is one delivery to a webhook and the session it started (see
// package webhook).
type WebhookRun struct {
	ID     string
	TeamID string
	Hook   string
	// DeliveryID is the sender's id for the delivery (GitHub's
	// X-GitHub-Delivery); see DeliverySeen.
	DeliveryID string
	Event      string
	Action     string
	// About is one line on what happened.
	About     string
	ProjectID string
	// SessionID is empty until the run starts, and for runs that never did.
	SessionID  string
	State      string
	ReceivedAt time.Time
	// StartedAt and FinishedAt are zero until then.
	StartedAt  time.Time
	FinishedAt time.Time
	// Summary is the first line of the final reply, or why it failed or
	// was skipped.
	Summary string
	// Refused are commands refused because nobody could approve them.
	Refused []string
	// Quiet is set when the report was "nothing to report".
	Quiet bool
}

const webhookRunCols = `id, team_id, hook, delivery_id, event, action, about, project_id, session_id, state, received_at, started_at, finished_at, summary, refused, quiet`

func scanWebhookRun(row interface{ Scan(...any) error }) (WebhookRun, error) {
	var r WebhookRun
	var received int64
	var started, finished sql.NullInt64
	var refused string
	err := row.Scan(&r.ID, &r.TeamID, &r.Hook, &r.DeliveryID, &r.Event, &r.Action, &r.About, &r.ProjectID, &r.SessionID,
		&r.State, &received, &started, &finished, &r.Summary, &refused, &r.Quiet)
	if errors.Is(err, sql.ErrNoRows) {
		return WebhookRun{}, ErrNotFound
	}
	r.ReceivedAt, r.StartedAt, r.FinishedAt = time.Unix(0, received), nullableTime(started), nullableTime(finished)
	r.Refused = splitNames(refused)
	return r, err
}

func nullTime(t time.Time) sql.NullInt64 {
	if t.IsZero() {
		return sql.NullInt64{}
	}
	return sql.NullInt64{Int64: t.UnixNano(), Valid: true}
}

// CreateWebhookRun stores a new run.
func (s *Store) CreateWebhookRun(ctx context.Context, r *WebhookRun) error {
	_, err := s.db.ExecContext(ctx, `INSERT INTO webhook_runs (`+webhookRunCols+`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		r.ID, r.TeamID, r.Hook, r.DeliveryID, r.Event, r.Action, r.About, r.ProjectID, r.SessionID, r.State,
		r.ReceivedAt.UnixNano(), nullTime(r.StartedAt), nullTime(r.FinishedAt), r.Summary, joinNames(r.Refused), r.Quiet)
	return err
}

// DeliverySeen reports whether hook already has a run for delivery id that
// didn't fail or get skipped, so a redelivery of it shouldn't run again.
func (s *Store) DeliverySeen(ctx context.Context, teamID, hook, id string) (bool, error) {
	if id == "" {
		return false, nil
	}
	var n int
	err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM webhook_runs WHERE team_id = ? AND hook = ? AND delivery_id = ? AND state NOT IN (?, ?)`,
		teamID, hook, id, WebhookFailed, WebhookSkipped).Scan(&n)
	return n > 0, err
}

// UpdateWebhookRun stores a run's session, state and outcome.
func (s *Store) UpdateWebhookRun(ctx context.Context, r WebhookRun) error {
	res, err := s.db.ExecContext(ctx, `UPDATE webhook_runs SET session_id = ?, project_id = ?, state = ?, started_at = ?, finished_at = ?,
		summary = ?, refused = ?, quiet = ? WHERE id = ?`,
		r.SessionID, r.ProjectID, r.State, nullTime(r.StartedAt), nullTime(r.FinishedAt), r.Summary, joinNames(r.Refused), r.Quiet, r.ID)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotFound
	}
	return nil
}

// GetWebhookRun returns one run.
func (s *Store) GetWebhookRun(ctx context.Context, id string) (WebhookRun, error) {
	return scanWebhookRun(s.db.QueryRowContext(ctx, `SELECT `+webhookRunCols+` FROM webhook_runs WHERE id = ?`, id))
}

// ListWebhookRuns returns a team's runs of hook (all hooks if empty),
// newest first.
func (s *Store) ListWebhookRuns(ctx context.Context, teamID, hook string, limit, offset int) ([]WebhookRun, error) {
	rows, err := s.db.QueryContext(ctx, `SELECT `+webhookRunCols+` FROM webhook_runs WHERE team_id = ? AND (? = '' OR hook = ?)
		ORDER BY received_at DESC, id DESC LIMIT ? OFFSET ?`, teamID, hook, hook, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []WebhookRun
	for rows.Next() {
		r, err := scanWebhookRun(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// FailUnfinishedWebhookRuns marks runs left queued or running (by a
// previous flit that stopped) as failed.
func (s *Store) FailUnfinishedWebhookRuns(ctx context.Context, summary string) (int64, error) {
	res, err := s.db.ExecContext(ctx, `UPDATE webhook_runs SET state = ?, finished_at = ?, summary = ? WHERE state IN (?, ?)`,
		WebhookFailed, time.Now().UnixNano(), summary, WebhookQueued, WebhookRunning)
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// ArchiveWebhookSessions archives the sessions hook started beyond the
// newest keep. It returns the ids it archived.
func (s *Store) ArchiveWebhookSessions(ctx context.Context, teamID, hook string, keep int) ([]string, error) {
	rows, err := s.db.QueryContext(ctx, `UPDATE sessions SET archived = 1 WHERE team_id = ? AND webhook_id = ? AND NOT archived AND id NOT IN
		(SELECT id FROM sessions WHERE team_id = ? AND webhook_id = ? ORDER BY created_at DESC, id DESC LIMIT ?) RETURNING id`,
		teamID, hook, teamID, hook, keep)
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
